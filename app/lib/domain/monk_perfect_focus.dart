import 'class_resource_rules.dart';
import 'models.dart';

/// SRD 5.2.1 Monk 15: when Initiative is rolled without using Uncanny
/// Metabolism, raise the Focus pool to four if it is currently below four.
/// The app does not yet implement Uncanny Metabolism; its optional use is
/// never inferred from story text. This function is applied once at encounter
/// creation, never at the start of each combat turn.
class MonkPerfectFocus {
  const MonkPerfectFocus._();

  static PerfectFocusResult onInitiative(HeroCharacter hero, {
    bool uncannyMetabolismUsed = false,
  }) {
    if (ClassResourceRules.level(hero, 'Mönch') < 15 ||
        uncannyMetabolismUsed) {
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
}

class PerfectFocusResult {
  const PerfectFocusResult({required this.hero, required this.recovered});
  final HeroCharacter hero;
  final int recovered;
}
