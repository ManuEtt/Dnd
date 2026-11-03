import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _CountingRandom implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return 6; // Natural 7: exactly succeeds with +3 against DC 10.
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

Campaign _caster(
  GameEngine engine, {
  String primary = 'Monk',
  String secondary = 'Magier',
  int level = 15,
  int secondaryLevel = 1,
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
            temporaryHitPoints: 4,
            exhaustionLevel: 2,
            // Explicit CON proficiency and Monk 14 must never stack.
            savingThrowProficiencies: const ['constitution'],
            concentratingOn: 'Segen',
            spells: const ['Segen'],
            spentClassResources: const {},
            spentSpellSlots: const {},
            spentPactSlots: 0,
          ),
          encounter: null,
        )
        .toJson(),
  );
}

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late GameController controller;
  late GameEngine engine;
  late _CountingRandom random;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('concentration-class-');
    path = '${directory.path}/game.sqlite';
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    random = _CountingRandom();
    engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 11, 1),
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

  Future<void> open(Campaign campaign) async {
    await repository.saveCampaign(campaign, events: campaign.events);
    await controller.initialize();
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
    Campaign expected,
    Map<String, List<Map<String, Object?>>> rows,
  ) async {
    expect(controller.currentCampaign!.toJson(), expected.toJson());
    expect(controller.campaigns.single.toJson(), expected.toJson());
    expect(controller.characters.single.toJson(), expected.hero.toJson());
    expect(
      (await repository.getCampaign(expected.id))!.toJson(),
      expected.toJson(),
    );
    expect(
      (await repository.reconstructCampaign(
        expected.id,
        revision: expected.revision,
      ))!.toJson(),
      expected.toJson(),
    );
    expect(
      await repository.reconstructCampaign(
        expected.id,
        revision: expected.revision + 1,
      ),
      isNull,
    );
    // Compare raw stored JSON strings and all columns, not only loaded HP.
    expect(await tables(), rows);
  }

  Future<void> confirmDamage({
    GameController? target,
    required Campaign expected,
  }) => (target ?? controller).applyDamage(
    campaignId: expected.id,
    expectedRevision: expected.revision,
    source: 'Bestätigte Feuerfalle',
    components: const [DamageComponent(DamageType.fire, 10)],
    defenses: DamageDefenses(),
  );

  const invalidClasses = [
    (primary: 'Unbestätigt', secondary: 'Monk', level: 15, secondaryLevel: 14),
    (primary: 'Monk', secondary: 'Unbestätigt', level: 15, secondaryLevel: 1),
    (primary: 'Monk', secondary: 'Mönch', level: 14, secondaryLevel: 13),
  ];

  for (final classes in invalidClasses) {
    test(
      '${classes.primary}/${classes.secondary}: Altprofil importierbar, Konzentrationswurf vor RNG und sechs Tabellen gesperrt',
      () async {
        final before = _caster(
          engine,
          primary: classes.primary,
          secondary: classes.secondary,
          level: classes.level,
          secondaryLevel: classes.secondaryLevel,
        );
        final legacyJson = jsonEncode(before.toJson());
        // Legacy reading/import is deliberately independent of new SRD actions.
        await controller.importCampaign(legacyJson);
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect(jsonDecode(controller.exportCampaign()), before.toJson());
        final rows = await tables();
        final input = before.toJson();

        expect(
          () => engine.applyDamage(
            before,
            source: 'Bestätigte Feuerfalle',
            components: const [DamageComponent(DamageType.fire, 10)],
            defenses: DamageDefenses(),
          ),
          throwsFormatException,
        );
        expect(random.calls, 0);
        expect(before.toJson(), input);

        for (var attempt = 0; attempt < 2; attempt++) {
          await confirmDamage(expected: before);
          expect(controller.error, contains('Klassen'));
          expect(random.calls, 0);
          await unchanged(before, rows);
        }
        await restart();
        await unchanged(before, rows);
        expect(jsonDecode(controller.exportCampaign()), before.toJson());
        expect(random.calls, 0);
      },
    );
  }

  test(
    'benannte Zweitklasse Stufe 0 aus unbestätigtem Speicher vor RNG abgewiesen',
    () async {
      final before = _caster(
        engine,
        primary: 'Kleriker',
        secondary: '',
        secondaryLevel: 0,
        level: 5,
      );
      await open(before);
      final rows = await tables();
      final forged = before.copyWith(
        hero: before.hero.copyWith(secondaryClassName: 'Monk'),
      );
      expect(() => Campaign.fromJson(forged.toJson()), throwsFormatException);
      controller.currentCampaign = forged;
      await confirmDamage(expected: forged);
      expect(controller.error, contains('Klassen'));
      expect(random.calls, 0);
      expect(controller.currentCampaign!.toJson(), forged.toJson());
      expect(controller.campaigns.single.toJson(), before.toJson());
      expect(controller.characters.single.toJson(), before.hero.toJson());
      expect(await tables(), rows);
      await controller.openCampaign(before.id);
      await unchanged(before, rows);
      await restart();
      await unchanged(before, rows);
    },
  );

  for (final secondaryMonk in [false, true]) {
    test(
      '${secondaryMonk ? 'Cleric 1/Monk 14' : 'Monk 14/Magier 1'}: Konzentrationsbeleg, Replay, Export/Import und Revision überleben Neustart',
      () async {
        final before = _caster(
          engine,
          primary: secondaryMonk ? 'Cleric' : 'Monk',
          secondary: secondaryMonk ? 'Monk' : 'Magier',
          secondaryLevel: secondaryMonk ? 14 : 1,
        );
        await open(before);
        await confirmDamage(expected: before);
        expect(controller.error, isNull);
        final after = controller.currentCampaign!;
        expect(after.revision, before.revision + 1);
        expect(after.hero.hitPoints, 24);
        expect(after.hero.temporaryHitPoints, 0);
        expect(after.hero.concentratingOn, 'Segen');
        expect(after.hero.spentSpellSlots, before.hero.spentSpellSlots);
        expect(after.hero.spentClassResources, before.hero.spentClassResources);
        expect(random.calls, 1);
        expect(before.hero.hitPoints, 30);
        expect(before.hero.temporaryHitPoints, 4);
        expect(after.events, hasLength(before.events.length + 1));
        final event = after.events.last;
        expect(event.type, 'effect.damage');
        expect(event.payload['source'], 'Bestätigte Feuerfalle');
        expect(event.payload['targetId'], before.hero.id);
        expect(event.payload['damage'], 10);
        expect(event.payload['temporaryHitPointsAbsorbed'], 4);
        expect(event.payload['concentrationDc'], 10);
        expect(event.payload['concentrationMaintained'], isTrue);
        final save = event.payload['concentrationSave'] as Map;
        // +2 CON +5 proficiency -4 exhaustion: neither training source stacks.
        expect(save['modifier'], 3);
        expect(save['natural'], 7);
        expect(save['total'], 10);
        expect(save['rolls'], [7]);
        expect(
          MemoryEngine.replay(before, after.events).toJson(),
          after.toJson(),
        );
        final exported = controller.exportCampaign();
        expect(
          Campaign.fromJson(jsonDecode(exported)).toJson(),
          after.toJson(),
        );
        final rows = await tables();

        // Reusing the confirmed dialog revision cannot apply damage twice.
        await confirmDamage(expected: before);
        expect(controller.error, contains('erneut öffnen'));
        expect(random.calls, 1);
        await unchanged(after, rows);
        await restart();
        await unchanged(after, rows);
        await confirmDamage(expected: before);
        expect(controller.error, contains('erneut öffnen'));
        expect(random.calls, 1);
        await unchanged(after, rows);
        expect(
          (await repository.reconstructCampaign(
            before.id,
            revision: before.revision,
          ))!.toJson(),
          before.toJson(),
        );

        // Import into a separate store, without deleting or overwriting the save.
        final importPath = '${directory.path}/import.sqlite';
        var importedRepository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: importPath,
        );
        var importedController = GameController(
          repository: importedRepository,
          engine: engine,
        );
        try {
          await importedController.initialize();
          await importedController.importCampaign(exported);
          expect(importedController.error, isNull);
          expect(importedController.currentCampaign!.toJson(), after.toJson());
          importedController.dispose();
          await importedRepository.close();
          importedRepository = await SqliteCampaignRepository.open(
            factory: databaseFactoryFfi,
            path: importPath,
          );
          importedController = GameController(
            repository: importedRepository,
            engine: engine,
          );
          await importedController.initialize();
          expect(importedController.error, isNull);
          expect(importedController.currentCampaign!.toJson(), after.toJson());
          expect(random.calls, 1);
          await unchanged(after, rows);
        } finally {
          importedController.dispose();
          await importedRepository.close();
        }
      },
    );
  }

  test(
    'zweiter veralteter Controller verwirft gültigen Wurf beim SQLite-Revisionskonflikt',
    () async {
      final before = _caster(engine);
      await open(before);
      final stale = GameController(repository: repository, engine: engine);
      try {
        await stale.initialize();
        await stale.openCampaign(before.id);
        await confirmDamage(expected: before);
        expect(controller.error, isNull);
        final after = controller.currentCampaign!;
        final rows = await tables();
        expect(random.calls, 1);
        await confirmDamage(target: stale, expected: before);
        expect(stale.error, contains('neu laden'));
        // This older endpoint checks the durable revision at commit. A legitimate
        // provisional die cannot be rolled back; its state must not be stored.
        expect(random.calls, 2);
        expect(stale.currentCampaign!.toJson(), before.toJson());
        await unchanged(after, rows);
        await restart();
        await unchanged(after, rows);
      } finally {
        stale.dispose();
      }
    },
  );

  test(
    'später Ereignisfehler rollt TP, Konzentration, Ereignis und alle sechs Tabellen zurück',
    () async {
      final before = _caster(engine);
      await open(before);
      final rows = await tables();
      final database = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.execute('''
CREATE TRIGGER reject_concentration_event
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"effect.damage"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled concentration event failure');
END
''');
      } finally {
        await database.close();
      }
      await confirmDamage(expected: before);
      expect(controller.error, contains('letzter gespeicherter Spielstand'));
      expect(random.calls, 1);
      await unchanged(before, rows);
      await restart();
      await unchanged(before, rows);
    },
  );
}
