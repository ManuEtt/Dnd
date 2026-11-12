import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/paladin_lay_on_hands.dart';

HeroCharacter _hero({
  String primary = 'Paladin',
  String secondary = '',
  int level = 1,
  int secondaryLevel = 0,
  int hitPoints = 10,
  List<String> conditions = const [],
  Map<String, int> spent = const {},
}) => HeroCharacter(
  id: 'paladin-profile-test',
  name: 'Liora',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: hitPoints,
  maxHitPoints: 30,
  conditions: conditions,
  spentClassResources: spent,
);

void main() {
  group('SRD 5.2.1 Paladin 1: Lay on Hands class profile', () {
    test('valid single class and aliases spend exactly the healing amount', () {
      for (final name in ['Paladin', 'paladin']) {
        final hero = _hero(primary: name);
        expect(PaladinLayOnHands.remaining(hero), 5);
        final result = PaladinLayOnHands.useOnSelf(hero, healing: 3);
        expect(result.pointsSpent, 3);
        expect(result.hitPointsRestored, 3);
        expect(result.hero.hitPoints, 13);
        expect(PaladinLayOnHands.remaining(result.hero), 2);
        expect(hero.spentClassResources, isEmpty);
      }
    });

    test('valid multiclass uses Paladin class level, never overall level', () {
      final second = _hero(
        primary: 'Fighter',
        secondary: 'Paladin',
        level: 4,
        secondaryLevel: 2,
        conditions: ['vergiftet'],
      );
      expect(PaladinLayOnHands.remaining(second), 10);
      final healed = PaladinLayOnHands.useOnSelf(
        second,
        healing: 3,
        removePoisoned: true,
      );
      expect(healed.pointsSpent, 8);
      expect(healed.hitPointsRestored, 3);
      expect(healed.poisonedRemoved, isTrue);
      expect(healed.hero.conditions, isEmpty);
      expect(PaladinLayOnHands.remaining(healed.hero), 2);

      final primary = _hero(
        primary: 'Paladin',
        secondary: 'Monk',
        level: 12,
        secondaryLevel: 2,
      );
      expect(PaladinLayOnHands.remaining(primary), 50);
      expect(PaladinLayOnHands.remaining(_hero(level: 20)), 100);
    });

    test('invalid classes and levels never advertise or spend healing', () {
      final invalid = <HeroCharacter>[
        _hero(
          primary: 'Drachenritter',
          secondary: 'Paladin',
          level: 4,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Paladin',
          secondary: 'Drachenritter',
          level: 4,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Paladin',
          secondary: 'paladin',
          level: 4,
          secondaryLevel: 2,
        ),
        _hero(primary: 'Paladin', level: 4, secondaryLevel: 2),
        _hero(primary: 'Paladin', secondary: 'Monk', level: 4),
        _hero(
          primary: 'Fighter',
          secondary: 'Paladin',
          level: 2,
          secondaryLevel: 2,
        ),
        _hero(level: 0),
        _hero(level: 21),
        _hero(secondaryLevel: -1),
        _hero(
          primary: 'Fighter',
          secondary: 'Paladin',
          level: 4,
          secondaryLevel: 5,
        ),
      ];
      for (final hero in invalid) {
        final original = hero.toJson();
        expect(PaladinLayOnHands.remaining(hero), 0);
        expect(
          () => PaladinLayOnHands.useOnSelf(hero, healing: 1),
          throwsFormatException,
        );
        expect(hero.toJson(), original);
        expect(hero.hitPoints, 10);
        expect(hero.spentClassResources, isEmpty);
      }
    });

    test('invalid profile preserves existing uses and poison sources', () {
      final hero = _hero(
        primary: 'Paladin',
        secondary: 'paladin',
        level: 4,
        secondaryLevel: 2,
        conditions: ['vergiftet'],
        spent: {'layOnHands': 2},
      );
      final before = hero.toJson();
      expect(PaladinLayOnHands.remaining(hero), 0);
      expect(
        () => PaladinLayOnHands.useOnSelf(hero, removePoisoned: true),
        throwsFormatException,
      );
      expect(hero.toJson(), before);
      expect(hero.conditions, ['vergiftet']);
    });

    test('a valid non-Paladin cannot use or advertise the feature', () {
      final hero = _hero(primary: 'Fighter');
      expect(PaladinLayOnHands.remaining(hero), 0);
      expect(
        () => PaladinLayOnHands.useOnSelf(hero, healing: 1),
        throwsStateError,
      );
      expect(hero.spentClassResources, isEmpty);
    });

    test('confirmed result retains resource count after JSON reload', () {
      final hero = _hero(level: 3);
      final result = PaladinLayOnHands.useOnSelf(hero, healing: 4);
      final reloaded = HeroCharacter.fromJson(result.hero.toJson());
      expect(reloaded.hitPoints, 14);
      expect(reloaded.spentClassResources['layOnHands'], 4);
      expect(PaladinLayOnHands.remaining(reloaded), 11);
      expect(hero.hitPoints, 10);
      expect(hero.spentClassResources, isEmpty);
    });
  });
}
