import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

class LowRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

class HighRandom implements Random {
  @override
  int nextInt(int max) => max - 1;
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0.999;
}

HeroCharacter caster({String className = 'Magier', int level = 5,
    List<String> spells = const ['Magisches Geschoss', 'Unsichtbarkeit', 'Licht']}) =>
  HeroCharacter(id: 'arcane', name: 'Arina', species: 'Mensch',
    className: className, level: level, spells: spells,
    abilities: const {'strength': 10, 'dexterity': 12, 'constitution': 14,
      'intelligence': 16, 'wisdom': 12, 'charisma': 14},
    hitPoints: 12, maxHitPoints: 24, armorClass: 14, speed: 9,
    weaponDamage: '1d4');

void main() {
  group('SRD 5.2.1 Zauberplätze und Konzentration', () {
    test('Alte Spielstände haben unverbrauchte Zauberressourcen', () {
      final old = caster().toJson();
      expect(old.containsKey('spentSpellSlots'), isFalse);
      final reloaded = HeroCharacter.fromJson(old);
      expect(reloaded.spentSpellSlots, isEmpty);
      expect(reloaded.spentPactSlots, 0);
      expect(reloaded.concentratingOn, '');
      expect(SpellcastingRules.availableSlots(reloaded),
          {1: 4, 2: 3, 3: 2});
    });

    test('Zauberplatzverbrauch wird einmal gezählt und persistiert', () {
      final before = caster();
      final cast = SpellcastingRules.cast(before,
          spellName: 'Magisches Geschoss', spellLevel: 1, slotLevel: 3);
      expect(cast.slotLevel, 3);
      expect(cast.hero.spentSpellSlots, {'3': 1});
      expect(SpellcastingRules.availableSlots(cast.hero)[3], 1);
      expect(HeroCharacter.fromJson(cast.hero.toJson()).spentSpellSlots,
          {'3': 1});
      expect(before.spentSpellSlots, isEmpty);
      final last = SpellcastingRules.cast(cast.hero,
          spellName: 'Magisches Geschoss', spellLevel: 1, slotLevel: 3);
      expect(() => SpellcastingRules.cast(last.hero,
          spellName: 'Magisches Geschoss', spellLevel: 1, slotLevel: 3),
          throwsStateError);
    });

    test('Zaubertrick verbraucht keinen Platz; Konzentrationswechsel ersetzt alten', () {
      final hero = caster().copyWith(concentratingOn: 'Alter Zauber');
      final light = SpellcastingRules.cast(hero,
          spellName: 'Licht', spellLevel: 0);
      expect(light.hero.spentSpellSlots, isEmpty);
      expect(light.hero.concentratingOn, 'Alter Zauber');
      final invis = SpellcastingRules.cast(light.hero,
          spellName: 'Unsichtbarkeit', spellLevel: 2,
          concentration: true);
      expect(invis.hero.concentratingOn, 'Unsichtbarkeit');
      expect(SpellcastingRules.endConcentration(invis.hero).concentratingOn, '');
      expect(hero.concentratingOn, 'Alter Zauber');
    });

    test('Ungültige Zauber, Grad, Pool und fehlende Ressourcen werden abgewiesen', () {
      final wizard = caster();
      expect(() => SpellcastingRules.cast(wizard,
          spellName: 'Unbekannt', spellLevel: 1), throwsFormatException);
      expect(() => SpellcastingRules.cast(wizard,
          spellName: 'Licht', spellLevel: 10), throwsRangeError);
      expect(() => SpellcastingRules.cast(wizard,
          spellName: 'Unsichtbarkeit', spellLevel: 2, slotLevel: 1),
          throwsStateError);
      expect(() => SpellcastingRules.cast(wizard,
          spellName: 'Licht', spellLevel: 0, pactMagic: true),
          throwsFormatException);
      expect(() => SpellcastingRules.cast(wizard,
          spellName: 'Unsichtbarkeit', spellLevel: 2, pactMagic: true),
          throwsStateError);
      expect(() => SpellcastingRules.cast(wizard.copyWith(hitPoints: 0),
          spellName: 'Licht', spellLevel: 0), throwsStateError);
    });

    test('Paktmagie hat eigenen Ressourcenpool und feste Platzstufe', () {
      final warlock = caster(className: 'Hexenmeister');
      expect(SpellcastingRules.availableSlots(warlock), isEmpty);
      expect(SpellcastingRules.pactSlotLevel(warlock), 3);
      expect(SpellcastingRules.availablePactSlots(warlock), 2);
      final cast = SpellcastingRules.cast(warlock,
          spellName: 'Unsichtbarkeit', spellLevel: 2, pactMagic: true);
      expect(cast.slotLevel, 3);
      expect(cast.hero.spentPactSlots, 1);
      expect(cast.hero.spentSpellSlots, isEmpty);
      final both = SpellcastingRules.cast(cast.hero,
          spellName: 'Unsichtbarkeit', spellLevel: 2, pactMagic: true);
      expect(() => SpellcastingRules.cast(both.hero,
          spellName: 'Unsichtbarkeit', spellLevel: 2, pactMagic: true),
          throwsStateError);
      expect(SpellcastingRules.afterShortRest(both.hero).spentPactSlots, 0);
    });

    test('Mehrklassen trennen Paktmagie und normale Zauberplätze', () {
      final mix = caster(level: 3).copyWith(
          className: 'Magier', secondaryClassName: 'Hexenmeister',
          secondaryClassLevel: 2);
      expect(SpellcastingRules.availableSlots(mix), {1: 2});
      expect(SpellcastingRules.availablePactSlots(mix), 2);
      final spell = SpellcastingRules.cast(mix,
          spellName: 'Magisches Geschoss', spellLevel: 1);
      final pact = SpellcastingRules.cast(spell.hero,
          spellName: 'Magisches Geschoss', spellLevel: 1, pactMagic: true);
      expect(pact.hero.spentSpellSlots, {'1': 1});
      expect(pact.hero.spentPactSlots, 1);
      final rest = SpellcastingRules.afterShortRest(pact.hero);
      expect(rest.spentSpellSlots, {'1': 1});
      expect(rest.spentPactSlots, 0);
    });

    test('Konzentrations-SG 10 oder halber Schaden, Konstitutionsbonus einmal', () {
      final hero = caster().copyWith(concentratingOn: 'Unsichtbarkeit');
      expect(SpellcastingRules.concentrationDc(21), 10);
      expect(SpellcastingRules.concentrationDc(22), 11);
      expect(SpellcastingRules.concentrationDc(38), 19);
      expect(SpellcastingRules.concentrationDc(0), 10);
      expect(SpellcastingRules.concentrationDc(59), 29);
      expect(SpellcastingRules.concentrationDc(60), 30);
      expect(SpellcastingRules.concentrationDc(500), 30);
      expect(() => SpellcastingRules.concentrationDc(-1), throwsRangeError);
      final held = SpellcastingRules.saveAfterDamage(hero, damage: 21, d20: 8);
      expect(held.total, 10);
      expect(held.maintained, isTrue);
      expect(held.hero.concentratingOn, 'Unsichtbarkeit');
      final lost = SpellcastingRules.saveAfterDamage(hero, damage: 38, d20: 3);
      expect(lost.total, 5);
      expect(lost.maintained, isFalse);
      expect(lost.hero.concentratingOn, '');
    });

    test('Bewusstlosigkeit und tödliche Erschöpfung lösen Konzentration', () {
      final hero = caster().copyWith(hitPoints: 3,
          concentratingOn: 'Unsichtbarkeit');
      final down = RulesEngine.damage(hero, 5);
      expect(down.hitPoints, 0);
      expect(down.concentratingOn, '');
      expect(() => SpellcastingRules.cast(down,
          spellName: 'Licht', spellLevel: 0), throwsStateError);
    });

    test('Lange Rast lädt normale und Paktplätze auf und beendet Konzentration', () {
      final initial = caster(level: 3).copyWith(
          className: 'Magier', secondaryClassName: 'Hexenmeister',
          secondaryClassLevel: 2);
      final cast = SpellcastingRules.cast(initial,
          spellName: 'Magisches Geschoss', spellLevel: 1,
          concentration: true);
      final mixed = SpellcastingRules.cast(cast.hero,
          spellName: 'Magisches Geschoss', spellLevel: 1, pactMagic: true);
      final refreshed = RestRules.longRest(mixed.hero);
      expect(refreshed.spentSpellSlots, isEmpty);
      expect(refreshed.spentPactSlots, 0);
      expect(refreshed.concentratingOn, '');
      expect(refreshed.hitPoints, refreshed.maxHitPoints);
      expect(mixed.hero.spentPactSlots, 1);
    });

    test('Manipulierte Verbrauchszahlen und inkonsistente Pools werden abgewiesen', () {
      final original = caster(level: 1).toJson();
      for (final invalid in [
        {'0': 1}, {'3': 1}, {'1': 5}, {'1': -1},
        {'01': 1}, {'1': '2'}, {'9': 1},
      ]) {
        expect(() => HeroCharacter.fromJson({...original,
            'spentSpellSlots': invalid}), throwsFormatException);
      }
      for (final invalid in [-1, 5, '2']) {
        expect(() => HeroCharacter.fromJson({...original,
            'spentPactSlots': invalid}), throwsFormatException);
      }
      expect(() => HeroCharacter.fromJson({...original,
          'concentratingOn': '  Zauber  '}), throwsFormatException);
    });

    test('Gegnerangriff protokolliert den Konzentrationsrettungswurf', () {
      final engine = GameEngine(dice: DiceEngine(random: HighRandom()),
          clock: () => DateTime.utc(2026, 10, 15));
      var campaign = engine.createDemo();
      campaign = campaign.copyWith(hero: caster().copyWith(
          concentratingOn: 'Unsichtbarkeit', hitPoints: 24));
      campaign = engine.act(campaign, 'Ich gehe zum Waldschrein.').campaign;
      campaign = engine.act(campaign, 'Ich greife an.').campaign;
      expect(campaign.pendingRoll?.type, 'attack');
      final resolved = engine.resolveRoll(campaign, natural: 1);
      final enemyTurn = resolved.events.single.payload['enemyTurn'] as Map;
      expect(enemyTurn['hit'], true);
      expect(enemyTurn['concentrationSave'], isNotNull);
      expect(enemyTurn['concentrationDc'], 10);
      expect(enemyTurn['concentrationMaintained'], true);
      expect(resolved.campaign.hero.concentratingOn, 'Unsichtbarkeit');
      expect(Campaign.fromJson(resolved.campaign.toJson()).hero.concentratingOn,
          'Unsichtbarkeit');
    });

    test('Kurze Rast lädt Paktplätze auch bei vollen TP ohne Trefferwürfel', () {
      final engine = GameEngine(dice: DiceEngine(random: LowRandom()),
          clock: () => DateTime.utc(2026, 10, 15));
      final demo = engine.createDemo();
      final warlock = caster(className: 'Hexenmeister', level: 2)
          .copyWith(hitPoints: 24, maxHitPoints: 24, spentPactSlots: 1);
      final before = demo.copyWith(hero: warlock);
      final update = engine.act(before, 'Ich mache eine kurze Rast.');
      expect(update.events.single.type, 'character.shortRest');
      expect(update.campaign.hero.spentPactSlots, 0);
      expect(update.events.single.payload['pactSlotsRecovered'], 1);
    });
  });
}
