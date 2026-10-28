import 'class_resource_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'monk_perfect_focus.dart';
import 'rules_engine.dart';

/// SRD 5.2.1 Monk initiative features. The once-per-long-rest choice must be
/// confirmed by the player at the initiative roll, never inferred from text.
///
/// The caller decides whether to use Uncanny Metabolism before initiating the
/// encounter. No die is rolled, HP changed or once-per-rest use consumed if
/// the feature is not explicitly selected.
class MonkInitiativeFeatures {
  const MonkInitiativeFeatures._();

  static MonkInitiativeResult onInitiative(
    HeroCharacter hero, {
    bool useUncannyMetabolism = false,
    DiceEngine? dice,
  }) {
    if (!useUncannyMetabolism) {
      final perfectFocus = MonkPerfectFocus.onInitiative(hero);
      return MonkInitiativeResult(
        hero: perfectFocus.hero,
        focusRecovered: perfectFocus.recovered,
        hitPointsRecovered: 0,
        uncannyMetabolismUsed: false,
      );
    }

    final monkLevel = ClassResourceRules.level(hero, 'Mönch');
    if (monkLevel < 2) {
      throw StateError('Unheimlicher Stoffwechsel erfordert Mönchsstufe 2.');
    }
    if (hero.isDead ||
        hero.hitPoints == null ||
        hero.maxHitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.maxHitPoints! < hero.hitPoints!) {
      throw StateError(
        'Unheimlicher Stoffwechsel erfordert einen kampffähigen Helden.',
      );
    }
    if (ClassResourceRules.remaining(hero, 'uncannyMetabolism') == 0) {
      throw StateError(
        'Unheimlicher Stoffwechsel ist bis zur nächsten langen Rast verbraucht.',
      );
    }
    final remainingFocus = ClassResourceRules.remaining(hero, 'focusPoints');
    if (dice == null) {
      throw StateError('Für Unheimlichen Stoffwechsel fehlt der Würfeldienst.');
    }

    final dieSides = ClassResourceRules.martialArtsDie(monkLevel);
    final rolled = dice.roll('1d$dieSides').rolls.single;
    final spent = {...hero.spentClassResources, 'uncannyMetabolism': 1}
      ..remove('focusPoints');
    final restored = hero.copyWith(spentClassResources: spent);
    final healed = RulesEngine.heal(restored, monkLevel + rolled);
    return MonkInitiativeResult(
      hero: healed,
      focusRecovered: remainingFocus == monkLevel
          ? 0
          : monkLevel - remainingFocus,
      hitPointsRecovered: healed.hitPoints! - hero.hitPoints!,
      uncannyMetabolismUsed: true,
      martialArtsDieRoll: rolled,
    );
  }
}

class MonkInitiativeResult {
  const MonkInitiativeResult({
    required this.hero,
    required this.focusRecovered,
    required this.hitPointsRecovered,
    required this.uncannyMetabolismUsed,
    this.martialArtsDieRoll,
  });

  final HeroCharacter hero;
  final int focusRecovered;
  final int hitPointsRecovered;
  final bool uncannyMetabolismUsed;
  final int? martialArtsDieRoll;
}
