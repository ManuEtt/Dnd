import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_terrain_movement_budget_preview_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_terrain_movement_rules.dart';

HeroCharacter hero({int hp = 20}) => HeroCharacter(
  id: 'terrain-preview',
  name: 'Held',
  className: 'Kämpfer',
  level: 1,
  hitPoints: hp,
  maxHitPoints: 20,
  speed: 9,
);

Encounter encounter({int remaining = 9, int remainder = 0}) => Encounter(
  id: 'terrain-preview',
  enemyName: 'Wache',
  enemyHitPoints: 10,
  enemyMaxHitPoints: 10,
  movementRemaining: remaining,
  movementRemainderDecimeters: remainder,
);

SrdTerrainMovementBudgetPreview inspect({
  int feet = 10,
  bool difficult = false,
  bool confirmed = true,
  bool checkRequired = false,
  bool checkPassed = false,
  int remaining = 9,
  int remainder = 0,
  int hp = 20,
}) => SrdTerrainMovementBudgetRules.preview(
  encounter: encounter(remaining: remaining, remainder: remainder),
  hero: hero(hp: hp),
  kind: SrdTerrainMovement.climb,
  distanceFeet: feet,
  difficultTerrain: difficult,
  terrainConfirmed: confirmed,
  additionalCheckRequired: checkRequired,
  additionalCheckPassedConfirmed: checkPassed,
);

void main() {
  test('normal climb previews exact budget without spending it', () {
    final result = inspect();
    expect(result.requiredDecimeters, 60);
    expect(result.availableDecimeters, 90);
    expect(result.remainingDecimeters, 30);
    expect(result.affordable, isTrue);
  });

  test('difficult terrain can exceed budget without throwing', () {
    final result = inspect(difficult: true, remaining: 6);
    expect(result.requiredDecimeters, 90);
    expect(result.availableDecimeters, 60);
    expect(result.remainingDecimeters, -30);
    expect(result.affordable, isFalse);
  });

  test('fractional meter movement is retained exactly', () {
    final result = inspect(feet: 1, remaining: 0, remainder: 6);
    expect(result.requiredDecimeters, 6);
    expect(result.remainingDecimeters, 0);
    expect(result.affordable, isTrue);
  });

  test('unconfirmed terrain or athletics cannot be previewed', () {
    expect(() => inspect(confirmed: false), throwsFormatException);
    expect(() => inspect(checkRequired: true), throwsFormatException);
    expect(
      inspect(checkRequired: true, checkPassed: true).affordable,
      isTrue,
    );
  });

  test('invalid actor, movement or distance fail closed', () {
    expect(() => inspect(hp: 0), throwsFormatException);
    expect(() => inspect(remainder: 10), throwsFormatException);
    expect(() => inspect(feet: 0), throwsFormatException);
  });
}
