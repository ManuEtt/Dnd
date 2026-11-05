import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

HeroCharacter _hero({
  String first = 'Magier',
  String second = '',
  int secondLevel = 0,
  int level = 3,
  Map<String, int> slots = const {},
  int pact = 0,
  Map<String, int> dice = const {},
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
  spentSpellSlots: slots,
  spentPactSlots: pact,
  spentHitDice: dice,
);

void _rejectRest(HeroCharacter hero) {
  final before = hero.toJson();
  final spellsBefore = Map<String, int>.from(hero.spentSpellSlots);
  final pactBefore = hero.spentPactSlots;
  expect(() => RestRules.longRest(hero), throwsFormatException);
  expect(hero.toJson(), before);
  expect(hero.spentSpellSlots, spellsBefore);
  expect(hero.spentPactSlots, pactBefore);
  expect(hero.hitPoints, 12);
  expect(hero.concentratingOn, 'Unsichtbarkeit');
}

void main() {
  test('missing high-grade slots block long rest', () {
    _rejectRest(_hero(slots: const {'8': 1}));
  });

  test('overspent level-one spell slots block long rest', () {
    _rejectRest(_hero(level: 1, slots: const {'1': 3}));
  });

  test('negative normal spell slot use blocks long rest', () {
    _rejectRest(_hero(slots: const {'1': -1}));
  });

  test('noncanonical grade 01 blocks long rest', () {
    _rejectRest(_hero(slots: const {'01': 1}));
  });

  test('unrecognized grade 10 blocks long rest', () {
    _rejectRest(_hero(slots: const {'10': 1}));
  });

  test('overspent warlock pact slots block long rest', () {
    _rejectRest(_hero(first: 'Hexenmeister', level: 1, pact: 2));
  });

  test('pact spending without warlock blocks long rest', () {
    _rejectRest(_hero(pact: 1));
  });

  test('negative pact spending blocks long rest', () {
    _rejectRest(_hero(pact: -1));
  });

  test('valid wizard warlock multiclass regains both pools', () {
    final hero = _hero(
      first: 'Wizard',
      second: 'Warlock',
      level: 6,
      secondLevel: 3,
      slots: const {'1': 2, '2': 1},
      pact: 1,
      dice: const {'d6': 2, 'd8': 1},
    );
    final before = hero.toJson();
    expect(SpellcastingRules.availableSlots(hero), {1: 2, 2: 1});
    expect(SpellcastingRules.availablePactSlots(hero), 1);

    final rested = RestRules.longRest(hero);
    expect(rested.hitPoints, 20);
    expect(rested.spentSpellSlots, isEmpty);
    expect(rested.spentPactSlots, 0);
    expect(rested.spentHitDice, isEmpty);
    expect(rested.concentratingOn, isEmpty);
    expect(hero.toJson(), before);
    final decoded = HeroCharacter.fromJson(rested.toJson());
    expect(decoded.toJson(), rested.toJson());
  });

  test('legacy noncaster without spent slots keeps valid rest', () {
    final original = _hero(first: 'Fighter', level: 2);
    final before = original.toJson();
    final loaded = HeroCharacter.fromJson(before);
    expect(loaded.toJson(), before);
    expect(loaded.spentSpellSlots, isEmpty);
    expect(loaded.spentPactSlots, 0);

    final rested = RestRules.longRest(loaded);
    expect(rested.hitPoints, 20);
    expect(rested.spentSpellSlots, isEmpty);
    expect(rested.spentPactSlots, 0);
    expect(rested.preparedSpellRecord, isNull);
    expect(loaded.toJson(), before);
  });

  test('valid warlock pact slots return after long rest', () {
    final hero = _hero(first: 'Hexenmeister', level: 5, pact: 2);
    expect(SpellcastingRules.availablePactSlots(hero), 0);
    final rested = RestRules.longRest(hero);
    expect(rested.spentPactSlots, 0);
    expect(SpellcastingRules.availablePactSlots(rested), 2);
    expect(hero.spentPactSlots, 2);
  });
}
