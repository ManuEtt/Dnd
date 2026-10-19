import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<Campaign> seed(SqliteCampaignRepository repository) async {
    final initial = GameEngine().createDemo();
    final campaign = initial.copyWith(
      hero: initial.hero.copyWith(conditions: ['liegend']),
      encounter: const Encounter(
        id: 'standing-fixture',
        enemyName: 'Gegner',
        enemyHitPoints: 10,
        enemyMaxHitPoints: 10,
        movementRemaining: 9,
      ),
    );
    await repository.saveCampaign(campaign, events: campaign.events);
    return campaign;
  }

  test('Aufstehen speichert 4,5 m atomar inklusive Journal und Neustart', () async {
    final folder = await Directory.systemTemp.createTemp('standing-sqlite-');
    final path = p.join(folder.path, 'standing.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var controller = GameController(repository: repository);
    try {
      final before = await seed(repository);
      await controller.openCampaign(before.id);
      expect(controller.error, isNull);
      await controller.standUp(
        campaignId: before.id,
        expectedRevision: before.revision,
      );
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(after.revision, before.revision + 1);
      expect(after.hero.conditions, isNot(contains('liegend')));
      expect(after.encounter!.movementRemainingLabel, '4.5 m');
      expect(after.events.last.type, 'combat.stoodUp');
      expect((await repository.getCampaign(before.id))!.toJson(), after.toJson());

      await controller.standUp(
        campaignId: before.id,
        expectedRevision: before.revision,
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
  });

  test('SQLite-Ereignisfehler lässt Aufstehen und Bewegung vollständig zurückrollen', () async {
    final folder = await Directory.systemTemp.createTemp('standing-rollback-');
    final path = p.join(folder.path, 'standing.sqlite');
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
CREATE TRIGGER reject_standing
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"combat.stoodUp"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled stand-up event failure');
END
''');
        await controller.standUp(
          campaignId: before.id,
          expectedRevision: before.revision,
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect((await repository.getCampaign(before.id))!.toJson(), before.toJson());
        expect(
          await repository.reconstructCampaign(
            before.id,
            revision: before.revision + 1,
          ),
          isNull,
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
}
