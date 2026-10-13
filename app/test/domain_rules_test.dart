import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

class SequenceRandom implements Random {
  SequenceRandom(this.values);
  final List<int> values;
  int position = 0;

  @override
  int nextInt(int max) {
    if (position >= values.length) throw StateError('Random exhausted');
    final value = values[position++];
    if (value < 0 || value >= max) throw RangeError.range(value, 0, max - 1);
    return value;
  }

  @override
  bool nextBool() => throw UnsupportedError('Only nextInt is used');

  @override
  double nextDouble() => throw UnsupportedError('Only nextInt is used');
}

HeroCharacter hero({
  int hp = 12,
  int maxHp = 12,
  int successes = 0,
  int failures = 0,
  List<String> conditions = const [],
}) => HeroCharacter.fromJson({
  'schemaVersion': 1,
  'id': 'hero-test',
  'name': 'Liora',
  'species': 'Mensch',
  'className': 'Waldläufer',
  'level': 1,
  'abilities': {
    'strength': 10,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 14,
    'charisma': 8,
  },
  'hitPoints': hp,
  'maxHitPoints': maxHp,
  'armorClass': 14,
  'speed': 9,
  'weaponAbility': 'dexterity',
  'weaponDamage': '1d6',
  'weaponProficient': true,
  'conditions': conditions,
  'deathSuccesses': successes,
  'deathFailures': failures,
});

void main() {
  group('DiceEngine', () {
    test('supports every advertised die and includes maximum faces', () {
      for (final sides in DiceEngine.supportedSides) {
        final engine = DiceEngine(random: SequenceRandom([sides - 1]));
        final result = engine.roll('1W$sides');
        expect(result.rolls, [sides]);
        expect(result.total, sides);
        expect(result.natural, sides == 20 ? 20 : null);
      }
    });

    test('sums dice with positive and negative modifiers', () {
      final engine = DiceEngine(random: SequenceRandom([0, 5, 3]));
      expect(engine.roll('2d6 + 3').total, 10);
      final result = engine.roll('1d8-2');
      expect(result.total, 2);
      expect(result.modifier, -2);
      expect(result.expression, '1d8-2');
    });

    test('rejects invalid, oversized and unsupported expressions', () {
      final engine = DiceEngine(random: SequenceRandom([]));
      for (final expression in [
        '',
        'd20',
        '0d20',
        '101d6',
        '1d3',
        '1d20+1001',
        '1d20-1001',
        '1d20+2+3',
        '1d20 hello',
        '1d20/2',
        '1d20\n1d20',
        '99999999999999999999999999999999999999999999999999999d20',
      ]) {
        expect(
          () => engine.roll(expression),
          throwsA(anyOf(isA<FormatException>(), isA<RangeError>())),
          reason: expression,
        );
      }
    });

    test('manual natural applies the modifier exactly once', () {
      final result = DiceEngine(
        random: SequenceRandom([]),
      ).check(modifier: 5, natural: 16);
      expect(result.natural, 16);
      expect(result.total, 21);
      expect(result.modifier, 5);
    });

    test('manual total never adds a bonus or infers a natural die', () {
      final result = DiceEngine(
        random: SequenceRandom([]),
      ).check(modifier: 7, total: 19);
      expect(result.total, 19);
      expect(result.natural, isNull);
      expect(result.modifier, 0);
      expect(result.rolls, isEmpty);
    });

    test('rejects ambiguous manual input and out-of-range natural dice', () {
      final engine = DiceEngine(random: SequenceRandom([]));
      expect(
        () => engine.check(modifier: 2, natural: 12, total: 14),
        throwsArgumentError,
      );
      expect(() => engine.check(modifier: 0, natural: 0), throwsRangeError);
      expect(() => engine.check(modifier: 0, natural: 21), throwsRangeError);
      expect(() => engine.check(modifier: 1001), throwsRangeError);
    });

    test('advantage uses the higher die and disadvantage the lower', () {
      final engine = DiceEngine(random: SequenceRandom([1, 18, 16, 2]));
      final advantage = engine.check(modifier: 3, advantage: true);
      expect(advantage.rolls, [2, 19]);
      expect(advantage.natural, 19);
      expect(advantage.total, 22);
      final disadvantage = engine.check(modifier: 3, disadvantage: true);
      expect(disadvantage.natural, 3);
      expect(disadvantage.total, 6);
    });

    test('advantage and disadvantage cancel into one die', () {
      final random = SequenceRandom([9]);
      final result = DiceEngine(
        random: random,
      ).check(modifier: 2, advantage: true, disadvantage: true);
      expect(result.rolls, [10]);
      expect(random.position, 1);
    });
  });

  group('Character calculations', () {
    test('attribute modifiers round negative halves down', () {
      expect(RulesEngine.abilityModifier(1), -5);
      expect(RulesEngine.abilityModifier(9), -1);
      expect(RulesEngine.abilityModifier(10), 0);
      expect(RulesEngine.abilityModifier(16), 3);
      expect(RulesEngine.abilityModifier(30), 10);
      expect(() => RulesEngine.abilityModifier(0), throwsRangeError);
    });

    test('proficiency grows at the correct levels', () {
      expect(
        [1, 4, 5, 8, 9, 12, 13, 16, 17, 20].map(RulesEngine.proficiencyBonus),
        [2, 2, 3, 3, 4, 4, 5, 5, 6, 6],
      );
      expect(() => RulesEngine.proficiencyBonus(0), throwsRangeError);
      expect(() => RulesEngine.proficiencyBonus(21), throwsRangeError);
    });

    test('attack and initiative use confirmed attributes', () {
      expect(RulesEngine.attackBonus(hero()), 5);
      expect(RulesEngine.initiativeBonus(hero()), 3);
      expect(
        RulesEngine.attackBonus(hero().copyWith(weaponProficient: false)),
        3,
      );
    });

    test(
      'missing attributes block calculation instead of inventing values',
      () {
        final incomplete = hero().copyWith(abilities: {'dexterity': null});
        expect(() => RulesEngine.attackBonus(incomplete), throwsStateError);
        expect(() => RulesEngine.initiativeBonus(incomplete), throwsStateError);
      },
    );
  });

  group('Attacks', () {
    final dice = DiceEngine(random: SequenceRandom([]));

    test('natural 1 misses even with a high modifier', () {
      final outcome = RulesEngine.attack(
        roll: dice.check(modifier: 30, natural: 1),
        armorClass: 10,
      );
      expect(outcome.hit, isFalse);
      expect(outcome.critical, isFalse);
    });

    test('natural 20 hits and crits regardless of armor', () {
      final outcome = RulesEngine.attack(
        roll: dice.check(modifier: -5, natural: 20),
        armorClass: 30,
      );
      expect(outcome.hit, isTrue);
      expect(outcome.critical, isTrue);
    });

    test('a total of twenty is not a confirmed critical', () {
      final outcome = RulesEngine.attack(
        roll: dice.check(modifier: 5, total: 20),
        armorClass: 20,
      );
      expect(outcome.hit, isTrue);
      expect(outcome.critical, isFalse);
      expect(
        RulesEngine.attack(
          roll: dice.check(modifier: 5, total: 19),
          armorClass: 20,
        ).hit,
        isFalse,
      );
    });
  });

  group('Damage and healing', () {
    test(
      'weapon damage adds the ability once and only doubles dice on crits',
      () {
        final dice = DiceEngine(random: SequenceRandom([2, 4]));
        final base = dice.roll('1d6+2');
        final extra = dice.roll('1d6+2');
        expect(RulesEngine.weaponDamage(hero(), baseRoll: base), 8);
        expect(
          RulesEngine.weaponDamage(
            hero(),
            baseRoll: base,
            criticalExtra: extra,
          ),
          13,
        );
      },
    );

    test('negative weapon totals cannot heal a target', () {
      final base = DiceEngine(random: SequenceRandom([0])).roll('1d6-10');
      expect(RulesEngine.weaponDamage(hero(), baseRoll: base), 0);
    });

    test('remaining enemy HP is clamped and validates negative input', () {
      expect(RulesEngine.remainingHitPoints(hitPoints: 5, damage: 3), 2);
      expect(RulesEngine.remainingHitPoints(hitPoints: 5, damage: 7), 0);
      expect(
        () => RulesEngine.remainingHitPoints(hitPoints: -1, damage: 3),
        throwsRangeError,
      );
      expect(
        () => RulesEngine.remainingHitPoints(hitPoints: 5, damage: -3),
        throwsRangeError,
      );
    });

    test('damage updates HP without mutating the original character', () {
      final original = hero();
      final damaged = RulesEngine.damage(original, 5);
      expect(damaged.hitPoints, 7);
      expect(original.hitPoints, 12);
    });

    test('zero HP starts unconscious without inventing instant death', () {
      final down = RulesEngine.damage(hero(hp: 4, maxHp: 12), 15);
      expect(down.hitPoints, 0);
      expect(down.conditions, contains(RulesEngine.unconscious));
      expect(down.conditions, isNot(contains(RulesEngine.dead)));
      expect(down.deathFailures, 0);
    });

    test('leftover damage equal to maximum HP causes instant death', () {
      final killed = RulesEngine.damage(hero(hp: 4, maxHp: 12), 16);
      expect(killed.hitPoints, 0);
      expect(killed.conditions, contains(RulesEngine.dead));
    });

    test('damage at zero HP causes failures and ends stability', () {
      final down = hero(
        hp: 0,
        conditions: [RulesEngine.unconscious, RulesEngine.stable],
      );
      final injured = RulesEngine.damage(down, 1);
      expect(injured.deathFailures, 1);
      expect(injured.conditions, isNot(contains(RulesEngine.stable)));
      final killed = RulesEngine.damage(injured, 1, critical: true);
      expect(killed.conditions, contains(RulesEngine.dead));
      expect(killed.deathFailures, 3);
    });

    test('healing caps HP and clears unconsciousness and saving counters', () {
      final down = hero(
        hp: 0,
        successes: 1,
        failures: 2,
        conditions: [RulesEngine.unconscious],
      );
      final healed = RulesEngine.heal(down, 100);
      expect(healed.hitPoints, 12);
      expect(healed.deathSuccesses, 0);
      expect(healed.deathFailures, 0);
      expect(healed.conditions, isNot(contains(RulesEngine.unconscious)));
    });

    test('negative values and ordinary healing of the dead are rejected', () {
      expect(() => RulesEngine.damage(hero(), -1), throwsRangeError);
      expect(() => RulesEngine.heal(hero(), -1), throwsRangeError);
      expect(
        () => RulesEngine.heal(hero(hp: 0, conditions: [RulesEngine.dead]), 1),
        throwsStateError,
      );
    });
  });

  group('Death saves', () {
    test('a natural one adds two failures', () {
      final down = hero(hp: 0, failures: 1);
      final result = RulesEngine.deathSave(down, 1);
      expect(result.deathFailures, 3);
      expect(result.conditions, contains(RulesEngine.dead));
    });

    test('a natural twenty restores one HP and clears counters', () {
      final result = RulesEngine.deathSave(
        hero(hp: 0, failures: 2, conditions: [RulesEngine.unconscious]),
        20,
      );
      expect(result.hitPoints, 1);
      expect(result.deathFailures, 0);
      expect(result.conditions, isNot(contains(RulesEngine.unconscious)));
    });

    test('three successes stabilize and reset both counters', () {
      final result = RulesEngine.deathSave(
        hero(hp: 0, successes: 2, failures: 1),
        10,
      );
      expect(result.conditions, contains(RulesEngine.stable));
      expect(result.hitPoints, 0);
      expect(result.deathSuccesses, 0);
      expect(result.deathFailures, 0);
      expect(() => RulesEngine.deathSave(result, 12), throwsStateError);
    });

    test('alive, dead and invalid dice cannot produce a death save', () {
      expect(() => RulesEngine.deathSave(hero(), 10), throwsStateError);
      expect(
        () => RulesEngine.deathSave(
          hero(hp: 0, conditions: [RulesEngine.dead]),
          10,
        ),
        throwsStateError,
      );
      expect(() => RulesEngine.deathSave(hero(hp: 0), 21), throwsRangeError);
    });
  });
}
