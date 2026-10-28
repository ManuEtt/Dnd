import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_long_jump_encounter_rules.dart';

Campaign fighting({
  int? strength = 15,
  int wholeMeters = 5,
  int remainder = 7,
  int speed = 9,
  String participant = 'hero',
  int enemyHitPoints = 10,
  bool jumpDoubled = false,
  List<String> conditions = const [],
}) {
  final initial = GameEngine().createDemo();
  return initial.copyWith(
    hero: initial.hero.copyWith(
      abilities: {...initial.hero.abilities, 'strength': strength},
      speed: speed,
      conditions: conditions,
    ),
    encounter: Encounter(
      id: 'long-jump-target',
      enemyName: 'Wache',
      enemyHitPoints: enemyHitPoints,
      enemyMaxHitPoints: 10,
      activeParticipant: participant,
      movementRemaining: wholeMeters,
      movementRemainderDecimeters: remainder,
      heroCover: CoverLevel.half,
      jumpDoubledThisTurn: jumpDoubled,
    ),
  );
}

SrdLongJumpEncounterPlan plan(
  Campaign campaign, {
  String? campaignId,
  String encounterId = 'long-jump-target',
  int? revision,
  int runUpFeet = 10,
  bool runUpSpent = true,
  int jumpCm = 450,
  bool? difficult = false,
  bool clearPath = true,
  int? obstacleCm,
  bool? athleticsRequired,
  int? acrobaticsTotal,
  int? athleticsTotal,
}) => SrdLongJumpEncounterRules.prepare(
  campaign: campaign,
  expectedCampaignId: campaignId ?? campaign.id,
  expectedEncounterId: encounterId,
  expectedRevision: revision ?? campaign.revision,
  immediateRunUpFeet: runUpFeet,
  runUpAlreadySpentConfirmed: runUpSpent,
  jumpDistanceCentimeters: jumpCm,
  landingInDifficultTerrainConfirmed: difficult,
  obstacleFreePathConfirmed: clearPath,
  lowObstacleHeightCentimeters: obstacleCm,
  dmRequiresAthleticsCheck: athleticsRequired,
  confirmedLandingAcrobaticsTotal: acrobaticsTotal,
  confirmedObstacleAthleticsTotal: athleticsTotal,
);

void main() {
  test('confirmed jump spends precise decimeters but no combat action', () {
    final before = fighting();
    final old = before.toJson();
    final result = plan(before);
    final after = result.projectedCampaign;
    expect(result.movementSpentDecimeters, 45);
    expect(after.encounter!.remainingMovementDecimeters, 12);
    expect(after.encounter!.movementRemainingLabel, '1.2 m');
    expect(after.encounter!.heroCover, CoverLevel.none);
    expect(after.encounter!.actionUsed, isFalse);
    expect(after.encounter!.bonusActionUsed, isFalse);
    expect(after.encounter!.reactionUsed, isFalse);
    expect(after.hero.conditions, isNot(contains('liegend')));
    expect(result.addsProne, isFalse);
    expect(after.revision, before.revision);
    expect(after.events, hasLength(before.events.length));
    expect(before.toJson(), old);
    expect(before.encounter!.movementRemainingLabel, '5.7 m');
  });

  test('failed difficult-terrain landing plans Prone exactly once', () {
    final before = fighting();
    final result = plan(before, difficult: true, acrobaticsTotal: 9);
    expect(result.addsProne, isTrue);
    expect(result.projectedCampaign.hero.conditions, contains('liegend'));
    expect(result.projectedCampaign.hero.manualConditions, ['liegend']);
    expect(before.hero.conditions, isNot(contains('liegend')));
    expect(
      Campaign.fromJson(result.projectedCampaign.toJson()).toJson(),
      result.projectedCampaign.toJson(),
    );
    final passed = plan(before, difficult: true, acrobaticsTotal: 10);
    expect(passed.addsProne, isFalse);
    expect(
      passed.projectedCampaign.hero.conditions,
      isNot(contains('liegend')),
    );
  });

  test('unknown dice result and unpassed obstacle cannot produce a plan', () {
    final before = fighting();
    expect(() => plan(before, difficult: true), throwsFormatException);
    expect(
      () => plan(
        before,
        clearPath: false,
        obstacleCm: 100,
        athleticsRequired: true,
      ),
      throwsFormatException,
    );
    expect(
      () => plan(
        before,
        clearPath: false,
        obstacleCm: 100,
        athleticsRequired: true,
        athleticsTotal: 9,
      ),
      throwsFormatException,
    );
    final passed = plan(
      before,
      clearPath: false,
      obstacleCm: 100,
      athleticsRequired: true,
      athleticsTotal: 10,
    );
    expect(passed.projectedCampaign.encounter!.remainingMovementDecimeters, 12);
  });

  test(
    'wrong campaign, encounter, revision, turn, or finished fight block',
    () {
      final before = fighting();
      expect(() => plan(before, campaignId: 'another'), throwsFormatException);
      expect(() => plan(before, encounterId: 'another'), throwsFormatException);
      expect(
        () => plan(before, revision: before.revision + 1),
        throwsFormatException,
      );
      expect(() => plan(fighting(participant: 'enemy')), throwsFormatException);
      expect(() => plan(fighting(enemyHitPoints: 0)), throwsFormatException);
      expect(
        () => plan(before.copyWith(encounter: null)),
        throwsFormatException,
      );
    },
  );

  test('all pending rule actions must finish before movement is prepared', () {
    final before = fighting();
    expect(
      () => plan(
        before.copyWith(
          pendingRoll: const PendingRoll(
            id: 'roll-pending',
            type: 'ability',
            modifier: 0,
            difficulty: 10,
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => plan(
        before.copyWith(
          pendingDeathSave: const PendingDeathSave(
            originalNatural: 5,
            modifier: 0,
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => plan(
        before.copyWith(
          pendingEnemyShieldHit: const PendingEnemyShieldHit(
            encounterId: 'long-jump-target',
            natural: 15,
            modifier: 2,
            total: 17,
            rolls: [15],
            advanceRound: false,
          ),
        ),
      ),
      throwsFormatException,
    );
  });

  test('Prone, Grappled, zero speed and jump bonuses stay fail-closed', () {
    expect(
      () => plan(fighting(conditions: const ['liegend'])),
      throwsFormatException,
    );
    expect(
      () => plan(fighting(conditions: const ['gepackt'])),
      throwsFormatException,
    );
    expect(() => plan(fighting(speed: 0)), throwsFormatException);
    expect(() => plan(fighting(jumpDoubled: true)), throwsUnsupportedError);
    expect(() => plan(fighting(strength: null)), throwsFormatException);
  });

  test('run-up must be accounted for before the jump, never twice', () {
    final before = fighting();
    expect(() => plan(before, runUpSpent: false), throwsFormatException);
    expect(
      () => plan(before, runUpFeet: 0, runUpSpent: true),
      throwsFormatException,
    );
    final standing = plan(before, runUpFeet: 0, runUpSpent: false, jumpCm: 220);
    expect(standing.assessment.maximumDistanceCentimeters, 225);
    expect(standing.movementSpentDecimeters, 22);
    expect(
      standing.projectedCampaign.encounter!.remainingMovementDecimeters,
      35,
    );
    final shortRun = plan(before, runUpFeet: 9, runUpSpent: true, jumpCm: 220);
    expect(shortRun.assessment.runningStart, isFalse);
    expect(
      shortRun.projectedCampaign.encounter!.remainingMovementDecimeters,
      35,
    );
  });

  test('unrepresentable half-foot values do not lose movement precision', () {
    final before = fighting();
    expect(
      () => plan(before, runUpFeet: 0, runUpSpent: false, jumpCm: 225),
      throwsFormatException,
    );
    expect(() => plan(before, jumpCm: 455), throwsFormatException);
    expect(() => plan(before, jumpCm: 450 + 10), throwsFormatException);
    expect(
      () => plan(fighting(wholeMeters: 4, remainder: 4)),
      throwsFormatException,
    );
    expect(() => plan(fighting(wholeMeters: -1)), throwsFormatException);
    expect(() => plan(fighting(remainder: 10)), throwsFormatException);
  });

  test('expected revision is a caller guard, not a fake stored receipt', () {
    final before = fighting();
    final first = plan(before);
    final currentAfterCommit = first.projectedCampaign.copyWith(
      revision: before.revision + 1,
    );
    expect(
      () => plan(currentAfterCommit, revision: before.revision),
      throwsFormatException,
    );
    expect(first.projectedCampaign.events, before.events);
    expect(first.expectedRevision, before.revision);
    expect(
      Campaign.fromJson(first.projectedCampaign.toJson()).toJson(),
      first.projectedCampaign.toJson(),
    );
  });
}
