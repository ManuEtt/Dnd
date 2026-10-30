import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_audited_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_material_value_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter _wizard({List<InventoryItem>? inventory}) => HeroCharacter(
  id: 'verified-value-caster',
  name: 'Wertprüfer',
  className: 'Magier',
  level: 9,
  spells: const ['Secret Chest'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 18,
    'wisdom': 12,
    'charisma': 10,
  },
  hitPoints: 38,
  maxHitPoints: 38,
  inventory:
      inventory ??
      const [
        InventoryItem(id: 'first', name: 'Extern bestätigter Gegenstand'),
        InventoryItem(id: 'second', name: 'Zweiter bestätigter Gegenstand'),
        InventoryItem(id: 'other', name: 'Seil'),
      ],
);

List<SrdAuditedInventoryBinding> _bindings(String first, String second) => [
  SrdAuditedInventoryBinding(
    materialId: first,
    inventoryId: 'first',
    identityAndValueConfirmed: true,
    requiredQuantityConfirmed: true,
  ),
  SrdAuditedInventoryBinding(
    materialId: second,
    inventoryId: 'second',
    identityAndValueConfirmed: true,
    requiredQuantityConfirmed: true,
  ),
];

List<SrdSpellMaterialValueEvidence> _values(
  String first,
  String second,
  int firstCp,
  int secondCp,
) => [
  SrdSpellMaterialValueEvidence(
    materialId: first,
    inventoryId: 'first',
    confirmedUnitValueCp: firstCp,
    identityIndependentlyConfirmed: true,
    valueIndependentlyConfirmed: true,
  ),
  SrdSpellMaterialValueEvidence(
    materialId: second,
    inventoryId: 'second',
    confirmedUnitValueCp: secondCp,
    identityIndependentlyConfirmed: true,
    valueIndependentlyConfirmed: true,
  ),
];

SrdSpellCastPlan _plan(HeroCharacter hero, SrdSpellDefinition spell) =>
    SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: 'Magier',
      slotLevel: 4,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      materialComponentConfirmed: true,
      costlyComponentAvailableConfirmed: true,
      slotTurnLimitConfirmed: true,
      confirmedMaterialItems: [
        for (final item in SrdSpellComponentRules.auditedItems(spell))
          SrdMaterialItemConfirmation(
            id: item.id,
            identityAndCostConfirmed: true,
            requiredQuantityConfirmed: true,
            consumptionReservedConfirmed: item.isConsumed,
          ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all four audited recipes enforce each per-unit GP minimum', () {
    final cases = [
      (
        name: 'Astral Projection',
        first: 'astral-jacinth',
        second: 'astral-silver-bar',
        firstCp: 100000,
        secondCp: 10000,
        count: 2,
        firstConsumed: 2,
        secondConsumed: 2,
        secondQuantity: 2,
      ),
      (
        name: 'Clone',
        first: 'clone-diamond',
        second: 'clone-vessel',
        firstCp: 100000,
        secondCp: 200000,
        count: null,
        firstConsumed: 1,
        secondConsumed: 0,
        secondQuantity: 1,
      ),
      (
        name: 'Legend Lore',
        first: 'legend-incense',
        second: 'legend-ivory-strips',
        firstCp: 25000,
        secondCp: 5000,
        count: null,
        firstConsumed: 1,
        secondConsumed: 0,
        secondQuantity: 4,
      ),
      (
        name: 'Secret Chest',
        first: 'secret-large-chest',
        second: 'secret-tiny-replica',
        firstCp: 500000,
        secondCp: 5000,
        count: null,
        firstConsumed: 0,
        secondConsumed: 0,
        secondQuantity: 1,
      ),
    ];
    for (final recipe in cases) {
      final spell = catalog.find(recipe.name)!;
      final hero = _wizard(
        inventory: [
          InventoryItem(
            id: 'first',
            name: 'No pricing from this name',
            quantity: recipe.count ?? 1,
          ),
          InventoryItem(
            id: 'second',
            name: 'No pricing from this name',
            quantity: recipe.secondQuantity,
          ),
        ],
      );
      final bindings = _bindings(recipe.first, recipe.second);
      final values = _values(
        recipe.first,
        recipe.second,
        recipe.firstCp,
        recipe.secondCp,
      );
      final consumed = SrdSpellMaterialValueRules.validatedConsumption(
        hero,
        spell,
        bindings: bindings,
        values: values,
        confirmedTargetCount: recipe.count,
      );
      expect(consumed, {
        if (recipe.firstConsumed > 0) 'first': recipe.firstConsumed,
        if (recipe.secondConsumed > 0) 'second': recipe.secondConsumed,
      }, reason: recipe.name);
      for (final invalid in [
        _values(
          recipe.first,
          recipe.second,
          recipe.firstCp - 1,
          recipe.secondCp,
        ),
        _values(
          recipe.first,
          recipe.second,
          recipe.firstCp,
          recipe.secondCp - 1,
        ),
      ]) {
        expect(
          () => SrdSpellMaterialValueRules.validatedConsumption(
            hero,
            spell,
            bindings: bindings,
            values: invalid,
            confirmedTargetCount: recipe.count,
          ),
          throwsFormatException,
          reason: recipe.name,
        );
      }
      expect(hero.spentSpellSlots, isEmpty);
    }
  });

  test('missing, duplicate, unverified and misbound prices fail closed', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = _wizard();
    final bindings = _bindings('secret-large-chest', 'secret-tiny-replica');
    final values = _values(
      'secret-large-chest',
      'secret-tiny-replica',
      500000,
      5000,
    );
    final bad = <List<SrdSpellMaterialValueEvidence>>[
      [],
      [values.first],
      [values.first, values.first],
      [
        SrdSpellMaterialValueEvidence(
          materialId: 'secret-large-chest',
          inventoryId: 'other',
          confirmedUnitValueCp: 500000,
          identityIndependentlyConfirmed: true,
          valueIndependentlyConfirmed: true,
        ),
        values.last,
      ],
      [
        SrdSpellMaterialValueEvidence(
          materialId: 'secret-large-chest',
          inventoryId: 'first',
          confirmedUnitValueCp: 500000,
          identityIndependentlyConfirmed: false,
          valueIndependentlyConfirmed: true,
        ),
        values.last,
      ],
      [
        SrdSpellMaterialValueEvidence(
          materialId: 'secret-large-chest',
          inventoryId: 'first',
          confirmedUnitValueCp: 500000,
          identityIndependentlyConfirmed: true,
          valueIndependentlyConfirmed: false,
        ),
        values.last,
      ],
      _values('unknown', 'secret-tiny-replica', 500000, 5000),
      _values('secret-large-chest', 'secret-tiny-replica', -1, 5000),
    ];
    final before = jsonEncode(hero.toJson());
    for (final invalid in bad) {
      expect(
        () => SrdSpellMaterialValueRules.validatedConsumption(
          hero,
          spell,
          bindings: bindings,
          values: invalid,
        ),
        throwsFormatException,
      );
    }
    expect(jsonEncode(hero.toJson()), before);
  });

  test('typed stored price never substitutes independent confirmation', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = _wizard(
      inventory: const [
        InventoryItem(
          id: 'first',
          name: 'Self-declared chest',
          stats: InventoryItemStats(priceCp: 500000),
        ),
        InventoryItem(id: 'second', name: 'Replica'),
      ],
    );
    final bindings = _bindings('secret-large-chest', 'secret-tiny-replica');
    final values = _values(
      'secret-large-chest',
      'secret-tiny-replica',
      500000,
      5000,
    );
    expect(
      SrdSpellMaterialValueRules.validatedConsumption(
        hero,
        spell,
        bindings: bindings,
        values: values,
      ),
      isEmpty,
    );
    final inconsistent = _values(
      'secret-large-chest',
      'secret-tiny-replica',
      500001,
      5000,
    );
    expect(
      () => SrdSpellMaterialValueRules.validatedConsumption(
        hero,
        spell,
        bindings: bindings,
        values: inconsistent,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellMaterialValueRules.validatedConsumption(
        hero,
        spell,
        bindings: bindings,
        values: [
          SrdSpellMaterialValueEvidence(
            materialId: 'secret-large-chest',
            inventoryId: 'first',
            confirmedUnitValueCp: 500000,
            identityIndependentlyConfirmed: true,
            valueIndependentlyConfirmed: false,
          ),
          values.last,
        ],
      ),
      throwsFormatException,
    );
  });

  test('target count and original stack quantities remain mandatory', () {
    final spell = catalog.find('Astral Projection')!;
    final hero = _wizard(
      inventory: const [
        InventoryItem(id: 'first', name: 'Jacinth', quantity: 2),
        InventoryItem(id: 'second', name: 'Silver', quantity: 2),
      ],
    );
    final bindings = _bindings('astral-jacinth', 'astral-silver-bar');
    final values = _values(
      'astral-jacinth',
      'astral-silver-bar',
      100000,
      10000,
    );
    for (final count in <int?>[null, 0, 3]) {
      expect(
        () => SrdSpellMaterialValueRules.validatedConsumption(
          hero,
          spell,
          bindings: bindings,
          values: values,
          confirmedTargetCount: count,
        ),
        throwsA(anyOf(isA<FormatException>(), isA<StateError>())),
      );
    }
  });

  test('unknown single-material spells cannot fake audited value proofs', () {
    final spell = catalog.find('Chromatic Orb')!;
    expect(
      () => SrdSpellMaterialValueRules.validatedConsumption(
        _wizard(),
        spell,
        bindings: _bindings('secret-large-chest', 'secret-tiny-replica'),
        values: _values(
          'secret-large-chest',
          'secret-tiny-replica',
          500000,
          5000,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('strict material commit retains items and rejects stale plan', () {
    final spell = catalog.find('Secret Chest')!;
    final firstHero = _wizard();
    final source = jsonEncode(firstHero.toJson());
    final bindings = _bindings('secret-large-chest', 'secret-tiny-replica');
    final values = _values(
      'secret-large-chest',
      'secret-tiny-replica',
      500000,
      5000,
    );
    final originalPlan = _plan(firstHero, spell);
    final result = SrdSpellMaterialValueRules.commitConfirmedCast(
      firstHero,
      originalPlan,
      spellEffectResolvedConfirmed: true,
      bindings: bindings,
      values: values,
    );
    expect(result.hero.spentSpellSlots, {'4': 1});
    expect(
      jsonEncode(result.hero.inventory.map((item) => item.toJson()).toList()),
      jsonEncode(firstHero.inventory.map((item) => item.toJson()).toList()),
    );
    expect(jsonEncode(firstHero.toJson()), source);
    final restored = HeroCharacter.fromJson(result.hero.toJson());
    final again = SrdSpellMaterialValueRules.commitConfirmedCast(
      restored,
      _plan(restored, spell),
      spellEffectResolvedConfirmed: true,
      bindings: bindings,
      values: values,
    );
    expect(again.hero.spentSpellSlots, {'4': 2});
    expect(
      () => SrdSpellMaterialValueRules.commitConfirmedCast(
        again.hero,
        originalPlan,
        spellEffectResolvedConfirmed: true,
        bindings: bindings,
        values: values,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellMaterialValueRules.commitConfirmedCast(
        firstHero,
        originalPlan,
        spellEffectResolvedConfirmed: false,
        bindings: bindings,
        values: values,
      ),
      throwsStateError,
    );
    expect(jsonEncode(firstHero.toJson()), source);
  });

  test('strict commit rejects undervalued materials without spending slot', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = _wizard();
    final original = jsonEncode(hero.toJson());
    final plan = _plan(hero, spell);
    expect(
      () => SrdSpellMaterialValueRules.commitConfirmedCast(
        hero,
        plan,
        spellEffectResolvedConfirmed: true,
        bindings: _bindings('secret-large-chest', 'secret-tiny-replica'),
        values: _values(
          'secret-large-chest',
          'secret-tiny-replica',
          499999,
          5000,
        ),
      ),
      throwsFormatException,
    );
    expect(jsonEncode(hero.toJson()), original);
  });
}
