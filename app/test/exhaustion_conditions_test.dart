import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

HeroCharacter hero({int level = 0, int hp = 8}) => HeroCharacter(
  id: 'exhausted-hero', name: 'Liora', species: 'Mensch',
  className: 'Kämpfer', level: 2,
  abilities: const {
    'strength': 16, 'dexterity': 14, 'constitution': 12,
    'intelligence': 10, 'wisdom': 10, 'charisma': 10,
  },
  hitPoints: hp, maxHitPoints: 15, armorClass: 16, speed: 9,
  weaponDamage: '1d8', weaponProficient: true,
  exhaustionLevel: level,
);

void main() {
  group('SRD 5.2.1 Erschöpfung', () {
    test('Schema-1-Altdaten bleiben kompatibel, neue Werte persistieren', () {
      final old = hero().toJson();
      expect(old.containsKey('exhaustionLevel'), isFalse);
      final restored = HeroCharacter.fromJson(old);
      expect(restored.exhaustionLevel, 0);
      final exhausted = restored.copyWith(exhaustionLevel: 3);
      expect(HeroCharacter.fromJson(exhausted.toJson()).exhaustionLevel, 3);
      expect(restored.exhaustionLevel, 0);
      for (final invalid in [-1, 7, '3', 2.5, true]) {
        expect(() => HeroCharacter.fromJson({...old,
          'exhaustionLevel': invalid}), throwsFormatException);
      }
    });

    test('jede Stufe: −2 auf W20 und −1.5 m Bewegung; Basis bleibt', () {
      final bruised = hero(level: 3);
      expect(ExhaustionRules.d20Modifier(bruised), -6);
      expect(ExhaustionRules.effectiveSpeedMeters(bruised), 4.5);
      expect(ExhaustionRules.availableWholeMeters(bruised), 4);
      expect(bruised.speed, 9);
      expect(ExhaustionRules.effectiveSpeedMeters(hero(level: 0)), 9);
      expect(ExhaustionRules.effectiveSpeedMeters(hero(level: 5)), 1.5);
      expect(ExhaustionRules.effectiveSpeedMeters(hero(level: 6)), 0);
      expect(ExhaustionRules.effectiveSpeedMeters(
        hero().copyWith(speed: null)), null);
    });

    test('Angriff/Initiative werden einmal reduziert, nicht Waffenschaden', () {
      final normal = hero();
      final exhausted = hero(level: 2);
      expect(RulesEngine.attackBonus(normal) - RulesEngine.attackBonus(exhausted), 4);
      expect(RulesEngine.initiativeBonus(normal) -
          RulesEngine.initiativeBonus(exhausted), 4);
    });

    test('Stufe 6 bedeutet Tod, Sättigung und Heilung bleibt blockiert', () {
      final before = hero(level: 5);
      final dead = ExhaustionRules.gain(before, levels: 2);
      expect(dead.exhaustionLevel, 6);
      expect(dead.isDead, true);
      expect(dead.conditions.where((v) => v == 'tot').length, 1);
      expect(HeroCharacter.fromJson(dead.toJson()).isDead, true);
      expect(() => RulesEngine.heal(dead, 1), throwsStateError);
      expect(() => RestRules.longRest(dead), throwsStateError);
      expect(before.exhaustionLevel, 5);
      expect(() => ExhaustionRules.gain(hero(), levels: 0), throwsRangeError);
      expect(() => ExhaustionRules.gain(dead), throwsStateError);
    });

    test('lange Rast senkt Erschöpfung genau um eine Stufe', () {
      final before = hero(level: 3, hp: 3);
      final after = RestRules.longRest(before);
      expect(after.exhaustionLevel, 2);
      expect(after.hitPoints, 15);
      expect(before.exhaustionLevel, 3);
      expect(RestRules.longRest(hero()).exhaustionLevel, 0);
    });

    test('Todesrettungswurf berücksichtigt Erschöpfung nur beim Testwert', () {
      final normal = hero(hp: 0).copyWith(conditions: ['bewusstlos']);
      final exhausted = normal.copyWith(exhaustionLevel: 1);
      expect(RulesEngine.deathSave(normal, 10).deathSuccesses, 1);
      expect(RulesEngine.deathSave(exhausted, 10).deathFailures, 1);
      expect(RulesEngine.deathSave(exhausted, 1).deathFailures, 2);
      expect(RulesEngine.deathSave(exhausted, 20).hitPoints, 1);
    });
  });

  group('Zustandsauswertung ohne automatische Quellenannahme', () {
    test('alle 14 SRD-Zustände haben eine Erklärung', () {
      expect(ConditionRules.descriptions.length, 14);
      expect(ConditionRules.descriptions.containsKey('blind'), true);
      expect(ConditionRules.descriptions.containsKey('bewusstlos'), true);
    });
    test('Handlungs- und Bewegungsverbote werden konservativ geprüft', () {
      expect(ConditionRules.canTakeActions(hero()), true);
      expect(ConditionRules.canTakeActions(
        hero().copyWith(conditions: ['gelähmt'])), false);
      expect(ConditionRules.canMove(
        hero().copyWith(conditions: ['gepackt'])), false);
      expect(ConditionRules.canTakeActions(
        hero().copyWith(conditions: ['gepackt'])), true);
      // Incapacitated prohibits actions, not movement on its own.
      expect(ConditionRules.canTakeActions(
        hero().copyWith(conditions: ['handlungsunfähig'])), false);
      expect(ConditionRules.canMove(
        hero().copyWith(conditions: ['handlungsunfähig'])), true);
      expect(ConditionRules.canTakeActions(hero(level: 6)), false);
      expect(ConditionRules.hasUnconditionalAttackDisadvantage(
        hero().copyWith(conditions: ['vergiftet'])), true);
      expect(ConditionRules.hasUnconditionalAttackDisadvantage(
        hero().copyWith(conditions: ['verängstigt'])), false);
    });
  });
}
