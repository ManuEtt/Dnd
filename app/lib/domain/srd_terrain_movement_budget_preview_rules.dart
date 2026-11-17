import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'srd_terrain_movement_rules.dart';

/// Read-only movement affordability for a confirmed climb or swim route.
/// All arithmetic uses decimeters to preserve the engine's exact foot cost.
class SrdTerrainMovementBudgetPreview {
  const SrdTerrainMovementBudgetPreview({
    required this.requiredDecimeters,
    required this.availableDecimeters,
    required this.remainingDecimeters,
    required this.affordable,
  });

  final int requiredDecimeters;
  final int availableDecimeters;
  final int remainingDecimeters;
  final bool affordable;
}

/// Checks terrain and movement evidence without spending movement.
/// A separate confirmed Athletics check, when required, must be resolved
/// before any movement transaction; this preview does not waive it.
class SrdTerrainMovementBudgetRules {
  const SrdTerrainMovementBudgetRules._();

  static SrdTerrainMovementBudgetPreview preview({
    required Encounter encounter,
    required HeroCharacter hero,
    required SrdTerrainMovement kind,
    required int distanceFeet,
    required bool difficultTerrain,
    required bool terrainConfirmed,
    bool additionalCheckRequired = false,
    bool additionalCheckPassedConfirmed = false,
  }) {
    if (!terrainConfirmed) {
      throw const FormatException(
        'Gelände und zurückzulegende Strecke müssen bestätigt sein.',
      );
    }
    if (additionalCheckRequired && !additionalCheckPassedConfirmed) {
      throw const FormatException(
        'Eine erforderliche Athletikprobe ist noch nicht bestätigt.',
      );
    }
    if (hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.isDead ||
        !ConditionRules.canMove(hero) ||
        hero.conditions.contains('liegend') ||
        (CharacterRuleEngine.speedMeters(hero) ?? 0) <= 0) {
      throw const FormatException(
        'Dieser Charakter kann die Strecke nicht zurücklegen.',
      );
    }
    if (encounter.movementRemaining < 0 ||
        encounter.movementRemainderDecimeters < 0 ||
        encounter.movementRemainderDecimeters > 9) {
      throw const FormatException('Ungültiges Bewegungsbudget.');
    }
    final cost = SrdTerrainMovementRules.costDecimeters(
      hero,
      kind: kind,
      distanceFeet: distanceFeet,
      difficultTerrain: difficultTerrain,
    );
    final available = encounter.remainingMovementDecimeters;
    return SrdTerrainMovementBudgetPreview(
      requiredDecimeters: cost,
      availableDecimeters: available,
      remainingDecimeters: available - cost,
      affordable: cost <= available,
    );
  }
}
