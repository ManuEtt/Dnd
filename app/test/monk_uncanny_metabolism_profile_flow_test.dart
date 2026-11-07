import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _InitiativeRandom implements Random {
  final sides = <int>[];
  int get calls => sides.length;

  @override
  int nextInt(int max) {
    final position = calls % 3;
    sides.add(max);
    // Hero 20, foe 1, then martial-arts die 4. The hero starts, so no
    // enemy attack or damage can hide an extra draw or resource change.
    return switch (position) {
      0 => max - 1,
      1 => 0,
      _ => 3,
    };
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
  String primary = 'Fighter',
  String secondary = 'Monk',
  int level = 4,
  int secondaryLevel = 2,
  int spentFocus = 2,
  Map<String, int> otherResources = const {},
}) {
  final demo = engine.createDemo();
  final hero = demo.hero.copyWith(
    id: '${demo.id}-hero',
    name: 'Liora',
    className: primary,
    secondaryClassName: secondary,
    secondaryClassLevel: secondaryLevel,
    level: level,
    subclass: '',
    secondarySubclass: '',
    abilities: const {
      'strength': 12,
      'dexterity': 16,
      'constitution': 14,
      'intelligence': 10,
      'wisdom': 16,
      'charisma': 10,
    },
    hitPoints: 10,
    maxHitPoints: 30,
    temporaryHitPoints: 0,
    armorClass: 16,
    speed: 9,
    weaponDamage: '1d8',
    conditions: const [],
    exhaustionLevel: 0,
    inventory: const [],
    equippedArmorId: '',
    equippedShieldId: '',
    equippedWeaponId: '',
    equippedArmorTrained: false,
    equippedShieldTrained: false,
    spentClassResources: {'focusPoints': spentFocus, ...otherResources},
  );
  final plan = AiStoryPlan.fromJson({
    'title': 'Nebelland',
    'world': 'Veyr',
    'opening': 'Ein dunkler Wald wartet.',
    'premise': 'Die Straße ist versperrt.',
    'secret': 'Ein alter Verrat.',
    'goal': 'Finde den Pfad.',
    'threads': [
      {'id': 'weg', 'title': 'Der Weg', 'description': 'Suche den Pfad.'},
      {'id': 'bund', 'title': 'Der Bund', 'description': 'Finde Freunde.'},
    ],
    'npcs': [
      {
        'id': 'mara',
        'name': 'Mara',
        'description': 'Pfadfinderin',
        'relationship': 'neutral',
      },
    ],
    'places': [
      {'id': 'wald', 'name': 'Wald', 'description': 'Nebliger Pfad'},
    ],
  });
  final campaign = engine
      .createAiCampaign(hero, plan, provider: 'mock')
      .copyWith(
        adventureOffer: AdventureOffer.fromJson({
          'id': 'offer',
          'title': 'Die Brücke',
          'description': 'Ein Schatten wartet.',
          'archetype': 'bandit',
          'questTitle': 'Der Weg',
          'questDescription': 'Überwinde die Brücke.',
        }),
      );
  return Campaign.fromJson(campaign.toJson());
}

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late GameController controller;
  late GameEngine engine;
  late _InitiativeRandom random;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'monk-uncanny-metabolism-profile-',
    );
    path = '${directory.path}/game.sqlite';
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    random = _InitiativeRandom();
    engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 11, 6),
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
    final calls = random.calls;
    // Use the real legacy import, including character/resource validation.
    await controller.importCampaign(jsonEncode(campaign.toJson()));
    expect(controller.error, isNull);
    expect(
      _canonical(controller.currentCampaign!.toJson()),
      _canonical(campaign.toJson()),
    );
    expect(random.calls, calls);
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
      (await repository.loadCharacters())
          .singleWhere((hero) => hero.id == campaign.hero.id)
          .toJson(),
      campaign.hero.toJson(),
    );
    expect(await repository.pendingActionFor(campaign.id), isNull);
  }

  Future<void> expectExportImport(Campaign campaign) async {
    final exported = await repository.exportCampaign(campaign.id);
    final decoded = jsonDecode(exported) as Map<String, dynamic>;
    expect(decoded['schemaVersion'], 1);
    final imported = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: '${directory.path}/export-${campaign.id}.sqlite',
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
      expect(
        (await imported.loadCharacters()).single.toJson(),
        campaign.hero.toJson(),
      );
    } finally {
      await imported.close();
    }
  }

  void expectUsed(
    Campaign before,
    Campaign started, {
    int monkLevel = 2,
    int healing = 6,
  }) {
    expect(started.revision, before.revision + 1);
    expect(started.adventureOffer, isNull);
    expect(started.encounter, isNotNull);
    expect(started.encounter!.isFinished, isFalse);
    expect(started.events.length, before.events.length + 1);
    final event = started.events.last;
    expect(event.type, 'adventure.accepted');
    expect(event.payload['uncannyMetabolismUsed'], isTrue);
    expect(event.payload['uncannyMetabolismHealing'], healing);
    expect(event.payload['uncannyMetabolismDieRoll'], 4);
    expect(
      event.payload['focusRecoveredAtInitiative'],
      before.hero.spentClassResources['focusPoints'],
    );
    expect((event.payload['heroInitiative'] as Map)['natural'], 20);
    expect((event.payload['enemyInitiative'] as Map)['natural'], 1);
    final spent = {...before.hero.spentClassResources, 'uncannyMetabolism': 1}
      ..remove('focusPoints');
    expect(started.hero.spentClassResources, spent);
    expect(
      ClassResourceRules.remaining(started.hero, 'focusPoints'),
      monkLevel,
    );
    expect(started.hero.hitPoints, before.hero.hitPoints! + healing);
    expect(
      started.hero.toJson(),
      before.hero
          .copyWith(
            hitPoints: before.hero.hitPoints! + healing,
            spentClassResources: spent,
          )
          .toJson(),
    );
  }

  for (final profile in [
    (primary: 'Historische Klasse', secondary: 'Monk'),
    (primary: 'Monk', secondary: 'Historische Klasse'),
    (primary: 'Mönch', secondary: 'Monk'),
  ]) {
    test(
      '${profile.primary}/${profile.secondary}: lesbares Altprofil verweigert Stoffwechsel vor allen Würfen und Schreibzugriffen',
      () async {
        final before = await prepare(
          _campaign(
            engine,
            primary: profile.primary,
            secondary: profile.secondary,
          ),
        );
        final hero = _canonical(before.hero.toJson());
        final rows = await tables();
        await controller.acceptAdventure(useUncannyMetabolism: true);
        expect(
          controller.error,
          'Die bestätigten Klassen und Stufen sind nicht konsistent.',
        );
        expect(random.calls, 0);
        expect(_canonical(before.hero.toJson()), hero);
        expect(await tables(), rows);
        await expectPersisted(before);
        expect(controller.currentCampaign!.adventureOffer!.id, 'offer');
        await expectExportImport(before);
        await restart();
        await expectPersisted(before);
        expect(await tables(), rows);
        expect(random.calls, 0);
      },
    );
  }

  test(
    'gültige Mehrklassen und Aliase heilen mit Mönchsstufe und Würfel; Export, Neustart und doppelte Annahme bleiben einmalig',
    () async {
      for (final profile in [
        (
          primary: 'Fighter',
          secondary: 'Monk',
          level: 4,
          secondaryLevel: 2,
          monkLevel: 2,
          dieSides: 6,
          healing: 6,
          otherResources: <String, int>{},
        ),
        (
          primary: 'Monk',
          secondary: 'Fighter',
          level: 4,
          secondaryLevel: 2,
          monkLevel: 2,
          dieSides: 6,
          healing: 6,
          otherResources: <String, int>{},
        ),
        (
          primary: ' KÄMPFER ',
          secondary: ' MÖNCH ',
          level: 7,
          secondaryLevel: 5,
          monkLevel: 5,
          dieSides: 8,
          healing: 9,
          otherResources: <String, int>{},
        ),
        (
          primary: 'Fighter',
          secondary: 'Monk',
          level: 20,
          secondaryLevel: 11,
          monkLevel: 11,
          dieSides: 10,
          healing: 15,
          otherResources: {'indomitable': 1},
        ),
        (
          primary: ' MONK ',
          secondary: 'Fighter',
          level: 19,
          secondaryLevel: 2,
          monkLevel: 17,
          dieSides: 12,
          healing: 20,
          otherResources: <String, int>{},
        ),
      ]) {
        final before = await prepare(
          _campaign(
            engine,
            primary: profile.primary,
            secondary: profile.secondary,
            level: profile.level,
            secondaryLevel: profile.secondaryLevel,
            spentFocus: profile.monkLevel,
            otherResources: profile.otherResources,
          ),
        );
        final originalHero = _canonical(before.hero.toJson());
        final calls = random.calls;
        final oldRows = await tables();
        await controller.acceptAdventure(useUncannyMetabolism: true);
        expect(controller.error, isNull);
        final started = controller.currentCampaign!;
        expectUsed(
          before,
          started,
          monkLevel: profile.monkLevel,
          healing: profile.healing,
        );
        expect(_canonical(before.hero.toJson()), originalHero);
        expect(random.calls, calls + 3);
        expect(random.sides.sublist(calls), [20, 20, profile.dieSides]);
        final rows = await tables();
        expect(rows['game_events']!.length, oldRows['game_events']!.length + 1);
        expect(
          rows['campaign_revisions']!.length,
          oldRows['campaign_revisions']!.length + 1,
        );
        await expectPersisted(started);
        await expectExportImport(started);
        await restart();
        await expectPersisted(started);
        await controller.acceptAdventure(useUncannyMetabolism: true);
        expect(controller.error, contains('Keine annehmbare Begegnung'));
        expect(await tables(), rows);
        await expectPersisted(started);
        expect(random.calls, calls + 3);
      }
    },
  );

  test(
    'veraltete Angebotsannahme bestätigt weder Heilung noch Ressourcen erneut',
    () async {
      final before = await prepare(_campaign(engine));
      final stale = GameController(repository: repository, engine: engine);
      await stale.initialize();
      expect(stale.currentCampaign!.revision, before.revision);
      try {
        await controller.acceptAdventure(useUncannyMetabolism: true);
        expect(controller.error, isNull);
        final started = controller.currentCampaign!;
        expectUsed(before, started);
        final rows = await tables();
        expect(random.calls, 3);
        await stale.acceptAdventure(useUncannyMetabolism: true);
        expect(stale.error, contains('inzwischen geändert'));
        expect(
          _canonical(stale.currentCampaign!.toJson()),
          _canonical(before.toJson()),
        );
        expect(await tables(), rows);
        // acceptAdventure currently checks the revision at SQL commit, after
        // calculating initiative. Its three rolled dice cannot be rolled back.
        expect(random.calls, 6);
        await expectPersisted(started);
        await stale.openCampaign(started.id);
        expect(stale.error, isNull);
        expect(
          _canonical(stale.currentCampaign!.toJson()),
          _canonical(started.toJson()),
        );
        await stale.acceptAdventure(useUncannyMetabolism: true);
        expect(stale.error, contains('Keine annehmbare Begegnung'));
        expect(await tables(), rows);
        expect(random.calls, 6);
      } finally {
        stale.dispose();
      }
    },
  );

  test(
    'später SQLite-Ereignisfehler rollt alle Tabellen zurück; Wiederholung bestätigt Stoffwechsel genau einmal',
    () async {
      final before = await prepare(_campaign(engine));
      final rows = await tables();
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await db.execute('''
CREATE TRIGGER reject_uncanny_adventure BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"type":"adventure.accepted"') > 0
BEGIN SELECT RAISE(ABORT, 'test rejects uncanny adventure'); END
''');
        await controller.acceptAdventure(useUncannyMetabolism: true);
        expect(controller.error, isNotNull);
        expect(random.calls, 3); // Random draws precede the SQL transaction.
        expect(await tables(), rows);
        await expectPersisted(before);
        await db.execute('DROP TRIGGER reject_uncanny_adventure');
      } finally {
        await db.close();
      }
      await restart();
      await expectPersisted(before);
      await controller.acceptAdventure(useUncannyMetabolism: true);
      expect(controller.error, isNull);
      final started = controller.currentCampaign!;
      expectUsed(before, started);
      expect(random.calls, 6);
      await expectPersisted(started);
      final confirmedRows = await tables();
      expect(
        confirmedRows['game_events']!.length,
        rows['game_events']!.length + 1,
      );
      await controller.acceptAdventure(useUncannyMetabolism: true);
      expect(controller.error, contains('Keine annehmbare Begegnung'));
      expect(await tables(), confirmedRows);
      await expectPersisted(started);
      expect(random.calls, 6);
    },
  );
}
