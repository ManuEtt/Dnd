import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_evasion_rules.dart';

HeroCharacter _hero({
  String primary = 'Mönch',
  String secondary = '',
  int level = 7,
  int secondaryLevel = 0,
  int? hitPoints = 30,
}) => HeroCharacter(
  id: 'evasion-class-profile',
  name: 'Nebeltritt',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: hitPoints,
  maxHitPoints: 30,
  armorClass: 15,
  speed: 9,
  abilities: const {
    'strength': 10,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 16,
    'charisma': 10,
  },
);

SrdEvasionResult _preview(HeroCharacter hero, bool success) =>
    SrdEvasionRules.previewConfirmedDexteritySave(
      hero,
      incomingDamage: 23,
      incomingDamageConfirmed: true,
      dexteritySaveForHalfConfirmed: true,
      saveSucceeded: success,
    );

void main() {
  group('SRD 5.2.1 Entrinnen: konsistente Klassenprofile', () {
    test('Ungültige Direktprofile schalten Entrinnen nicht frei', () {
      final invalid = <HeroCharacter>[
        _hero(
          primary: 'Monk',
          secondary: 'Mönch',
          level: 14,
          secondaryLevel: 7,
        ),
        _hero(
          primary: 'Rogue',
          secondary: 'Schurke',
          level: 14,
          secondaryLevel: 7,
        ),
        _hero(primary: 'Unbekannt'),
        _hero(
          primary: 'Mönch',
          secondary: 'Unbekannt',
          level: 12,
          secondaryLevel: 5,
        ),
        _hero(primary: 'Mönch', level: 9, secondaryLevel: 2),
        _hero(primary: 'Mönch', secondary: 'Fighter', level: 7),
        _hero(
          primary: 'Mönch',
          secondary: 'Fighter',
          level: 8,
          secondaryLevel: -1,
        ),
        _hero(
          primary: 'Fighter',
          secondary: 'Rogue',
          level: 7,
          secondaryLevel: 7,
        ),
        _hero(level: 0),
        _hero(level: 21),
      ];
      for (final hero in invalid) {
        final before = hero.toJson();
        expect(SrdEvasionRules.unlocked(hero), isFalse);
        expect(SrdEvasionRules.eligible(hero), isFalse);
        for (final succeeded in [true, false]) {
          expect(() => _preview(hero, succeeded), throwsFormatException);
        }
        expect(hero.toJson(), before);
      }
    });

    test('Gültige deutsche und englische Klassenaliase erhalten Entrinnen', () {
      final valid = <HeroCharacter>[
        _hero(primary: 'Mönch'),
        _hero(primary: 'Monk'),
        _hero(primary: 'Mönchin'),
        _hero(primary: 'Schurke'),
        _hero(primary: 'Rogue'),
        _hero(primary: 'Schurkin'),
        _hero(
          primary: 'Fighter',
          secondary: 'Monk',
          level: 10,
          secondaryLevel: 7,
        ),
        _hero(
          primary: 'Kämpfer',
          secondary: 'Rogue',
          level: 12,
          secondaryLevel: 7,
        ),
        _hero(
          primary: 'Rogue',
          secondary: 'Cleric',
          level: 9,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Monk',
          secondary: 'Rogue',
          level: 14,
          secondaryLevel: 7,
        ),
      ];
      for (final hero in valid) {
        final before = hero.toJson();
        expect(SrdEvasionRules.unlocked(hero), isTrue);
        expect(SrdEvasionRules.eligible(hero), isTrue);
        final success = _preview(hero, true);
        final failed = _preview(hero, false);
        expect(success.incomingDamage, 23);
        expect(success.damageAfterEvasion, 0);
        expect(success.preventedDamage, 23);
        expect(failed.damageAfterEvasion, 11);
        expect(failed.preventedDamage, 12);
        expect(hero.toJson(), before);
        final loaded = HeroCharacter.fromJson(before);
        expect(loaded.toJson(), before);
        expect(_preview(loaded, false).damageAfterEvasion, 11);
      }
    });

    test('Zwei Klassen unter Stufe sieben addieren ihre Stufen nicht', () {
      final hero = _hero(
        primary: 'Monk',
        secondary: 'Rogue',
        level: 12,
        secondaryLevel: 6,
      );
      expect(SrdEvasionRules.unlocked(hero), isFalse);
      expect(() => _preview(hero, true), throwsFormatException);
      expect(SrdEvasionRules.unlocked(_hero(level: 6)), isFalse);
      expect(
        SrdEvasionRules.unlocked(_hero(primary: 'Rogue', level: 6)),
        isFalse,
      );
      expect(SrdEvasionRules.unlocked(_hero(level: 20)), isTrue);
    });

    test('Bestätigter rettungswurf bleibt ohne HP- oder Ressourcenbuchung', () {
      final hero = _hero(
        primary: 'Fighter',
        secondary: 'Rogue',
        level: 9,
        secondaryLevel: 7,
      );
      final before = hero.toJson();
      expect(_preview(hero, true).damageAfterEvasion, 0);
      expect(_preview(hero, false).damageAfterEvasion, 11);
      expect(_preview(hero, true).damageAfterEvasion, 0);
      expect(hero.hitPoints, 30);
      expect(hero.toJson(), before);
    });
  });
}
