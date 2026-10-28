import 'condition_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';

/// SRD 5.2.1 (CC BY 4.0): Warlock 2 Magical Cunning, Warlock 20
/// Eldritch Master. This helper resolves an explicitly *completed* rite.
/// A one-minute ritual, interruptions and free-world elapsed time require a
/// separate confirmed clock; never infer completion from story narration.
///
/// https://www.dndbeyond.com/srd
class SrdWarlockMagicalCunningRules {
  const SrdWarlockMagicalCunningRules._();

  static const resourceKey = 'magicalCunning';

  static int maximumUses(HeroCharacter hero) =>
      SpellcastingRules.pactClassLevel(hero) >= 2 ? 1 : 0;

  /// Recovery cap is ceil(half maximum Pact Magic slots), except at Warlock
  /// class level 20 when Eldritch Master restores every expended Pact slot.
  static int maximumRecoveredSlots(HeroCharacter hero) {
    final level = SpellcastingRules.pactClassLevel(hero);
    if (level < 2) return 0;
    final pool = SpellcastingRules.pactSlotCount(hero);
    return level >= 20 ? pool : (pool + 1) ~/ 2;
  }

  /// Pure, immutable state transition after player-confirmed rite completion.
  /// Failed/invalid attempts never spend the once-per-Long-Rest use.
  static SrdWarlockMagicalCunningResult restoreAfterCompletedRite(
    HeroCharacter hero,
  ) {
    if (SpellcastingRules.pactClassLevel(hero) < 2) {
      throw StateError('Magische List erfordert Hexenmeister-Klassenstufe 2.');
    }
    if (hero.isDead ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.maxHitPoints == null ||
        hero.maxHitPoints! < hero.hitPoints! ||
        !ConditionRules.canTakeActions(hero)) {
      throw StateError('Der Charakter kann das Ritual nicht abschließen.');
    }
    final expended = hero.spentPactSlots;
    // SpellcastingRules is the source of truth for Pact Magic slots.
    SpellcastingRules.availablePactSlots(hero);
    final spentUse = hero.spentClassResources[resourceKey] ?? 0;
    if (spentUse < 0 || spentUse > maximumUses(hero)) {
      throw const FormatException('Ungültiger Verbrauch der Magischen List.');
    }
    if (spentUse != 0) {
      throw StateError('Magische List wurde seit der letzten langen Rast benutzt.');
    }
    if (expended == 0) {
      throw StateError('Es sind keine Paktmagieplätze verbraucht.');
    }
    final maximum = maximumRecoveredSlots(hero);
    final recovered = expended < maximum ? expended : maximum;
    final updated = hero.copyWith(
      spentPactSlots: expended - recovered,
      spentClassResources: {
        ...hero.spentClassResources,
        resourceKey: 1,
      },
    );
    return SrdWarlockMagicalCunningResult(
      hero: updated,
      recoveredSlots: recovered,
      spentPactSlotsBefore: expended,
      spentPactSlotsAfter: expended - recovered,
      usesRemaining: 0,
      eldritchMaster: SpellcastingRules.pactClassLevel(hero) >= 20,
    );
  }
}

class SrdWarlockMagicalCunningResult {
  const SrdWarlockMagicalCunningResult({
    required this.hero,
    required this.recoveredSlots,
    required this.spentPactSlotsBefore,
    required this.spentPactSlotsAfter,
    required this.usesRemaining,
    required this.eldritchMaster,
  });

  final HeroCharacter hero;
  final int recoveredSlots;
  final int spentPactSlotsBefore;
  final int spentPactSlotsAfter;
  final int usesRemaining;
  final bool eldritchMaster;
}
