import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_high_jump_rules.dart';

void main() {
  test('high jump strength boundaries use floor for negative odd modifiers', () {
    for (var strength = 1; strength <= 30; strength++) {
      final modifier = ((strength - 10) / 2).floor();
      final feet = 3 + modifier;
      final expectedRunning = feet > 0 ? feet * 30 : 0;
      final expectedStanding = feet > 0 ? feet * 15 : 0;
      expect(
        SrdHighJumpRules.maximumHeightCentimeters(
          strengthScore: strength,
          runUpFeet: 10,
          runUpOnFootConfirmed: true,
        ),
        expectedRunning,
        reason: 'running strength $strength',
      );
      expect(
        SrdHighJumpRules.maximumHeightCentimeters(
          strengthScore: strength,
          runUpFeet: 0,
          runUpOnFootConfirmed: false,
        ),
        expectedStanding,
        reason: 'standing strength $strength',
      );
    }
  });

  test('run-up threshold changes height only at ten confirmed feet', () {
    for (var runUp = 0; runUp <= 11; runUp++) {
      final maximum = SrdHighJumpRules.maximumHeightCentimeters(
        strengthScore: 10,
        runUpFeet: runUp,
        runUpOnFootConfirmed: runUp > 0,
      );
      expect(maximum, runUp >= 10 ? 90 : 45, reason: 'run-up $runUp');
    }
  });

  test('exact movement budget is sufficient and never double-spends run-up', () {
    final assessment = SrdHighJumpRules.preflight(
      strengthScore: 10,
      runUpFeet: 10,
      runUpOnFootConfirmed: true,
      jumpHeightCentimeters: 90,
      movementRemainingCentimeters: 90,
      creatureHeightCentimeters: 181,
    );
    expect(assessment.runningStart, isTrue);
    expect(assessment.maximumHeightCentimeters, 90);
    expect(assessment.movementCostCentimeters, 90);
    expect(assessment.remainingMovementCentimeters, 0);
    expect(assessment.reachableHeightHalfCentimeters, 723);
    expect(
      () => SrdHighJumpRules.preflight(
        strengthScore: 10,
        runUpFeet: 10,
        runUpOnFootConfirmed: true,
        jumpHeightCentimeters: 90,
        movementRemainingCentimeters: 89,
      ),
      throwsFormatException,
    );
  });

  test('zero maximum cannot authorize a positive high jump', () {
    for (final strength in [1, 2, 3, 4]) {
      expect(
        () => SrdHighJumpRules.preflight(
          strengthScore: strength,
          runUpFeet: 10,
          runUpOnFootConfirmed: true,
          jumpHeightCentimeters: 1,
          movementRemainingCentimeters: 100,
        ),
        throwsFormatException,
      );
    }
  });
}
