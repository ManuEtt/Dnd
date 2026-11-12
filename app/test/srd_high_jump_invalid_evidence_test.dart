import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_high_jump_rules.dart';

void main() {
  test('invalid strength scores cannot authorize a jump', () {
    for (final strength in <int?>[null, -1, 0, 31, 100]) {
      expect(
        () => SrdHighJumpRules.maximumHeightCentimeters(
          strengthScore: strength,
          runUpFeet: 0,
          runUpOnFootConfirmed: false,
        ),
        throwsFormatException,
      );
    }
  });

  test('unconfirmed and inconsistent run-up facts fail closed', () {
    for (final (feet, confirmed) in [
      (-1, false),
      (-1, true),
      (0, true),
      (1, false),
      (9, false),
      (10, false),
    ]) {
      expect(
        () => SrdHighJumpRules.maximumHeightCentimeters(
          strengthScore: 16,
          runUpFeet: feet,
          runUpOnFootConfirmed: confirmed,
        ),
        throwsFormatException,
      );
    }
  });

  test('invalid rise and insufficient movement are rejected', () {
    for (final (rise, remaining) in [
      (0, 300),
      (-1, 300),
      (181, 300),
      (180, 179),
      (180, -1),
    ]) {
      expect(
        () => SrdHighJumpRules.preflight(
          strengthScore: 16,
          runUpFeet: 10,
          runUpOnFootConfirmed: true,
          jumpHeightCentimeters: rise,
          movementRemainingCentimeters: remaining,
        ),
        throwsFormatException,
      );
    }
  });

  test('unconfirmed creature height never becomes a reach value', () {
    for (final height in [-1, 0]) {
      expect(
        () => SrdHighJumpRules.preflight(
          strengthScore: 16,
          runUpFeet: 10,
          runUpOnFootConfirmed: true,
          jumpHeightCentimeters: 90,
          movementRemainingCentimeters: 90,
          creatureHeightCentimeters: height,
        ),
        throwsFormatException,
      );
    }

    final result = SrdHighJumpRules.preflight(
      strengthScore: 16,
      runUpFeet: 10,
      runUpOnFootConfirmed: true,
      jumpHeightCentimeters: 90,
      movementRemainingCentimeters: 90,
    );
    expect(result.reachableHeightHalfCentimeters, isNull);
    expect(result.remainingMovementCentimeters, 0);
  });
}
