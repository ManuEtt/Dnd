import 'srd_concentration_damage_rules.dart';

/// Exact read-only d20 probability for one confirmed concentration save.
/// Natural 1 and 20 are not automatic failure/success for saving throws.
class SrdConcentrationSaveOdds {
  const SrdConcentrationSaveOdds({
    required this.difficultyClass,
    required this.modifier,
    required this.successfulOutcomes,
    required this.totalOutcomes,
  });

  final int difficultyClass;
  final int modifier;
  final int successfulOutcomes;
  final int totalOutcomes;

  int get failedOutcomes => totalOutcomes - successfulOutcomes;
  double get successProbability => successfulOutcomes / totalOutcomes;
  double get failureProbability => failedOutcomes / totalOutcomes;
}

/// This preview does not roll dice, change concentration, or infer the
/// outcome of any independently required saving throw.
class SrdConcentrationSaveOddsRules {
  const SrdConcentrationSaveOddsRules._();

  static SrdConcentrationSaveOdds preview({
    required int damageTaken,
    required bool damageConfirmed,
    required int constitutionSaveModifier,
    required bool modifiersConfirmed,
    required bool rollCircumstancesConfirmed,
    bool advantage = false,
    bool disadvantage = false,
  }) {
    if (!damageConfirmed ||
        !modifiersConfirmed ||
        !rollCircumstancesConfirmed ||
        constitutionSaveModifier < -60 ||
        constitutionSaveModifier > 60) {
      throw const FormatException(
        'Schaden, Rettungswurfmodifikator und Wurfumstände müssen bestätigt sein.',
      );
    }
    final dc = SrdConcentrationDamageRules.difficultyClass(damageTaken);
    var successes = 0;
    var total = 0;
    for (var first = 1; first <= 20; first++) {
      final secondCount = advantage || disadvantage ? 20 : 1;
      for (var second = 1; second <= secondCount; second++) {
        final natural = advantage && !disadvantage
            ? (first > second ? first : second)
            : disadvantage && !advantage
            ? (first < second ? first : second)
            : first;
        if (natural + constitutionSaveModifier >= dc) successes++;
        total++;
      }
    }
    return SrdConcentrationSaveOdds(
      difficultyClass: dc,
      modifier: constitutionSaveModifier,
      successfulOutcomes: successes,
      totalOutcomes: total,
    );
  }
}
