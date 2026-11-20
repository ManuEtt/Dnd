import 'death_saving_throw_rules.dart';
import 'models.dart';

/// Exhaustive, read-only outcomes of the next ordinary death saving throw.
/// Reroll features and situational advantage are not assumed.
class SrdDeathSaveOutcomePreview {
  const SrdDeathSaveOutcomePreview({
    required this.successfulRolls,
    required this.failedRolls,
    required this.stabilizingRolls,
    required this.fatalRolls,
    required this.regainingHitPointsRolls,
  });

  final int successfulRolls;
  final int failedRolls;
  final int stabilizingRolls;
  final int fatalRolls;
  final int regainingHitPointsRolls;

  static const int totalRolls = 20;
  double get successProbability => successfulRolls / totalRolls;
  double get deathProbability => fatalRolls / totalRolls;
  double get stabilizationProbability => stabilizingRolls / totalRolls;
  double get revivalProbability => regainingHitPointsRolls / totalRolls;
}

/// Reuses the canonical death-save resolver for all twenty natural d20s,
/// including class bonuses, exhaustion, natural 1 and natural 20.
/// No roll is made, no resource spent and the hero is never modified.
class SrdDeathSaveOutcomeRules {
  const SrdDeathSaveOutcomeRules._();

  static SrdDeathSaveOutcomePreview preview(HeroCharacter hero) {
    var successes = 0;
    var failures = 0;
    var stabilized = 0;
    var fatal = 0;
    var regained = 0;

    for (var natural = 1; natural <= 20; natural++) {
      final result = DeathSavingThrowRules.resolve(
        hero: hero,
        natural: natural,
      );
      if (result.passed) {
        successes++;
      } else {
        failures++;
      }
      if (result.hero.conditions.contains('stabil') &&
          !hero.conditions.contains('stabil')) {
        stabilized++;
      }
      if (result.hero.isDead) fatal++;
      if (result.hero.hitPoints != null &&
          hero.hitPoints != null &&
          result.hero.hitPoints! > hero.hitPoints!) {
        regained++;
      }
    }

    return SrdDeathSaveOutcomePreview(
      successfulRolls: successes,
      failedRolls: failures,
      stabilizingRolls: stabilized,
      fatalRolls: fatal,
      regainingHitPointsRolls: regained,
    );
  }
}
