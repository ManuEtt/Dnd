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
  int natural = 10;
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

Object? _sorted(Object? value) {
  if (value is Map<String, dynamic>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _sorted(value[key])};
  }
  if (value is List) return value.map(_sorted).toList();
  return value;
}

String _canonical(Object? value) => jsonEncode(_sorted(value));

Campaign _campaign(
  GameEngine engine, {
  String primary = 'Wizard',
  String secondary = 'Monk',
  int level = 15,
  int secondaryLevel = 14,
  int exhaustion = 1,
  List<String> conditions = const [],
  List<String> proficiencies = const ['wisdom'],
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
            savingThrowProficiencies: proficiencies,
            spentClassResources: const {},
            conditions: conditions,
            exhaustionLevel: exhaustion,
            concentratingOn: '',
            inventory: const [],
            equippedArmorId: '',
            equippedShieldId: '',
            equippedWeaponId: '',
          ),
        )
        .toJson(),
  );
}

const _wisdomSave = 'Rettungswurf: Weisheit SG 20';
const _dexteritySave = 'Rettungswurf: Geschicklichkeit SG 20';

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late GameController controller;
  late GameEngine engine;
  late _CountingRandom random;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('manual-save-profile-');
    path = '${directory.path}/game.sqlite';
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    random = _CountingRandom();
    engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 11, 5),
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

  Future<Campaign> prepare(Campaign campaign) async {
    await repository.saveCampaign(campaign, events: campaign.events);
    await controller.openCampaign(campaign.id);
    expect(controller.error, isNull);
    expect(random.calls, 0);
    return controller.currentCampaign!;
  }

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

  Future<void> expectExportImport(Campaign campaign) async {
    final exported = await repository.exportCampaign(campaign.id);
    final imported = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: '${directory.path}/import.sqlite',
    );
    try {
      final restored = await imported.importCampaign(exported);
      expect(_canonical(restored.toJson()), _canonical(campaign.toJson()));
      expect(
        _canonical(
          (await imported.reconstructCampaign(
            restored.id,
            revision: restored.revision,
          ))!.toJson(),
        ),
        _canonical(campaign.toJson()),
      );
    } finally {
      await imported.close();
    }
  }

  for (final profile in [
    (
      primary: 'Historische Klasse',
      secondary: 'Monk',
      level: 15,
      secondaryLevel: 14,
    ),
    (primary: 'Kämpfer', secondary: 'Fighter', level: 15, secondaryLevel: 6),
  ]) {
    test(
      '${profile.primary}/${profile.secondary}: alter Spielstand bleibt lesbar, Save ohne RNG abgewiesen',
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
        await controller.sendAction(_wisdomSave, requestId: 'rejected-save');
        expect(controller.error, isNull);
        final blocked = controller.currentCampaign!;
        expect(blocked.revision, before.revision + 1);
        expect(blocked.events.last.type, 'rules.blocked');
        expect(blocked.events.last.payload.containsKey('roll'), isFalse);
        expect(
          _canonical(blocked.hero.toJson()),
          _canonical(before.hero.toJson()),
        );
        expect(blocked.hero.spentClassResources, isEmpty);
        expect(random.calls, 0);
        final rows = await tables();
        // A rejected free-text action deliberately records its journal/revision.
        expect(rows['game_events']!.length, oldRows['game_events']!.length + 1);
        expect(
          rows['characters']!.single['snapshot'],
          oldRows['characters']!.single['snapshot'],
        );
        await expectPersisted(blocked);
        await expectExportImport(blocked);
        await restart();
        await expectPersisted(blocked);
        await controller.sendAction(_wisdomSave, requestId: 'rejected-save');
        expect(controller.error, isNull);
        expect(await tables(), rows);
        expect(random.calls, 0);
      },
    );
  }

  for (final monk in [true, false]) {
    test(
      '${monk ? 'Wizard/Monk' : 'Cleric/Fighter'}: Alias, Übung und Erschöpfung einmal, Export und Replay nach Neustart',
      () async {
        final before = await prepare(
          _campaign(
            engine,
            primary: monk ? 'Wizard' : 'Cleric',
            secondary: monk ? ' MONK ' : 'Fighter',
            level: monk ? 15 : 10,
            secondaryLevel: monk ? 14 : 9,
          ),
        );
        await controller.sendAction(_wisdomSave, requestId: 'confirmed-save');
        expect(controller.error, isNull);
        final saved = controller.currentCampaign!;
        final event = saved.events.last;
        expect(event.type, 'saving.roll');
        final roll = event.payload['roll'] as Map<String, dynamic>;
        // WIS +2, one total-level PB (+5 or+4), one Exhaustion penalty -2.
        expect(roll['modifier'], monk ? 5 : 4);
        expect(roll['natural'], 10);
        expect(roll['total'], monk ? 15 : 14);
        expect(event.payload['total'], monk ? 15 : 14);
        expect(event.payload['failed'], isTrue);
        expect(saved.hero.toJson(), before.hero.toJson());
        expect(random.calls, 1);
        final rows = await tables();
        await expectPersisted(saved);
        await expectExportImport(saved);
        await restart();
        await expectPersisted(saved);
        random.natural = 20;
        await controller.sendAction(_wisdomSave, requestId: 'confirmed-save');
        expect(controller.error, isNull);
        expect(await tables(), rows);
        expect(random.calls, 1);
      },
    );
  }

  for (final restrained in [false, true]) {
    test(
      'Danger Sense mit ${restrained ? 'aufgehobenem' : 'bestätigtem'} Vorteil wird korrekt gespeichert',
      () async {
        // Bard supplies recorded DEX training; Barbarian 2 supplies Danger Sense.
        final before = await prepare(
          _campaign(
            engine,
            primary: 'Bard',
            secondary: 'Barbarian',
            level: 3,
            secondaryLevel: 2,
            proficiencies: const ['dexterity'],
            conditions: restrained ? const ['festgesetzt'] : const [],
          ),
        );
        await controller.sendAction(
          _dexteritySave,
          requestId: 'danger-sense-save',
        );
        expect(controller.error, isNull);
        final saved = controller.currentCampaign!;
        expect(saved.events.last.type, 'saving.roll');
        final roll = saved.events.last.payload['roll'] as Map<String, dynamic>;
        expect(roll['modifier'], 2); // +2 DEX +2 PB -2 Exhaustion.
        expect(roll['total'], 12);
        expect(roll['rolls'], restrained ? [10] : [10, 10]);
        expect(random.calls, restrained ? 1 : 2);
        expect(saved.hero.toJson(), before.hero.toJson());
        await restart();
        await expectPersisted(saved);
      },
    );
  }

  test(
    'veralteter Controller vor RNG abgewiesen, bestätigte ID spielt nur gespeichertes Ergebnis zurück',
    () async {
      final before = await prepare(_campaign(engine));
      final stale = GameController(repository: repository, engine: engine);
      await stale.initialize();
      expect(stale.currentCampaign!.revision, before.revision);
      try {
        await controller.sendAction(_wisdomSave, requestId: 'first-writer');
        expect(controller.error, isNull);
        final saved = controller.currentCampaign!;
        final rows = await tables();
        expect(random.calls, 1);
        await stale.sendAction(_wisdomSave, requestId: 'stale-writer');
        expect(stale.error, contains('inzwischen geändert'));
        expect(await tables(), rows);
        expect(random.calls, 1);
        await stale.sendAction(_wisdomSave, requestId: 'first-writer');
        expect(stale.error, isNull);
        expect(
          _canonical(stale.currentCampaign!.toJson()),
          _canonical(saved.toJson()),
        );
        expect(await tables(), rows);
        expect(random.calls, 1);
      } finally {
        stale.dispose();
      }
    },
  );

  test(
    'später SQL-Ereignisfehler rollt alle Tabellen zurück, ein legitimer W20 bleibt verbraucht',
    () async {
      final before = await prepare(_campaign(engine));
      final rows = await tables();
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await db.execute('''
CREATE TRIGGER reject_manual_save BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"type":"saving.roll"') > 0
BEGIN SELECT RAISE(ABORT, 'test rejects manual saving throw'); END
''');
        await controller.sendAction(_wisdomSave, requestId: 'retry-after-sql');
        expect(controller.error, isNotNull);
        expect(random.calls, 1);
        expect(await tables(), rows);
        await expectPersisted(before);
        await db.execute('DROP TRIGGER reject_manual_save');
      } finally {
        await db.close();
      }
      await restart();
      await expectPersisted(before);
      await controller.sendAction(_wisdomSave, requestId: 'retry-after-sql');
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.events.last.type, 'saving.roll');
      expect(controller.currentCampaign!.hero.toJson(), before.hero.toJson());
      expect(random.calls, 2);
    },
  );
}
