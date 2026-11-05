import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_sorcerous_restoration_rules.dart';

HeroCharacter _hero({
  String primary = 'Zauberer',
  String secondary = '',
  int level = 10,
  int secondaryLevel = 0,
  int pointsSpent = 6,
  int restorationSpent = 0,
}) => HeroCharacter(
  id: 'restoration-class-profile',
  name: 'Ela',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 12,
  maxHitPoints: 20,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d6',
  abilities: const {
    'strength': 10,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 12,
    'charisma': 16,
  },
  spentClassResources: {
    if (pointsSpent > 0) 'sorceryPoints': pointsSpent,
    if (restorationSpent > 0) 'sorcerousRestoration': restorationSpent,
  },
);

void main() {
  group('SRD 5.2.1 Zauberkraftregeneration: Klassenprofil', () {
    test('Ungültige direkte Klassenprofile gewähren keine Regeneration', () {
      final invalid = <HeroCharacter>[
        _hero(
          primary: 'Zauberer',
          secondary: 'Sorcerer',
          level: 12,
          secondaryLevel: 6,
        ),
        _hero(
          primary: 'Zauberin',
          secondary: 'Zauberer',
          level: 12,
          secondaryLevel: 6,
        ),
        _hero(primary: 'Unbekannt'),
        _hero(primary: 'Zauberer', secondary: 'Unbekannt', secondaryLevel: 2),
        _hero(primary: 'Zauberer', secondary: 'Kämpfer', secondaryLevel: 0),
        _hero(primary: 'Zauberer', secondaryLevel: 3),
        _hero(primary: 'Zauberer', secondary: 'Kämpfer', secondaryLevel: -1),
        _hero(
          primary: 'Zauberer',
          secondary: 'Kämpfer',
          level: 3,
          secondaryLevel: 3,
        ),
        _hero(level: 0),
        _hero(level: 21),
      ];
      for (final hero in invalid) {
        final before = hero.toJson();
        expect(SrdSorcerousRestorationRules.sorcererClassLevel(hero), 0);
        expect(SrdSorcerousRestorationRules.maximumUses(hero), 0);
        expect(SrdSorcerousRestorationRules.maximumRecoveredPoints(hero), 0);
        expect(
          () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
            hero,
          ),
          throwsFormatException,
        );
        expect(hero.toJson(), before);
      }
    });

    test('Ungültiger alter Verbrauch wird nicht durch Rast legitimiert', () {
      final hero = _hero(
        primary: 'Sorcerer',
        secondary: 'Zauberer',
        level: 12,
        secondaryLevel: 6,
        restorationSpent: 1,
      );
      final before = hero.toJson();
      expect(() => ClassResourceRules.validate(hero), throwsFormatException);
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          hero,
        ),
        throwsFormatException,
      );
      expect(hero.toJson(), before);
    });

    test('Gültige deutsche und englische Zauberer-Aliase bleiben nutzbar', () {
      final valid = <HeroCharacter>[
        _hero(primary: 'Sorcerer', level: 5, pointsSpent: 2),
        _hero(primary: 'Zauberin', level: 5, pointsSpent: 2),
        _hero(
          primary: 'Kämpfer',
          secondary: 'Sorcerer',
          level: 9,
          secondaryLevel: 5,
          pointsSpent: 2,
        ),
        _hero(
          primary: 'Zauberer',
          secondary: 'Fighter',
          level: 9,
          secondaryLevel: 4,
          pointsSpent: 2,
        ),
      ];
      for (final hero in valid) {
        final before = hero.toJson();
        expect(SrdSorcerousRestorationRules.sorcererClassLevel(hero), 5);
        expect(SrdSorcerousRestorationRules.maximumUses(hero), 1);
        expect(SrdSorcerousRestorationRules.maximumRecoveredPoints(hero), 2);
        final result =
            SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(hero);
        expect(result.recoveredPoints, 2);
        expect(result.spentAfter, 0);
        expect(result.hero.spentClassResources['sorcerousRestoration'], 1);
        expect(hero.toJson(), before);
        expect(
          HeroCharacter.fromJson(result.hero.toJson()).toJson(),
          result.hero.toJson(),
        );
      }
    });

    test('Grenzen: Stufe 4 und Nicht-Zauberer ohne Ressourcenzugriff', () {
      final early = _hero(level: 4, pointsSpent: 2);
      final noClass = _hero(primary: 'Magier', pointsSpent: 0);
      expect(SrdSorcerousRestorationRules.maximumUses(early), 0);
      expect(SrdSorcerousRestorationRules.sorcererClassLevel(noClass), 0);
      expect(SrdSorcerousRestorationRules.maximumUses(noClass), 0);
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          early,
        ),
        throwsStateError,
      );
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          noClass,
        ),
        throwsStateError,
      );
    });

    test('Stufe 20 behält den unveränderten Halbierungsdeckel', () {
      final hero = _hero(level: 20, pointsSpent: 12);
      expect(SrdSorcerousRestorationRules.maximumRecoveredPoints(hero), 10);
      final result =
          SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(hero);
      expect(result.recoveredPoints, 10);
      expect(result.spentAfter, 2);
      expect(hero.spentClassResources['sorceryPoints'], 12);
    });
  });
}
