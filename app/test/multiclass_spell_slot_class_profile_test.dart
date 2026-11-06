import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/multiclass_rules.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

HeroCharacter _caster({
  String primary = 'Wizard',
  String secondary = '',
  int level = 5,
  int secondaryLevel = 0,
  Map<String, int> spent = const {},
}) => HeroCharacter(
  id: 'normal-slots-profile',
  name: 'Runenmagie',
  className: primary,
  secondaryClassName: secondary,
  level: level,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 18,
  maxHitPoints: 25,
  spells: const ['Magisches Geschoss'],
  spentSpellSlots: spent,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 13,
    'charisma': 14,
  },
);

void main() {
  group('Normale Zauberplätze: Klassenprofil vor Slotberechnung', () {
    test('ungültige SRD-Klassenprofile geben keine Zauberplätze frei', () {
      final invalid = <HeroCharacter>[
        _caster(primary: 'Unknown Homebrew'),
        _caster(primary: 'Unknown Homebrew', secondary: 'Wizard',
            level: 8, secondaryLevel: 5),
        _caster(secondary: 'Unknown Homebrew', level: 8, secondaryLevel: 3),
        _caster(primary: 'Magier', secondary: 'Wizard',
            level: 8, secondaryLevel: 3),
        _caster(primary: 'Wizard', secondary: 'Magier',
            level: 8, secondaryLevel: 3),
        _caster(primary: 'Bardin', secondary: 'Bard',
            level: 8, secondaryLevel: 3),
        _caster(secondary: 'Ranger'),
        _caster(secondaryLevel: 1),
        _caster(secondaryLevel: -1),
        _caster(level: 0),
        _caster(level: 21),
        _caster(secondary: 'Cleric', level: 8, secondaryLevel: 8),
        _caster(secondary: 'Cleric', level: 8, secondaryLevel: 9),
        _caster(secondary: ' ', level: 8, secondaryLevel: 3),
      ];
      for (final hero in invalid) {
        final snapshot = hero.toJson();
        expect(MulticlassRules.combinedSpellcasterLevel(hero), 0);
        expect(MulticlassRules.spellSlots(hero), everyElement(0));
        expect(SpellcastingRules.availableSlots(hero), isEmpty);
        expect(
          () => SpellcastingRules.cast(
            hero,
            spellName: 'Magisches Geschoss',
            spellLevel: 1,
          ),
          throwsStateError,
        );
        expect(hero.toJson(), snapshot);
      }
    });

    test('ungültiger Legacy-Verbrauch erzeugt keinen neuen Slot', () {
      final hero = _caster(
        primary: 'Unknown Homebrew',
        secondary: 'Wizard',
        level: 8,
        secondaryLevel: 5,
        spent: const {'1': 1},
      );
      final original = hero.toJson();
      expect(MulticlassRules.combinedSpellcasterLevel(hero), 0);
      expect(
        () => SpellcastingRules.availableSlots(hero),
        throwsFormatException,
      );
      expect(hero.toJson(), original);
    });

    test('deutsche und englische Zauberklassen bleiben verfügbar', () {
      final valid = <HeroCharacter>[
        _caster(primary: 'Magier'),
        _caster(primary: 'Wizard'),
        _caster(primary: 'Bardin'),
        _caster(primary: 'Waldläufer', level: 5),
        _caster(primary: 'Ranger', level: 5),
      ];
      for (final hero in valid) {
        final before = hero.toJson();
        final level = MulticlassRules.combinedSpellcasterLevel(hero);
        expect(level, greaterThan(0));
        expect(SpellcastingRules.availableSlots(hero)[1], greaterThan(0));
        expect(hero.toJson(), before);
      }
    });

    test('bestätigte Mehrklassen berechnen nur eigene Klassenstufen', () {
      final hero = _caster(
        primary: ' Wizard ',
        secondary: 'RANGER',
        level: 8,
        secondaryLevel: 3,
      );
      final original = hero.toJson();
      expect(hero.primaryClassLevel, 5);
      expect(MulticlassRules.combinedSpellcasterLevel(hero), 7);
      expect(SpellcastingRules.availableSlots(hero), {
        1: 4,
        2: 3,
        3: 3,
        4: 1,
      });
      final result = SpellcastingRules.cast(
        hero,
        spellName: 'Magisches Geschoss',
        spellLevel: 1,
      );
      expect(result.hero.spentSpellSlots['1'], 1);
      expect(hero.toJson(), original);
      expect(
        HeroCharacter.fromJson(result.hero.toJson()).toJson(),
        result.hero.toJson(),
      );
    });

    test('bestätigte Paktmagie bleibt ein unabhängiger Zauberplatzpool', () {
      final hero = _caster(
        primary: 'WARLOCK',
        secondary: 'Wizard',
        level: 8,
        secondaryLevel: 5,
      );
      final before = hero.toJson();
      expect(MulticlassRules.combinedSpellcasterLevel(hero), 5);
      expect(SpellcastingRules.availableSlots(hero), {1: 4, 2: 3, 3: 2});
      expect(SpellcastingRules.pactClassLevel(hero), 3);
      expect(SpellcastingRules.availablePactSlots(hero), 2);
      expect(hero.toJson(), before);
    });
  });
}
