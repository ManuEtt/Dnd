import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_long_jump_rules.dart';

void main() {
  test('invalid strength and run-up facts never authorize a long jump', () {
    for (final strength in <int?>[null, -1, 0, 31, 100]) {
      expect(
        () => SrdLongJumpRules.maximumDistanceCentimeters(
          strengthScore: strength,
          runUpFeet: 0,
          immediateRunUpConfirmed: false,
        ),
        throwsFormatException,
      );
    }

    for (final (feet, confirmed) in [
      (-1, false),
      (-1, true),
      (0, true),
      (1, false),
      (9, false),
      (10, false),
    ]) {
      expect(
        () => SrdLongJumpRules.maximumDistanceCentimeters(
          strengthScore: 10,
          runUpFeet: feet,
          immediateRunUpConfirmed: confirmed,
        ),
        throwsFormatException,
      );
    }
  });

  test('invalid distance and insufficient movement are rejected', () {
    for (final (distance, movement) in [
      (0, 300),
      (-1, 300),
      (301, 301),
      (300, 299),
      (300, -1),
    ]) {
      expect(
        () => SrdLongJumpRules.preflight(
          strengthScore: 10,
          runUpFeet: 10,
          immediateRunUpConfirmed: true,
          jumpDistanceCentimeters: distance,
          movementRemainingCentimeters: movement,
          landingInDifficultTerrainConfirmed: false,
          obstacleFreePathConfirmed: true,
        ),
        throwsFormatException,
      );
    }
  });

  test('odd strength standing jump preserves exact centimeters', () {
    final result = SrdLongJumpRules.preflight(
      strengthScore: 11,
      runUpFeet: 0,
      immediateRunUpConfirmed: false,
      jumpDistanceCentimeters: 165,
      movementRemainingCentimeters: 165,
      landingInDifficultTerrainConfirmed: false,
      obstacleFreePathConfirmed: true,
    );
    expect(result.runningStart, isFalse);
    expect(result.maximumDistanceCentimeters, 165);
    expect(result.movementCostCentimeters, 165);
    expect(result.movementRemainingCentimeters, 0);
    expect(result.readyForConfirmation, isTrue);
  });
}
