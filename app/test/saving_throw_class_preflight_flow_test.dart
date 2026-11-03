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
  int natural = 1;
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return (natural - 1) % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

Object? _sortedJson(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _sortedJson(value[key])};
  }
  if (value is List) return value.map(_sortedJson).toList();
  return value;
}

String _canonical(Object? value) => jsonEncode(_sortedJson(value));

Campaign _campaign(
  GameEngine engine, {
  String primary = 'Paladin',
  String secondary = 'Fighter',
  int level = 12,
  int secondaryLevel = 9,
  int exhaustion = 0,
}) {
  final demo = engine.createDemo();
  return Campaign.fromJson(
    demo
        .copyWith(
          hero: demo.hero.copyWith(
            className: primary,
            secondaryClassName: secondary,
            secondaryClassLevel: secondaryLevel,
            level: level,
            abilities: {for (final ability in abilityNames) ability: 14},
            hitPoints: 30,
            maxHitPoints: 40,
            savingThrowProficiencies: const ['wisdom'],
            spentClassResources: const {},
            conditions: const [],
            exhaustionLevel: exhaustion,
            concentratingOn: '',
          ),
        )
        .toJson(),
  );
}

const _initialSave = 'Rettungswurf: Weisheit SG 30';
const _fighterReroll = 'Rettungswurf wiederholen: Unbeugsam';
const _monkReroll = 'Rettungswurf wiederholen: Fokus';

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late GameController controller;
  late GameEngine engine;
  late _CountingRandom random;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('save-reroll-profile-');
    path = '${directory.path}/game.sqlite';
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    random = _CountingRandom();
    engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 11, 2),
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
    final database = await databaseFactoryFfi.openDatabase(
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
          table: await database.query(table, orderBy: 'rowid'),
      };
    } finally {
      await database.close();
    }
  }

  Future<Campaign> prepare(Campaign campaign) async {
    await repository.saveCampaign(campaign, events: campaign.events);
    await controller.openCampaign(campaign.id);
    expect(controller.error, isNull);
    // This package protects the class reroll. The prior ordinary save remains
    // a separate, confirmed operation and legitimately consumes its own d20.
    await controller.sendAction(_initialSave, requestId: 'initial-save');
    expect(controller.error, isNull);
    expect(controller.currentCampaign!.events.last.type, 'saving.roll');
    expect(controller.currentCampaign!.events.last.payload['failed'], isTrue);
    expect(random.calls, 1);
    random.calls = 0;
    random.natural = 10;
    return controller.currentCampaign!;
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

  Future<void> expectPersisted(Campaign campaign) async {
    expect(
      _canonical(controller.currentCampaign!.toJson()),
      _canonical(campaign.toJson()),
    );
    expect(
      _canonical((await repository.getCampaign(campaign.id))!.toJson()),
      _canonical(campaign.toJson()),
    );
    expect(
      _canonical(
        (await repository.reconstructCampaign(
          campaign.id,
          revision: campaign.revision,
        ))!.toJson(),
      ),
      _canonical(campaign.toJson()),
    );
    expect(
      (await repository.loadCharacters()).single.toJson(),
      campaign.hero.toJson(),
    );
  }

  for (final profile in [
    (
      primary: 'Unbestätigt',
      secondary: 'Monk',
      level: 15,
      secondaryLevel: 14,
      action: _monkReroll,
    ),
    (
      primary: 'Unbestätigt',
      secondary: 'Fighter',
      level: 10,
      secondaryLevel: 9,
      action: _fighterReroll,
    ),
    (
      primary: 'Mönch',
      secondary: 'Monk',
      level: 15,
      secondaryLevel: 7,
      action: _monkReroll,
    ),
    (
      primary: 'Kämpfer',
      secondary: 'Fighter',
      level: 10,
      secondaryLevel: 5,
      action: _fighterReroll,
    ),
  ]) {
    test(
      '${profile.primary}/${profile.secondary}: lesbarer Altstand, blockierter Reroll ohne RNG oder Ressourcenänderung',
      () async {
        final before = await prepare(
          _campaign(
            engine,
            primary: profile.primary,
            secondary: profile.secondary,
            level: profile.level,
            secondaryLevel: profile.secondaryLevel,
          ),
        );
        final oldRows = await tables();
        final savedHero = _canonical(before.hero.toJson());

        await controller.sendAction(profile.action, requestId: 'denied-reroll');
        expect(controller.error, isNull);
        final blocked = controller.currentCampaign!;
        expect(blocked.revision, before.revision + 1);
        expect(blocked.events.last.type, 'rules.blocked');
        expect(_canonical(blocked.hero.toJson()), savedHero);
        expect(blocked.hero.spentClassResources, isEmpty);
        expect(random.calls, 0);
        final blockedRows = await tables();
        // Free-text rejection is an intentional journal entry, not a failed
        // database transaction. Only hero/resource state remains unchanged.
        expect(
          blockedRows['game_events']!.length,
          oldRows['game_events']!.length + 1,
        );
        expect(
          blockedRows['characters']!.single['snapshot'],
          oldRows['characters']!.single['snapshot'],
        );
        await expectPersisted(blocked);

        await controller.sendAction(profile.action, requestId: 'denied-reroll');
        expect(controller.error, isNull);
        expect(await tables(), blockedRows);
        expect(random.calls, 0);

        final exported = await repository.exportCampaign(blocked.id);
        final imported = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: '${directory.path}/import.sqlite',
        );
        try {
          final restored = await imported.importCampaign(exported);
          expect(_canonical(restored.toJson()), _canonical(blocked.toJson()));
          expect(_canonical(restored.hero.toJson()), savedHero);
        } finally {
          await imported.close();
        }
        await restart();
        await expectPersisted(blocked);
        expect(await tables(), blockedRows);
        await controller.sendAction(profile.action, requestId: 'denied-reroll');
        expect(await tables(), blockedRows);
        expect(random.calls, 0);
      },
    );
  }

  for (final monk in [false, true]) {
    test(
      '${monk ? 'Rogue/Monk' : 'Paladin/Fighter'}: echter Alias-Reroll einmal gespeichert, exportiert und nach Neustart bestätigt',
      () async {
        final before = await prepare(
          _campaign(
            engine,
            primary: monk ? 'Rogue' : 'Paladin',
            secondary: monk ? 'Monk' : 'Fighter',
            level: monk ? 15 : 12,
            secondaryLevel: monk ? 14 : 9,
            exhaustion: 1,
          ),
        );
        final action = monk ? _monkReroll : _fighterReroll;
        await controller.sendAction(action, requestId: 'valid-reroll');
        expect(controller.error, isNull);
        final saved = controller.currentCampaign!;
        final event = saved.events.last;
        expect(event.type, 'saving.rerolled');
        expect(event.payload['fighterLevelBonus'], monk ? 0 : 9);
        expect(event.payload['previousTotal'], monk ? 6 : 5);
        final roll = event.payload['roll'] as Map<String, dynamic>;
        expect(roll['natural'], 10);
        // WIS +2, one proficiency (+5 Monk/+4 Fighter total level), one
        // exhaustion penalty (-2), and only Fighter adds its class level9.
        expect(roll['modifier'], monk ? 5 : 13);
        expect(roll['total'], monk ? 15 : 23);
        expect(event.payload['passed'], isFalse);
        expect(saved.hero.spentClassResources, {
          monk ? 'focusPoints' : 'indomitable': 1,
        });
        expect(saved.hero.className, before.hero.className);
        expect(saved.hero.secondaryClassName, before.hero.secondaryClassName);
        expect(random.calls, 1);
        await expectPersisted(saved);
        final rows = await tables();

        await controller.sendAction(action, requestId: 'valid-reroll');
        expect(controller.error, isNull);
        expect(await tables(), rows);
        expect(random.calls, 1);

        final backup = await repository.exportCampaign(saved.id);
        final imported = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: '${directory.path}/import.sqlite',
        );
        try {
          final restored = await imported.importCampaign(backup);
          expect(_canonical(restored.toJson()), _canonical(saved.toJson()));
          expect(
            _canonical(
              (await imported.reconstructCampaign(
                saved.id,
                revision: saved.revision,
              ))!.toJson(),
            ),
            _canonical(saved.toJson()),
          );
        } finally {
          await imported.close();
        }

        await restart();
        await expectPersisted(saved);
        await controller.sendAction(action, requestId: 'valid-reroll');
        expect(await tables(), rows);
        expect(random.calls, 1);
        // A different ID cannot reuse the saving.rerolled event as a new
        // failed initial saving.roll, even while resources remain available.
        await controller.sendAction(action, requestId: 'second-reroll');
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.events.last.type, 'rules.blocked');
        expect(controller.currentCampaign!.hero.toJson(), saved.hero.toJson());
        expect(random.calls, 1);
      },
    );
  }

  test(
    'veralteter zweiter Controller vor RNG abgelehnt, identische bestätigte ID bleibt sicher',
    () async {
      final before = await prepare(_campaign(engine));
      final stale = GameController(repository: repository, engine: engine);
      await stale.initialize();
      expect(stale.currentCampaign!.revision, before.revision);
      try {
        await controller.sendAction(_fighterReroll, requestId: 'writer-reroll');
        expect(controller.error, isNull);
        final saved = controller.currentCampaign!;
        final rows = await tables();
        expect(random.calls, 1);

        await stale.sendAction(_fighterReroll, requestId: 'stale-reroll');
        expect(stale.error, contains('inzwischen geändert'));
        expect(random.calls, 1);
        expect(await tables(), rows);
        expect(stale.currentCampaign!.revision, before.revision);

        await stale.sendAction(_fighterReroll, requestId: 'writer-reroll');
        expect(stale.error, isNull);
        expect(
          _canonical(stale.currentCampaign!.toJson()),
          _canonical(saved.toJson()),
        );
        expect(random.calls, 1);
        expect(await tables(), rows);
      } finally {
        stale.dispose();
      }
    },
  );

  test(
    'später SQLite-Ereignisfehler rollt Spend und Journal zurück, aber keinen legitimen W20',
    () async {
      final before = await prepare(_campaign(engine));
      final rows = await tables();
      final database = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.execute('''
CREATE TRIGGER reject_class_reroll BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"type":"saving.rerolled"') > 0
BEGIN SELECT RAISE(ABORT, 'test rejects saved class reroll'); END
''');
        await controller.sendAction(
          _fighterReroll,
          requestId: 'failed-sql-reroll',
        );
        expect(controller.error, isNotNull);
        expect(random.calls, 1);
        await expectPersisted(before);
        expect(await tables(), rows);
        await database.execute('DROP TRIGGER reject_class_reroll');
      } finally {
        await database.close();
      }

      await restart();
      await expectPersisted(before);
      expect(await tables(), rows);
      await controller.sendAction(
        _fighterReroll,
        requestId: 'failed-sql-reroll',
      );
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.events.last.type, 'saving.rerolled');
      expect(controller.currentCampaign!.hero.spentClassResources, {
        'indomitable': 1,
      });
      expect(random.calls, 2);
    },
  );
}
