import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_terrain_movement_rules.dart';

Campaign battle({
  bool ranger = true,
  int rangerLevel = 6,
  int remaining = 9,
  int remainder = 0,
  String participant = 'hero',
  List<String> conditions = const [],
  int speed = 9,
}) {
  final initial = GameEngine().createDemo();
  return initial.copyWith(
    hero: initial.hero.copyWith(
      className: ranger ? 'Waldläufer' : 'Kämpfer',
      level: rangerLevel,
      speed: speed,
      conditions: conditions,
    ),
    encounter: Encounter(
      id: 'terrain',
      enemyName: 'Wache',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      movementRemaining: remaining,
      movementRemainderDecimeters: remainder,
      activeParticipant: participant,
      heroCover: CoverLevel.half,
    ),
  );
}

GameUpdate climb(Campaign current, {
  int feet = 10,
  bool difficult = false,
  bool confirmed = true,
  bool checkRequired = false,
  bool checkPassed = false,
}) => GameEngine().moveOnConfirmedTerrain(
  current,
  kind: SrdTerrainMovement.climb,
  distanceFeet: feet,
  difficultTerrain: difficult,
  terrainConfirmed: confirmed,
  additionalCheckRequired: checkRequired,
  additionalCheckPassedConfirmed: checkPassed,
);

void main() {
  test('Roving: 10 feet climbing costs 3 m and clears old cover', () {
    final before = battle();
    final result = climb(before);
    final after = result.campaign;
    expect(after.encounter!.remainingMovementDecimeters, 60);
    expect(after.encounter!.heroCover, CoverLevel.none);
    expect(after.encounter!.actionUsed, isFalse);
    expect(after.encounter!.bonusActionUsed, isFalse);
    expect(after.hero.toJson(), before.hero.toJson());
    expect(before.encounter!.heroCover, CoverLevel.half);
    expect(after.revision, before.revision + 1);
    expect(result.events.single.type, 'combat.climbed');
    expect(result.events.single.payload['movementSpentDecimeters'], 30);
    expect(result.events.single.payload['specialSpeedApplied'], true);
    expect(result.events.single.payload['terrainConfirmed'], true);
  });

  test('Without Roving 10ft climbing costs 6m, difficult costs 9m', () {
    final normal = battle(ranger: false);
    expect(climb(normal).campaign.encounter!.remainingMovementDecimeters, 30);
    expect(
      climb(normal, difficult: true)
          .campaign
          .encounter!
          .remainingMovementDecimeters,
      0,
    );
    expect(
      SrdTerrainMovementRules.costDecimeters(
        normal.hero,
        kind: SrdTerrainMovement.climb,
        distanceFeet: 10,
        difficultTerrain: true,
      ),
      90,
    );
  });

  test('Roving difficult terrain still costs 2 movement feet per foot', () {
    final before = battle();
    final climbed = climb(before, difficult: true);
    expect(climbed.campaign.encounter!.remainingMovementDecimeters, 30);
    expect(climbed.events.single.payload['movementSpentDecimeters'], 60);
    final swam = GameEngine().moveOnConfirmedTerrain(
      before,
      kind: SrdTerrainMovement.swim,
      distanceFeet: 10,
      difficultTerrain: true,
      terrainConfirmed: true,
    );
    expect(swam.campaign.encounter!.remainingMovementDecimeters, 30);
    expect(swam.events.single.type, 'combat.swam');
    expect(swam.events.single.payload['specialSpeedApplied'], true);
  });

  test('Swimming without a Swim Speed pays 2 or 3 movement feet', () {
    final without = battle(ranger: false);
    final normal = GameEngine().moveOnConfirmedTerrain(
      without,
      kind: SrdTerrainMovement.swim,
      distanceFeet: 5,
      difficultTerrain: false,
      terrainConfirmed: true,
    );
    expect(normal.campaign.encounter!.movementRemainingLabel, '6 m');
    expect(normal.events.single.payload['movementSpentDecimeters'], 30);
    final rough = GameEngine().moveOnConfirmedTerrain(
      without,
      kind: SrdTerrainMovement.swim,
      distanceFeet: 5,
      difficultTerrain: true,
      terrainConfirmed: true,
      additionalCheckRequired: true,
      additionalCheckPassedConfirmed: true,
    );
    expect(rough.campaign.encounter!.movementRemainingLabel, '4.5 m');
    expect(rough.events.single.payload['movementSpentDecimeters'], 45);
  });

  test('Class level 5 receives neither specialized speed nor discount', () {
    final below = battle(rangerLevel: 5);
    expect(climb(below).campaign.encounter!.remainingMovementDecimeters, 30);
    expect(
      SrdTerrainMovementRules.hasSpecialSpeed(
        below.hero,
        SrdTerrainMovement.climb,
      ),
      false,
    );
  });

  test('Submeter budgets are kept precisely and JSON persists events', () {
    final before = battle(remaining: 2, remainder: 9);
    final update = climb(before, feet: 5);
    expect(update.campaign.encounter!.movementRemainingLabel, '1.4 m');
    expect(update.events.single.payload['movementSpentDecimeters'], 15);
    final restored = Campaign.fromJson(update.campaign.toJson());
    expect(restored.toJson(), update.campaign.toJson());
    expect(restored.encounter!.movementRemainderDecimeters, 4);
    expect(restored.events.last.type, 'combat.climbed');
  });

  test('Unknown terrain, optional checks, wrong turn block without commit', () {
    final before = battle();
    for (final movement in [
      () => climb(before, confirmed: false),
      () => climb(before, checkRequired: true),
      () => climb(before.copyWith(
        encounter: before.encounter!.copyWith(activeParticipant: 'enemy'),
      )),
      () => climb(battle(conditions: const ['liegend'])),
      () => climb(battle(conditions: const ['gepackt'])),
      () => climb(battle(speed: 0)),
    ]) {
      expect(movement, throwsFormatException);
    }
    expect(before.encounter!.remainingMovementDecimeters, 90);
    expect(before.revision, battle().revision);
  });

  test('Distance bounds and budget insufficiency block cleanly', () {
    final before = battle(remaining: 2);
    for (final feet in [0, -1, 101, 10]) {
      expect(() => climb(before, feet: feet), throwsFormatException);
    }
    expect(before.encounter!.remainingMovementDecimeters, 20);
  });

  test('A pending roll or pending opportunity prevents terrain movement', () {
    final pendingRoll = battle().copyWith(
      pendingRoll: const PendingRoll(
        id: 'pending',
        type: 'attack',
        modifier: 2,
        difficulty: 12,
      ),
    );
    expect(() => climb(pendingRoll), throwsFormatException);
  });
}
