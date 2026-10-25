import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_opportunity_attack_rules.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/story/story_rule_boundary.dart';

class _NoDice implements Random {
  @override
  int nextInt(int max) => throw StateError('No dice before a confirmed attack');
  @override
  bool nextBool() => throw StateError('No randomness');
  @override
  double nextDouble() => throw StateError('No randomness');
}

GameEngine _engine({int second = 0}) => GameEngine(
  dice: DiceEngine(random: _NoDice()),
  clock: () => DateTime.utc(2026, 10, 25, 17, 0, second),
);

Campaign _campaign() {
  final demo = GameEngine().createDemo();
  return Campaign.fromJson(
    demo
        .copyWith(
          hero: demo.hero.copyWith(
            equippedWeaponId: 'dagger',
            inventory: const [
              InventoryItem(
                id: 'dagger',
                name: 'Dolch',
                catalogId: 'weapon-dagger',
              ),
            ],
          ),
          encounter: const Encounter(
            id: 'foe',
            enemyName: 'Bestätigter Gegner',
            enemyHitPoints: 30,
            enemyMaxHitPoints: 30,
            activeParticipant: 'enemy',
            enemyAttacksPerTurn: 3,
            enemyAttacksRemaining: 2,
          ),
        )
        .toJson(),
  );
}

ConfirmedOpportunityTrigger _trigger({
  OpportunityMovement movement = OpportunityMovement.ordinary,
}) => ConfirmedOpportunityTrigger(
  encounterId: 'foe',
  beforeDistanceFeet: 5,
  afterDistanceFeet: 10,
  reachFeet: 5,
  targetVisibleConfirmed: true,
  playerAuthorizedReaction: true,
  movement: movement,
  strike: OpportunityStrike.equippedMeleeWeapon,
  weaponId: 'dagger',
);

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'confirmed segment pauses without rolling, spending or advancing the enemy turn',
    () {
      final engine = _engine();
      final original = _campaign();
      final update = engine.confirmOpportunityMovement(original, _trigger());
      final offered = update.campaign;
      expect(
        offered.pendingOpportunityAttack!.offeredAtRevision,
        offered.revision,
      );
      expect(offered.pendingOpportunityAttack!.encounterId, 'foe');
      expect(offered.encounter!.toJson(), original.encounter!.toJson());
      expect(offered.hero.toJson(), original.hero.toJson());
      expect(update.events.single.type, 'combat.opportunityOffered');
      expect(Campaign.fromJson(offered.toJson()).toJson(), offered.toJson());
      expect(original.pendingOpportunityAttack, isNull);
    },
  );

  test(
    'decline is explicit, target-bound and preserves all combat resources',
    () {
      final engine = _engine();
      final initial = _campaign();
      final offered = engine
          .confirmOpportunityMovement(initial, _trigger())
          .campaign;
      final id = offered.pendingOpportunityAttack!.id;
      for (final invalid in [
        () => engine.declineOpportunityAttack(
          offered,
          offerId: 'wrong',
          playerConfirmed: true,
        ),
        () => engine.declineOpportunityAttack(
          offered,
          offerId: id,
          playerConfirmed: false,
        ),
        () => engine.confirmOpportunityMovement(offered, _trigger()),
      ]) {
        expect(invalid, throwsFormatException);
      }
      final result = engine.declineOpportunityAttack(
        offered,
        offerId: id,
        playerConfirmed: true,
      );
      expect(result.campaign.pendingOpportunityAttack, isNull);
      expect(result.campaign.encounter!.toJson(), initial.encounter!.toJson());
      expect(result.campaign.hero.toJson(), initial.hero.toJson());
      expect(result.events.single.type, 'combat.opportunityDeclined');
      expect(result.events.single.payload['id'], id);
      expect(
        () => engine.declineOpportunityAttack(
          result.campaign,
          offerId: id,
          playerConfirmed: true,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'exception movement types, shield/roll pending and malformed old facts do not create offers',
    () {
      final engine = _engine();
      for (final movement in OpportunityMovement.values.where(
        (v) => v != OpportunityMovement.ordinary,
      )) {
        expect(
          () => engine.confirmOpportunityMovement(
            _campaign(),
            _trigger(movement: movement),
          ),
          throwsFormatException,
        );
      }
      final original = _campaign();
      final shield = original.copyWith(
        pendingEnemyShieldHit: const PendingEnemyShieldHit(
          encounterId: 'foe',
          natural: 20,
          modifier: 2,
          total: 22,
          rolls: [20],
          advanceRound: true,
        ),
      );
      expect(
        () => engine.confirmOpportunityMovement(shield, _trigger()),
        throwsFormatException,
      );
      final blocked = original.copyWith(
        pendingRoll: const PendingRoll(
          id: 'old-roll',
          type: 'perception',
          modifier: 0,
          difficulty: 10,
        ),
      );
      expect(
        () => engine.confirmOpportunityMovement(blocked, _trigger()),
        throwsFormatException,
      );
    },
  );

  test(
    'combat progression, character edits, free dice and story writes cannot bypass the interruption',
    () {
      final engine = _engine();
      final offered = engine
          .confirmOpportunityMovement(_campaign(), _trigger())
          .campaign;
      for (final action in [
        () => engine.act(offered, 'Gegnerangriff fortsetzen'),
        () => engine.continueEnemyTurn(offered),
        () => engine.rollDice(offered, '1d20'),
        () => engine.updateHero(offered, offered.hero.copyWith(hitPoints: 1)),
        () => engine.resolvePendingEnemyShieldHit(offered),
        () => engine.saveSessionRecap(offered),
      ]) {
        expect(action, throwsFormatException);
      }
      expect(
        () => StoryRuleBoundary.ensureRuleStateUnchanged(
          offered,
          offered.copyWith(pendingOpportunityAttack: null),
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'old JSON omits the new field; forged target, weapon, resource and confirmation imports fail',
    () {
      final original = _campaign();
      expect(
        original.toJson().containsKey('pendingOpportunityAttack'),
        isFalse,
      );
      expect(
        Campaign.fromJson(original.toJson()).pendingOpportunityAttack,
        isNull,
      );
      final offered = _engine()
          .confirmOpportunityMovement(original, _trigger())
          .campaign;
      Map<String, dynamic> copy() =>
          jsonDecode(jsonEncode(offered.toJson())) as Map<String, dynamic>;
      for (final change in <void Function(Map<String, dynamic>)>[
        (j) => j['pendingOpportunityAttack']['encounterId'] = 'other',
        (j) => j['pendingOpportunityAttack']['round'] = 2,
        (j) => j['pendingOpportunityAttack']['offeredAtRevision'] = 200,
        (j) => j['pendingOpportunityAttack']['targetVisibleConfirmed'] = false,
        (j) =>
            j['pendingOpportunityAttack']['playerAuthorizedReaction'] = false,
        (j) => j['pendingOpportunityAttack']['movement'] = 'teleport',
        (j) => j['pendingOpportunityAttack']['beforeDistanceFeet'] = 10,
        (j) => j['pendingOpportunityAttack']['afterDistanceFeet'] = 5,
        (j) => j['pendingOpportunityAttack']['weaponId'] = 'missing',
        (j) => j['pendingOpportunityAttack']['unarmedStrike'] = true,
        (j) => j['encounter']['activeParticipant'] = 'hero',
        (j) => j['encounter']['reactionUsed'] = true,
        (j) => j['hero']['equippedWeaponId'] = '',
        (j) => j['hero']['hitPoints'] = 0,
      ]) {
        final forged = copy();
        change(forged);
        expect(() => Campaign.fromJson(forged), throwsFormatException);
      }
    },
  );

  test(
    'SQLite restart, export and replay retain the offer; explicit decline is saved atomically',
    () async {
      final dir = await Directory.systemTemp.createTemp('opportunity-restart-');
      final path = '${dir.path}/game.db';
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var controller = GameController(
        repository: repository,
        engine: _engine(),
      );
      try {
        final original = _campaign();
        await repository.saveCampaign(original, events: original.events);
        await controller.openCampaign(original.id);
        await controller.confirmOpportunityMovement(
          campaignId: original.id,
          expectedRevision: original.revision,
          trigger: _trigger(),
        );
        expect(controller.error, isNull);
        final offered = controller.currentCampaign!;
        final offerId = offered.pendingOpportunityAttack!.id;
        final exported = Campaign.fromJson(
          jsonDecode(await repository.exportCampaign(original.id))['campaign'],
        );
        expect(exported.pendingOpportunityAttack!.id, offerId);
        expect(
          (await repository.reconstructCampaign(
            original.id,
          ))!.pendingOpportunityAttack!.id,
          offerId,
        );
        controller.dispose();
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        controller = GameController(repository: repository, engine: _engine());
        await controller.initialize();
        expect(
          controller.currentCampaign!.pendingOpportunityAttack!.id,
          offerId,
        );
        await controller.rollDice('1d20');
        expect(controller.error, contains('Gelegenheitsreaktion'));
        expect(controller.currentCampaign!.revision, offered.revision);
        await controller.declineOpportunityAttack(
          campaignId: original.id,
          expectedRevision: original.revision,
          offerId: offerId,
          playerConfirmed: true,
        );
        expect(controller.error, isNotNull);
        await controller.declineOpportunityAttack(
          campaignId: original.id,
          expectedRevision: offered.revision,
          offerId: offerId,
          playerConfirmed: true,
        );
        expect(controller.error, isNull);
        final saved = (await repository.getCampaign(original.id))!;
        expect(saved.pendingOpportunityAttack, isNull);
        expect(saved.encounter!.toJson(), original.encounter!.toJson());
        expect(saved.events.last.type, 'combat.opportunityDeclined');
        expect(
          (await repository.reconstructCampaign(
            original.id,
            revision: offered.revision,
          ))!.pendingOpportunityAttack!.id,
          offerId,
        );
      } finally {
        controller.dispose();
        await repository.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test(
    'a stale second writer cannot replace the stored offer or acknowledge a stale shield action',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'opportunity-conflict-',
      );
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: '${dir.path}/game.db',
      );
      final first = GameController(repository: repository, engine: _engine());
      final stale = GameController(
        repository: repository,
        engine: _engine(second: 1),
      );
      try {
        final initial = _campaign();
        await repository.saveCampaign(initial, events: initial.events);
        await first.openCampaign(initial.id);
        await stale.openCampaign(initial.id);
        await first.confirmOpportunityMovement(
          campaignId: initial.id,
          expectedRevision: initial.revision,
          trigger: _trigger(),
        );
        final saved = first.currentCampaign!;
        await stale.confirmOpportunityMovement(
          campaignId: initial.id,
          expectedRevision: initial.revision,
          trigger: _trigger(),
        );
        expect(stale.error, isNotNull);
        expect(stale.currentCampaign!.revision, initial.revision);
        expect(
          (await repository.getCampaign(initial.id))!.toJson(),
          saved.toJson(),
        );
        await first.resolveEnemyShieldHit(
          campaignId: initial.id,
          expectedRevision: initial.revision,
        );
        expect(first.error, isNotNull);
        expect(first.currentCampaign!.toJson(), saved.toJson());
      } finally {
        first.dispose();
        stale.dispose();
        await repository.close();
        await dir.delete(recursive: true);
      }
    },
  );

  test('failed offer event leaves the original game and UI untouched', () async {
    final dir = await Directory.systemTemp.createTemp(
      'opportunity-offer-failure-',
    );
    final path = '${dir.path}/game.db';
    final repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final controller = GameController(
      repository: repository,
      engine: _engine(),
    );
    final connection = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      final initial = _campaign();
      await repository.saveCampaign(initial, events: initial.events);
      await controller.openCampaign(initial.id);
      final displayed = controller.currentCampaign!;
      await connection.execute(
        "CREATE TRIGGER reject_offer BEFORE INSERT ON game_events WHEN instr(NEW.event_json, 'combat.opportunityOffered') > 0 BEGIN SELECT RAISE(ABORT, 'controlled offer failure'); END",
      );
      await controller.confirmOpportunityMovement(
        campaignId: initial.id,
        expectedRevision: initial.revision,
        trigger: _trigger(),
      );
      expect(controller.error, isNotNull);
      expect(identical(controller.currentCampaign, displayed), isTrue);
      expect(
        (await repository.getCampaign(initial.id))!.toJson(),
        displayed.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(
          initial.id,
        ))!.pendingOpportunityAttack,
        isNull,
      );
    } finally {
      controller.dispose();
      await connection.close();
      await repository.close();
      await dir.delete(recursive: true);
    }
  });

  test(
    'event write failure rolls back decline, snapshot, resources and displayed state',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'opportunity-rollback-',
      );
      final path = '${dir.path}/game.db';
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final controller = GameController(
        repository: repository,
        engine: _engine(),
      );
      final connection = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        final initial = _campaign();
        await repository.saveCampaign(initial, events: initial.events);
        await controller.openCampaign(initial.id);
        await controller.confirmOpportunityMovement(
          campaignId: initial.id,
          expectedRevision: initial.revision,
          trigger: _trigger(),
        );
        final offered = controller.currentCampaign!;
        await connection.execute(
          "CREATE TRIGGER reject_decline BEFORE INSERT ON game_events WHEN instr(NEW.event_json, 'combat.opportunityDeclined') > 0 BEGIN SELECT RAISE(ABORT, 'controlled opportunity write failure'); END",
        );
        await controller.declineOpportunityAttack(
          campaignId: initial.id,
          expectedRevision: offered.revision,
          offerId: offered.pendingOpportunityAttack!.id,
          playerConfirmed: true,
        );
        expect(controller.error, isNotNull);
        expect(identical(controller.currentCampaign, offered), isTrue);
        expect(
          (await repository.getCampaign(initial.id))!.toJson(),
          offered.toJson(),
        );
        expect(
          (await repository.reconstructCampaign(initial.id))!.toJson(),
          offered.toJson(),
        );
        await connection.execute('DROP TRIGGER reject_decline');
        await controller.declineOpportunityAttack(
          campaignId: initial.id,
          expectedRevision: offered.revision,
          offerId: offered.pendingOpportunityAttack!.id,
          playerConfirmed: true,
        );
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.pendingOpportunityAttack, isNull);
      } finally {
        controller.dispose();
        await connection.close();
        await repository.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
