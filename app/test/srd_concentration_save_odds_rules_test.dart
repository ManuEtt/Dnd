import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_concentration_save_odds_rules.dart';

SrdConcentrationSaveOdds odds({
  int damage = 20,
  int modifier = 0,
  bool advantage = false,
  bool disadvantage = false,
  bool damageConfirmed = true,
  bool modifiersConfirmed = true,
  bool circumstancesConfirmed = true,
}) => SrdConcentrationSaveOddsRules.preview(
  damageTaken: damage,
  damageConfirmed: damageConfirmed,
  constitutionSaveModifier: modifier,
  modifiersConfirmed: modifiersConfirmed,
  rollCircumstancesConfirmed: circumstancesConfirmed,
  advantage: advantage,
  disadvantage: disadvantage,
);

void main() {
  test('ordinary DC 10 save succeeds on eleven natural outcomes', () {
    final result = odds();
    expect(result.difficultyClass, 10);
    expect(result.totalOutcomes, 20);
    expect(result.successfulOutcomes, 11);
    expect(result.failedOutcomes, 9);
    expect(result.successProbability, 0.55);
  });

  test('advantage and disadvantage enumerate all four hundred outcomes', () {
    final better = odds(advantage: true);
    final worse = odds(disadvantage: true);
    expect(better.totalOutcomes, 400);
    expect(better.successfulOutcomes, 319);
    expect(worse.successfulOutcomes, 121);
    expect(odds(advantage: true, disadvantage: true).successfulOutcomes, 220);
  });

  test('natural one and twenty do not automatically fail or succeed', () {
    expect(odds(modifier: 20).successfulOutcomes, 20);
    expect(odds(modifier: -20).successfulOutcomes, 0);
  });

  test('high damage uses capped concentration DC', () {
    final result = odds(damage: 100, modifier: 10);
    expect(result.difficultyClass, 30);
    expect(result.successfulOutcomes, 1);
  });

  test('unconfirmed or invalid facts are rejected', () {
    expect(() => odds(damageConfirmed: false), throwsFormatException);
    expect(() => odds(modifiersConfirmed: false), throwsFormatException);
    expect(() => odds(circumstancesConfirmed: false), throwsFormatException);
    expect(() => odds(damage: 0), throwsRangeError);
    expect(() => odds(modifier: 61), throwsFormatException);
  });
}
