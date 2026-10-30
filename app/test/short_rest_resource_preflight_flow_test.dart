import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _CountingRandom implements Random {
  final maxima = <int>[];
  int get calls => maxima.length;

  @override
  int nextInt(int max) {
    maxima.add(max);
    return 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

Campaign _wounded(GameEngine engine, {bool monk = false}) {
  final demo = engine.createDemo();
  return Campaign.fromJson(
    demo
        .copyWith(
          hero: demo.hero.copyWith(
            className: monk ? 'Monk' : 'Fighter',
            secondaryClassName: monk ? 'Magier' : 'Warlock',
            secondaryClassLevel: 2,
            level: monk ? 6 : 4,
            abilities: {for (final ability in abilityNames) ability: 14},
            hitPoints: 3,
            maxHitPoints: 40,
            temporaryHitPoints: 7,
            spentSecondWind: monk ? 0 : 2,
            spentActionSurge: monk ? 0 : 1,
            spentPactSlots: monk ? 0 : 2,
            spentSpellSlots: monk ? const {'1': 1} : const {},
            spentClassResources: monk ? const {'focusPoints': 4} : const {},
            spentHitDice: const {},
            concentratingOn: '',
          ),
          encounter: null,
        )
        .toJson(),
  );
}

enum _InvalidPool { secondWind, actionSurge, generalClassResource, pactMagic }

HeroCharacter _invalidHero(HeroCharacter before, _InvalidPool pool) =>
    switch (pool) {
      _InvalidPool.secondWind => before.copyWith(spentSecondWind: 3),
      _InvalidPool.actionSurge => before.copyWith(spentActionSurge: 2),
      _InvalidPool.generalClassResource => before.copyWith(
        spentClassResources: const {'focusPoints': 1},
      ),
      _InvalidPool.pactMagic => before.copyWith(spentPactSlots: 3),
    };

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late GameController controller;
  late GameEngine engine;
  late _CountingRandom random;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('short-rest-preflight-');
    path = '${directory.path}/game.sqlite';
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    random = _CountingRandom();
    engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 10, 30),
    );
    controller = GameController(repository: repository, engine: engine);
    await controller.initialize();
    expect(controller.error, isNull);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
    await directory.delete(recursive: true);
  });

  Future<Map<String, List<Map<String, Object?>>>> tables() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      return {
        for (final table in [
          'campaigns',
          'campaign_revisions',
          'game_events',
          'characters',
          'settings',
          'pending_player_actions',
        ])
          table: await db.query(table, orderBy: 'rowid'),
      };
    } finally {
      await db.close();
    }
  }

  Future<void> open(Campaign campaign) async {
    await repository.saveCampaign(campaign, events: campaign.events);
    await controller.initialize();
    expect(controller.error, isNull);
    await controller.openCampaign(campaign.id);
    expect(controller.error, isNull);
    expect(controller.currentCampaign!.toJson(), campaign.toJson());
  }

  Future<void> restart() async {
    controller.dispose();
    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    controller = GameController(repository: repository, engine: engine);
    await controller.initialize();
    expect(controller.error, isNull);
  }

  Future<void> unchanged(
    Campaign campaign,
    Map<String, List<Map<String, Object?>>> rows,
  ) async {
    expect(controller.currentCampaign!.toJson(), campaign.toJson());
    expect(controller.campaigns.single.toJson(), campaign.toJson());
    expect(controller.characters.single.toJson(), campaign.hero.toJson());
    expect(
      (await repository.getCampaign(campaign.id))!.toJson(),
      campaign.toJson(),
    );
    expect(
      (await repository.reconstructCampaign(
        campaign.id,
        revision: campaign.revision,
      ))!.toJson(),
      campaign.toJson(),
    );
    expect(
      await repository.reconstructCampaign(
        campaign.id,
        revision: campaign.revision + 1,
      ),
      isNull,
    );
    // This compares raw JSON snapshot strings and every other stored column,
    // rather than merely comparing deserialized character values.
    expect(await tables(), rows);
  }

  for (final pool in _InvalidPool.values) {
    test(
      '${pool.name}: explizite 1/2W10-Rast blockiert vor RNG, Heilung und sechs SQLite-Tabellen',
      () async {
        final before = _wounded(engine);
        await open(before);
        final rows = await tables();
        final forged = before.copyWith(hero: _invalidHero(before.hero, pool));
        final originalInput = forged.toJson();

        for (final count in [1, 2]) {
          // Engine catches the rest failure to prepare a blocked event, but
          // its final snapshot validation rejects the invalid original hero.
          // No blocked event can authorize or persist the forged resource.
          expect(
            () => engine.act(forged, 'Ich mache eine kurze Rast ${count}W10.'),
            throwsFormatException,
          );
          expect(random.calls, 0);
          expect(forged.toJson(), originalInput);
          await unchanged(before, rows);
        }

        // Model constructors/copyWith are not an import authority. Simulate
        // an invalid in-memory caller while the durable save remains valid.
        controller.currentCampaign = forged;
        await controller.sendAction(
          'Ich mache eine kurze Rast 2W10.',
          requestId: 'rejected-rest-${pool.name}',
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), originalInput);
        expect(controller.campaigns.single.toJson(), before.toJson());
        expect(controller.characters.single.toJson(), before.hero.toJson());
        expect(random.calls, 0);
        expect(await tables(), rows);

        await controller.openCampaign(before.id);
        expect(controller.error, isNull);
        await unchanged(before, rows);
        await expectLater(
          repository.saveCampaign(
            forged.copyWith(revision: before.revision + 1),
            expectedRevision: before.revision,
          ),
          throwsFormatException,
        );
        await controller.importCampaign(jsonEncode(forged.toJson()));
        expect(controller.error, isNotNull);
        await unchanged(before, rows);
        expect(random.calls, 0);
        await restart();
        await unchanged(before, rows);
      },
    );
  }

  for (final monk in [false, true]) {
    test(
      '${monk ? 'Monk 4/Magier 2' : 'Fighter 2/Warlock 2'}: Rast verbucht Heilung und Erholung einmal, Retry/Neustart bleiben inert',
      () async {
        final before = _wounded(engine, monk: monk);
        await open(before);
        final stale = GameController(repository: repository, engine: engine);
        try {
          await stale.initialize();
          await stale.openCampaign(before.id);
          expect(stale.error, isNull);
          final sides = monk ? 8 : 10;
          final text = 'Ich mache eine kurze Rast 2W$sides.';
          final requestId = monk ? 'monk-rest-once' : 'fighter-rest-once';
          await controller.sendAction(text, requestId: requestId);
          expect(controller.error, isNull);
          final after = controller.currentCampaign!;
          expect(after.revision, before.revision + 1);
          expect(after.hero.hitPoints, 9);
          expect(after.hero.temporaryHitPoints, 7);
          expect(after.hero.spentHitDice, {'d$sides': 2});
          expect(after.hero.spentSecondWind, monk ? 0 : 1);
          expect(after.hero.spentActionSurge, 0);
          expect(after.hero.spentPactSlots, 0);
          expect(after.hero.spentClassResources, isEmpty);
          expect(after.hero.spentSpellSlots, before.hero.spentSpellSlots);
          if (monk) expect(after.hero.spentSpellSlots, {'1': 1});
          expect(random.maxima, [sides, sides]);
          expect(before.hero.hitPoints, 3);
          expect(before.hero.spentHitDice, isEmpty);
          expect(before.hero.spentSecondWind, monk ? 0 : 2);
          expect(after.events, hasLength(before.events.length + 1));
          final event = after.events.last;
          expect(event.type, 'character.shortRest');
          expect(event.payload['hitDice'], 'd$sides');
          expect(event.payload['count'], 2);
          expect(event.payload['constitutionBonus'], 2);
          expect(event.payload['healed'], 6);
          expect(event.payload['pactSlotsRecovered'], monk ? 0 : 2);
          expect(event.payload['sorcerousRestorationUsed'], isFalse);
          expect(event.payload['actionRequestId'], requestId);
          final rolls = event.payload['rolls'] as List;
          expect(rolls, hasLength(2));
          expect(rolls.map((r) => r['rolls']).toList(), [
            [1],
            [1],
          ]);
          expect(
            MemoryEngine.replay(before, after.events).toJson(),
            after.toJson(),
          );
          final exported = jsonDecode(controller.exportCampaign());
          expect(Campaign.fromJson(exported).toJson(), after.toJson());
          final rows = await tables();

          // A matching confirmed request acknowledges the durable event; it
          // does not perform another rest or recover another Second Wind.
          await controller.sendAction(text, requestId: requestId);
          expect(controller.error, isNull);
          expect(random.calls, 2);
          await unchanged(after, rows);

          await stale.sendAction(text, requestId: 'stale-rest-request');
          expect(stale.error, contains('neu laden'));
          expect(random.calls, 2);
          await unchanged(after, rows);

          await restart();
          await unchanged(after, rows);
          await controller.sendAction(text, requestId: requestId);
          expect(controller.error, isNull);
          expect(random.calls, 2);
          await unchanged(after, rows);
          expect(
            (await repository.reconstructCampaign(
              before.id,
              revision: before.revision,
            ))!.toJson(),
            before.toJson(),
          );
        } finally {
          stale.dispose();
        }
      },
    );
  }

  test(
    'später SQLite-Ereignisfehler rollt gültige Rast samt Heilung, Würfeln und Ressourcen zurück',
    () async {
      final before = _wounded(engine);
      await open(before);
      final rows = await tables();
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await db.execute('''
CREATE TRIGGER reject_short_rest
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"character.shortRest"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled rest event failure');
END
''');
      } finally {
        await db.close();
      }
      await controller.sendAction(
        'Ich mache eine kurze Rast 2W10.',
        requestId: 'rolled-back-rest',
      );
      expect(controller.error, isNotNull);
      // Dice were legitimately resolved before the database failure. Only
      // the confirmed state is atomic; an external RNG cannot be rolled back.
      expect(random.maxima, [10, 10]);
      await unchanged(before, rows);
      await restart();
      await unchanged(before, rows);
    },
  );
}
