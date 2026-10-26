import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _CountingRandom implements Random {
  int calls = 0;
  final maxima = <int>[];

  @override
  int nextInt(int max) {
    maxima.add(max);
    // A natural 10 fails against SG 12; both damage dice then show 1.
    final result = calls == 0 ? 9 : 0;
    calls++;
    return result;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

Future<void> _cast(GameController controller, Campaign campaign) =>
    controller.castSacredFlame(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      confirmedTargetDexteritySaveModifier: 0,
      targetVisibleConfirmed: true,
      targetWithinRangeConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      noRadiantDamageAdjustmentConfirmed: true,
      noUnmodelledDcModifiersConfirmed: true,
      saveCircumstancesConfirmed: true,
    );

Campaign _fixture({required String primary, String secondary = 'Kleriker'}) {
  final start = GameEngine().createDemo();
  // Old imported profiles remain readable. Normalize their item stats before
  // taking snapshots, just as the repository does when reading a save.
  final hero = HeroCharacter.fromJson(
    start.hero
        .copyWith(
          className: primary,
          secondaryClassName: secondary,
          secondaryClassLevel: 1,
          level: 6,
          spells: const ['Heilige Flamme'],
          abilities: const {
            'strength': 10,
            'dexterity': 12,
            'constitution': 14,
            'intelligence': 20,
            'wisdom': 12,
            'charisma': 10,
          },
        )
        .toJson(),
  );
  return Campaign.fromJson(
    start
        .copyWith(
          hero: hero,
          encounter: const Encounter(
            id: 'sacred-flame-class-target',
            enemyName: 'Gegner',
            enemyHitPoints: 30,
            enemyMaxHitPoints: 30,
          ),
        )
        .toJson(),
  );
}

Future<Map<String, List<Map<String, Object?>>>> _storedRows(
  Database database,
) async => {
  'campaigns': await database.query('campaigns', orderBy: 'id'),
  'campaign_revisions': await database.query(
    'campaign_revisions',
    orderBy: 'campaign_id, revision',
  ),
  'game_events': await database.query(
    'game_events',
    orderBy: 'campaign_id, ordinal',
  ),
  'characters': await database.query('characters', orderBy: 'id'),
};

void main() {
  setUpAll(sqfliteFfiInit);

  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late Database database;
  late GameController controller;
  late _CountingRandom random;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sacred-class-sqlite-');
    path = p.join(directory.path, 'game.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    random = _CountingRandom();
    controller = GameController(
      repository: repository,
      engine: GameEngine(dice: DiceEngine(random: random)),
    );
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
    await repository.close();
    await directory.delete(recursive: true);
  });

  Future<Campaign> importAndOpen({
    required String primary,
    String secondary = 'Kleriker',
  }) async {
    final fixture = _fixture(primary: primary, secondary: secondary);
    final imported = await repository.importCampaign(
      jsonEncode(fixture.toJson()),
    );
    expect(imported.toJson(), fixture.toJson());
    await controller.initialize();
    await controller.openCampaign(imported.id);
    expect(controller.error, isNull);
    expect(controller.currentCampaign!.hero.isComplete, isTrue);
    expect(controller.currentCampaign!.toJson(), imported.toJson());
    expect(imported.encounter!.enemyHitPoints, 30);
    expect(imported.encounter!.actionUsed, isFalse);
    return imported;
  }

  Future<void> expectUnchanged(
    Campaign before,
    Map<String, List<Map<String, Object?>>> rowsBefore,
  ) async {
    expect(controller.currentCampaign!.toJson(), before.toJson());
    expect(controller.campaigns.single.toJson(), before.toJson());
    expect(controller.characters.single.toJson(), before.hero.toJson());
    expect(
      (await repository.getCampaign(before.id))!.toJson(),
      before.toJson(),
    );
    expect(
      (await repository.reconstructCampaign(
        before.id,
        revision: before.revision,
      ))!.toJson(),
      before.toJson(),
    );
    expect(
      await repository.reconstructCampaign(
        before.id,
        revision: before.revision + 1,
      ),
      isNull,
    );
    expect(await _storedRows(database), rowsBefore);
  }

  for (final primary in ['Cleric', 'Unbekannt']) {
    test(
      'importiertes $primary 5 / Kleriker 1 wird vor RNG und Speicheränderung abgelehnt',
      () async {
        final before = await importAndOpen(primary: primary);
        expect(before.hero.className, primary);
        expect(before.hero.secondaryClassName, 'Kleriker');
        expect(before.hero.primaryClassLevel, 5);
        expect(before.hero.secondaryClassLevel, 1);
        final rowsBefore = await _storedRows(database);

        await _cast(controller, before);

        expect(controller.error, contains('Zauberklasse'));
        expect(random.calls, 0);
        await expectUnchanged(before, rowsBefore);

        // Reopening the existing profile remains supported after rejection.
        await controller.openCampaign(before.id);
        expect(controller.error, isNull);
        await expectUnchanged(before, rowsBefore);
        expect(random.calls, 0);
      },
    );
  }

  test(
    'Wizard 5 / Cleric 1 speichert WIS-SG 12, Aktion und Schaden mit Reload und Journal',
    () async {
      final before = await importAndOpen(
        primary: 'Wizard',
        secondary: 'Cleric',
      );

      await _cast(controller, before);

      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(random.calls, 3);
      expect(random.maxima, [20, 8, 8]);
      expect(after.revision, before.revision + 1);
      expect(after.hero.toJson(), before.hero.toJson());
      expect(after.encounter!.enemyHitPoints, 28);
      expect(after.encounter!.actionUsed, isTrue);
      expect(after.events, hasLength(before.events.length + 1));
      final event = after.events.last;
      expect(event.type, 'spell.sacredFlame');
      expect(event.payload['castingClass'], 'Kleriker');
      expect(event.payload['spellcastingAbility'], 'wisdom');
      expect(event.payload['savingThrowDc'], 12);
      expect(event.payload['savingThrowModifier'], 0);
      expect(event.payload['savingThrowRoll']['natural'], 10);
      expect(event.payload['savingThrowRoll']['total'], 10);
      expect(event.payload['savingThrowSucceeded'], isFalse);
      expect(event.payload['damageRoll']['rolls'], [1, 1]);
      expect(event.payload['damage'], 2);
      expect(event.payload['noSpellSlotSpent'], isTrue);
      expect(controller.campaigns.single.toJson(), after.toJson());
      expect(
        (await repository.getCampaign(after.id))!.toJson(),
        after.toJson(),
      );
      final rowsAfter = await _storedRows(database);

      // A dialog opened at the previous revision must not roll or commit again.
      await _cast(controller, before);
      expect(controller.error, contains('erneut öffnen'));
      expect(random.calls, 3);
      await expectUnchanged(after, rowsAfter);

      controller.dispose();
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(
        repository: repository,
        engine: GameEngine(dice: DiceEngine(random: random)),
      );
      await controller.initialize();
      expect(controller.error, isNull);
      await expectUnchanged(after, rowsAfter);
      expect(
        (await repository.reconstructCampaign(
          before.id,
          revision: before.revision,
        ))!.toJson(),
        before.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(after.id))!.toJson(),
        after.toJson(),
      );
      expect(
        rowsAfter['game_events']!
            .map((row) => jsonDecode(row['event_json']! as String))
            .toList(),
        after.events.map((event) => event.toJson()).toList(),
      );

      // Reload restores the spent action, so a new request also stays inert.
      await _cast(controller, after);
      expect(controller.error, contains('Magieaktion'));
      expect(random.calls, 3);
      await expectUnchanged(after, rowsAfter);
    },
  );

  test(
    'SQLite-Eventfehler rollt gültige Heilige Flamme samt Aktion und Revision zurück',
    () async {
      final before = await importAndOpen(
        primary: 'Wizard',
        secondary: 'Cleric',
      );
      final rowsBefore = await _storedRows(database);
      await database.execute('''
CREATE TRIGGER reject_sacred_flame
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"spell.sacredFlame"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled sacred flame event failure');
END
''');

      await _cast(controller, before);

      expect(controller.error, isNotNull);
      // This reaches the real transaction after save and damage resolution.
      expect(random.calls, 3);
      expect(random.maxima, [20, 8, 8]);
      await expectUnchanged(before, rowsBefore);

      controller.dispose();
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(repository: repository);
      await controller.initialize();
      expect(controller.error, isNull);
      await expectUnchanged(before, rowsBefore);
    },
  );
}
