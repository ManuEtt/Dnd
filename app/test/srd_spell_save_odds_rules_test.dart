import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_save_odds_rules.dart';

SrdSpellSaveOdds odds({
  int dc = 15,
  int modifier = 4,
  bool advantage = false,
  bool disadvantage = false,
  bool confirmed = true,
}) => SrdSpellSaveOddsRules.preview(
  dc: dc,
  confirmedTargetModifier: modifier,
  saveCircumstancesConfirmed: confirmed,
  advantage: advantage,
  disadvantage: disadvantage,
);

void main() {
  test('ordinary saving throw succeeds on 11 through 20', () {
    final result = odds();
    expect(result.outcomes, 20);
    expect(result.successes, 10);
    expect(result.failures, 10);
    expect(result.successProbability, 0.5);
  });

  test('advantage and disadvantage enumerate all ordered pairs', () {
    final high = odds(advantage: true);
    final low = odds(disadvantage: true);
    expect(high.outcomes, 400);
    expect(high.successes, 300);
    expect(low.successes, 100);
    expect(
      odds(advantage: true, disadvantage: true).successes,
      10,
    );
    expect(
      odds(advantage: true, disadvantage: true).outcomes,
      20,
    );
  });

  test('natural 1 may succeed and natural 20 may fail', () {
    expect(odds(dc: 1, modifier: 30).successes, 20);
    expect(odds(dc: 50, modifier: -30).successes, 0);
    expect(odds(dc: 21, modifier: 0).successes, 0);
  });

  test('boundaries and unconfirmed conditions fail closed', () {
    expect(() => odds(dc: 0), throwsRangeError);
    expect(() => odds(dc: 51), throwsRangeError);
    expect(() => odds(modifier: -31), throwsRangeError);
    expect(() => odds(modifier: 31), throwsRangeError);
    expect(() => odds(confirmed: false), throwsA(isA<FormatException>()));
  });
}
