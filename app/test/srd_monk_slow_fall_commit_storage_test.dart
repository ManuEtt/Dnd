import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

Future<Campaign> seedSlowFall(SqliteCampaignRepository repo) async {
  final demo = GameEngine().createDemo();
  final saved = demo.copyWith(
    hero: demo.hero.copyWith(
      className: 'Mönch',
      level: 4,
      hitPoints: 20,
      maxHitPoints: 20,
      temporaryHitPoints: 3,
    ),
    encounter: const Encounter(
      id: 'stored-fall',
      enemyName: 'Wache',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      activeParticipant: 'enemy',
    ),
  );
  await repo.saveCampaign(saved, events: saved.events);
  return saved;
}

Future<void> commitSlowFall(
  GameController controller,
  Campaign before, {
  int? revision,
  bool confirmed = true,
  String encounterId = 'stored-fall',
}) => controller.applyConfirmedSlowFall(
  campaignId: before.id,
  expectedRevision: revision ?? before.revision,
  encounterId: encounterId,
  confirmedFallDamage: 28,
  fallConfirmed: confirmed,
  playerConfirmedReaction: true,
  damageAfterOtherDefensesConfirmed: true,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'Commit saves HP, Reaction, event and revision across restart',
    () async {
      final folder = await Directory.systemTemp.createTemp('slow-fall-sqlite-');
      final path = p.join(folder.path, 'campaign.sqlite');
      var repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var controller = GameController(repository: repo);
      try {
        final before = await seedSlowFall(repo);
        await controller.openCampaign(before.id);
        await commitSlowFall(controller, before);
        expect(controller.error, isNull);
        final after = controller.currentCampaign!;
        expect(after.encounter!.reactionUsed, isTrue);
        expect(after.encounter!.activeParticipant, 'enemy');
        expect(after.hero.temporaryHitPoints, 0);
        expect(after.hero.hitPoints, 15);
        expect(after.revision, before.revision + 1);
        expect(after.events.last.type, 'combat.slowFallResolved');
        expect(after.events.last.payload['incomingFallDamage'], 28);
        expect(after.events.last.payload['damagePrevented'], 20);
        expect(after.events.last.payload['hitPointDamage'], 5);

        await commitSlowFall(controller, before, revision: before.revision);
        expect(controller.error, contains('erneut öffnen'));
        expect(controller.currentCampaign!.toJson(), after.toJson());

        controller.dispose();
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        controller = GameController(repository: repo);
        await controller.openCampaign(before.id);
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.toJson(), after.toJson());

        await commitSlowFall(controller, after, revision: after.revision);
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), after.toJson());
      } finally {
        controller.dispose();
        await repo.close();
        await folder.delete(recursive: true);
      }
    },
  );

  test('SQLite event failure rolls back HP and Reaction together', () async {
    final folder = await Directory.systemTemp.createTemp('fall-rollback-');
    final path = p.join(folder.path, 'campaign.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repo);
    try {
      final before = await seedSlowFall(repo);
      await controller.openCampaign(before.id);
      final database = await databaseFactoryFfi.openDatabase(path);
      try {
        await database.execute('''
CREATE TRIGGER reject_slow_fall
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"combat.slowFallResolved"') > 0
BEGIN
  SELECT RAISE(ABORT, 'forced slow-fall transaction failure');
END
''');
        await commitSlowFall(controller, before);
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect((await repo.getCampaign(before.id))!.toJson(), before.toJson());
      } finally {
        await database.close();
      }
    } finally {
      controller.dispose();
      await repo.close();
      await folder.delete(recursive: true);
    }
  });

  test('Unconfirmed fall cannot change any saved HP or action', () async {
    final folder = await Directory.systemTemp.createTemp('fall-denied-');
    final path = p.join(folder.path, 'campaign.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repo);
    try {
      final before = await seedSlowFall(repo);
      await controller.openCampaign(before.id);
      await commitSlowFall(controller, before, confirmed: false);
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), before.toJson());
      expect((await repo.getCampaign(before.id))!.toJson(), before.toJson());
    } finally {
      controller.dispose();
      await repo.close();
      await folder.delete(recursive: true);
    }
  });
}
