import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Map<String, int> assign(List<int> values) => {
  for (var i = 0; i < abilityNames.length; i++) abilityNames[i]: values[i],
};

void main() {
  test('4W6: exactly 24 dice, six immutable rolls, lowest discarded', () {
    const dice = [
      6, 6, 6, 1, 5, 5, 5, 1, 4, 4, 4, 1,
      3, 3, 3, 1, 2, 2, 2, 1, 1, 1, 1, 1,
    ];
    var calls = 0;
    final rolled = AbilityRollSet.generate(rollD6: () => dice[calls++]);
    expect(calls, 24);
    expect(rolled.scores, [18, 15, 12, 9, 6, 3]);
    expect(rolled.rolls.first.dice, [6, 6, 6, 1]);
    expect(() => rolled.scores[0] = 3, throwsUnsupportedError);
    expect(() => rolled.rolls.first.dice[0] = 1, throwsUnsupportedError);
    expect(() => rolled.rolls.clear(), throwsUnsupportedError);
  });

  test('rolled values may be assigned in any order, never substituted', () {
    final rolled = AbilityRollSet.generate(rollD6: () => 3);
    final valid = AbilityAllocation(
      method: AbilityGenerationMethod.randomRoll,
      baseScores: assign([9, 9, 9, 9, 9, 9]),
      rollSet: rolled,
    );
    expect(valid.isValid, isTrue);
    expect(valid.compose().finalScores, valid.baseScores);
    expect(valid.pointCost, isNull);
    expect(valid.withScore('wisdom', 12).isValid, isFalse);
    expect(valid.withScore('wisdom', 12).compose, throwsFormatException);
    expect(
      AbilityAllocation(
        method: AbilityGenerationMethod.randomRoll,
        baseScores: assign([9, 9, 9, 9, 9, 9]),
      ).isValid,
      isFalse,
    );
  });

  test('duplicate rolled results retain exact multiplicity', () {
    var calls = 0;
    final rolled = AbilityRollSet.generate(rollD6: () {
      final value = calls < 12 ? 6 : 1;
      calls++;
      return value;
    });
    expect(rolled.scores, [18, 18, 18, 3, 3, 3]);
    final wrong = AbilityAllocation(
      method: AbilityGenerationMethod.randomRoll,
      baseScores: assign([18, 18, 18, 18, 3, 3]),
      rollSet: rolled,
    );
    expect(wrong.isValid, isFalse);
    expect(wrong.compose, throwsFormatException);
  });

  test('invalid dice are rejected rather than normalized', () {
    for (final invalid in [0, -1, 7, 20]) {
      expect(
        () => AbilityRollSet.generate(rollD6: () => invalid),
        throwsFormatException,
      );
    }
  });

  test('background increases compose once from immutable rolled bases', () {
    final rolled = AbilityRollSet.generate(rollD6: () => 4);
    final allocation = AbilityAllocation(
      method: AbilityGenerationMethod.randomRoll,
      baseScores: assign([12, 12, 12, 12, 12, 12]),
      rollSet: rolled,
    );
    final boost = BackgroundAbilityBoost(
      background: SrdBackground.soldier,
      increases: {'strength': 2, 'dexterity': 1},
    );
    final first = allocation.compose(backgroundBoost: boost);
    final second = allocation.compose(backgroundBoost: boost);
    expect(first.baseScores['strength'], 12);
    expect(first.finalScores['strength'], 14);
    expect(second.finalScores['strength'], 14);
  });
}
