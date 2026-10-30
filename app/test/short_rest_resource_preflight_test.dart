import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';

class _CountingRandom implements Random {
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return 0;
  }

  @override
  bool nextBool() => throw UnsupportedError('D20 is not used by a rest.');
  @override
  double nextDouble() => throw UnsupportedError('Only Hit Dice are requested.');
}

HeroCharacter _wounded({String className = 'Kämpfer', int level = 2}) =>
    HeroCharacter(
      id: 'rest-preflight',
      name: 'Liora',
      className: className,
      level: level,
      abilities: const {'constitution': 14, 'charisma': 14, 'wisdom': 14},
      hitPoints: 3,
      maxHitPoints: 30,
    );

void main() {
  group('Short Rest checks original resources before Hit Dice', () {
    final fighter = _wounded();
    final warlock = _wounded(className: 'Hexenmeister');
    final invalid = <String, HeroCharacter>{
      'negative Second Wind': fighter.copyWith(spentSecondWind: -1),
      'Second Wind above two uses': fighter.copyWith(spentSecondWind: 3),
      'negative Action Surge': fighter.copyWith(spentActionSurge: -1),
      'Action Surge above one use': fighter.copyWith(spentActionSurge: 2),
      'Second Wind without Fighter': warlock.copyWith(spentSecondWind: 1),
      'negative class resource': fighter.copyWith(
        spentClassResources: {'rage': -1},
      ),
      'unearned Rage': fighter.copyWith(spentClassResources: {'rage': 1}),
      'unknown class resource': fighter.copyWith(
        spentClassResources: {'invented': 1},
      ),
      'too many Focus Points': _wounded(
        className: 'Mönch',
      ).copyWith(spentClassResources: {'focusPoints': 3}),
      'negative Pact Magic': warlock.copyWith(spentPactSlots: -1),
      'Pact Magic above two slots': warlock.copyWith(spentPactSlots: 3),
      'Pact Magic without Warlock': fighter.copyWith(spentPactSlots: 1),
    };
    for (final entry in invalid.entries) {
      for (final count in [1, 2]) {
        test('${entry.key}, $count Hit Dice: reject before the first die', () {
          final random = _CountingRandom();
          final before = jsonEncode(entry.value.toJson());
          expect(
            () => RestRules.shortRest(
              entry.value,
              dice: DiceEngine(random: random),
              count: count,
            ),
            throwsFormatException,
          );
          expect(random.calls, 0);
          expect(jsonEncode(entry.value.toJson()), before);
        });
      }
    }

    final recovery = [
      ('Barbar', 2, 'rage', 2, 1),
      ('Kleriker', 2, 'channelDivinityCleric', 2, 1),
      ('Druide', 2, 'wildShape', 2, 1),
      ('Paladin', 3, 'channelDivinityPaladin', 2, 1),
      ('Mönch', 4, 'focusPoints', 4, 0),
      ('Barde', 5, 'bardicInspiration', 2, 0),
    ];
    for (final (name, level, resource, spent, remainingSpent) in recovery) {
      test('$name: existing class recovery occurs exactly once', () {
        final hero = _wounded(
          className: name,
          level: level,
        ).copyWith(spentClassResources: {resource: spent});
        final before = jsonEncode(hero.toJson());
        final random = _CountingRandom();
        final result = RestRules.shortRest(
          hero,
          dice: DiceEngine(random: random),
        );
        expect(result.hero.spentClassResources[resource] ?? 0, remainingSpent);
        expect(result.recovered, 3);
        expect(result.hero.hitPoints, 6);
        expect(result.dice.single.rolls, [1]);
        expect(random.calls, 1);
        expect(jsonEncode(hero.toJson()), before);
      });
    }

    test(
      'Fighter/Warlock aliases: recover once without adding spell slots',
      () {
        final hero = fighter.copyWith(
          className: 'fighter',
          level: 3,
          secondaryClassName: 'warlock',
          secondaryClassLevel: 1,
          spentSecondWind: 2,
          spentActionSurge: 1,
          spentPactSlots: 1,
        );
        final random = _CountingRandom();
        final result = RestRules.shortRest(
          hero,
          dice: DiceEngine(random: random),
          dieSides: 10,
          count: 2,
        );
        expect(result.hero.spentSecondWind, 1);
        expect(result.hero.spentActionSurge, 0);
        expect(result.hero.spentPactSlots, 0);
        expect(result.hero.spentSpellSlots, isEmpty);
        expect(result.hero.spentHitDice, {'d10': 2});
        expect(result.recovered, 6);
        expect(random.calls, 2);
        expect(hero.spentSecondWind, 2);
        expect(hero.spentActionSurge, 1);
        expect(hero.spentPactSlots, 1);
      },
    );

    test('Sorcerous Restoration remains explicit and applies its cap once', () {
      final hero = _wounded(className: 'Zauberer', level: 5).copyWith(
        spentClassResources: {'sorceryPoints': 5},
        spentSpellSlots: {'1': 2},
      );
      final random = _CountingRandom();
      final result = RestRules.shortRest(
        hero,
        dice: DiceEngine(random: random),
        restoreSorceryPoints: true,
      );
      expect(result.hero.spentClassResources, {
        'sorceryPoints': 3,
        'sorcerousRestoration': 1,
      });
      expect(result.hero.spentSpellSlots, {'1': 2});
      expect(random.calls, 1);
      final ordinary = RestRules.shortRest(
        hero,
        dice: DiceEngine(random: random),
      );
      expect(ordinary.hero.spentClassResources, {'sorceryPoints': 5});
      expect(ordinary.hero.spentSpellSlots, {'1': 2});
    });

    test(
      'bad Pact Magic also blocks before optional Sorcerous Restoration',
      () {
        final hero = _wounded(className: 'Zauberer', level: 5).copyWith(
          spentPactSlots: 1,
          spentClassResources: {'sorceryPoints': 5},
        );
        final before = jsonEncode(hero.toJson());
        final random = _CountingRandom();
        expect(
          () => RestRules.shortRest(
            hero,
            dice: DiceEngine(random: random),
            restoreSorceryPoints: true,
          ),
          throwsFormatException,
        );
        expect(random.calls, 0);
        expect(jsonEncode(hero.toJson()), before);
      },
    );
  });
}
