import 'cover_rules.dart';

/// Exact, read-only d20 outcome counts for a separately authorized spell
/// attack. This never rolls dice, reserves an action or resolves damage.
class SrdSpellAttackOdds {
  const SrdSpellAttackOdds({
    required this.effectiveArmorClass,
    required this.appliedCover,
    required this.hits,
    required this.criticalHits,
    required this.outcomes,
  });

  final int effectiveArmorClass;
  final CoverLevel appliedCover;
  final int hits;
  final int criticalHits;
  final int outcomes;

  double get hitProbability => hits / outcomes;
  double get criticalProbability => criticalHits / outcomes;
  double get missProbability => (outcomes - hits) / outcomes;
}

/// SRD 5.2.1: natural 1 misses, natural 20 hits critically, and
/// advantage/disadvantage selects the higher/lower of two d20s.
/// The preview requires independently confirmed attack circumstances.
class SrdSpellAttackOddsRules {
  const SrdSpellAttackOddsRules._();

  static SrdSpellAttackOdds preview({
    required int confirmedAttackModifier,
    required int confirmedTargetArmorClass,
    required CoverLevel targetCover,
    required bool coverCircumstancesConfirmed,
    required bool sourceOppositeCover,
    required bool spellAndTargetAuthorizedConfirmed,
    required bool attackCircumstancesConfirmed,
    bool advantage = false,
    bool disadvantage = false,
  }) {
    if (!coverCircumstancesConfirmed ||
        !spellAndTargetAuthorizedConfirmed ||
        !attackCircumstancesConfirmed) {
      throw const FormatException(
        'Zauber, Ziel, Angriff und Deckung müssen bestätigt sein.',
      );
    }
    if (confirmedAttackModifier < -30 || confirmedAttackModifier > 30) {
      throw RangeError.range(
        confirmedAttackModifier, -30, 30, 'confirmedAttackModifier',
      );
    }
    if (confirmedTargetArmorClass < 1 || confirmedTargetArmorClass > 100) {
      throw RangeError.range(
        confirmedTargetArmorClass, 1, 100, 'confirmedTargetArmorClass',
      );
    }
    final appliedCover = sourceOppositeCover ? targetCover : CoverLevel.none;
    final ac = CoverRules.armorClass(confirmedTargetArmorClass, appliedCover);
    final twoDice = advantage != disadvantage;
    var hits = 0;
    var criticalHits = 0;
    for (var first = 1; first <= 20; first++) {
      for (var second = 1; second <= (twoDice ? 20 : 1); second++) {
        final natural = twoDice
            ? (advantage
                ? (first > second ? first : second)
                : (first < second ? first : second))
            : first;
        final critical = natural == 20;
        final hit = natural != 1 &&
            (critical || natural + confirmedAttackModifier >= ac);
        if (hit) hits++;
        if (critical) criticalHits++;
      }
    }
    return SrdSpellAttackOdds(
      effectiveArmorClass: ac,
      appliedCover: appliedCover,
      hits: hits,
      criticalHits: criticalHits,
      outcomes: twoDice ? 400 : 20,
    );
  }
}
