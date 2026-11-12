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
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    // Each real combat start rolls hero 20, then enemy 1. The hero starts,
    // so these tests need no enemy attack/damage rolls or resource side effects.
    return calls.isOdd ? max - 1 : 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

enum _CombatPath { waldschrein, aiAdventure, rabenwacht }

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
  _CombatPath path = _CombatPath.waldschrein,
  String primary = 'Monk',
  String secondary = '',
  int level = 15,
  int secondaryLevel = 0,
  int spent = 15,
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
    abilities: {
      'strength': 12,
      'dexterity': 16,
      'constitution': 12,
      'intelligence': 10,
      'wisdom': 16,
      'charisma': 16,
    },
    hitPoints: 35,
    maxHitPoints: 40,
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
    temporaryHitPoints: 3,
    gold: 23,
    spentHitDice: const {'d8': 2},
    spentClassResources: {'focusPoints': spent, 'uncannyMetabolism': 1},
  );
  final Campaign campaign;
  switch (path) {
    case _CombatPath.waldschrein:
      campaign = demo.copyWith(hero: hero);
    case _CombatPath.rabenwacht:
      final source = engine.createRabenwacht(hero);
      campaign = source.copyWith(
        storyBible: {...source.storyBible, 'stage': 'bonehall'},
      );
    case _CombatPath.aiAdventure:
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
      campaign = engine
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
  }
  return Campaign.fromJson(campaign.toJson());
}

const _waldschreinAction = 'Ich gehe zum Waldschrein.';
const _rabenwachtAction = 'Ich greife den Wächter an.';

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
      'monk-perfect-focus-profile-',
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
    // Exercise the actual legacy JSON import instead of bypassing its checks
    // through an in-memory repository or a hand-built controller snapshot.
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

  void expectInitiative(Campaign campaign, {required int recovered}) {
    final event = campaign.events.last;
    expect(event.payload['focusRecoveredAtInitiative'], recovered);
    expect(event.payload['bardicInspirationRecoveredAtInitiative'], 0);
    expect(event.payload['heroInitiative']['natural'], 20);
    expect(event.payload['enemyInitiative']['natural'], 1);
    expect(event.payload, isNot(contains('uncannyMetabolismUsed')));
    expect(event.payload, isNot(contains('uncannyMetabolismHealing')));
    expect(event.payload, isNot(contains('uncannyMetabolismDieRoll')));
    expect(campaign.hero.hitPoints, 35);
    expect(campaign.hero.maxHitPoints, 40);
    expect(campaign.hero.temporaryHitPoints, 3);
    expect(campaign.hero.spentClassResources['uncannyMetabolism'], 1);
    expect(campaign.hero.spentHitDice, {'d8': 2});
    expect(campaign.hero.gold, 23);
  }

  Future<void> startCombat(_CombatPath combatPath, String requestId) async {
    // Omit the optional Uncanny Metabolism argument: the ordinary initiative
    // path must never infer its use or heal the injured hero.
    if (combatPath == _CombatPath.aiAdventure) {
      await controller.acceptAdventure();
    } else {
      await controller.sendAction(
        combatPath == _CombatPath.rabenwacht
            ? _rabenwachtAction
            : _waldschreinAction,
        requestId: requestId,
      );
    }
    expect(controller.error, isNull);
  }

  for (final profile in [
    (
      primary: 'Historische Klasse',
      secondary: 'Monk',
      secondaryLevel: 15,
      path: _CombatPath.waldschrein,
    ),
    (
      primary: 'Monk',
      secondary: 'Historische Klasse',
      secondaryLevel: 2,
      path: _CombatPath.aiAdventure,
    ),
    (
      // These display names pass legacy JSON import while both resolve to
      // Monk. Raw Monk/monk is rejected by the existing importer.
      primary: 'Mönch',
      secondary: 'monk',
      secondaryLevel: 2,
      path: _CombatPath.rabenwacht,
    ),
  ]) {
    test(
      '${profile.path.name}: lesbares ${profile.primary}/${profile.secondary}-Altprofil startet Kampf ohne Fokuserholung',
      () async {
        final before = await prepare(
          _campaign(
            engine,
            path: profile.path,
            primary: profile.primary,
            secondary: profile.secondary,
            level: 17,
            secondaryLevel: profile.secondaryLevel,
          ),
        );
        final oldRows = await tables();
        await startCombat(profile.path, 'legacy-combat-start');
        final started = controller.currentCampaign!;
        expect(started.revision, before.revision + 1);
        expect(started.encounter, isNotNull);
        expect(started.encounter!.isFinished, isFalse);
        expect(started.events.length, before.events.length + 1);
        expect(
          started.events.last.type,
          profile.path == _CombatPath.aiAdventure
              ? 'adventure.accepted'
              : 'combat.started',
        );
        expectInitiative(started, recovered: 0);
        expect(started.hero.toJson(), before.hero.toJson());
        expect(started.hero.spentClassResources, {
          'focusPoints': 15,
          'uncannyMetabolism': 1,
        });
        expect(random.calls, 2); // The two legitimate initiative rolls remain.
        final rows = await tables();
        expect(rows['game_events']!.length, oldRows['game_events']!.length + 1);
        expect(
          rows['campaign_revisions']!.length,
          oldRows['campaign_revisions']!.length + 1,
        );
        expect(
          rows['characters']!.single['snapshot'],
          oldRows['characters']!.single['snapshot'],
        );
        await expectPersisted(started);
        await expectExportImport(started);
        await restart();
        await expectPersisted(started);
        if (profile.path != _CombatPath.aiAdventure) {
          await startCombat(profile.path, 'legacy-combat-start');
          expect(await tables(), rows);
          expect(random.calls, 2);
        }
      },
    );
  }

  test(
    'gültige Mönchsaliase und beide Mehrklassenreihenfolgen erholen bis vier; Export und Neustart-Replay bleiben einmalig',
    () async {
      for (final profile in [
        (
          primary: ' MONK ',
          secondary: '',
          level: 15,
          secondaryLevel: 0,
          spent: 15,
          recovered: 4,
          path: _CombatPath.waldschrein,
        ),
        (
          primary: ' MÖNCH ',
          secondary: ' Fighter ',
          level: 17,
          secondaryLevel: 2,
          spent: 15,
          recovered: 4,
          path: _CombatPath.aiAdventure,
        ),
        (
          primary: ' Kämpfer ',
          secondary: ' MONK ',
          level: 17,
          secondaryLevel: 15,
          spent: 14,
          recovered: 3,
          path: _CombatPath.rabenwacht,
        ),
        (
          primary: 'Monk',
          secondary: 'Fighter',
          level: 17,
          secondaryLevel: 2,
          spent: 11,
          recovered: 0,
          path: _CombatPath.waldschrein,
        ),
        (
          primary: 'Fighter',
          secondary: 'Mönch',
          level: 17,
          secondaryLevel: 15,
          spent: 10,
          recovered: 0,
          path: _CombatPath.aiAdventure,
        ),
      ]) {
        var campaign = _campaign(
          engine,
          path: profile.path,
          primary: profile.primary,
          secondary: profile.secondary,
          level: profile.level,
          secondaryLevel: profile.secondaryLevel,
          spent: profile.spent,
        );
        if (profile.secondary.isNotEmpty) {
          // Both Fighter2 resources must survive automatic Monk recovery.
          campaign = campaign.copyWith(
            hero: campaign.hero.copyWith(
              spentSecondWind: 1,
              spentActionSurge: 1,
            ),
          );
        }
        final before = await prepare(campaign);
        final calls = random.calls;
        final requestId = 'valid-${before.id}';
        await startCombat(profile.path, requestId);
        final started = controller.currentCampaign!;
        expect(
          started.events.last.type,
          profile.path == _CombatPath.aiAdventure
              ? 'adventure.accepted'
              : 'combat.started',
        );
        expectInitiative(started, recovered: profile.recovered);
        expect(
          ClassResourceRules.remaining(started.hero, 'focusPoints'),
          profile.spent >= 11 ? 4 : 5,
        );
        expect(
          started.hero.toJson(),
          before.hero
              .copyWith(
                spentClassResources: {
                  ...before.hero.spentClassResources,
                  'focusPoints': profile.spent - profile.recovered,
                },
              )
              .toJson(),
        );
        expect(started.events.length, before.events.length + 1);
        expect(started.revision, before.revision + 1);
        expect(random.calls, calls + 2);
        final rows = await tables();
        await expectPersisted(started);
        await expectExportImport(started);
        await restart();
        await expectPersisted(started);
        if (profile.path != _CombatPath.aiAdventure) {
          await startCombat(profile.path, requestId);
          expect(await tables(), rows);
          expect(random.calls, calls + 2);
        }
      }
    },
  );

  test(
    'veralteter Controller erholt keinen weiteren Fokus und liest die bestätigte Kampfstart-ID zurück',
    () async {
      final before = await prepare(_campaign(engine));
      final stale = GameController(repository: repository, engine: engine);
      await stale.initialize();
      expect(stale.currentCampaign!.revision, before.revision);
      try {
        await controller.sendAction(
          _waldschreinAction,
          requestId: 'first-start',
        );
        expect(controller.error, isNull);
        final started = controller.currentCampaign!;
        expectInitiative(started, recovered: 4);
        expect(started.hero.spentClassResources, {
          'focusPoints': 11,
          'uncannyMetabolism': 1,
        });
        final rows = await tables();
        expect(random.calls, 2);
        await stale.sendAction(_waldschreinAction, requestId: 'stale-start');
        expect(stale.error, contains('inzwischen geändert'));
        expect(stale.currentCampaign!.hero.toJson(), before.hero.toJson());
        expect(await tables(), rows);
        expect(random.calls, 2);
        await stale.sendAction(_waldschreinAction, requestId: 'first-start');
        expect(stale.error, isNull);
        expect(
          _canonical(stale.currentCampaign!.toJson()),
          _canonical(started.toJson()),
        );
        expect(await tables(), rows);
        expect(random.calls, 2);
        await expectPersisted(started);
      } finally {
        stale.dispose();
      }
    },
  );

  test(
    'später SQLite-Ereignisfehler rollt Kampfbeginn und Fokus zurück; Wiederholung bestätigt genau einmal',
    () async {
      final before = await prepare(_campaign(engine));
      final rows = await tables();
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await db.execute('''
CREATE TRIGGER reject_monk_combat BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"type":"combat.started"') > 0
BEGIN SELECT RAISE(ABORT, 'test rejects monk combat start'); END
''');
        await controller.sendAction(
          _waldschreinAction,
          requestId: 'retry-start',
        );
        expect(controller.error, isNotNull);
        expect(random.calls, 2); // A rolled initiative cannot be rolled back.
        expect(await tables(), rows);
        await expectPersisted(before);
        await db.execute('DROP TRIGGER reject_monk_combat');
      } finally {
        await db.close();
      }
      await restart();
      await expectPersisted(before);
      await controller.sendAction(_waldschreinAction, requestId: 'retry-start');
      expect(controller.error, isNull);
      final started = controller.currentCampaign!;
      expect(started.events.length, before.events.length + 1);
      expect(started.events.last.type, 'combat.started');
      expectInitiative(started, recovered: 4);
      expect(started.hero.spentClassResources, {
        'focusPoints': 11,
        'uncannyMetabolism': 1,
      });
      expect(random.calls, 4);
      await expectPersisted(started);
      await expectExportImport(started);
      final confirmedRows = await tables();
      await controller.sendAction(_waldschreinAction, requestId: 'retry-start');
      expect(controller.error, isNull);
      expect(await tables(), confirmedRows);
      expect(random.calls, 4);
    },
  );
}
