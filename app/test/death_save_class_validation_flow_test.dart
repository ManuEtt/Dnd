import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _CountingRandom implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return max - 1;
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

// SQLite writes canonical JSON object keys. Compare the complete values with
// the same key order; tables() additionally checks the stored snapshot bytes.
String _canonicalJson(Object? value) => jsonEncode(_sortedJson(value));

Campaign _fallen(
  GameEngine engine, {
  String primary = 'Mönch',
  String secondary = 'Schurke',
  int level = 20,
  int secondaryLevel = 6,
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
            hitPoints: 0,
            maxHitPoints: 40,
            deathFailures: 2,
            deathSuccesses: 0,
            spentClassResources: const {},
            savingThrowProficiencies: const [],
            conditions: const ['bewusstlos', 'liegend'],
            concentratingOn: '',
          ),
          encounter: const Encounter(
            id: 'death-class-validation-fight',
            enemyName: 'Bestätigter Gegner',
            enemyHitPoints: 30,
            enemyMaxHitPoints: 30,
          ),
        )
        .toJson(),
  );
}

const _invalidClasses = [
  (primary: 'Unbestätigt', secondary: 'Mönch', level: 20, secondaryLevel: 14),
  (primary: 'Mönch', secondary: 'Unbestätigt', level: 20, secondaryLevel: 6),
  (primary: 'Unbestätigt', secondary: 'Kämpfer', level: 14, secondaryLevel: 9),
  (primary: 'Kämpfer', secondary: 'Unbestätigt', level: 14, secondaryLevel: 5),
];

void main() {
  setUpAll(sqfliteFfiInit);
  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late GameController controller;
  late GameEngine engine;
  late _CountingRandom random;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('death-save-class-');
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
    expect(await tables(), rows);
  }

  for (final classes in _invalidClasses) {
    test(
      '${classes.primary}/${classes.secondary}: Altprofil bleibt lesbar, neue Todesrettung vor RNG und sechs Tabellen abgelehnt',
      () async {
        final before = _fallen(
          engine,
          primary: classes.primary,
          secondary: classes.secondary,
          level: classes.level,
          secondaryLevel: classes.secondaryLevel,
        );
        final serialized = _canonicalJson(before.toJson());
        expect(
          _canonicalJson(Campaign.fromJson(jsonDecode(serialized)).toJson()),
          serialized,
        );
        await open(before);
        final rows = await tables();

        expect(
          () => engine.act(before, 'Todesrettungswurf'),
          throwsFormatException,
        );
        expect(before.pendingRoll, isNull);
        expect(random.calls, 0);

        for (var attempt = 0; attempt < 2; attempt++) {
          await controller.sendAction('Todesrettungswurf');
          expect(controller.error, contains('SRD-Klassen'));
          expect(random.calls, 0);
          await unchanged(before, rows);
        }

        await restart();
        expect(
          _canonicalJson(controller.currentCampaign!.toJson()),
          serialized,
        );
        await unchanged(before, rows);
        expect(random.calls, 0);
      },
    );
  }

  for (final provisionalChoice in [false, true]) {
    test(
      'manipulierte ${provisionalChoice ? 'Todesauswahl' : 'v1-Todesprobe'} verweigert Import, Commit und RNG',
      () async {
        final before = _fallen(engine);
        await open(before);
        final rows = await tables();
        final requested = engine.act(before, 'Todesrettungswurf').campaign;
        expect(requested.pendingRoll!.deathSaveRulesVersion, 1);
        final valid = provisionalChoice
            ? engine.resolveRoll(requested, natural: 1).campaign
            : requested;
        final forged = valid.copyWith(
          hero: valid.hero.copyWith(
            className: 'Unbestätigt',
            secondaryClassName: 'Mönch',
            secondaryClassLevel: 14,
          ),
        );
        // Total level, Monk level and +6 bonus are still numerically plausible;
        // only the unknown first class distinguishes this manipulated proof.
        expect(forged.hero.level, 20);
        expect(forged.hero.secondaryClassLevel, 14);
        expect(() => Campaign.fromJson(forged.toJson()), throwsFormatException);
        if (provisionalChoice) {
          for (final feature in [
            null,
            SavingThrowRerollFeature.disciplinedSurvivor,
            SavingThrowRerollFeature.indomitable,
          ]) {
            expect(
              () => engine.resolveDeathSaveDecision(forged, feature: feature),
              throwsFormatException,
            );
          }
        } else {
          expect(() => engine.resolveRoll(forged), throwsFormatException);
        }
        expect(random.calls, 0);

        await controller.importCampaign(jsonEncode(forged.toJson()));
        expect(controller.error, isNotNull);
        await unchanged(before, rows);
        await expectLater(
          repository.saveCampaign(
            forged,
            events: forged.events,
            expectedRevision: before.revision,
          ),
          throwsFormatException,
        );
        await unchanged(before, rows);
        expect(random.calls, 0);
      },
    );
  }

  test(
    'unversionierte historische Todesprobe bleibt lesbar, erlaubt keine neue SRD-Auflösung oder Zufallszahl',
    () async {
      final legacy = Campaign.fromJson(
        _fallen(engine, primary: 'Unbestätigt')
            .copyWith(
              pendingRoll: const PendingRoll(
                id: 'historical-death-roll',
                type: 'death',
                modifier: 0,
                difficulty: 10,
              ),
            )
            .toJson(),
      );
      expect(legacy.pendingRoll!.deathSaveRulesVersion, 0);
      expect(legacy.pendingRoll!.modifier, 0);
      final serialized = _canonicalJson(legacy.toJson());
      await open(legacy);
      final rows = await tables();
      await restart();
      expect(_canonicalJson(controller.currentCampaign!.toJson()), serialized);
      await unchanged(legacy, rows);

      expect(() => engine.resolveRoll(legacy), throwsFormatException);
      expect(random.calls, 0);
      await controller.resolveRoll();
      expect(controller.error, contains('SRD-Klassen'));
      await unchanged(legacy, rows);
      expect(random.calls, 0);
      await restart();
      await unchanged(legacy, rows);
    },
  );

  for (final fighter in [false, true]) {
    test(
      '${fighter ? 'Fighter 9/Wizard 5' : 'Monk 14/Rogue 6'}: gültige Alias-Klassen und atomare Wiederholung überleben Neustart',
      () async {
        final before = _fallen(
          engine,
          primary: fighter ? 'Fighter' : 'Monk',
          secondary: fighter ? 'Wizard' : 'Rogue',
          level: fighter ? 14 : 20,
          secondaryLevel: fighter ? 5 : 6,
        );
        await open(before);
        await controller.sendAction('Todesrettungswurf');
        expect(controller.error, isNull);
        expect(
          controller.currentCampaign!.pendingRoll!.modifier,
          fighter ? 0 : 6,
        );
        await controller.resolveRoll(natural: 1);
        expect(controller.error, isNull);
        final choice = controller.currentCampaign!;
        expect(choice.pendingDeathSave, isNotNull);
        expect(choice.hero.toJson(), before.hero.toJson());
        expect(random.calls, 0);
        await restart();
        expect(controller.currentCampaign!.toJson(), choice.toJson());
        final feature = fighter
            ? SavingThrowRerollFeature.indomitable
            : SavingThrowRerollFeature.disciplinedSurvivor;
        await controller.resolveDeathSaveDecision(
          campaignId: choice.id,
          expectedRevision: choice.revision,
          feature: feature,
        );
        expect(controller.error, isNull);
        final accepted = controller.currentCampaign!;
        expect(accepted.revision, choice.revision + 1);
        expect(accepted.hero.hitPoints, 1);
        expect(accepted.hero.deathFailures, 0);
        expect(accepted.hero.deathSuccesses, 0);
        expect(accepted.hero.spentClassResources, {
          fighter ? 'indomitable' : 'focusPoints': 1,
        });
        expect(accepted.pendingDeathSave, isNull);
        expect(accepted.encounter!.deathSaveResolvedThisTurn, isTrue);
        expect(random.calls, 1);
        final event = accepted.events.last;
        expect(event.type, 'deathSave.resolved');
        expect(event.payload['roll']['natural'], 20);
        expect(event.payload['fighterLevelBonus'], fighter ? 9 : 0);
        final rows = await tables();

        await controller.resolveDeathSaveDecision(
          campaignId: choice.id,
          expectedRevision: choice.revision,
          feature: feature,
        );
        expect(controller.error, contains('erneut öffnen'));
        expect(random.calls, 1);
        await unchanged(accepted, rows);
        await restart();
        await unchanged(accepted, rows);
        expect(random.calls, 1);
      },
    );
  }
}
