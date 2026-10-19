import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';

/// SRD 5.2.1, Rules Glossary: Prone (Restricted Movement).
///
/// Speed in the existing hero model is measured in meters; 1 ft = 0.3 m
/// consistently with the app's 5 ft = 1.5 m conversion. Compute the
/// 2024 rule's *feet* first (round down half Speed) and retain the exact
/// tenth-of-a-meter remainder rather than charging a rounded whole meter.
class ProneMovementRules {
  const ProneMovementRules._();

  static int standingCostDecimeters(HeroCharacter hero) {
    if (!ConditionRules.canMove(hero)) {
      throw const FormatException(
        'Du kannst mit deinem aktuellen Zustand oder Tempo nicht aufstehen.',
      );
    }
    final speedMeters = CharacterRuleEngine.speedMeters(hero);
    if (speedMeters == null || speedMeters <= 0) {
      throw const FormatException(
        'Zum Aufstehen ist eine bestätigte positive Bewegungsrate erforderlich.',
      );
    }
    // 1 foot is 3 decimeters. SRD rounds the HALF SPEED down in feet.
    final speedFeet = (speedMeters * 10 / 3).round();
    if (speedFeet <= 0) {
      throw const FormatException(
        'Die bestätigte Bewegungsrate reicht nicht zum Aufstehen.',
      );
    }
    return (speedFeet ~/ 2) * 3;
  }

  static Encounter spendStandingMovement(
    Encounter encounter,
    HeroCharacter hero,
  ) {
    final cost = standingCostDecimeters(hero);
    if (encounter.movementRemainderDecimeters < 0 ||
        encounter.movementRemainderDecimeters > 9 ||
        encounter.movementRemaining < 0) {
      throw const FormatException('Ungültiger verbleibender Bewegungswert.');
    }
    final remaining = encounter.remainingMovementDecimeters;
    if (remaining < cost) {
      throw FormatException(
        'Aufstehen kostet ${formatDecimeters(cost)} Bewegung, '
        'verfügbar sind nur ${formatDecimeters(remaining)}.',
      );
    }
    final updated = remaining - cost;
    return encounter.copyWith(
      movementRemaining: updated ~/ 10,
      movementRemainderDecimeters: updated % 10,
    );
  }

  static String formatDecimeters(int decimeters) {
    final whole = decimeters ~/ 10;
    final fraction = decimeters % 10;
    return fraction == 0 ? '$whole m' : '$whole.$fraction m';
  }
}
