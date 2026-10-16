import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_feature_resources.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';

class LowRandom implements Random {
  @override int nextInt(int max) => 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

HeroCharacter fighter(int level, {String primary = 'Kämpfer',
    String second = '', int secondLevel = 0, int hp = 8,
    int maxHp = 24}) => HeroCharacter(
  id: 'fighter-resource', name: 'Liora', className: primary,
  level: level, secondaryClassName: second, secondaryClassLevel: secondLevel,
  hitPoints: hp, maxHitPoints: maxHp,
  abilities: const {'strength': 16, 'dexterity': 14, 'constitution': 14,
    'intelligence': 10, 'wisdom': 10, 'charisma': 10},
);

void main() {
  final dice = DiceEngine(random: LowRandom());
  group('SRD 5.2.1 Fighter resource accounting', () {
    test('Second Wind capacity changes at Fighter levels 4 and 10', () {
      for (final (level, count) in [(1,2),(3,2),(4,3),(9,3),(10,4),(20,4)]) {
        expect(ClassFeatureResources.secondWindMaximum(fighter(level)), count);
      }
      for (final (level, count) in [(1,0),(2,1),(16,1),(17,2),(20,2)]) {
        expect(ClassFeatureResources.actionSurgeMaximum(fighter(level)), count);
      }
      expect(ClassFeatureResources.secondWindMaximum(
        fighter(10, primary: 'Magier')), 0);
      expect(ClassFeatureResources.secondWindMaximum(
        fighter(10, primary: 'Magier', second: 'Kämpfer', secondLevel: 4)), 3);
      expect(ClassFeatureResources.actionSurgeMaximum(
        fighter(10, primary: 'Magier', second: 'Kämpfer', secondLevel: 1)), 0);
    });

    test('Second Wind adds fighter class level, consumes once, heals to max', () {
      final hero = fighter(2, hp: 7, maxHp: 10);
      final result = ClassFeatureResources.useSecondWind(hero, dice);
      expect(result.roll.rolls.single, 1);
      expect(result.totalHealing, 3);
      expect(result.hitPointsRestored, 3);
      expect(result.hero.hitPoints, 10);
      expect(result.hero.spentSecondWind, 1);
      expect(hero.spentSecondWind, 0);
      final twice = ClassFeatureResources.useSecondWind(result.hero, dice);
      expect(twice.hero.spentSecondWind, 2);
      expect(twice.hitPointsRestored, 0);
      expect(() => ClassFeatureResources.useSecondWind(twice.hero, dice),
        throwsStateError);
    });

    test('Short rest restores exactly one Second Wind; all Action Surge', () {
      final hero = fighter(17).copyWith(spentSecondWind: 4,
        spentActionSurge: 2);
      final afterShort = ClassFeatureResources.afterShortRest(hero);
      expect(afterShort.spentSecondWind, 3);
      expect(afterShort.spentActionSurge, 0);
      expect(ClassFeatureResources.afterShortRest(afterShort).spentSecondWind, 2);
      final afterLong = ClassFeatureResources.afterLongRest(hero);
      expect(afterLong.spentSecondWind, 0);
      expect(afterLong.spentActionSurge, 0);
      expect(RestRules.longRest(hero).spentSecondWind, 0);
      final rested = RestRules.shortRest(fighter(2).copyWith(spentSecondWind: 2,
          spentActionSurge: 1), dice: dice);
      expect(rested.hero.spentSecondWind, 1);
      expect(rested.hero.spentActionSurge, 0);
    });

    test('Action Surge checked by class level and remaining pool', () {
      expect(() => ClassFeatureResources.spendActionSurge(fighter(1)),
        throwsStateError);
      final level17 = fighter(17);
      final first = ClassFeatureResources.spendActionSurge(level17);
      final second = ClassFeatureResources.spendActionSurge(first);
      expect(second.spentActionSurge, 2);
      expect(() => ClassFeatureResources.spendActionSurge(second),
        throwsStateError);
      expect(() => ClassFeatureResources.useSecondWind(
        fighter(2, hp: 0), dice), throwsStateError);
    });

    test('Old schema 1 remains valid; forged resource counts are rejected', () {
      final hero = fighter(5);
      final old = hero.toJson();
      expect(old.containsKey('spentSecondWind'), false);
      expect(old.containsKey('spentActionSurge'), false);
      expect(HeroCharacter.fromJson(old).spentSecondWind, 0);
      final used = ClassFeatureResources.spendActionSurge(hero.copyWith(
          spentSecondWind: 2));
      final saved = HeroCharacter.fromJson(used.toJson());
      expect(saved.spentSecondWind, 2);
      expect(saved.spentActionSurge, 1);
      expect(() => HeroCharacter.fromJson({...old, 'spentSecondWind': 4}),
        throwsFormatException);
      expect(() => HeroCharacter.fromJson({...old, 'spentActionSurge': 2}),
        throwsFormatException);
      expect(() => HeroCharacter.fromJson({...old, 'spentSecondWind': -1}),
        throwsFormatException);
      final mage = fighter(5, primary: 'Magier').toJson();
      expect(() => HeroCharacter.fromJson({...mage, 'spentActionSurge': 1}),
        throwsFormatException);
    });
  });
}
