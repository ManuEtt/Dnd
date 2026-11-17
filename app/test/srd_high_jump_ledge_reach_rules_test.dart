import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_high_jump_ledge_reach_rules.dart';

SrdHighJumpLedgeReachPreview reach({
  int strength = 14,
  int runUp = 10,
  bool runUpConfirmed = true,
  int height = 180,
  bool heightConfirmed = true,
  int targetHalfCm = 600,
  bool targetConfirmed = true,
  int movement = 300,
}) => SrdHighJumpLedgeReachRules.preview(
  strengthScore: strength,
  runUpFeet: runUp,
  runUpOnFootConfirmed: runUpConfirmed,
  creatureHeightCentimeters: height,
  creatureHeightConfirmed: heightConfirmed,
  targetHeightHalfCentimeters: targetHalfCm,
  targetHeightConfirmed: targetConfirmed,
  movementRemainingCentimeters: movement,
);

void main() {
  test('reachable ledge uses confirmed body height and minimum jump', () {
    final result = reach();
    expect(result.standingReachHalfCentimeters, 540);
    expect(result.minimumJumpCentimeters, 30);
    expect(result.maximumJumpCentimeters, 150);
    expect(result.movementAfterReachCentimeters, 270);
    expect(result.reachable, isTrue);
  });

  test('ledge below standing reach needs no jump', () {
    final result = reach(targetHalfCm: 500, movement: 0);
    expect(result.minimumJumpCentimeters, 0);
    expect(result.reachable, isTrue);
  });

  test('half-centimeter threshold rounds required jump upward', () {
    final result = reach(targetHalfCm: 543);
    expect(result.minimumJumpCentimeters, 2);
  });

  test('insufficient jump limit and movement are distinguished', () {
    final tooHigh = reach(targetHalfCm: 1000);
    expect(tooHigh.withinJumpLimit, isFalse);
    expect(tooHigh.reachable, isFalse);
    final tooFar = reach(movement: 29);
    expect(tooFar.withinJumpLimit, isTrue);
    expect(tooFar.withinMovementBudget, isFalse);
    expect(tooFar.reachable, isFalse);
  });

  test('unconfirmed facts and invalid run-up are rejected', () {
    expect(() => reach(heightConfirmed: false), throwsFormatException);
    expect(() => reach(targetConfirmed: false), throwsFormatException);
    expect(() => reach(height: 0), throwsFormatException);
    expect(() => reach(movement: -1), throwsFormatException);
    expect(() => reach(runUpConfirmed: false), throwsFormatException);
    expect(() => reach(strength: 0), throwsFormatException);
  });
}
