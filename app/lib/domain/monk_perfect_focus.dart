import 'class_resource_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 Monk 15: when Initiative is rolled without using Uncanny
/// Metabolism, raise the Focus pool to four if it is currently below four.
/// Uncanny Metabolism is a separate explicit choice handled by the initiative
/// integration; this helper never selects it from story text. Apply once at
/// encounter creation, never at the start of each combat turn.
/// Source: https://www.dndbeyond.com/srd (SRD 5.2.1 p. 52, CC BY 4.0).
class MonkPerfectFocus {
  const MonkPerfectFocus._();

  static PerfectFocusResult onInitiative(
    HeroCharacter hero, {
    bool uncannyMetabolismUsed = false,
  }) {
    if (uncannyMetabolismUsed ||
        !_hasConfirmedClassLevels(hero) ||
        ClassResourceRules.level(hero, 'Mönch') < 15) {
      return PerfectFocusResult(hero: hero, recovered: 0);
    }
    final maximum = ClassResourceRules.maximum(hero, 'focusPoints');
    final remaining = ClassResourceRules.remaining(hero, 'focusPoints');
    if (remaining >= 4) return PerfectFocusResult(hero: hero, recovered: 0);
    final newSpent = maximum - 4;
    final used = {...hero.spentClassResources};
    if (newSpent == 0) {
      used.remove('focusPoints');
    } else {
      used['focusPoints'] = newSpent;
    }
    return PerfectFocusResult(
      hero: hero.copyWith(spentClassResources: used),
      recovered: 4 - remaining,
    );
  }

  /// Contradictory legacy classes cannot grant automatic resources. Preserve
  /// the exact snapshot and the surrounding initiative; this helper does not
  /// validate or roll the combat that triggered it.
  static bool _hasConfirmedClassLevels(HeroCharacter hero) {
    final primary = findSrdClass(hero.className)?.name;
    final secondary = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    return primary != null &&
        hero.level >= 1 &&
        hero.level <= 20 &&
        hero.secondaryClassLevel >= 0 &&
        hero.secondaryClassLevel < hero.level &&
        (hero.hasSecondClass
            ? hero.secondaryClassLevel > 0 &&
                  secondary != null &&
                  secondary != primary
            : hero.secondaryClassLevel == 0);
  }
}

class PerfectFocusResult {
  const PerfectFocusResult({required this.hero, required this.recovered});
  final HeroCharacter hero;
  final int recovered;
}
