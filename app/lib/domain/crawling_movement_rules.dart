import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';

/// SRD 5.2.1 Rules Glossary: Crawling, Difficult Terrain.
/// One foot of crawling costs two feet of movement, three in difficult terrain.
class CrawlingMovementRules {
  const CrawlingMovementRules._();

  static int costDecimeters({
    required int distanceFeet,
    required bool difficultTerrain,
  }) {
    if (distanceFeet < 1 || distanceFeet > 100) {
      throw const FormatException('Kriechstrecke muss 1 bis 100 Fuß betragen.');
    }
    return distanceFeet * 3 * (difficultTerrain ? 3 : 2);
  }

  static Encounter spend(
    Encounter encounter,
    HeroCharacter hero, {
    required int distanceFeet,
    required bool difficultTerrain,
  }) {
    if (!hero.conditions.contains('liegend')) {
      throw const FormatException('Nur liegende Figuren können hier kriechen.');
    }
    if (!ConditionRules.canMove(hero) ||
        (CharacterRuleEngine.speedMeters(hero) ?? 0) <= 0) {
      throw const FormatException('Dein Zustand verhindert Bewegung.');
    }
    if (encounter.movementRemaining < 0 ||
        encounter.movementRemainderDecimeters < 0 ||
        encounter.movementRemainderDecimeters > 9) {
      throw const FormatException('Ungültiges Bewegungsbudget.');
    }
    final cost = costDecimeters(
      distanceFeet: distanceFeet,
      difficultTerrain: difficultTerrain,
    );
    final remaining = encounter.remainingMovementDecimeters;
    if (cost > remaining) {
      throw FormatException(
        'Kriechen kostet ${cost / 10} m Bewegung, '
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
