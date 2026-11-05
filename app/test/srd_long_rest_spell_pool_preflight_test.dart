import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

HeroCharacter _hero({
  String first = 'Magier',
  String second = '',
  int secondLevel = 0,
  int level = 3,
  Map<String, int> spentSpellSlots = const {},
  int spentPactSlots = 0,
  Map<String, int> spentHitDice = const {},
}) => HeroCharacter(
  id: 'long-rest-spell-source',
  name: 'Rastprobe',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  level: level,
  hitPoints: 12,
  maxHitPoints: 20,
  concentratingOn: 'Unsichtbarkeit',
  spentSpellSlots: spentSpellSlots,
  spentPactSlots: spentPactSlots,
  spentHitDice: spentHitDice,
);

void main() {
  group('Lange Rast: ursprüngliche Zauberpools validieren', () {
    final invalid = <String, HeroCharacter>{
      'Zaubergrad ohne Plätze': _hero(spentSpellSlots: const {'8': 1}),
      'zu viele verbrauchte normale Plätze': _hero(
        level: 1,
        spentSpellSlots: const {'1': 3},
      ),
      'negativer normaler Verbrauch': _hero(spentSpellSlots: const {'1': -1}),
      'ungültiger Grad 01': _hero(spentSpellSlots: const {'01': 1}),
      'fremder Gradschlüssel': _hero(spentSpellSlots: const {'10': 1}),
      'Paktplätze über Klassengrenze': _hero(
        first: 'Hexenmeister',
        level: 1,
        spentPactSlots: 2,
      ),
      'Paktverbrauch ohne Hexenmeister': _hero(spentPactSlots: 1),
      'negativer Paktverbrauch': _hero(spentPactSlots: -1),
    };

    for (final entry in invalid.entries) {
      test('${entry.key}: keine stillschweigende Ressourcenreparatur', () {
        final hero = entry.value;
        final before = hero.toJson();
        final initialSpells = Map<String, int>.from(hero.spentSpellSlots);
        final initialPactSlots = hero.spentPactSlots;

        expect(() => RestRules.longRest(hero), throwsFormatException);
        expect(hero.toJson(), before);
        expect(hero.spentSpellSlots, initialSpells);
        expect(hero.spentPactSlots, initialPactSlots);
        expect(hero.hitPoints, 12);
        expect(hero.concentratingOn, 'Unsichtbarkeit');
      });
    }

    test('gültige Mehrklasse regeneriert beide Slotpools', () {
      final hero = _hero(
        first: 'Wizard',
        second: 'Warlock',
        level: 6,
        secondLevel: 3,
        spentSpellSlots: const {'1': 2, '2': 1},
        spentPactSlots: 1,
        spentHitDice: const {'d6': 2, 'd8': 1},
      );
      final initial = hero.toJson();
      expect(SpellcastingRules.availableSlots(hero), {1: 2, 2: 1});
      expect(SpellcastingRules.availablePactSlots(hero), 1);

      final rested = RestRules.longRest(hero);
      expect(rested.hitPoints, 20);
      expect(rested.spentSpellSlots, isEmpty);
      expect(rested.spentPactSlots, 0);
      expect(rested.spentHitDice, isEmpty);
      expect(rested.concentratingOn, isEmpty);
      expect(hero.toJson(), initial);
      final reloaded = HeroCharacter.fromJson(rested.toJson());
      expect(reloaded.toJson(), rested.toJson());
    });

    test('Altspielstand ohne Zauberverbrauch bleibt gültig', () {
      final oldHero = _hero(first: 'Fighter', level: 2);
      final original = oldHero.toJson();
      final loaded = HeroCharacter.fromJson(original);
      expect(loaded.toJson(), original);
      expect(loaded.spentSpellSlots, isEmpty);
      expect(loaded.spentPactSlots, 0);

      final rested = RestRules.longRest(loaded);
      expect(rested.hitPoints, 20);
      expect(rested.spentSpellSlots, isEmpty);
      expect(rested.spentPactSlots, 0);
      expect(rested.preparedSpellRecord, isNull);
      expect(loaded.toJson(), original);
    });

    test('rechtmäßige Hexenmeister-Paktplätze werden zurückgesetzt', () {
      final hero = _hero(
        first: 'Hexenmeister',
        level: 5,
        spentPactSlots: 2,
      );
      expect(SpellcastingRules.availablePactSlots(hero), 0);
      final after = RestRules.longRest(hero);
      expect(after.spentPactSlots, 0);
      expect(SpellcastingRules.availablePactSlots(after), 2);
      expect(hero.spentPactSlots, 2);
    });
  });
}
