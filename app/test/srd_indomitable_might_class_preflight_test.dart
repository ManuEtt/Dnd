import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_indomitable_might_rules.dart';

HeroCharacter _hero({
  String primary = 'Barbar',
  String secondary = '',
  int level = 18,
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'indomitable-class-profile',
  name: 'Klassenprofil',
  className: primary,
  secondaryClassName: secondary,
  level: level,
  secondaryClassLevel: secondaryLevel,
  abilities: const {'strength': 20},
  hitPoints: 40,
  maxHitPoints: 40,
);

void main() {
  group('Unbezwingbare Stärke: Klassenprofil vor Mindestwurf', () {
    test('ungültige Haupt-/Zweitklassen und Level schalten nichts frei', () {
      final invalid = <HeroCharacter>[
        _hero(primary: 'Unbekannt'),
        _hero(
          primary: 'Unbekannt',
          secondary: 'Barbar',
          level: 20,
          secondaryLevel: 18,
        ),
        _hero(
          primary: 'Barbar',
          secondary: 'Unbekannt',
          level: 20,
          secondaryLevel: 1,
        ),
        _hero(
          primary: 'Barbar',
          secondary: 'Barbarian',
          level: 20,
          secondaryLevel: 1,
        ),
        _hero(
          primary: 'Barbarian',
          secondary: 'Barbar',
          level: 20,
          secondaryLevel: 1,
        ),
        _hero(secondary: 'Paladin', level: 20, secondaryLevel: 0),
        _hero(level: 20, secondaryLevel: 1),
        _hero(level: 21),
        _hero(level: 0),
        _hero(level: 18, secondaryLevel: -1),
        _hero(secondary: 'Paladin', level: 18, secondaryLevel: 18),
        _hero(secondary: 'Paladin', level: 19, secondaryLevel: 2),
      ];
      for (final hero in invalid) {
        final before = hero.toJson();
        expect(SrdIndomitableMightRules.isEligible(hero), isFalse);
        expect(
          SrdIndomitableMightRules.effectiveTotal(
            hero: hero,
            ability: 'strength',
            kind: SrdD20CheckKind.savingThrow,
            rolledTotal: 3,
          ),
          3,
        );
        expect(hero.toJson(), before);
      }
    });

    test('gültige deutsche und englische Klassenaliase bleiben aktiv', () {
      final valid = <HeroCharacter>[
        _hero(),
        _hero(primary: 'Barbarian'),
        _hero(
          primary: 'Barbar',
          secondary: 'Paladin',
          level: 20,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Paladin',
          secondary: 'Barbarian',
          level: 20,
          secondaryLevel: 18,
        ),
      ];
      for (final hero in valid) {
        final before = hero.toJson();
        expect(SrdIndomitableMightRules.isEligible(hero), isTrue);
        expect(
          SrdIndomitableMightRules.effectiveTotal(
            hero: hero,
            ability: 'strength',
            kind: SrdD20CheckKind.abilityCheck,
            rolledTotal: 3,
          ),
          20,
        );
        expect(hero.toJson(), before);
      }
    });

    test('17 Barbarenstufen oder nur andere Klasse genügen nicht', () {
      final low = _hero(
        primary: 'Paladin',
        secondary: 'Barbar',
        level: 20,
        secondaryLevel: 17,
      );
      final other = _hero(primary: 'Paladin', level: 20);
      expect(SrdIndomitableMightRules.isEligible(low), isFalse);
      expect(SrdIndomitableMightRules.isEligible(other), isFalse);
    });
  });
}
