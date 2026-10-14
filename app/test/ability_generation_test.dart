import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

Map<String, int> scores(List<int> values) => {
  for (var index = 0; index < abilityNames.length; index++)
    abilityNames[index]: values[index],
};

AbilityAllocation standard({Map<String, int>? values}) => AbilityAllocation(
  method: AbilityGenerationMethod.standardArray,
  baseScores: values ?? scores([15, 14, 13, 12, 10, 8]),
);

AbilityAllocation pointBuy(List<int> values) => AbilityAllocation(
  method: AbilityGenerationMethod.pointBuy,
  baseScores: scores(values),
);

Iterable<List<int>> permutations(List<int> values) sync* {
  if (values.isEmpty) {
    yield [];
    return;
  }
  for (var index = 0; index < values.length; index++) {
    for (final rest in permutations([
      ...values.take(index),
      ...values.skip(index + 1),
    ])) {
      yield [values[index], ...rest];
    }
  }
}

void main() {
  group('Standard array', () {
    test('accepts all 720 assignments and returns exactly the six IDs', () {
      var count = 0;
      for (final values in permutations(AbilityAllocation.standardArray)) {
        final allocation = standard(values: scores(values));
        expect(allocation.isValid, isTrue);
        expect(allocation.compose().finalScores, scores(values));
        expect(allocation.compose().finalScores.keys, abilityNames);
        count++;
      }
      expect(count, 720);
    });

    test('rejects duplicate, missing or additional standard values', () {
      for (final values in [
        [15, 14, 13, 12, 10, 10],
        [15, 14, 13, 12, 10, 7],
        [16, 14, 13, 12, 10, 8],
      ]) {
        final allocation = standard(values: scores(values));
        expect(allocation.isValid, isFalse);
        expect(allocation.compose, throwsFormatException);
      }
    });

    test('rejects unknown IDs even with a valid numeric array', () {
      final values = scores([15, 14, 13, 12, 10, 8]);
      values['agility'] = values.remove('dexterity')!;
      final allocation = standard(values: values);
      expect(allocation.errors, isNotEmpty);
      expect(allocation.compose, throwsFormatException);
    });

    test('requires six IDs and rejects an extra ID', () {
      for (final values in [
        scores([15, 14, 13, 12, 10, 8])..remove('wisdom'),
        {
          ...scores([15, 14, 13, 12, 10, 8]),
          'luck': 8,
        },
        <String, int>{},
      ]) {
        final allocation = standard(values: values);
        expect(allocation.isValid, isFalse);
        expect(allocation.compose, throwsFormatException);
      }
    });

    test('does not present a point-buy budget for a standard array', () {
      final allocation = standard();
      expect(allocation.pointCost, isNull);
      expect(allocation.remainingPoints, isNull);
      expect(allocation.usesFullBudget, isFalse);
    });
  });

  group('Point buy', () {
    test('cost table matches every SRD value from 8 to 15', () {
      const costs = [0, 1, 2, 3, 4, 5, 7, 9];
      for (var value = 8; value <= 15; value++) {
        final allocation = pointBuy([value, 8, 8, 8, 8, 8]);
        expect(allocation.pointCost, costs[value - 8]);
        expect(allocation.remainingPoints, 27 - costs[value - 8]);
        expect(allocation.isValid, isTrue);
      }
    });

    test('accepts exactly 27 points and exposes full budget', () {
      final allocation = pointBuy([15, 15, 15, 8, 8, 8]);
      expect(allocation.pointCost, 27);
      expect(allocation.remainingPoints, 0);
      expect(allocation.usesFullBudget, isTrue);
      expect(allocation.compose().finalScores, allocation.baseScores);
    });

    test('unused points are allowed and remain visible', () {
      final minimum = pointBuy([8, 8, 8, 8, 8, 8]);
      expect(minimum.isValid, isTrue);
      expect(minimum.pointCost, 0);
      expect(minimum.remainingPoints, 27);
      expect(minimum.usesFullBudget, isFalse);
      final partial = pointBuy([14, 14, 14, 10, 8, 8]);
      expect(partial.isValid, isTrue);
      expect(partial.remainingPoints, 4);
      expect(partial.compose().finalScores['strength'], 14);
    });

    test('rejects 28 points and the maximum 54-point draft', () {
      for (final values in [
        [15, 15, 15, 9, 8, 8],
        [15, 15, 15, 15, 15, 15],
      ]) {
        final allocation = pointBuy(values);
        expect(allocation.pointCost, greaterThan(27));
        expect(allocation.remainingPoints, lessThan(0));
        expect(allocation.isValid, isFalse);
        expect(allocation.usesFullBudget, isFalse);
        expect(allocation.compose, throwsFormatException);
      }
    });

    test('rejects both boundaries and never prices an invalid score', () {
      for (final value in [-1, 0, 7, 16, 20, 30, 100]) {
        final allocation = pointBuy([value, 8, 8, 8, 8, 8]);
        expect(allocation.isValid, isFalse);
        expect(allocation.pointCost, isNull);
        expect(allocation.remainingPoints, isNull);
        expect(allocation.compose, throwsFormatException);
      }
    });

    test('rejects missing and unknown IDs without misleading totals', () {
      for (final values in [
        scores([8, 8, 8, 8, 8, 8])..remove('strength'),
        {
          ...scores([8, 8, 8, 8, 8, 8]),
          'luck': 8,
        },
        <String, int>{},
      ]) {
        final allocation = AbilityAllocation(
          method: AbilityGenerationMethod.pointBuy,
          baseScores: values,
        );
        expect(allocation.isValid, isFalse);
        expect(allocation.pointCost, isNull);
        expect(allocation.compose, throwsFormatException);
      }
    });
  });

  group('Background choices', () {
    test('the four SRD mappings and German names are exact', () {
      expect(SrdBackground.acolyte.label, 'Akolyth');
      expect(SrdBackground.acolyte.abilityKeys, [
        'intelligence',
        'wisdom',
        'charisma',
      ]);
      expect(SrdBackground.criminal.label, 'Krimineller');
      expect(SrdBackground.criminal.abilityKeys, [
        'dexterity',
        'constitution',
        'intelligence',
      ]);
      expect(SrdBackground.sage.label, 'Weiser');
      expect(SrdBackground.sage.abilityKeys, [
        'constitution',
        'intelligence',
        'wisdom',
      ]);
      expect(SrdBackground.soldier.label, 'Soldat');
      expect(SrdBackground.soldier.abilityKeys, [
        'strength',
        'dexterity',
        'constitution',
      ]);
    });

    test(
      'allows every ordered +2/+1 choice on distinct eligible abilities',
      () {
        for (final background in SrdBackground.values) {
          for (final plusTwo in background.abilityKeys) {
            for (final plusOne in background.abilityKeys) {
              if (plusTwo == plusOne) continue;
              final boost = BackgroundAbilityBoost(
                background: background,
                increases: {plusTwo: 2, plusOne: 1},
              );
              expect(boost.isValid, isTrue);
              final result = standard().compose(backgroundBoost: boost);
              expect(result.backgroundApplied, isTrue);
              expect(result.backgroundBoost, same(boost));
              for (final key in abilityNames) {
                expect(
                  result.finalScores[key],
                  result.baseScores[key]! + (boost.increases[key] ?? 0),
                );
              }
            }
          }
        }
      },
    );

    test('allows +1 on all three eligible abilities for every background', () {
      for (final background in SrdBackground.values) {
        final boost = BackgroundAbilityBoost(
          background: background,
          increases: {for (final key in background.abilityKeys) key: 1},
        );
        expect(boost.isValid, isTrue);
        final finalScores = boost.applyTo(scores([10, 10, 10, 10, 10, 10]));
        for (final key in abilityNames) {
          expect(
            finalScores[key],
            background.abilityKeys.contains(key) ? 11 : 10,
          );
        }
      }
    });

    test('rejects ineligible and unknown abilities', () {
      for (final increases in [
        {'strength': 2, 'wisdom': 1},
        {'luck': 2, 'wisdom': 1},
        {'strength': 1, 'wisdom': 1, 'charisma': 1},
      ]) {
        final boost = BackgroundAbilityBoost(
          background: SrdBackground.acolyte,
          increases: increases,
        );
        expect(boost.isValid, isFalse);
        expect(
          () => standard().compose(backgroundBoost: boost),
          throwsFormatException,
        );
      }
    });

    test('rejects single +3, incorrect totals, negatives and zero entries', () {
      for (final increases in [
        <String, int>{},
        {'intelligence': 3},
        {'intelligence': 2},
        {'intelligence': 2, 'wisdom': 2},
        {'intelligence': 1, 'wisdom': 1},
        {'intelligence': 2, 'wisdom': 1, 'charisma': 0},
        {'intelligence': 3, 'wisdom': -1, 'charisma': 1},
      ]) {
        final boost = BackgroundAbilityBoost(
          background: SrdBackground.acolyte,
          increases: increases,
        );
        expect(boost.errors, isNotEmpty);
        expect(
          () => boost.applyTo(scores([10, 10, 10, 10, 10, 10])),
          throwsFormatException,
        );
      }
    });

    test('allows exactly 20 but rejects 21 and never silently caps', () {
      final boost = BackgroundAbilityBoost(
        background: SrdBackground.soldier,
        increases: {'strength': 2, 'dexterity': 1},
      );
      expect(boost.applyTo(scores([18, 19, 10, 10, 10, 10])), {
        ...scores([20, 20, 10, 10, 10, 10]),
      });
      expect(
        () => boost.applyTo(scores([19, 19, 10, 10, 10, 10])),
        throwsFormatException,
      );
      expect(
        () => boost.applyTo(scores([18, 20, 10, 10, 10, 10])),
        throwsFormatException,
      );
    });

    test('rejects missing, unknown or out-of-range composition inputs', () {
      final boost = BackgroundAbilityBoost(
        background: SrdBackground.soldier,
        increases: {'strength': 2, 'dexterity': 1},
      );
      for (final values in [
        scores([10, 10, 10, 10, 10, 10])..remove('wisdom'),
        {
          ...scores([10, 10, 10, 10, 10, 10]),
          'luck': 10,
        },
        scores([0, 10, 10, 10, 10, 10]),
        scores([10, 10, 10, 21, 10, 10]),
      ]) {
        expect(() => boost.applyTo(values), throwsFormatException);
      }
    });
  });

  group('Separation and immutability', () {
    test('no background is an explicitly marked base-only preview', () {
      final allocation = standard();
      final result = allocation.compose();
      expect(result.backgroundApplied, isFalse);
      expect(result.backgroundBoost, isNull);
      expect(result.finalScores, allocation.baseScores);
    });

    test('recomposition never adds a background increase twice', () {
      final allocation = standard();
      final boost = BackgroundAbilityBoost(
        background: SrdBackground.soldier,
        increases: {'strength': 2, 'dexterity': 1},
      );
      final first = allocation.compose(backgroundBoost: boost);
      final second = allocation.compose(backgroundBoost: boost);
      expect(first.finalScores['strength'], 17);
      expect(second.finalScores, first.finalScores);
      expect(allocation.baseScores['strength'], 15);
      expect(first.baseScores['strength'], 15);
    });

    test('final scores produce modifiers using the existing rules engine', () {
      final allocation = standard();
      final boost = BackgroundAbilityBoost(
        background: SrdBackground.soldier,
        increases: {'strength': 2, 'dexterity': 1},
      );
      final result = allocation.compose(backgroundBoost: boost);
      final hero = HeroCharacter(
        id: 'test',
        name: 'Liora',
        abilities: result.finalScores,
        background: boost.background.label,
        weaponAbility: 'strength',
        weaponProficient: true,
      );
      expect(RulesEngine.abilityModifier(hero.abilities['strength']!), 3);
      expect(RulesEngine.attackBonus(hero), 5);
      expect(RulesEngine.initiativeBonus(hero), 2);
      expect(hero.isComplete, isFalse);
      expect(hero.hitPoints, isNull);
      expect(hero.features, isEmpty);
      expect(hero.inventory, isEmpty);
    });

    test('does not restrict established general 1-to-30 character values', () {
      expect(RulesEngine.abilityModifier(1), -5);
      expect(RulesEngine.abilityModifier(30), 10);
      final hero = HeroCharacter(
        id: 'existing',
        name: 'Bestehender Held',
        abilities: scores([30, 20, 18, 12, 10, 1]),
      );
      expect(hero.abilities['strength'], 30);
    });

    test('freezes inputs, constants, validation lists and final scores', () {
      final input = scores([15, 14, 13, 12, 10, 8]);
      final allocation = standard(values: input);
      input['strength'] = 30;
      final increases = {'strength': 2, 'dexterity': 1};
      final boost = BackgroundAbilityBoost(
        background: SrdBackground.soldier,
        increases: increases,
      );
      increases['strength'] = 3;
      final result = allocation.compose(backgroundBoost: boost);
      expect(result.finalScores['strength'], 17);
      expect(
        () => allocation.baseScores['strength'] = 20,
        throwsUnsupportedError,
      );
      expect(() => boost.increases['strength'] = 3, throwsUnsupportedError);
      expect(() => result.finalScores['strength'] = 20, throwsUnsupportedError);
      expect(() => result.baseScores['strength'] = 20, throwsUnsupportedError);
      expect(() => allocation.errors.add('changed'), throwsUnsupportedError);
      expect(() => boost.errors.add('changed'), throwsUnsupportedError);
      expect(
        () => AbilityAllocation.standardArray.add(20),
        throwsUnsupportedError,
      );
      expect(
        () => AbilityAllocation.pointCosts[15] = 0,
        throwsUnsupportedError,
      );
      expect(
        () => SrdBackground.soldier.abilityKeys.add('luck'),
        throwsUnsupportedError,
      );
    });

    test('withScore returns an independent draft and rejects unknown IDs', () {
      final before = pointBuy([8, 8, 8, 8, 8, 8]);
      final after = before.withScore('dexterity', 15);
      expect(before.baseScores['dexterity'], 8);
      expect(after.baseScores['dexterity'], 15);
      expect(after.pointCost, 9);
      expect(() => before.withScore('luck', 15), throwsArgumentError);
      final invalid = before.withScore('dexterity', 16);
      expect(invalid.isValid, isFalse);
      expect(before.isValid, isTrue);
    });
  });
}
