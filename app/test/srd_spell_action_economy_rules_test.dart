import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_action_economy_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'action-economy-wizard',
  name: 'Zugaktiver Zaubernder',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 10,
  },
  spells: const ['Magic Missile', 'Healing Word', 'Light'],
  hitPoints: 27,
  maxHitPoints: 27,
);

Encounter _fight({
  bool actionUsed = false,
  bool bonusUsed = false,
  bool slotUsed = false,
  bool surgeReserved = false,
  bool surgeUsed = false,
  int rageUntil = 0,
  int round = 1,
  String activeParticipant = 'hero',
  int enemyHp = 25,
}) => Encounter(
  id: 'encounter-1',
  enemyName: 'Schattenwächter',
  enemyHitPoints: enemyHp,
  enemyMaxHitPoints: 25,
  actionUsed: actionUsed,
  bonusActionUsed: bonusUsed,
  spellSlotExpendedThisTurn: slotUsed,
  surgeReserved: surgeReserved,
  surgeUsedThisTurn: surgeUsed,
  rageUntilRound: rageUntil,
  round: round,
  activeParticipant: activeParticipant,
);

SrdSpellTurnActionEvidence _inspect(
  SrdSpellDefinition spell, {
  HeroCharacter? hero,
  Encounter? encounter,
  bool currentConfirmed = true,
  bool outOfCombatConfirmed = false,
}) => SrdSpellActionEconomyRules.inspect(
  hero: hero ?? _hero(),
  spell: spell,
  encounter: encounter,
  currentEncounterConfirmed: currentConfirmed,
  noActiveEncounterConfirmed: outOfCombatConfirmed,
);

SrdSpellDefinition _alter(
  SrdSpellDefinition spell, {
  String? castingTime,
  bool? ritual,
  int? level,
}) => SrdSpellDefinition(
  id: spell.id,
  name: spell.name,
  level: level ?? spell.level,
  school: spell.school,
  classes: spell.classes,
  castingTime: castingTime ?? spell.castingTime,
  range: spell.range,
  components: spell.components,
  duration: spell.duration,
  verbal: spell.verbal,
  somatic: spell.somatic,
  material: spell.material,
  concentration: spell.concentration,
  ritual: ritual ?? spell.ritual,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('Magic action and bonus action are separate independent turn uses', () {
    final normal = catalog.find('Magic Missile')!;
    final bonus = catalog.find('Healing Word')!;
    final free = _fight();
    expect(
      _inspect(normal, encounter: free).action,
      SrdSpellTurnAction.magicAction,
    );
    expect(
      _inspect(bonus, encounter: free).action,
      SrdSpellTurnAction.bonusAction,
    );

    final usedAction = _fight(actionUsed: true);
    expect(
      () => _inspect(normal, encounter: usedAction),
      throwsStateError,
    );
    expect(
      _inspect(bonus, encounter: usedAction).action,
      SrdSpellTurnAction.bonusAction,
    );

    final usedBonus = _fight(bonusUsed: true);
    expect(
      () => _inspect(bonus, encounter: usedBonus),
      throwsStateError,
    );
    expect(
      _inspect(normal, encounter: usedBonus).action,
      SrdSpellTurnAction.magicAction,
    );
    expect(() => _inspect(normal, encounter: _fight(
      actionUsed: true,
      bonusUsed: true,
    )), throwsStateError);
    expect(() => _inspect(bonus, encounter: _fight(
      actionUsed: true,
      bonusUsed: true,
    )), throwsStateError);
  });

  test('already spent spell slot rejects leveled spells, not cantrips', () {
    final spent = _fight(slotUsed: true);
    final normal = catalog.find('Magic Missile')!;
    final bonus = catalog.find('Healing Word')!;
    final cantrip = catalog.find('Light')!;
    expect(
      () => _inspect(normal, encounter: spent),
      throwsStateError,
    );
    expect(
      () => _inspect(bonus, encounter: spent),
      throwsStateError,
    );
    final permitted = _inspect(cantrip, encounter: spent);
    expect(permitted.expendSpellSlot, isFalse);
    expect(permitted.action, SrdSpellTurnAction.magicAction);
    final first = _inspect(normal, encounter: _fight());
    expect(first.expendSpellSlot, isTrue);
  });

  test('Action Surge never grants a Magic action but not a bonus action', () {
    final normal = catalog.find('Magic Missile')!;
    final bonus = catalog.find('Healing Word')!;
    for (final encounter in [
      _fight(surgeReserved: true),
      _fight(surgeUsed: true),
    ]) {
      expect(
        () => _inspect(normal, encounter: encounter),
        throwsStateError,
      );
      expect(
        _inspect(bonus, encounter: encounter).action,
        SrdSpellTurnAction.bonusAction,
      );
    }
  });

  test('actual own active turn, no rage and positive HP are required', () {
    final normal = catalog.find('Magic Missile')!;
    for (final encounter in [
      _fight(activeParticipant: 'enemy'),
      _fight(activeParticipant: 'unknown'),
      _fight(enemyHp: 0),
      _fight(rageUntil: 1),
    ]) {
      expect(() => _inspect(normal, encounter: encounter), throwsStateError);
    }
    for (final hero in [
      _hero().copyWith(hitPoints: 0),
      _hero().copyWith(conditions: ['bewusstlos']),
      _hero().copyWith(conditions: ['handlungsunfähig']),
      _hero().copyWith(conditions: ['tot']),
    ]) {
      expect(
        () => _inspect(normal, hero: hero, encounter: _fight()),
        throwsStateError,
      );
    }
    expect(
      _inspect(normal, encounter: _fight(rageUntil: 1, round: 2)).inCombat,
      isTrue,
    );
  });

  test('unknown combat state cannot silently pretend to be outside combat', () {
    final spell = catalog.find('Magic Missile')!;
    expect(
      () => _inspect(spell, encounter: null),
      throwsFormatException,
    );
    expect(
      () => _inspect(
        spell,
        encounter: _fight(),
        currentConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => _inspect(
        spell,
        encounter: _fight(),
        outOfCombatConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(
      () => _inspect(
        spell,
        encounter: null,
        outOfCombatConfirmed: true,
      ),
      throwsFormatException,
    );
    final outside = _inspect(
      spell,
      encounter: null,
      currentConfirmed: false,
      outOfCombatConfirmed: true,
    );
    expect(outside.inCombat, isFalse);
    expect(outside.encounterSnapshot, isNull);
  });

  test('ritual Action is ordinary magic but triggered times stay blocked', () {
    final detect = catalog.find('Detect Magic')!;
    final result = _inspect(detect, encounter: _fight());
    expect(result.action, SrdSpellTurnAction.magicAction);
    expect(result.expendSpellSlot, isTrue);
    for (final name in ['Counterspell', 'Divine Smite', 'Find Familiar']) {
      expect(
        () => _inspect(catalog.find(name)!, encounter: _fight()),
        throwsUnsupportedError,
        reason: name,
      );
    }
    for (final bad in [
      _alter(detect, ritual: false),
      _alter(catalog.find('Magic Missile')!, ritual: true),
      _alter(catalog.find('Healing Word')!, ritual: true),
    ]) {
      expect(() => _inspect(bad, encounter: _fight()), throwsFormatException);
    }
  });

  test('unknown action or spoofed timing does not get normalized', () {
    final normal = catalog.find('Magic Missile')!;
    for (final value in [
      ' Action',
      'Action ',
      'action',
      'Action\u200b',
      'Bonus Action, which you take after attacking',
      'Reaction, which you take when hit',
      'Action or Ritual ',
      '1 minute',
      'Special',
    ]) {
      expect(
        () => _inspect(_alter(normal, castingTime: value), encounter: _fight()),
        throwsUnsupportedError,
        reason: value,
      );
    }
    expect(
      () => _inspect(_alter(normal, level: 10), encounter: _fight()),
      throwsFormatException,
    );
  });

  test('approval binds hero, encounter and all spell metadata snapshots', () {
    final hero = _hero();
    final encounter = _fight();
    final spell = catalog.find('Magic Missile')!;
    final beforeHero = jsonEncode(hero.toJson());
    final beforeFight = jsonEncode(encounter.toJson());
    final proof = _inspect(spell, hero: hero, encounter: encounter);
    proof.validateUnchanged(hero: hero, spell: spell, encounter: encounter);
    proof.validateUnchanged(
      hero: HeroCharacter.fromJson(hero.toJson()),
      spell: spell,
      encounter: Encounter.fromJson(encounter.toJson()),
    );
    for (final changed in [
      _fight(actionUsed: true),
      _fight(bonusUsed: true),
      _fight(slotUsed: true),
      _fight(activeParticipant: 'enemy'),
    ]) {
      expect(
        () => proof.validateUnchanged(
          hero: hero,
          spell: spell,
          encounter: changed,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => proof.validateUnchanged(
        hero: hero.copyWith(gold: 17),
        spell: spell,
        encounter: encounter,
      ),
      throwsFormatException,
    );
    expect(
      () => proof.validateUnchanged(
        hero: hero,
        spell: _alter(spell, castingTime: 'Bonus Action'),
        encounter: encounter,
      ),
      throwsFormatException,
    );
    expect(jsonEncode(hero.toJson()), beforeHero);
    expect(jsonEncode(encounter.toJson()), beforeFight);
    expect(proof.action, SrdSpellTurnAction.magicAction);
  });
}
