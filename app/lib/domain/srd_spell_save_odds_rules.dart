/// Exact read-only SRD 5.2.1 d20 saving throw probabilities.
///
/// Unlike attack rolls, natural 1 and 20 do not automatically fail or
/// succeed on ordinary saving throws. Confirm any special auto-failure
/// effects independently before using this preview.
class SrdSpellSaveOdds {
  const SrdSpellSaveOdds({
    required this.dc,
    required this.modifier,
    required this.successes,
    required this.outcomes,
  });

  final int dc;
  final int modifier;
  final int successes;
  final int outcomes;

  int get failures => outcomes - successes;
  double get successProbability => successes / outcomes;
  double get failureProbability => failures / outcomes;
}

class SrdSpellSaveOddsRules {
  const SrdSpellSaveOddsRules._();

  /// Enumerates all equally likely d20 outcomes without rolling dice.
  /// Advantage and disadvantage cancel when both apply.
  static SrdSpellSaveOdds preview({
    required int dc,
    required int confirmedTargetModifier,
    required bool saveCircumstancesConfirmed,
    bool advantage = false,
    bool disadvantage = false,
  }) {
    if (dc < 1 || dc > 50) {
      throw RangeError.range(dc, 1, 50, 'dc');
    }
    if (confirmedTargetModifier < -30 || confirmedTargetModifier > 30) {
      throw RangeError.range(
        confirmedTargetModifier, -30, 30, 'confirmedTargetModifier',
      );
    }
    if (!saveCircumstancesConfirmed) {
      throw const FormatException(
        'Rettungswurfbedingungen und automatische Fehlschläge '
        'müssen unabhängig bestätigt sein.',
      );
    }

    final twoDice = advantage != disadvantage;
    var successes = 0;
    for (var first = 1; first <= 20; first++) {
      for (var second = 1; second <= (twoDice ? 20 : 1); second++) {
        final natural = twoDice
            ? (advantage
                ? (first > second ? first : second)
                : (first < second ? first : second))
            : first;
        if (natural + confirmedTargetModifier >= dc) {
          successes++;
        }
      }
    }
    return SrdSpellSaveOdds(
      dc: dc,
      modifier: confirmedTargetModifier,
      successes: successes,
      outcomes: twoDice ? 400 : 20,
    );
  }
}
