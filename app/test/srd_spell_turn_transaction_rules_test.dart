import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_action_economy_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_turn_transaction_rules.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'atomic-spell-hero',
  name: 'Arkana',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 18,
    'wisdom': 12,
    'charisma': 10,
  },
  spells: const ['Magic Missile', 'Misty Step', 'Fire Bolt', 'Detect Magic'],
  hitPoints: 25,
  maxHitPoints: 25,
);

Encounter _fight({
  bool actionUsed = false,
  bool bonusUsed = false,
  bool slotUsed = false,
  String active = 'hero',
  bool surgeReserved = false,
}) => Encounter(
  id: 'fight-1',
  enemyName: 'Schatten',
  enemyHitPoints: 24,
  enemyMaxHitPoints: 24,
  activeParticipant: active,
  actionUsed: actionUsed,
  bonusActionUsed: bonusUsed,
  spellSlotExpendedThisTurn: slotUsed,
  surgeReserved: surgeReserved,
);

SrdSpellTurnPlan _prepare(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  Encounter? encounter,
  bool inCombat = true,
  bool actionConfirmed = true,
  bool targetConfirmed = true,
  bool outOfCombatSlotConfirmed = false,
}) => SrdSpellTurnTransactionRules.prepare(
  hero: hero,
  spell: spell,
  castingClass: 'Magier',
  slotLevel: spell.level,
  encounter: encounter,
  currentEncounterConfirmed: inCombat,
  noActiveEncounterConfirmed: !inCombat,
  noSlotSpentOutsideEncounterConfirmed: outOfCombatSlotConfirmed,
  actionAvailableConfirmed: actionConfirmed,
  targetRulesConfirmed: targetConfirmed,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: true,
);

SrdSpellTurnStagedResult _stage(
  HeroCharacter hero,
  Encounter? encounter,
  SrdSpellTurnPlan plan, {
  bool effectConfirmed = true,
  bool outsideConfirmed = false,
}) => SrdSpellTurnTransactionRules.stageConfirmed(
  hero: hero,
  encounter: encounter,
  plan: plan,
  effectResolvedSeparatelyConfirmed: effectConfirmed,
  outsideEncounterStillConfirmed: outsideConfirmed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('Magic Action spends action and exactly one slot in staged state', () {
    final hero = _hero();
    final fight = _fight();
    final originalHero = jsonEncode(hero.toJson());
    final originalFight = jsonEncode(fight.toJson());
    final prepared = _prepare(hero, catalog.find('Magic Missile')!, encounter: fight);
    final result = _stage(hero, fight, prepared);

    expect(result.action, SrdSpellTurnAction.magicAction);
    expect(result.encounter!.actionUsed, isTrue);
    expect(result.encounter!.bonusActionUsed, isFalse);
    expect(result.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(result.hero.spentSpellSlots['1'], 1);
    expect(result.cast.slotLevel, 1);
    expect(jsonEncode(hero.toJson()), originalHero);
    expect(jsonEncode(fight.toJson()), originalFight);
    expect(
      () => _stage(result.hero, result.encounter, prepared),
      throwsFormatException,
    );
  });

  test('Bonus Action spends only bonus action and a level-two slot', () {
    final hero = _hero();
    final fight = _fight(actionUsed: true);
    final prepared = _prepare(hero, catalog.find('Misty Step')!, encounter: fight);
    final result = _stage(hero, fight, prepared);

    expect(result.action, SrdSpellTurnAction.bonusAction);
    expect(result.encounter!.actionUsed, isTrue);
    expect(result.encounter!.bonusActionUsed, isTrue);
    expect(result.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(result.hero.spentSpellSlots['2'], 1);
    expect(hero.spentSpellSlots, isEmpty);
  });

  test('used turn action, bonus action and slot cannot be replayed', () {
    final hero = _hero();
    final action = catalog.find('Magic Missile')!;
    final bonus = catalog.find('Misty Step')!;
    expect(
      () => _prepare(hero, action, encounter: _fight(actionUsed: true)),
      throwsStateError,
    );
    expect(
      () => _prepare(hero, bonus, encounter: _fight(bonusUsed: true)),
      throwsStateError,
    );
    for (final spell in [action, bonus]) {
      expect(
        () => _prepare(hero, spell, encounter: _fight(slotUsed: true)),
        throwsStateError,
      );
    }
    expect(
      () => _prepare(hero, action, encounter: _fight(surgeReserved: true)),
      throwsStateError,
    );
    expect(
      _prepare(hero, bonus, encounter: _fight(surgeReserved: true))
          .actionEvidence.action,
      SrdSpellTurnAction.bonusAction,
    );
  });

  test('cantrip stages Magic Action without expending another slot', () {
    final hero = _hero();
    final fight = _fight(slotUsed: true);
    final plan = _prepare(hero, catalog.find('Fire Bolt')!, encounter: fight);
    final result = _stage(hero, fight, plan);
    expect(result.encounter!.actionUsed, isTrue);
    expect(result.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(result.hero.spentSpellSlots, isEmpty);
    expect(result.cast.slotLevel, 0);
  });

  test('not confirmed spell effect or intended action blocks both changes', () {
    final hero = _hero();
    final fight = _fight();
    final spell = catalog.find('Magic Missile')!;
    expect(
      () => _prepare(hero, spell, encounter: fight, actionConfirmed: false),
      throwsFormatException,
    );
    expect(
      () => _prepare(hero, spell, encounter: fight, targetConfirmed: false),
      throwsFormatException,
    );
    final plan = _prepare(hero, spell, encounter: fight);
    expect(
      () => _stage(hero, fight, plan, effectConfirmed: false),
      throwsStateError,
    );
    expect(hero.spentSpellSlots, isEmpty);
    expect(fight.actionUsed, isFalse);
    expect(fight.spellSlotExpendedThisTurn, isFalse);
  });

  test('encounter and hero changes invalidate a prepared transaction', () {
    final hero = _hero();
    final fight = _fight();
    final plan = _prepare(hero, catalog.find('Magic Missile')!, encounter: fight);
    for (final changed in [
      _fight(actionUsed: true),
      _fight(bonusUsed: true),
      _fight(slotUsed: true),
      _fight(active: 'enemy'),
    ]) {
      expect(() => _stage(hero, changed, plan), throwsFormatException);
    }
    expect(
      () => _stage(hero.copyWith(gold: 5), fight, plan),
      throwsFormatException,
    );
    expect(
      () => _stage(hero, null, plan),
      throwsFormatException,
    );
    final restoredHero = HeroCharacter.fromJson(hero.toJson());
    final restoredFight = Encounter.fromJson(fight.toJson());
    final valid = _stage(restoredHero, restoredFight, plan);
    expect(valid.encounter!.actionUsed, isTrue);
  });

  test('unknown/out-of-combat turns must be confirmed both times', () {
    final hero = _hero();
    final leveled = catalog.find('Magic Missile')!;
    final cantrip = catalog.find('Fire Bolt')!;

    expect(
      () => _prepare(hero, leveled, inCombat: false),
      throwsFormatException,
    );
    final plan = _prepare(
      hero, leveled,
      inCombat: false,
      outOfCombatSlotConfirmed: true,
    );
    expect(() => _stage(hero, null, plan), throwsFormatException);
    final staged = _stage(hero, null, plan, outsideConfirmed: true);
    expect(staged.encounter, isNull);
    expect(staged.hero.spentSpellSlots['1'], 1);

    final free = _prepare(hero, cantrip, inCombat: false);
    final finished = _stage(hero, null, free, outsideConfirmed: true);
    expect(finished.encounter, isNull);
    expect(finished.hero.spentSpellSlots, isEmpty);
  });

  test('invalid turn and unsupported triggers never mint staged outcomes', () {
    final hero = _hero();
    final fight = _fight();
    expect(
      () => _prepare(hero, catalog.find('Shield')!, encounter: fight),
      throwsUnsupportedError,
    );
    expect(
      () => _prepare(hero, catalog.find('Find Familiar')!, encounter: fight),
      throwsUnsupportedError,
    );
    expect(
      () => _prepare(hero, catalog.find('Magic Missile')!,
        encounter: _fight(active: 'enemy')),
      throwsStateError,
    );
    expect(
      () => _prepare(hero.copyWith(hitPoints: 0),
        catalog.find('Magic Missile')!, encounter: fight),
      throwsStateError,
    );
  });

  test('concentration is updated only in returned staged hero', () {
    final hero = _hero().copyWith(concentratingOn: 'Old Spell');
    final fight = _fight();
    final spell = catalog.find('Detect Magic')!;
    final plan = _prepare(hero, spell, encounter: fight);
    final staged = _stage(hero, fight, plan);
    expect(staged.hero.concentratingOn, 'Detect Magic');
    expect(hero.concentratingOn, 'Old Spell');
    expect(staged.encounter!.actionUsed, isTrue);
    expect(staged.encounter!.spellSlotExpendedThisTurn, isTrue);
  });
}
