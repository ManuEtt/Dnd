import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_long_jump_rules.dart';

void main() {
  SrdLongJumpAssessment check({
    int? strength = 15,
    int runUp = 10,
    bool confirmedRunUp = true,
    int distance = 450,
    int remaining = 500,
    bool? difficultLanding = false,
    bool clearPath = true,
    int? obstacleHeight,
    bool? dmRequestsCheck,
    int? acrobaticsTotal,
    int? athleticsTotal,
  }) {
    return SrdLongJumpRules.preflight(
      strengthScore: strength,
      runUpFeet: runUp,
      immediateRunUpConfirmed: confirmedRunUp,
      jumpDistanceCentimeters: distance,
      movementRemainingCentimeters: remaining,
      landingInDifficultTerrainConfirmed: difficultLanding,
      obstacleFreePathConfirmed: clearPath,
      lowObstacleHeightCentimeters: obstacleHeight,
      dmRequiresAthleticsCheck: dmRequestsCheck,
      confirmedLandingAcrobaticsTotal: acrobaticsTotal,
      confirmedObstacleAthleticsTotal: athleticsTotal,
    );
  }

  test('ten-foot immediate run-up allows Strength feet exactly', () {
    final result = check(distance: 450, remaining: 455);
    expect(result.runningStart, isTrue);
    expect(result.maximumDistanceCentimeters, 450);
    expect(result.distanceCentimeters, 450);
    expect(result.movementCostCentimeters, 450);
    expect(result.movementRemainingCentimeters, 5);
    expect(result.landingAcrobatics, SrdLongJumpCheckOutcome.notRequired);
    expect(result.obstacleAthletics, SrdLongJumpCheckOutcome.notRequired);
    expect(result.wouldLandProne, isFalse);
    expect(result.readyForConfirmation, isTrue);
  });

  test('standing or nine-foot run-up only permits half the distance', () {
    final standing = check(
      runUp: 0,
      confirmedRunUp: false,
      distance: 225,
      remaining: 225,
    );
    expect(standing.runningStart, isFalse);
    expect(standing.maximumDistanceCentimeters, 225);
    expect(standing.movementRemainingCentimeters, 0);
    expect(
      check(runUp: 9, distance: 225).maximumDistanceCentimeters,
      225,
    );
    expect(
      () => check(runUp: 9, distance: 226),
      throwsFormatException,
    );
    expect(
      () => check(runUp: 0, confirmedRunUp: false),
      throwsFormatException,
    );
    expect(
      SrdLongJumpRules.maximumDistanceCentimeters(
        strengthScore: 13,
        runUpFeet: 0,
        immediateRunUpConfirmed: false,
      ),
      195,
    );
  });

  test('unknown strength and unconfirmed run-up fail before any action', () {
    for (final bad in <int?>[null, -1, 0, 31]) {
      expect(
        () => check(strength: bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
    expect(() => check(runUp: -1), throwsFormatException);
    expect(() => check(confirmedRunUp: false), throwsFormatException);
    expect(
      () => check(runUp: 0, confirmedRunUp: true),
      throwsFormatException,
    );
  });

  test('invalid jump distance and unavailable movement fail closed', () {
    for (final bad in [-1, 0, 451]) {
      expect(
        () => check(distance: bad),
        throwsFormatException,
        reason: '$bad',
      );
    }
    expect(
      () => check(distance: 450, remaining: 449),
      throwsFormatException,
    );
    expect(() => check(remaining: -5), throwsFormatException);
    expect(
      () => check(difficultLanding: null),
      throwsFormatException,
    );
  });

  test('difficult-terrain landing asks for a confirmed DC 10 check', () {
    final pending = check(difficultLanding: true);
    expect(pending.landingAcrobatics, SrdLongJumpCheckOutcome.pending);
    expect(pending.wouldLandProne, isNull);
    expect(pending.readyForConfirmation, isFalse);

    final failed = check(
      difficultLanding: true,
      acrobaticsTotal: 9,
    );
    expect(failed.landingAcrobatics, SrdLongJumpCheckOutcome.failure);
    expect(failed.wouldLandProne, isTrue);
    expect(failed.readyForConfirmation, isTrue);

    final passed = check(
      difficultLanding: true,
      acrobaticsTotal: 10,
    );
    expect(passed.landingAcrobatics, SrdLongJumpCheckOutcome.success);
    expect(passed.wouldLandProne, isFalse);
    expect(passed.readyForConfirmation, isTrue);
    expect(
      () => check(acrobaticsTotal: 10),
      throwsFormatException,
    );
  });

  test('DM-selected low-obstacle Athletics is independent of landing', () {
    final pending = check(
      clearPath: false,
      obstacleHeight: 100,
      dmRequestsCheck: true,
    );
    expect(pending.obstacleAthletics, SrdLongJumpCheckOutcome.pending);
    expect(pending.readyForConfirmation, isFalse);
    final failed = check(
      clearPath: false,
      obstacleHeight: 100,
      dmRequestsCheck: true,
      athleticsTotal: 9,
    );
    expect(failed.obstacleAthletics, SrdLongJumpCheckOutcome.failure);
    expect(failed.readyForConfirmation, isFalse);
    final passed = check(
      clearPath: false,
      obstacleHeight: 100,
      dmRequestsCheck: true,
      athleticsTotal: 10,
    );
    expect(passed.obstacleAthletics, SrdLongJumpCheckOutcome.success);
    expect(passed.readyForConfirmation, isTrue);
    final waived = check(
      clearPath: false,
      obstacleHeight: 100,
      dmRequestsCheck: false,
    );
    expect(waived.obstacleAthletics, SrdLongJumpCheckOutcome.notRequired);
    expect(waived.readyForConfirmation, isTrue);
  });

  test('only obstacles at most one quarter distance use low rule', () {
    expect(
      check(
        clearPath: false,
        obstacleHeight: 112,
        dmRequestsCheck: false,
      ).readyForConfirmation,
      isTrue,
    );
    expect(
      () => check(
        clearPath: false,
        obstacleHeight: 113,
        dmRequestsCheck: false,
      ),
      throwsUnsupportedError,
    );
    expect(
      () => check(
        clearPath: false,
        obstacleHeight: 9223372036854775807,
        dmRequestsCheck: false,
      ),
      throwsUnsupportedError,
    );
  });

  test('obstacle declarations cannot contradict confirmed free path', () {
    expect(
      () => check(obstacleHeight: 50),
      throwsFormatException,
    );
    expect(
      () => check(dmRequestsCheck: true),
      throwsFormatException,
    );
    expect(
      () => check(athleticsTotal: 10),
      throwsFormatException,
    );
    expect(
      () => check(clearPath: false),
      throwsFormatException,
    );
    expect(
      () => check(clearPath: false, obstacleHeight: 0),
      throwsFormatException,
    );
    expect(
      () => check(clearPath: false, obstacleHeight: 30),
      throwsFormatException,
    );
    expect(
      () => check(
        clearPath: false,
        obstacleHeight: 30,
        dmRequestsCheck: false,
        athleticsTotal: 10,
      ),
      throwsFormatException,
    );
  });

  test('pending independent checks never pretend the jump succeeded', () {
    const before = 500;
    final pending = check(
      remaining: before,
      difficultLanding: true,
      clearPath: false,
      obstacleHeight: 30,
      dmRequestsCheck: true,
    );
    expect(pending.landingAcrobatics, SrdLongJumpCheckOutcome.pending);
    expect(pending.obstacleAthletics, SrdLongJumpCheckOutcome.pending);
    expect(pending.readyForConfirmation, isFalse);
    final again = check(
      remaining: before,
      difficultLanding: true,
      clearPath: false,
      obstacleHeight: 30,
      dmRequestsCheck: true,
    );
    expect(again.movementRemainingCentimeters, 50);
    expect(pending.movementRemainingCentimeters, 50);
    expect(before, 500);
  });
}
