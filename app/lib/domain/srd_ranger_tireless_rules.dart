import 'models.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 Ranger 10, Tireless — Decrease Exhaustion (CC BY 4.0).
///
/// This handles only the passive exhaustion benefit of an already confirmed
/// Short Rest. The separate Magic action that grants temporary HP remains
/// outside this helper and must never be inferred from narrative text.
///
/// Source: https://www.dndbeyond.com/srd
class SrdRangerTirelessRules {
  const SrdRangerTirelessRules._();

  static int _rangerClassLevel(HeroCharacter hero) {
    final primary = findSrdClass(hero.className)?.name == 'Waldläufer'
        ? hero.primaryClassLevel
        : 0;
    final secondary =
        hero.hasSecondClass &&
            findSrdClass(hero.secondaryClassName)?.name == 'Waldläufer'
        ? hero.secondaryClassLevel
        : 0;
    return primary + secondary;
  }

  /// Eligibility is tied to class levels, never total multiclass levels.
  static bool canReduceExhaustion(HeroCharacter hero) =>
      !hero.isDead &&
      hero.hitPoints != null &&
      hero.hitPoints! > 0 &&
      hero.maxHitPoints != null &&
      hero.maxHitPoints! >= hero.hitPoints! &&
      _rangerClassLevel(hero) >= 10 &&
      hero.exhaustionLevel > 0;

  /// Pure state transition; cannot be called by an AI narrative decision.
  /// Exactly one exhaustion level is removed per completed Short Rest.
  static HeroCharacter afterShortRest(HeroCharacter hero) {
    if (!canReduceExhaustion(hero)) return hero;
    return hero.copyWith(exhaustionLevel: hero.exhaustionLevel - 1);
  }
}
