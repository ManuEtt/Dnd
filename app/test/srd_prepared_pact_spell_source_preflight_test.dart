import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_prepared_spell_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'confirmed-pact-source',
  name: 'Zauberquelle',
  className: 'Magier',
  secondaryClassName: 'Hexenmeister',
  secondaryClassLevel: 3,
  level: 6,
  hitPoints: 20,
  maxHitPoints: 20,
  spells: const ['Magisches Geschoss', 'Unsichtbarkeit', 'Licht'],
);

HeroCharacter _confirmed(HeroCharacter hero, SrdSpellCatalog catalog) =>
    SrdClassPreparedSpellRules.confirm(
      hero,
      catalog: catalog,
      selectedByClass: const {
        'Wizard': ['Magisches Geschoss'],
        'Warlock': ['Unsichtbarkeit'],
      },
      preparationChoicesConfirmed: true,
    );

SrdSpellCastPlan _preflight(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  required String castingClass,
  required int slotLevel,
  bool pactMagic = false,
  bool classConfirmed = false,
}) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: castingClass,
  slotLevel: slotLevel,
  pactMagic: pactMagic,
  preparedForCastingClassConfirmed: classConfirmed,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: true,
  slotTurnLimitConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('Wizard spell uses Warlock Pact slot with stored class proof', () {
    final hero = _confirmed(_hero(), catalog);
    final before = hero.toJson();
    final plan = _preflight(
      hero,
      catalog.find('Magic Missile')!,
      castingClass: 'Wizard',
      slotLevel: 2,
      pactMagic: true,
    );
    expect(plan.castingClass, 'Magier');
    expect(plan.preparedName, 'Magisches Geschoss');
    expect(plan.pactMagic, isTrue);
    expect(hero.toJson(), before);
    final used = SrdSpellPreflightRules.recordConfirmedResourceUse(
      hero,
      plan,
      effectResolvedSeparatelyConfirmed: true,
    );
    expect(used.hero.spentPactSlots, 1);
    expect(used.hero.spentSpellSlots, isEmpty);
    expect(used.hero.preparedSpellRecord, isNotNull);
    expect(hero.toJson(), before);
    expect(
      HeroCharacter.fromJson(used.hero.toJson()).toJson(),
      used.hero.toJson(),
    );
    expect(
      () => SrdSpellPreflightRules.recordConfirmedResourceUse(
        used.hero,
        plan,
        effectResolvedSeparatelyConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  test('Warlock-prepared spell can use normal Wizard slot', () {
    final hero = _confirmed(_hero(), catalog);
    final before = hero.toJson();
    final plan = _preflight(
      hero,
      catalog.find('Invisibility')!,
      castingClass: 'Warlock',
      slotLevel: 2,
    );
    expect(plan.castingClass, 'Hexenmeister');
    expect(plan.pactMagic, isFalse);
    final spent = SrdSpellPreflightRules.recordConfirmedResourceUse(
      hero,
      plan,
      effectResolvedSeparatelyConfirmed: true,
    );
    expect(spent.hero.spentSpellSlots, {'2': 1});
    expect(spent.hero.spentPactSlots, 0);
    expect(spent.hero.concentratingOn, 'Unsichtbarkeit');
    expect(hero.toJson(), before);
  });

  test('stored record overrides a forged transient class confirmation', () {
    final hero = _confirmed(_hero(), catalog);
    final before = hero.toJson();
    expect(
      () => _preflight(
        hero,
        catalog.find('Invisibility')!,
        castingClass: 'Wizard',
        slotLevel: 2,
        classConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(hero.toJson(), before);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.spentPactSlots, 0);
  });

  test('flat known spell not in proof is rejected without slot spending', () {
    final hero = _confirmed(_hero(), catalog);
    final before = hero.toJson();
    expect(
      () => _preflight(
        hero,
        catalog.find('Light')!,
        castingClass: 'Magier',
        slotLevel: 0,
        classConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(hero.toJson(), before);
  });

  test('legacy flat spell list retains its explicit class choice', () {
    final legacy = _hero();
    final before = legacy.toJson();
    expect(legacy.preparedSpellRecord, isNull);
    expect(
      () => _preflight(
        legacy,
        catalog.find('Invisibility')!,
        castingClass: 'Magier',
        slotLevel: 2,
      ),
      throwsFormatException,
    );
    final plan = _preflight(
      legacy,
      catalog.find('Invisibility')!,
      castingClass: 'Magier',
      slotLevel: 2,
      classConfirmed: true,
    );
    expect(plan.castingClass, 'Magier');
    expect(legacy.toJson(), before);
    expect(before.containsKey('preparedSpellRecord'), isFalse);
  });

  test('JSON-loaded record retains a class-specific spell assignment', () {
    final original = _confirmed(_hero(), catalog);
    final encoded = original.toJson();
    final loaded = HeroCharacter.fromJson(encoded);
    expect(loaded.toJson(), encoded);
    final plan = _preflight(
      loaded,
      catalog.find('Invisibility')!,
      castingClass: 'Hexenmeister',
      slotLevel: 2,
      pactMagic: true,
    );
    expect(plan.pactMagic, isTrue);
    expect(plan.castingClass, 'Hexenmeister');
    expect(loaded.toJson(), encoded);
  });
}
