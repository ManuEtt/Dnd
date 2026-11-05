import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_turn_transaction_rules.dart';

HeroCharacter _hero({
  String first = 'Magier',
  String second = 'Zauberer',
  int level = 6,
  int secondLevel = 3,
}) => HeroCharacter(
  id: 'class-confirmed-turn',
  name: 'Klassenquelle',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  level: level,
  spells: const ['Magisches Geschoss'],
  hitPoints: 20,
  maxHitPoints: 20,
);

Encounter _encounter({bool usedAction = false}) => Encounter(
  id: 'confirmed-turn',
  enemyName: 'Schatten',
  enemyHitPoints: 20,
  enemyMaxHitPoints: 20,
  activeParticipant: 'hero',
  actionUsed: usedAction,
);

SrdSpellTurnPlan _prepare({
  required HeroCharacter hero,
  required Encounter encounter,
  required SrdSpellDefinition spell,
  String castingClass = 'Wizard',
  bool classConfirmed = false,
  bool pactMagic = false,
  int? slotLevel,
}) => SrdSpellTurnTransactionRules.prepare(
  hero: hero,
  encounter: encounter,
  spell: spell,
  castingClass: castingClass,
  slotLevel: slotLevel ?? spell.level,
  pactMagic: pactMagic,
  preparedForCastingClassConfirmed: classConfirmed,
  currentEncounterConfirmed: true,
  noActiveEncounterConfirmed: false,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: true,
);

SrdSpellTurnStagedResult _stage({
  required HeroCharacter hero,
  required Encounter encounter,
  required SrdSpellTurnPlan plan,
}) => SrdSpellTurnTransactionRules.stageConfirmed(
  hero: hero,
  encounter: encounter,
  plan: plan,
  effectResolvedSeparatelyConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('ambiguous legacy spell needs class confirmation', () {
    final hero = _hero();
    final encounter = _encounter();
    final before = hero.toJson();
    final fightBefore = encounter.toJson();
    expect(
      () => _prepare(
        hero: hero,
        encounter: encounter,
        spell: catalog.find('Magic Missile')!,
      ),
      throwsFormatException,
    );
    expect(hero.toJson(), before);
    expect(encounter.toJson(), fightBefore);
    expect(hero.spentSpellSlots, isEmpty);
  });

  test('confirmed Wizard class stages exactly one Magic Action and slot', () {
    final hero = _hero();
    final encounter = _encounter();
    final before = hero.toJson();
    final fightBefore = encounter.toJson();
    final plan = _prepare(
      hero: hero,
      encounter: encounter,
      spell: catalog.find('Magic Missile')!,
      classConfirmed: true,
    );
    expect(plan.spellPlan.castingClass, 'Magier');
    final result = _stage(hero: hero, encounter: encounter, plan: plan);
    expect(result.hero.spentSpellSlots, {'1': 1});
    expect(result.hero.spentPactSlots, 0);
    expect(result.encounter!.actionUsed, isTrue);
    expect(result.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(result.encounter!.bonusActionUsed, isFalse);
    expect(hero.toJson(), before);
    expect(encounter.toJson(), fightBefore);
  });

  test('confirmed Sorcerer alias also stages the same shared spell', () {
    final hero = _hero();
    final encounter = _encounter();
    final plan = _prepare(
      hero: hero,
      encounter: encounter,
      spell: catalog.find('Magic Missile')!,
      castingClass: 'Sorcerer',
      classConfirmed: true,
    );
    expect(plan.spellPlan.castingClass, 'Zauberer');
    final result = _stage(hero: hero, encounter: encounter, plan: plan);
    expect(result.hero.spentSpellSlots, {'1': 1});
    expect(result.encounter!.actionUsed, isTrue);
  });

  test('confirmation does not authorize an unowned class or invalid slot', () {
    final hero = _hero();
    final encounter = _encounter();
    final before = hero.toJson();
    final spell = catalog.find('Magic Missile')!;
    expect(
      () => _prepare(
        hero: hero,
        encounter: encounter,
        spell: spell,
        castingClass: 'Cleric',
        classConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(
      () => _prepare(
        hero: hero,
        encounter: encounter,
        spell: spell,
        classConfirmed: true,
        slotLevel: 0,
      ),
      throwsFormatException,
    );
    expect(hero.toJson(), before);
    expect(encounter.actionUsed, isFalse);
  });

  test('stale hero or encounter cannot stage a confirmed spell plan', () {
    final hero = _hero();
    final encounter = _encounter();
    final plan = _prepare(
      hero: hero,
      encounter: encounter,
      spell: catalog.find('Magic Missile')!,
      classConfirmed: true,
    );
    final changedHero = hero.copyWith(gold: 5);
    final changedEncounter = _encounter(usedAction: true);
    expect(
      () => _stage(hero: changedHero, encounter: encounter, plan: plan),
      throwsFormatException,
    );
    expect(
      () => _stage(hero: hero, encounter: changedEncounter, plan: plan),
      throwsFormatException,
    );
    expect(hero.spentSpellSlots, isEmpty);
    expect(changedHero.spentSpellSlots, isEmpty);
    expect(encounter.actionUsed, isFalse);
  });

  test('JSON restart preserves proof and blocks replay', () {
    final hero = _hero();
    final encounter = _encounter();
    final plan = _prepare(
      hero: hero,
      encounter: encounter,
      spell: catalog.find('Magic Missile')!,
      classConfirmed: true,
    );
    final restoredHero = HeroCharacter.fromJson(hero.toJson());
    final restoredEncounter = Encounter.fromJson(encounter.toJson());
    final result = _stage(
      hero: restoredHero,
      encounter: restoredEncounter,
      plan: plan,
    );
    expect(result.hero.spentSpellSlots, {'1': 1});
    expect(result.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(
      () => _stage(
        hero: result.hero,
        encounter: result.encounter!,
        plan: plan,
      ),
      throwsFormatException,
    );
    expect(hero.spentSpellSlots, isEmpty);
    expect(encounter.actionUsed, isFalse);
    expect(restoredHero.toJson(), hero.toJson());
  });

  test('Wizard spell can stage with Warlock Pact slot independently', () {
    final hero = _hero(second: 'Warlock');
    final encounter = _encounter();
    final before = hero.toJson();
    final plan = _prepare(
      hero: hero,
      encounter: encounter,
      spell: catalog.find('Magic Missile')!,
      pactMagic: true,
      slotLevel: 2,
    );
    expect(plan.spellPlan.castingClass, 'Magier');
    expect(plan.spellPlan.pactMagic, isTrue);
    final result = _stage(hero: hero, encounter: encounter, plan: plan);
    expect(result.hero.spentPactSlots, 1);
    expect(result.hero.spentSpellSlots, isEmpty);
    expect(result.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(hero.toJson(), before);
  });

  test('unambiguous single-class spell keeps existing no-approval path', () {
    final hero = _hero(second: '', secondLevel: 0);
    final encounter = _encounter();
    final plan = _prepare(
      hero: hero,
      encounter: encounter,
      spell: catalog.find('Magic Missile')!,
    );
    expect(plan.spellPlan.castingClass, 'Magier');
    final result = _stage(hero: hero, encounter: encounter, plan: plan);
    expect(result.hero.spentSpellSlots, {'1': 1});
  });
}
