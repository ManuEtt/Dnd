import 'class_resource_rules.dart';
import 'condition_rules.dart';
import 'models.dart';

/// Read-only calculation for SRD 5.2.1 Monk level 4: Slow Fall.
///
/// A Monk can use a Reaction while falling to reduce damage from the fall
/// by five times their *Monk class level*. This helper never rolls fall
/// damage, changes hit points, or spends a Reaction by itself.
///
/// Source: https://www.dndbeyond.com/srd (CC BY 4.0).
class SrdMonkSlowFallResult {
  const SrdMonkSlowFallResult({
    required this.monkClassLevel,
    required this.confirmedFallDamage,
    required this.maximumReduction,
    required this.preventedDamage,
    required this.remainingDamage,
  });

  final int monkClassLevel;
  final int confirmedFallDamage;
  final int maximumReduction;
  final int preventedDamage;
  final int remainingDamage;
}

class SrdMonkSlowFallRules {
  const SrdMonkSlowFallRules._();

  /// null means the feature is not unlocked. This is intentionally distinct
  /// from 0 damage reduction. Multiclass uses Monk level, not hero.level.
  static int? maximumReduction(HeroCharacter hero) {
    final monkLevel = ClassResourceRules.level(hero, 'Mönch');
    return monkLevel >= 4 ? monkLevel * 5 : null;
  }

  /// Preview only: an authorized integration must revalidate the current
  /// encounter revision, spend the Reaction and commit HP/event atomically.
  ///
  /// Fall status, damage and player consent must be explicitly confirmed;
  /// generated narration cannot supply them. Outside combat, the caller
  /// must confirm reaction availability separately.
  static SrdMonkSlowFallResult previewConfirmedReaction(
    HeroCharacter hero, {
    required int? confirmedFallDamage,
    required bool fallConfirmed,
    required bool reactionAvailable,
    required bool reactionConfirmed,
    Encounter? encounter,
  }) {
    final reduction = maximumReduction(hero);
    if (reduction == null) {
      throw const FormatException(
        'Sanfter Fall erfordert mindestens Mönch-Klassenstufe 4.',
      );
    }
    if (!fallConfirmed ||
        !reactionAvailable ||
        !reactionConfirmed ||
        encounter?.reactionUsed == true ||
        hero.isDead ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        !ConditionRules.canTakeActions(hero)) {
      throw const FormatException(
        'Sturz, freie Reaktion und Entscheidung müssen bestätigt sein.',
      );
    }
    if (confirmedFallDamage == null ||
        confirmedFallDamage < 0 ||
        confirmedFallDamage > 1000000) {
      throw const FormatException(
        'Der bestätigte Sturzschaden muss vor der Reaktion feststehen.',
      );
    }
    final prevented = confirmedFallDamage < reduction
        ? confirmedFallDamage
        : reduction;
    return SrdMonkSlowFallResult(
      monkClassLevel: ClassResourceRules.level(hero, 'Mönch'),
      confirmedFallDamage: confirmedFallDamage,
      maximumReduction: reduction,
      preventedDamage: prevented,
      remainingDamage: confirmedFallDamage - prevented,
    );
  }
}
