import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_terrain_movement_rules.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

Future<Campaign> seed(SqliteCampaignRepository repository) async {
  final initial = GameEngine().createDemo();
  final initialGame = initial.copyWith(
    hero: initial.hero.copyWith(className: 'Waldläufer', level: 6),
    encounter: const Encounter(
      id: 'terrain-storage',
      enemyName: 'Gegner',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      movementRemaining: 9,
    ),
  );
  await repository.saveCampaign(initialGame, events: initialGame.events);
  return initialGame;
}

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'Controller stores climb; rejects stale revision; restart restores movement',
    () async {
      final folder = await Directory.systemTemp.createTemp('climb-sqlite-');
      final path = p.join(folder.path, 'movement.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var controller = GameController(repository: repository);
      try {
        final before = await seed(repository);
        await controller.openCampaign(before.id);
        await controller.moveOnConfirmedTerrain(
          campaignId: before.id,
          expectedRevision: before.revision,
          kind: SrdTerrainMovement.climb,
          distanceFeet: 5,
          difficultTerrain: true,
          terrainConfirmed: true,
        );
        expect(controller.error, isNull);
        final after = controller.currentCampaign!;
        expect(after.encounter!.movementRemainingLabel, '6 m');
        expect(after.events.last.type, 'combat.climbed');
        expect(after.events.last.payload['movementSpentDecimeters'], 30);

        await controller.moveOnConfirmedTerrain(
          campaignId: before.id,
          expectedRevision: before.revision,
          kind: SrdTerrainMovement.swim,
          distanceFeet: 5,
          difficultTerrain: false,
          terrainConfirmed: true,
        );
        expect(controller.error, contains('erneut öffnen'));
        expect(controller.currentCampaign!.toJson(), after.toJson());

        controller.dispose();
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        controller = GameController(repository: repository);
        await controller.openCampaign(before.id);
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.toJson(), after.toJson());
      } finally {
        controller.dispose();
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );

  test('SQLite event failure rolls back swim and revision atomically', () async {
    final folder = await Directory.systemTemp.createTemp('swim-rollback-');
    final path = p.join(folder.path, 'movement.sqlite');
    final repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repository);
    try {
      final before = await seed(repository);
      await controller.openCampaign(before.id);
      final database = await databaseFactoryFfi.openDatabase(path);
      try {
        await database.execute('''
CREATE TRIGGER reject_swim
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"combat.swam"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled swim event failure');
END
''');
        await controller.moveOnConfirmedTerrain(
          campaignId: before.id,
          expectedRevision: before.revision,
          kind: SrdTerrainMovement.swim,
          distanceFeet: 5,
          difficultTerrain: false,
          terrainConfirmed: true,
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect(
          (await repository.getCampaign(before.id))!.toJson(),
          before.toJson(),
        );
      } finally {
        await database.close();
      }
    } finally {
      controller.dispose();
      await repository.close();
      await folder.delete(recursive: true);
    }
  });

  test('Unconfirmed water leaves persisted state unchanged', () async {
    final folder = await Directory.systemTemp.createTemp('swim-denied-');
    final path = p.join(folder.path, 'movement.sqlite');
    final repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repository);
    try {
      final before = await seed(repository);
      await controller.openCampaign(before.id);
      await controller.moveOnConfirmedTerrain(
        campaignId: before.id,
        expectedRevision: before.revision,
        kind: SrdTerrainMovement.swim,
        distanceFeet: 5,
        difficultTerrain: false,
        terrainConfirmed: false,
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), before.toJson());
      expect((await repository.getCampaign(before.id))!.toJson(), before.toJson());
    } finally {
      controller.dispose();
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
