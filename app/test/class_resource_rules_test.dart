import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';

HeroCharacter hero(
  String name,
  int level, {
  int charisma = 16,
  String secondary = '',
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'resource-hero',
  name: 'Liora',
  className: name,
  level: level,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 15,
  abilities: {'charisma': charisma},
);

void main() {
  group('SRD 5.2.1 general class resources', () {
    test('Class level, not total level, determines pools', () {
      expect(ClassResourceRules.maximum(hero('Barbar', 1), 'rage'), 2);
      expect(ClassResourceRules.maximum(hero('Barbar', 3), 'rage'), 3);
      expect(ClassResourceRules.maximum(hero('Barbar', 6), 'rage'), 4);
      expect(ClassResourceRules.maximum(hero('Barbar', 12), 'rage'), 5);
      expect(ClassResourceRules.maximum(hero('Barbar', 17), 'rage'), 6);
      expect(ClassResourceRules.maximum(hero('Mönch', 11), 'focusPoints'), 11);
      expect(ClassResourceRules.maximum(hero('Magier', 11), 'focusPoints'), 0);
      expect(
        ClassResourceRules.maximum(
          hero('Magier', 11, secondary: 'Mönch', secondaryLevel: 3),
          'focusPoints',
        ),
        3,
      );
      expect(
        ClassResourceRules.maximum(hero('Barde', 8), 'bardicInspiration'),
        3,
      );
      expect(
        ClassResourceRules.maximum(
          hero('Barde', 8, charisma: 8),
          'bardicInspiration',
        ),
        1,
      );
      expect(ClassResourceRules.maximum(hero('Paladin', 11), 'layOnHands'), 55);
      expect(
        ClassResourceRules.maximum(hero('Zauberer', 1), 'sorceryPoints'),
        0,
      );
      expect(
        ClassResourceRules.maximum(hero('Zauberer', 20), 'sorceryPoints'),
        20,
      );
      expect(ClassResourceRules.maximum(hero('Druide', 17), 'wildShape'), 4);
    });

    test('Rage, focus, sneak attack and bardic die scale by class level', () {
      expect(ClassResourceRules.rageDamageBonus(1), 2);
      expect(ClassResourceRules.rageDamageBonus(9), 3);
      expect(ClassResourceRules.rageDamageBonus(16), 4);
      expect(ClassResourceRules.sneakAttackDice(1), 1);
      expect(ClassResourceRules.sneakAttackDice(3), 2);
      expect(ClassResourceRules.sneakAttackDice(20), 10);
      expect(ClassResourceRules.martialArtsDie(1), 6);
      expect(ClassResourceRules.martialArtsDie(5), 8);
      expect(ClassResourceRules.martialArtsDie(11), 10);
      expect(ClassResourceRules.martialArtsDie(17), 12);
      expect(ClassResourceRules.bardicDie(1), 6);
      expect(ClassResourceRules.bardicDie(5), 8);
      expect(ClassResourceRules.bardicDie(10), 10);
      expect(ClassResourceRules.bardicDie(15), 12);
      expect(ClassResourceRules.monkMovementBonusFeet(18), 30);
    });

    test(
      'Warlock invocation and martial mastery tables are class-level only',
      () {
        expect(ClassResourceRules.warlockInvocationChoices(1), 1);
        expect(ClassResourceRules.warlockInvocationChoices(2), 3);
        expect(ClassResourceRules.warlockInvocationChoices(5), 5);
        expect(ClassResourceRules.warlockInvocationChoices(18), 10);
        expect(ClassResourceRules.fighterWeaponMasteries(1), 3);
        expect(ClassResourceRules.fighterWeaponMasteries(4), 4);
        expect(ClassResourceRules.fighterWeaponMasteries(10), 5);
        expect(ClassResourceRules.fighterWeaponMasteries(16), 6);
        expect(ClassResourceRules.barbarianWeaponMasteries(4), 3);
        expect(ClassResourceRules.barbarianWeaponMasteries(10), 4);
        expect(ClassResourceRules.fighterIndomitableMaximum(9), 1);
        expect(ClassResourceRules.fighterIndomitableMaximum(13), 2);
        expect(ClassResourceRules.fighterIndomitableMaximum(17), 3);
      },
    );

    test(
      'Spend resources and restore by the correct short/long rest rules',
      () {
        final b = hero('Barde', 5);
        var used = ClassResourceRules.spend(b, 'bardicInspiration', amount: 2);
        expect(ClassResourceRules.remaining(used, 'bardicInspiration'), 1);
        expect(
          ClassResourceRules.afterShortRest(
            used,
          ).spentClassResources['bardicInspiration'],
          isNull,
        );
        expect(
          ClassResourceRules.afterLongRest(used).spentClassResources,
          isEmpty,
        );
        expect(
          () => ClassResourceRules.spend(used, 'bardicInspiration', amount: 2),
          throwsStateError,
        );
        final rage = ClassResourceRules.spend(
          hero('Barbar', 3),
          'rage',
          amount: 3,
        );
        expect(
          ClassResourceRules.afterShortRest(rage).spentClassResources['rage'],
          2,
        );
        expect(
          ClassResourceRules.afterLongRest(rage).spentClassResources,
          isEmpty,
        );
      },
    );

    test('Legacy saves remain valid; forged counts fail closed', () {
      final original = hero('Mönch', 6);
      final old = original.toJson();
      expect(old.containsKey('spentClassResources'), false);
      expect(HeroCharacter.fromJson(old).spentClassResources, isEmpty);
      final used = ClassResourceRules.spend(original, 'focusPoints', amount: 2);
      expect(HeroCharacter.fromJson(used.toJson()).spentClassResources, {
        'focusPoints': 2,
      });
      expect(
        () => HeroCharacter.fromJson({
          ...old,
          'spentClassResources': {'rage': 2},
        }),
        throwsFormatException,
      );
      expect(
        () => HeroCharacter.fromJson({
          ...old,
          'spentClassResources': {'focusPoints': 7},
        }),
        throwsFormatException,
      );
      expect(
        () => HeroCharacter.fromJson({
          ...old,
          'spentClassResources': {'bogus': 1},
        }),
        throwsFormatException,
      );
    });
  });
}
