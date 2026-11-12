import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_long_jump_rules.dart';

void main() {
  test('unconfirmed terrain never silently authorizes a landing', () {
    expect(
      () => SrdLongJumpRules.preflight(
        strengthScore: 12,
        runUpFeet: 10,
        immediateRunUpConfirmed: true,
        jumpDistanceCentimeters: 300,
        movementRemainingCentimeters: 300,
        landingInDifficultTerrainConfirmed: null,
        obstacleFreePathConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  test('unrequested rolls and conflicting obstacle facts fail closed', () {
    for (final (freePath, height, check, landing, obstacle) in [
      (true, null, null, 10, null),
      (true, 30, null, null, null),
      (true, null, true, null, null),
      (true, null, null, null, 10),
      (false, null, true, null, null),
      (false, 30, null, null, null),
      (false, 30, false, null, 10),
    ]) {
      expect(
        () => SrdLongJumpRules.preflight(
          strengthScore: 12,
          runUpFeet: 10,
          immediateRunUpConfirmed: true,
          jumpDistanceCentimeters: 300,
          movementRemainingCentimeters: 300,
          landingInDifficultTerrainConfirmed: false,
          obstacleFreePathConfirmed: freePath,
          lowObstacleHeightCentimeters: height,
          dmRequiresAthleticsCheck: check,
          confirmedLandingAcrobaticsTotal: landing,
          confirmedObstacleAthleticsTotal: obstacle,
        ),
        throwsFormatException,
      );
    }
  });

  test('explicitly waived obstacle check permits a confirmed jump', () {
    final result = SrdLongJumpRules.preflight(
      strengthScore: 12,
      runUpFeet: 10,
      immediateRunUpConfirmed: true,
      jumpDistanceCentimeters: 300,
      movementRemainingCentimeters: 300,
      landingInDifficultTerrainConfirmed: false,
      obstacleFreePathConfirmed: false,
      lowObstacleHeightCentimeters: 75,
      dmRequiresAthleticsCheck: false,
    );
    expect(result.obstacleAthletics, SrdLongJumpCheckOutcome.notRequired);
    expect(result.readyForConfirmation, isTrue);
    expect(result.movementRemainingCentimeters, 0);
  });
}
