import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_high_jump_rules.dart';

void main() {
  SrdHighJumpAssessment check({
    int? strength = 16,
    int runUpFeet = 10,
    bool runUpConfirmed = true,
    int heightCm = 150,
    int remainingCm = 300,
    int? creatureHeightCm,
  }) {
    return SrdHighJumpRules.preflight(
      strengthScore: strength,
      runUpFeet: runUpFeet,
      runUpOnFootConfirmed: runUpConfirmed,
      jumpHeightCentimeters: heightCm,
      movementRemainingCentimeters: remainingCm,
      creatureHeightCentimeters: creatureHeightCm,
    );
  }

  test('SRD running high jump uses 3 + Strength modifier in feet', () {
    expect(
      SrdHighJumpRules.maximumHeightCentimeters(
        strengthScore: 16,
        runUpFeet: 10,
        runUpOnFootConfirmed: true,
      ),
      180,
    );
    final result = check(heightCm: 180, remainingCm: 200);
    expect(result.runningStart, isTrue);
    expect(result.maximumHeightCentimeters, 180);
    expect(result.jumpHeightCentimeters, 180);
    expect(result.movementCostCentimeters, 180);
    expect(result.remainingMovementCentimeters, 20);
    expect(result.reachableHeightHalfCentimeters, isNull);
  });

  test('nine feet of confirmed run-up is still a standing jump', () {
    final standing = check(
      runUpFeet: 9,
      heightCm: 90,
      remainingCm: 90,
    );
    expect(standing.runningStart, isFalse);
    expect(standing.maximumHeightCentimeters, 90);
    expect(standing.remainingMovementCentimeters, 0);
    expect(
      () => check(runUpFeet: 9, heightCm: 91),
      throwsFormatException,
    );

    final withoutRunUp = check(
      runUpFeet: 0,
      runUpConfirmed: false,
      heightCm: 90,
    );
    expect(withoutRunUp.maximumHeightCentimeters, 90);
  });

  test('half-foot standing reach never rounds away legal height', () {
    final jump = check(
      strength: 19,
      runUpFeet: 0,
      runUpConfirmed: false,
      heightCm: 105,
      remainingCm: 105,
      creatureHeightCm: 175,
    );
    expect(jump.maximumHeightCentimeters, 105);
    expect(jump.reachableHeightHalfCentimeters, 735);
    // 367.5 cm reach: 105 cm jump + 1.5 * 175 cm body height.
    expect(jump.reachableHeightHalfCentimeters! / 2, 367.5);
  });

  test('negative odd Strength modifier rounds down and clamps to zero', () {
    expect(
      check(strength: 9, heightCm: 60).maximumHeightCentimeters,
      60,
    );
    expect(
      check(strength: 7, heightCm: 30).maximumHeightCentimeters,
      30,
    );
    expect(
      SrdHighJumpRules.maximumHeightCentimeters(
        strengthScore: 1,
        runUpFeet: 10,
        runUpOnFootConfirmed: true,
      ),
      0,
    );
    expect(() => check(strength: 1, heightCm: 1), throwsFormatException);
  });

  test('unverified or incoherent Strength and run-up fail closed', () {
    for (final invalid in <int?>[null, 0, -1, 31]) {
      expect(
        () => check(strength: invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    expect(
      () => check(runUpFeet: -1),
      throwsFormatException,
    );
    expect(
      () => check(runUpConfirmed: false),
      throwsFormatException,
    );
    expect(
      () => check(runUpFeet: 0, runUpConfirmed: true),
      throwsFormatException,
    );
  });

  test('invalid distance, movement budget and body size are rejected', () {
    for (final invalid in [-20, 0, 181]) {
      expect(
        () => check(heightCm: invalid),
        throwsFormatException,
        reason: '$invalid',
      );
    }
    expect(
      () => check(heightCm: 180, remainingCm: 179),
      throwsFormatException,
    );
    expect(
      () => check(remainingCm: -1),
      throwsFormatException,
    );
    expect(
      () => check(creatureHeightCm: 0),
      throwsFormatException,
    );
    expect(
      () => check(creatureHeightCm: -1),
      throwsFormatException,
    );
  });

  test('preflight is deterministic and never books movement itself', () {
    const remainingBefore = 240;
    final first = check(heightCm: 150, remainingCm: remainingBefore);
    final again = check(heightCm: 150, remainingCm: remainingBefore);
    expect(first.movementCostCentimeters, 150);
    expect(again.movementCostCentimeters, 150);
    expect(first.remainingMovementCentimeters, 90);
    expect(again.remainingMovementCentimeters, 90);
    expect(remainingBefore, 240);
  });
}
