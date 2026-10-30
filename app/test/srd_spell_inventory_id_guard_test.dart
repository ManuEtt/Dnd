import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_audited_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_inventory_id_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter _wizard({List<InventoryItem>? inventory}) => HeroCharacter(
  id: 'material-binding-caster',
  name: 'Materialprüfer',
  className: 'Magier',
  level: 9,
  spells: const ['Secret Chest', 'Chromatic Orb'],
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
        InventoryItem(id: 'large-chest', name: 'Bestätigte Truhe'),
        InventoryItem(id: 'tiny-replica', name: 'Bestätigte Replik'),
        InventoryItem(id: 'rope', name: 'Seil'),
      ],
);

List<SrdAuditedInventoryBinding> _bindings({
  String chest = 'large-chest',
  String replica = 'tiny-replica',
}) => [
  SrdAuditedInventoryBinding(
    materialId: 'secret-large-chest',
    inventoryId: chest,
    identityAndValueConfirmed: true,
    requiredQuantityConfirmed: true,
  ),
  SrdAuditedInventoryBinding(
    materialId: 'secret-tiny-replica',
    inventoryId: replica,
    identityAndValueConfirmed: true,
    requiredQuantityConfirmed: true,
  ),
];

SrdSpellCastPlan _plan(HeroCharacter hero, SrdSpellDefinition spell) =>
    SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: 'Magier',
      slotLevel: spell.level,
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

  test('normal localized IDs are valid; hidden formatting is not', () {
    for (final id in ['chest-1', 'Truhe № 1', 'réplique-2', 'abc_xyz']) {
      expect(SrdSpellInventoryIdRules.isSafe(id), isTrue, reason: id);
    }
    for (final id in [
      '',
      ' chest',
      'chest ',
      'chest\nsecond',
      'chest\rsecond',
      'chest\tsecond',
      'chest\u0000second',
      'chest\u007fsecond',
      'chest\u0085second',
      'chest\u00adsecond',
      'chest\u200bsecond',
      'chest\u200esecond',
      'chest\u2028second',
      'chest\u202esecond',
      'chest\u2066second',
      'chest\u2069second',
      'chest\ufeffsecond',
    ]) {
      expect(SrdSpellInventoryIdRules.isSafe(id), isFalse, reason: id);
    }
  });

  test('retained costly components are bound without being consumed', () {
    final spell = catalog.find('Secret Chest')!;
    final original = _wizard();
    final approved = _plan(original, spell);
    final first = SrdSpellInventoryRules.commitConfirmedCast(
      original,
      approved,
      spellEffectResolvedConfirmed: true,
      materialIdentityAndQuantityConfirmed: true,
      auditedBindings: _bindings(),
    ).hero;
    expect(first.spentSpellSlots, {'4': 1});
    expect(
      jsonEncode(first.inventory.map((item) => item.toJson()).toList()),
      jsonEncode(original.inventory.map((item) => item.toJson()).toList()),
    );
    final restored = HeroCharacter.fromJson(first.toJson());
    final second = SrdSpellInventoryRules.commitConfirmedCast(
      restored,
      _plan(restored, spell),
      spellEffectResolvedConfirmed: true,
      materialIdentityAndQuantityConfirmed: true,
      auditedBindings: _bindings(),
    ).hero;
    expect(second.spentSpellSlots, {'4': 2});
    expect(second.inventory.map((item) => item.id).toList(), [
      'large-chest',
      'tiny-replica',
      'rope',
    ]);
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        second,
        approved,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        auditedBindings: _bindings(),
      ),
      throwsFormatException,
    );
    expect(original.spentSpellSlots, isEmpty);
  });

  test('changed material identity rejects old retained binding', () {
    final spell = catalog.find('Secret Chest')!;
    final changed = _wizard(
      inventory: const [
        InventoryItem(id: 'other-chest', name: 'Andere Truhe'),
        InventoryItem(id: 'tiny-replica', name: 'Replik'),
      ],
    );
    final before = jsonEncode(changed.toJson());
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        changed,
        _plan(changed, spell),
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        auditedBindings: _bindings(),
      ),
      throwsFormatException,
    );
    expect(jsonEncode(changed.toJson()), before);
  });

  test('spoofed retained ID fails even when confirmation matches', () {
    final spell = catalog.find('Secret Chest')!;
    for (final invalid in ['large\u202e-chest', 'large\u200b-chest']) {
      final wizard = _wizard(
        inventory: [
          InventoryItem(id: invalid, name: 'Truhe'),
          const InventoryItem(id: 'tiny-replica', name: 'Replik'),
        ],
      );
      final before = jsonEncode(wizard.toJson());
      expect(
        () => SrdSpellAuditedInventoryRules.consumedQuantities(
          wizard,
          spell,
          bindings: _bindings(chest: invalid),
        ),
        throwsFormatException,
      );
      expect(
        () => SrdSpellInventoryRules.commitConfirmedCast(
          wizard,
          _plan(wizard, spell),
          spellEffectResolvedConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          auditedBindings: _bindings(chest: invalid),
        ),
        throwsFormatException,
      );
      expect(jsonEncode(wizard.toJson()), before);
    }
  });

  test('unrelated malformed stack blocks unaudited resource commit', () {
    final spell = catalog.find('Chromatic Orb')!;
    final wizard = _wizard(
      inventory: const [
        InventoryItem(id: 'diamond', name: 'Confirmed diamond'),
        InventoryItem(id: 'other\u2067stack', name: 'Unrelated'),
      ],
    );
    final original = jsonEncode(wizard.toJson());
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        wizard,
        _plan(wizard, spell),
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(jsonEncode(wizard.toJson()), original);
  });

  test('plain consumed material IDs reject invisible formatting', () {
    final spell = catalog.find('Chromatic Orb')!;
    final wizard = _wizard();
    final plan = _plan(wizard, spell);
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        wizard,
        plan,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: const [
          SrdConsumedMaterial(inventoryId: 'rope\u202e', quantity: 1),
        ],
      ),
      throwsFormatException,
    );
    expect(wizard.spentSpellSlots, isEmpty);
  });
}
