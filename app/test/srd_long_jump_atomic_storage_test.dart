import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

Future<Campaign> seedJump(
  SqliteCampaignRepository repository, {
  bool withRunUp = false,
  bool pendingRoll = false,
  int strength = 16,
}) async {
  final engine = GameEngine();
  final initial = engine.createDemo();
  var state = initial.copyWith(
    hero: initial.hero.copyWith(
      abilities: {...initial.hero.abilities, 'strength': strength},
      speed: 9,
    ),
    encounter: const Encounter(
      id: 'jump-storage',
      enemyName: 'Wache',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      movementRemaining: 9,
      heroCover: CoverLevel.half,
    ),
  );
  if (withRunUp) {
    final runUp = engine.act(state, 'Ich gehe 3 Meter.');
    expect(runUp.events.single.type, 'combat.moved');
    state = runUp.campaign;
    expect(state.encounter!.remainingMovementDecimeters, 60);
  }
  if (pendingRoll) {
    state = state.copyWith(
      pendingRoll: const PendingRoll(
        id: 'other-roll',
        type: 'ability',
        modifier: 0,
        difficulty: 10,
      ),
    );
  }
  await repository.saveCampaign(state, events: state.events);
  return state;
}

Future<void> confirmJump(
  GameController controller,
  Campaign source, {
  String requestId = 'jump-request-1',
  bool playerConfirmed = true,
  int? expectedRevision,
  int runUpFeet = 10,
  int jumpCm = 450,
  bool? difficult = false,
  bool clearPath = true,
  int? lowObstacleCm,
  bool? athleticsRequired,
  int? acrobaticsTotal,
  int? athleticsTotal,
}) => controller.confirmLongJump(
  campaignId: source.id,
  encounterId: 'jump-storage',
  expectedRevision: expectedRevision ?? source.revision,
  requestId: requestId,
  playerConfirmed: playerConfirmed,
  immediateRunUpFeet: runUpFeet,
  jumpDistanceCentimeters: jumpCm,
  landingInDifficultTerrainConfirmed: difficult,
  obstacleFreePathConfirmed: clearPath,
  lowObstacleHeightCentimeters: lowObstacleCm,
  dmRequiresAthleticsCheck: athleticsRequired,
  confirmedLandingAcrobaticsTotal: acrobaticsTotal,
  confirmedObstacleAthleticsTotal: athleticsTotal,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test('immediate paid run-up, jump and one audit event survive restart', () async {
    final folder = await Directory.systemTemp.createTemp('jump-success-');
    final path = p.join(folder.path, 'jump.sqlite');
    var repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var controller = GameController(repository: repo);
    try {
      final before = await seedJump(repo, withRunUp: true);
      await controller.openCampaign(before.id);
      await confirmJump(controller, before);
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(after.revision, before.revision + 1);
      expect(after.encounter!.remainingMovementDecimeters, 15);
      expect(after.encounter!.heroCover, CoverLevel.none);
      expect(after.encounter!.actionUsed, isFalse);
      expect(after.encounter!.bonusActionUsed, isFalse);
      expect(after.events.last.type, 'combat.longJumpConfirmed');
      expect(after.events.last.payload['actionRequestId'], 'jump-request-1');
      expect(after.events.last.payload['movementSpentDecimeters'], 45);
      expect(after.events.last.payload['immediateRunUpFeet'], 10);
      expect(after.events.last.payload['expectedRevision'], before.revision);
      expect(after.events.last.payload['addsProne'], isFalse);
      expect(Campaign.fromJson(after.toJson()).toJson(), after.toJson());

      // Lost acknowledgement: exact same request is not charged again.
      await confirmJump(controller, before);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), after.toJson());
      await confirmJump(controller, before, jumpCm: 440);
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), after.toJson());

      controller.dispose();
      await repo.close();
      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(repository: repo);
      await controller.openCampaign(before.id);
      expect(controller.currentCampaign!.toJson(), after.toJson());
      await confirmJump(controller, before);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), after.toJson());

      await confirmJump(controller, before, requestId: 'fresh-stale');
      expect(controller.error, contains('neu laden'));
      expect((await repo.getCampaign(before.id))!.toJson(), after.toJson());
    } finally {
      controller.dispose();
      await repo.close();
      await folder.delete(recursive: true);
    }
  });

  test('failed landing adds Prone only in committed campaign and event', () async {
    final folder = await Directory.systemTemp.createTemp('jump-prone-');
    final path = p.join(folder.path, 'jump.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repo);
    try {
      final before = await seedJump(repo);
      await controller.openCampaign(before.id);
      await confirmJump(
        controller,
        before,
        requestId: 'standing-fall',
        runUpFeet: 0,
        jumpCm: 220,
        difficult: true,
        acrobaticsTotal: 9,
      );
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(after.hero.conditions, contains('liegend'));
      expect(after.hero.manualConditions, contains('liegend'));
      expect(after.encounter!.remainingMovementDecimeters, 68);
      expect(after.events.last.payload['addsProne'], isTrue);
      expect(after.events.last.payload['confirmedLandingAcrobaticsTotal'], 9);
      expect((await repo.getCampaign(before.id))!.toJson(), after.toJson());
    } finally {
      controller.dispose();
      await repo.close();
      await folder.delete(recursive: true);
    }
  });

  test('run-up cannot be invented from flags or older movement events', () async {
    final folder = await Directory.systemTemp.createTemp('jump-no-receipt-');
    final path = p.join(folder.path, 'jump.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repo);
    try {
      final before = await seedJump(repo);
      await controller.openCampaign(before.id);
      await confirmJump(controller, before);
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), before.toJson());
      expect((await repo.getCampaign(before.id))!.toJson(), before.toJson());
      await confirmJump(controller, before, runUpFeet: 9, jumpCm: 220);
      expect(controller.error, isNotNull);
    } finally {
      controller.dispose();
      await repo.close();
      await folder.delete(recursive: true);
    }
  });

  test('missing checks, unapproved jump, blocked roll and 15 cm fail closed', () async {
    final folder = await Directory.systemTemp.createTemp('jump-reject-');
    final path = p.join(folder.path, 'jump.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repo);
    try {
      final before = await seedJump(repo, strength: 15, pendingRoll: true);
      await controller.openCampaign(before.id);
      await confirmJump(
        controller,
        before,
        requestId: 'blocked-roll',
        runUpFeet: 0,
        jumpCm: 220,
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), before.toJson());
      final clear = before.copyWith(pendingRoll: null);
      // A distinct repository/fixture is not needed: direct engine must
      // reject unrepresentable 15 cm even when the roll has been resolved.
      expect(
        () => GameEngine().confirmLongJump(
          clear,
          expectedEncounterId: 'jump-storage',
          expectedRevision: clear.revision,
          requestId: 'unrounded-standing',
          playerConfirmed: true,
          immediateRunUpFeet: 0,
          jumpDistanceCentimeters: 225,
          landingInDifficultTerrainConfirmed: false,
          obstacleFreePathConfirmed: true,
        ),
        throwsFormatException,
      );
      await confirmJump(
        controller,
        before,
        requestId: 'unapproved',
        playerConfirmed: false,
      );
      expect(controller.error, isNotNull);
      expect((await repo.getCampaign(before.id))!.toJson(), before.toJson());
    } finally {
      controller.dispose();
      await repo.close();
      await folder.delete(recursive: true);
    }
  });

  test('SQLite event insert failure rolls movement and revision back', () async {
    final folder = await Directory.systemTemp.createTemp('jump-rollback-');
    final path = p.join(folder.path, 'jump.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repo);
    try {
      final before = await seedJump(repo, withRunUp: true);
      await controller.openCampaign(before.id);
      final database = await databaseFactoryFfi.openDatabase(path);
      try {
        await database.execute('''
CREATE TRIGGER reject_long_jump
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"combat.longJumpConfirmed"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled long jump failure');
END
''');
        await confirmJump(controller, before);
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

  test('low obstacle needs a completed DC 10 Athletics result', () async {
    final folder = await Directory.systemTemp.createTemp('jump-obstacle-');
    final path = p.join(folder.path, 'jump.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(repository: repo);
    try {
      final before = await seedJump(repo, withRunUp: true);
      await controller.openCampaign(before.id);
      await confirmJump(
        controller,
        before,
        clearPath: false,
        lowObstacleCm: 100,
        athleticsRequired: true,
      );
      expect(controller.error, isNotNull);
      await confirmJump(
        controller,
        before,
        clearPath: false,
        lowObstacleCm: 100,
        athleticsRequired: true,
        athleticsTotal: 9,
      );
      expect(controller.error, isNotNull);
      expect((await repo.getCampaign(before.id))!.toJson(), before.toJson());
      await confirmJump(
        controller,
        before,
        clearPath: false,
        lowObstacleCm: 100,
        athleticsRequired: true,
        athleticsTotal: 10,
      );
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.events.last.payload[
        'confirmedObstacleAthleticsTotal'
      ], 10);
    } finally {
      controller.dispose();
      await repo.close();
      await folder.delete(recursive: true);
    }
  });
}
