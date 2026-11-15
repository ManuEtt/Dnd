import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_attack_odds_rules.dart';

SrdSpellAttackOdds odds({
  int modifier = 4,
  int ac = 15,
  CoverLevel cover = CoverLevel.none,
  bool opposite = true,
  bool advantage = false,
  bool disadvantage = false,
  bool confirmed = true,
}) => SrdSpellAttackOddsRules.preview(
  confirmedAttackModifier: modifier,
  confirmedTargetArmorClass: ac,
  targetCover: cover,
  coverCircumstancesConfirmed: confirmed,
  sourceOppositeCover: opposite,
  spellAndTargetAuthorizedConfirmed: confirmed,
  attackCircumstancesConfirmed: confirmed,
  advantage: advantage,
  disadvantage: disadvantage,
);

void main() {
  test('ordinary roll counts hits and natural twenty separately', () {
    final result = odds();
    expect(result.outcomes, 20);
    expect(result.hits, 10); // 11..20
    expect(result.criticalHits, 1);
    expect(result.hitProbability, 0.5);
    expect(result.criticalProbability, 0.05);
  });

  test('advantage and disadvantage count all 400 ordered pairs', () {
    final high = odds(advantage: true);
    final low = odds(disadvantage: true);
    expect(high.outcomes, 400);
    expect(high.hits, 300);
    expect(high.criticalHits, 39);
    expect(low.hits, 100);
    expect(low.criticalHits, 1);
    expect(odds(advantage: true, disadvantage: true).outcomes, 20);
  });

  test('natural 1 always misses and natural 20 always critically hits', () {
    expect(odds(modifier: 30, ac: 1).hits, 19);
    expect(odds(modifier: -30, ac: 100).hits, 1);
    expect(odds(modifier: -30, ac: 100).criticalHits, 1);
  });

  test('relative cover affects odds and total cover fails closed', () {
    expect(odds(cover: CoverLevel.half).effectiveArmorClass, 17);
    expect(odds(cover: CoverLevel.half).hits, 8);
    expect(odds(cover: CoverLevel.threeQuarters).hits, 5);
    expect(odds(cover: CoverLevel.half, opposite: false).hits, 10);
    expect(
      () => odds(cover: CoverLevel.total),
      throwsA(isA<FormatException>()),
    );
  });

  test('unconfirmed or invalid evidence is rejected', () {
    expect(() => odds(confirmed: false), throwsA(isA<FormatException>()));
    expect(() => odds(modifier: 31), throwsRangeError);
    expect(() => odds(ac: 0), throwsRangeError);
  });
}
