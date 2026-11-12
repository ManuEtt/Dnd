import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_long_jump_rules.dart';

void main() {
  test('all valid strengths preserve standing half-foot precision', () {
    for (var strength = 1; strength <= 30; strength++) {
      expect(
        SrdLongJumpRules.maximumDistanceCentimeters(
          strengthScore: strength,
          runUpFeet: 0,
          immediateRunUpConfirmed: false,
        ),
        strength * 15,
      );
      expect(
        SrdLongJumpRules.maximumDistanceCentimeters(
          strengthScore: strength,
          runUpFeet: 10,
          immediateRunUpConfirmed: true,
        ),
        strength * 30,
      );
    }
  });

  test('running start threshold applies only at ten confirmed feet', () {
    for (var runUp = 0; runUp <= 11; runUp++) {
      expect(
        SrdLongJumpRules.maximumDistanceCentimeters(
          strengthScore: 11,
          runUpFeet: runUp,
          immediateRunUpConfirmed: runUp > 0,
        ),
        runUp >= 10 ? 330 : 165,
      );
    }
  });

  test('difficult terrain DC ten distinguishes pending and failed landing', () {
    for (final (total, outcome, prone, ready) in [
      (null, SrdLongJumpCheckOutcome.pending, null, false),
      (9, SrdLongJumpCheckOutcome.failure, true, true),
      (10, SrdLongJumpCheckOutcome.success, false, true),
    ]) {
      final result = SrdLongJumpRules.preflight(
        strengthScore: 10,
        runUpFeet: 10,
        immediateRunUpConfirmed: true,
        jumpDistanceCentimeters: 300,
        movementRemainingCentimeters: 300,
        landingInDifficultTerrainConfirmed: true,
        obstacleFreePathConfirmed: true,
        confirmedLandingAcrobaticsTotal: total,
      );
      expect(result.landingAcrobatics, outcome);
      expect(result.wouldLandProne, prone);
      expect(result.readyForConfirmation, ready);
      expect(result.movementRemainingCentimeters, 0);
    }
  });

  test('obstacle DC ten must resolve before confirmation', () {
    for (final (total, outcome, ready) in [
      (null, SrdLongJumpCheckOutcome.pending, false),
      (9, SrdLongJumpCheckOutcome.failure, false),
      (10, SrdLongJumpCheckOutcome.success, true),
    ]) {
      final result = SrdLongJumpRules.preflight(
        strengthScore: 10,
        runUpFeet: 10,
        immediateRunUpConfirmed: true,
        jumpDistanceCentimeters: 300,
        movementRemainingCentimeters: 300,
        landingInDifficultTerrainConfirmed: false,
        obstacleFreePathConfirmed: false,
        lowObstacleHeightCentimeters: 75,
        dmRequiresAthleticsCheck: true,
        confirmedObstacleAthleticsTotal: total,
      );
      expect(result.obstacleAthletics, outcome);
      expect(result.readyForConfirmation, ready);
    }
  });

  test('obstacles above one quarter jump distance require adjudication', () {
    expect(
      () => SrdLongJumpRules.preflight(
        strengthScore: 10,
        runUpFeet: 10,
        immediateRunUpConfirmed: true,
        jumpDistanceCentimeters: 300,
        movementRemainingCentimeters: 300,
        landingInDifficultTerrainConfirmed: false,
        obstacleFreePathConfirmed: false,
        lowObstacleHeightCentimeters: 76,
        dmRequiresAthleticsCheck: false,
      ),
      throwsUnsupportedError,
    );
  });
}
