import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';

/// Explicitly confirmed climb/swim movement, independent of narration.
///
/// SRD 5.2.1 Rules Glossary (Climbing, Swimming, Difficult Terrain):
/// without the corresponding speed: each foot costs 2 feet of movement
/// (3 in difficult terrain); with the corresponding speed: 1 foot
/// (2 in difficult terrain). The terrain and distance MUST come from a
/// confirmed rule action, never from a generated description.
///
/// One foot = 3 decimeters in the app's existing movement representation.
/// Does not assume a normal climb/swim speed for classes without Roving.
enum SrdTerrainMovement { climb, swim }

class SrdTerrainMovementRules {
  const SrdTerrainMovementRules._();

  static bool hasSpecialSpeed(HeroCharacter hero, SrdTerrainMovement kind) {
    final speed = switch (kind) {
      SrdTerrainMovement.climb => CharacterRuleEngine.rovingClimbSpeedMeters(
        hero,
      ),
      SrdTerrainMovement.swim => CharacterRuleEngine.rovingSwimSpeedMeters(
        hero,
      ),
    };
    return speed != null && speed > 0;
  }

  /// Strict input boundaries: 1-100 confirmed feet; the existing API takes
  /// exact integer feet to preserve decimeters, never rounded whole meters.
  static int costDecimeters(
    HeroCharacter hero, {
    required SrdTerrainMovement kind,
    required int distanceFeet,
    required bool difficultTerrain,
  }) {
    if (distanceFeet < 1 || distanceFeet > 100) {
      throw const FormatException(
        'Bestätigte Kletter-/Schwimmstrecke muss 1 bis 100 Fuß betragen.',
      );
    }
    final feetPerFoot =
        (hasSpecialSpeed(hero, kind) ? 1 : 2) + (difficultTerrain ? 1 : 0);
    return distanceFeet * 3 * feetPerFoot;
  }

  /// Recalculates only the current encounter movement budget and leaves the
  /// source hero, inventory, class resources and other encounter state intact.
  static Encounter spend(
    Encounter encounter,
    HeroCharacter hero, {
    required SrdTerrainMovement kind,
    required int distanceFeet,
    required bool difficultTerrain,
    required bool terrainConfirmed,
    bool additionalCheckRequired = false,
    bool additionalCheckPassedConfirmed = false,
  }) {
    if (!terrainConfirmed) {
      throw const FormatException(
        'Klettern/Schwimmen erfordert bestätigtes Gelände und Strecke.',
      );
    }
    if (additionalCheckRequired && !additionalCheckPassedConfirmed) {
      throw const FormatException(
        'Der geforderte Athletikwurf muss zuerst bestätigt sein.',
      );
    }
    if (hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.isDead ||
        !ConditionRules.canMove(hero) ||
        hero.conditions.contains('liegend') ||
        (CharacterRuleEngine.speedMeters(hero) ?? 0) <= 0) {
      throw const FormatException(
        'Dieser Charakter kann die bestätigte Strecke nicht zurücklegen.',
      );
    }
    if (encounter.movementRemaining < 0 ||
        encounter.movementRemainderDecimeters < 0 ||
        encounter.movementRemainderDecimeters > 9) {
      throw const FormatException('Ungültiges Bewegungsbudget.');
    }
    final cost = costDecimeters(
      hero,
      kind: kind,
      distanceFeet: distanceFeet,
      difficultTerrain: difficultTerrain,
    );
    final remaining = encounter.remainingMovementDecimeters;
    if (cost > remaining) {
      throw FormatException(
        'Klettern/Schwimmen kostet ${cost / 10} m Bewegung, '
        'verfügbar sind nur ${encounter.movementRemainingLabel}.',
      );
    }
    final after = remaining - cost;
    return encounter.copyWith(
      movementRemaining: after ~/ 10,
      movementRemainderDecimeters: after % 10,
    );
  }
}
