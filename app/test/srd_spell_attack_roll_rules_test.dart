import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_attack_roll_rules.dart';

class _SequenceRandom implements Random {
  _SequenceRandom(this.values);

  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) {
    final value = values[calls++];
    if (value < 0 || value >= max) throw RangeError.value(value);
    return value;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

SrdSpellAttackRollResolution _attack({
  DiceEngine? dice,
  int attackModifier = 4,
  int armorClass = 15,
  CoverLevel cover = CoverLevel.none,
  bool coverOpposite = true,
  bool coverConfirmed = true,
  bool eligibility = true,
  bool circumstances = true,
  bool advantage = false,
  bool disadvantage = false,
  int? natural,
}) => SrdSpellAttackRollRules.resolve(
  dice: dice ?? DiceEngine(random: _SequenceRandom([9, 14])),
  confirmedAttackModifier: attackModifier,
  confirmedTargetArmorClass: armorClass,
  targetCover: cover,
  coverCircumstancesConfirmed: coverConfirmed,
  sourceOppositeCover: coverOpposite,
  spellAndTargetAuthorizedConfirmed: eligibility,
  attackCircumstancesConfirmed: circumstances,
  advantage: advantage,
  disadvantage: disadvantage,
  confirmedNaturalRoll: natural,
);

void main() {
  group('SRD 5.2.1 – bestätigter Zauberangriff', () {
    test('base AC boundary, natural result and modifier are kept separate', () {
      final hit = _attack(natural: 11);
      expect(hit.roll.natural, 11);
      expect(hit.roll.total, 15);
      expect(hit.roll.modifier, 4);
      expect(hit.roll.rolls, [11]);
      expect(hit.effectiveArmorClass, 15);
      expect(hit.hit, isTrue);
      expect(hit.critical, isFalse);

      final miss = _attack(natural: 10);
      expect(miss.roll.total, 14);
      expect(miss.hit, isFalse);
      expect(miss.critical, isFalse);
    });

    test('natural 1 always misses even with very large attack bonus', () {
      final result = _attack(natural: 1, attackModifier: 30, armorClass: 1);
      expect(result.roll.total, 31);
      expect(result.hit, isFalse);
      expect(result.critical, isFalse);
    });

    test('natural 20 always hits and crits regardless of target AC', () {
      final result = _attack(natural: 20, attackModifier: -30, armorClass: 100);
      expect(result.roll.total, -10);
      expect(result.hit, isTrue);
      expect(result.critical, isTrue);
    });

    test('half and three-quarter cover change AC only when applicable', () {
      final half = _attack(natural: 12, armorClass: 15, cover: CoverLevel.half);
      expect(half.effectiveArmorClass, 17);
      expect(half.hit, isFalse);
      expect(half.appliedCover, CoverLevel.half);

      final threeQuarters = _attack(
        natural: 16,
        armorClass: 15,
        cover: CoverLevel.threeQuarters,
      );
      expect(threeQuarters.effectiveArmorClass, 20);
      expect(threeQuarters.hit, isTrue);

      final notOpposite = _attack(
        natural: 11,
        armorClass: 15,
        cover: CoverLevel.threeQuarters,
        coverOpposite: false,
      );
      expect(notOpposite.effectiveArmorClass, 15);
      expect(notOpposite.appliedCover, CoverLevel.none);
      expect(notOpposite.hit, isTrue);
    });

    test('full cover stops even natural 20 before dice consumption', () {
      final rng = _SequenceRandom([19]);
      expect(
        () => _attack(
          dice: DiceEngine(random: rng),
          armorClass: 15,
          cover: CoverLevel.total,
        ),
        throwsFormatException,
      );
      expect(rng.calls, 0);

      final notOpposite = _attack(
        natural: 20,
        cover: CoverLevel.total,
        coverOpposite: false,
      );
      expect(notOpposite.hit, isTrue);
      expect(notOpposite.appliedCover, CoverLevel.none);
    });

    test('advantage selects high die, disadvantage selects low die', () {
      final advantage = _attack(
        dice: DiceEngine(random: _SequenceRandom([2, 18])),
        advantage: true,
      );
      expect(advantage.roll.rolls, [3, 19]);
      expect(advantage.roll.natural, 19);
      expect(advantage.roll.total, 23);
      expect(advantage.hit, isTrue);

      final disadvantage = _attack(
        dice: DiceEngine(random: _SequenceRandom([2, 18])),
        disadvantage: true,
      );
      expect(disadvantage.roll.rolls, [3, 19]);
      expect(disadvantage.roll.natural, 3);
      expect(disadvantage.roll.total, 7);
      expect(disadvantage.hit, isFalse);
    });

    test('advantage and disadvantage cancel with exactly one d20', () {
      final rng = _SequenceRandom([9]);
      final result = _attack(
        dice: DiceEngine(random: rng),
        advantage: true,
        disadvantage: true,
      );
      expect(result.roll.rolls, [10]);
      expect(result.roll.total, 14);
      expect(result.hit, isFalse);
      expect(rng.calls, 1);
    });

    test('manual single d20 cannot masquerade as advantage roll', () {
      for (final flags in [(true, false), (false, true), (true, true)]) {
        expect(
          () =>
              _attack(natural: 20, advantage: flags.$1, disadvantage: flags.$2),
          throwsFormatException,
        );
      }
    });

    test('unconfirmed target, modifiers or relative cover fail closed', () {
      final rng = _SequenceRandom([19]);
      final dice = DiceEngine(random: rng);
      for (final args in [
        (false, true, true),
        (true, false, true),
        (true, true, false),
      ]) {
        expect(
          () => _attack(
            dice: dice,
            eligibility: args.$1,
            circumstances: args.$2,
            coverConfirmed: args.$3,
          ),
          throwsFormatException,
        );
      }
      expect(rng.calls, 0);
    });

    test('invalid attack modifier, AC and natural dice cannot roll', () {
      final rng = _SequenceRandom([19]);
      final dice = DiceEngine(random: rng);
      for (final value in [-31, 31]) {
        expect(
          () => _attack(dice: dice, attackModifier: value),
          throwsRangeError,
        );
      }
      for (final value in [0, 101]) {
        expect(() => _attack(dice: dice, armorClass: value), throwsRangeError);
      }
      for (final value in [0, 21]) {
        expect(() => _attack(dice: dice, natural: value), throwsRangeError);
      }
      expect(rng.calls, 0);
    });
  });
}
