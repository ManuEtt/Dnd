import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

HeroCharacter _pactHero({
  String primary = 'Warlock',
  String secondary = '',
  int secondaryLevel = 0,
  int level = 5,
  int spentPactSlots = 0,
}) => HeroCharacter(
  id: 'pact-profile-guard',
  name: 'Paktprofil',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 18,
  maxHitPoints: 24,
  spells: const ['Unsichtbarkeit'],
  spentPactSlots: spentPactSlots,
);

void main() {
  group('SRD 5.2.1: Paktmagie nur mit konsistentem Klassenprofil', () {
    final malformed = <String, HeroCharacter>{
      'unbekannte Hauptklasse mit Warlock als Zweitklasse': _pactHero(
        primary: 'Unbekannt',
        secondary: 'Warlock',
        secondaryLevel: 4,
        level: 8,
      ),
      'unbekannte Zweitklasse mit Warlock als Hauptklasse': _pactHero(
        secondary: 'Unbekannt',
        secondaryLevel: 2,
        level: 7,
      ),
      'doppelte Klassen mit unterschiedlichen Aliasnamen': _pactHero(
        primary: 'Hexenmeister',
        secondary: 'Warlock',
        secondaryLevel: 5,
        level: 10,
      ),
      'Zweitklassenstufe ohne Zweitklassennamen': _pactHero(
        secondaryLevel: 1,
        level: 6,
      ),
      'Zweitklassennamen ohne Zweitklassenstufe': _pactHero(
        secondary: 'Fighter',
      ),
      'leerer Zweitklassenname mit Leerzeichen': _pactHero(
        secondary: ' ',
        secondaryLevel: 2,
        level: 7,
      ),
      'null Hauptklassenstufen': _pactHero(
        primary: 'Fighter',
        secondary: 'Warlock',
        secondaryLevel: 5,
        level: 5,
      ),
      'negative Zweitklassenstufe': _pactHero(
        secondaryLevel: -1,
      ),
      'Gesamtlevel null': _pactHero(level: 0),
      'Gesamtlevel über zwanzig': _pactHero(level: 21),
    };

    for (final entry in malformed.entries) {
      test('${entry.key}: null Paktplätze, kein Zauberverbrauch', () {
        final hero = entry.value;
        final original = hero.toJson();
        expect(SpellcastingRules.pactClassLevel(hero), 0);
        expect(SpellcastingRules.pactSlotCount(hero), 0);
        expect(SpellcastingRules.pactSlotLevel(hero), 0);
        expect(SpellcastingRules.availablePactSlots(hero), 0);
        expect(
          () => SpellcastingRules.cast(
            hero,
            spellName: 'Unsichtbarkeit',
            spellLevel: 1,
            pactMagic: true,
          ),
          throwsStateError,
        );
        expect(hero.toJson(), original);
        expect(hero.spentPactSlots, 0);
      });
    }

    test('verdeckter Verbrauch bei ungültigem Profil blockiert Kurzrast', () {
      final hero = _pactHero(
        primary: 'Hexenmeister',
        secondary: 'Warlock',
        secondaryLevel: 2,
        level: 6,
        spentPactSlots: 1,
      );
      final before = hero.toJson();
      expect(SpellcastingRules.pactClassLevel(hero), 0);
      expect(
        () => SpellcastingRules.availablePactSlots(hero),
        throwsFormatException,
      );
      expect(
        () => RestRules.validateShortRestResources(hero),
        throwsFormatException,
      );
      expect(hero.toJson(), before);
    });

    test('englischer Alias und deutsche Klasse teilen sich die Paktwerte', () {
      final english = _pactHero(primary: '  WARLOCK  ');
      final german = _pactHero(primary: 'Hexenmeister');
      for (final hero in [english, german]) {
        expect(SpellcastingRules.pactClassLevel(hero), 5);
        expect(SpellcastingRules.pactSlotCount(hero), 2);
        expect(SpellcastingRules.pactSlotLevel(hero), 3);
        expect(SpellcastingRules.availablePactSlots(hero), 2);
        final cast = SpellcastingRules.cast(
          hero,
          spellName: 'Unsichtbarkeit',
          spellLevel: 2,
          pactMagic: true,
          concentration: true,
        );
        expect(cast.slotLevel, 3);
        expect(cast.hero.spentPactSlots, 1);
        expect(cast.hero.concentratingOn, 'Unsichtbarkeit');
        expect(hero.spentPactSlots, 0);
      }
    });

    test('legale Zweitklasse Fighter 2 / Warlock 11 behält Slots', () {
      final hero = _pactHero(
        primary: 'Fighter',
        secondary: 'Warlock',
        secondaryLevel: 11,
        level: 13,
        spentPactSlots: 1,
      );
      final old = hero.toJson();
      expect(SpellcastingRules.pactClassLevel(hero), 11);
      expect(SpellcastingRules.pactSlotCount(hero), 3);
      expect(SpellcastingRules.pactSlotLevel(hero), 5);
      expect(SpellcastingRules.availablePactSlots(hero), 2);
      final restored = HeroCharacter.fromJson(hero.toJson());
      expect(restored.toJson(), old);
      expect(SpellcastingRules.availablePactSlots(restored), 2);
      final cast = SpellcastingRules.cast(
        restored,
        spellName: 'Unsichtbarkeit',
        spellLevel: 2,
        pactMagic: true,
      );
      expect(cast.hero.spentPactSlots, 2);
      expect(SpellcastingRules.availablePactSlots(cast.hero), 1);
      expect(hero.toJson(), old);
    });

    test('Warlock Stufe eins und zwanzig bleiben regelkonform', () {
      final novice = _pactHero(level: 1);
      expect(SpellcastingRules.pactClassLevel(novice), 1);
      expect(SpellcastingRules.pactSlotCount(novice), 1);
      expect(SpellcastingRules.pactSlotLevel(novice), 1);
      final master = _pactHero(level: 20, spentPactSlots: 3);
      expect(SpellcastingRules.pactClassLevel(master), 20);
      expect(SpellcastingRules.pactSlotCount(master), 4);
      expect(SpellcastingRules.pactSlotLevel(master), 5);
      expect(SpellcastingRules.availablePactSlots(master), 1);
    });

    test('Fremdklasse erhält auch ohne Profilfehler keine Paktplätze', () {
      final fighter = _pactHero(primary: 'Fighter');
      expect(SpellcastingRules.pactClassLevel(fighter), 0);
      expect(SpellcastingRules.pactSlotCount(fighter), 0);
      expect(SpellcastingRules.availablePactSlots(fighter), 0);
      expect(
        () => SpellcastingRules.cast(
          fighter,
          spellName: 'Unsichtbarkeit',
          spellLevel: 1,
          pactMagic: true,
        ),
        throwsStateError,
      );
    });
  });
}
