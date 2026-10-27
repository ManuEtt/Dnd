import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_audited_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter _hero({List<InventoryItem> inventory = const []}) =>
    HeroCharacter(
      id: 'audited-inventory-hero',
      name: 'Prüfzauberer',
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
      inventory: inventory,
    );

List<SrdAuditedInventoryBinding> _bind(
  String first,
  String second, {
  bool costConfirmed = true,
  bool countConfirmed = true,
}) => [
  SrdAuditedInventoryBinding(
    materialId: first,
    inventoryId: 'stack-a',
    identityAndValueConfirmed: costConfirmed,
    requiredQuantityConfirmed: countConfirmed,
  ),
  SrdAuditedInventoryBinding(
    materialId: second,
    inventoryId: 'stack-b',
    identityAndValueConfirmed: true,
    requiredQuantityConfirmed: true,
  ),
];

List<SrdMaterialItemConfirmation> _preflightApprovals(
  SrdSpellDefinition spell,
) => [
  for (final item in SrdSpellComponentRules.auditedItems(spell))
    SrdMaterialItemConfirmation(
      id: item.id,
      identityAndCostConfirmed: true,
      requiredQuantityConfirmed: true,
      consumptionReservedConfirmed: item.isConsumed,
    ),
];

SrdSpellCastPlan _secretPlan(HeroCharacter hero, SrdSpellDefinition spell) =>
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
      confirmedMaterialItems: _preflightApprovals(spell),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('Clone validates consumed diamond and keeps vessel in inventory', () {
    final spell = catalog.find('Clone')!;
    final hero = _hero(
      inventory: const [
        InventoryItem(
          id: 'stack-a',
          name: 'Unbestätigtes Material',
          quantity: 2,
        ),
        InventoryItem(id: 'stack-b', name: 'Anderer Stapel', quantity: 1),
      ],
    );
    final result = SrdSpellAuditedInventoryRules.consumedQuantities(
      hero,
      spell,
      bindings: _bind('clone-diamond', 'clone-vessel'),
    );
    expect(result, {'stack-a': 1});
    expect(hero.inventory.first.quantity, 2);
    expect(hero.spentSpellSlots, isEmpty);
  });

  test('Legend Lore needs four separate ivory strips, not only one', () {
    final spell = catalog.find('Legend Lore')!;
    final short = _hero(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Incense', quantity: 1),
        InventoryItem(id: 'stack-b', name: 'Ivory', quantity: 3),
      ],
    );
    final bindings = _bind('legend-incense', 'legend-ivory-strips');
    expect(
      () => SrdSpellAuditedInventoryRules.consumedQuantities(
        short,
        spell,
        bindings: bindings,
      ),
      throwsStateError,
    );
    final complete = short.copyWith(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Incense', quantity: 1),
        InventoryItem(id: 'stack-b', name: 'Ivory', quantity: 4),
      ],
    );
    expect(
      SrdSpellAuditedInventoryRules.consumedQuantities(
        complete,
        spell,
        bindings: bindings,
      ),
      {'stack-a': 1},
    );
  });

  test('Astral Projection requires a matched stack per confirmed target', () {
    final spell = catalog.find('Astral Projection')!;
    final hero = _hero(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Jacinth', quantity: 2),
        InventoryItem(id: 'stack-b', name: 'Silver', quantity: 2),
      ],
    );
    final bindings = _bind('astral-jacinth', 'astral-silver-bar');
    for (final count in <int?>[null, 0, -1]) {
      expect(
        () => SrdSpellAuditedInventoryRules.consumedQuantities(
          hero,
          spell,
          bindings: bindings,
          confirmedTargetCount: count,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => SrdSpellAuditedInventoryRules.consumedQuantities(
        hero,
        spell,
        bindings: bindings,
        confirmedTargetCount: 3,
      ),
      throwsStateError,
    );
    expect(
      SrdSpellAuditedInventoryRules.consumedQuantities(
        hero,
        spell,
        bindings: bindings,
        confirmedTargetCount: 2,
      ),
      {'stack-a': 2, 'stack-b': 2},
    );
  });

  test('unknown, duplicate or incomplete bindings cannot pass', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = _hero(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'A'),
        InventoryItem(id: 'stack-b', name: 'B'),
      ],
    );
    final bindings = _bind('secret-large-chest', 'secret-tiny-replica');
    final variants = <List<SrdAuditedInventoryBinding>>[
      [],
      [bindings.first],
      [bindings.first, bindings.first],
      [
        bindings.first,
        const SrdAuditedInventoryBinding(
          materialId: 'unknown',
          inventoryId: 'stack-b',
          identityAndValueConfirmed: true,
          requiredQuantityConfirmed: true,
        ),
      ],
      [
        bindings.first,
        const SrdAuditedInventoryBinding(
          materialId: 'secret-tiny-replica',
          inventoryId: 'stack-a',
          identityAndValueConfirmed: true,
          requiredQuantityConfirmed: true,
        ),
      ],
      _bind('secret-large-chest', 'secret-tiny-replica', costConfirmed: false),
      _bind('secret-large-chest', 'secret-tiny-replica', countConfirmed: false),
    ];
    for (final invalid in variants) {
      expect(
        () => SrdSpellAuditedInventoryRules.consumedQuantities(
          hero,
          spell,
          bindings: invalid,
        ),
        throwsFormatException,
      );
    }
  });

  test('missing, duplicated or equipped consumed stacks fail closed', () {
    final spell = catalog.find('Clone')!;
    final bindings = _bind('clone-diamond', 'clone-vessel');
    final missing = _hero(
      inventory: const [InventoryItem(id: 'stack-a', name: 'Diamond')],
    );
    expect(
      () => SrdSpellAuditedInventoryRules.consumedQuantities(
        missing,
        spell,
        bindings: bindings,
      ),
      throwsFormatException,
    );
    final duplicate = _hero(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Diamond'),
        InventoryItem(id: 'stack-a', name: 'Another'),
        InventoryItem(id: 'stack-b', name: 'Vessel'),
      ],
    );
    expect(
      () => SrdSpellAuditedInventoryRules.consumedQuantities(
        duplicate,
        spell,
        bindings: bindings,
      ),
      throwsFormatException,
    );
    final equipped = _hero(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Diamond'),
        InventoryItem(id: 'stack-b', name: 'Vessel'),
      ],
    ).copyWith(equippedWeaponId: 'stack-a');
    expect(
      () => SrdSpellAuditedInventoryRules.consumedQuantities(
        equipped,
        spell,
        bindings: bindings,
      ),
      throwsStateError,
    );
  });

  test('legacy free-form commit cannot skip audited inventory validation', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = _hero(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Chest'),
        InventoryItem(id: 'stack-b', name: 'Replica'),
        InventoryItem(id: 'unrelated', name: 'Torch', quantity: 2),
      ],
    );
    final plan = _secretPlan(hero, spell);
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        hero,
        plan,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
      ),
      throwsFormatException,
    );
    final result = SrdSpellInventoryRules.commitConfirmedCast(
      hero,
      plan,
      spellEffectResolvedConfirmed: true,
      materialIdentityAndQuantityConfirmed: true,
      auditedBindings: _bind('secret-large-chest', 'secret-tiny-replica'),
    );
    expect(result.hero.spentSpellSlots, {'4': 1});
    expect(result.hero.inventory.map((item) => item.quantity).toList(), [
      1,
      1,
      2,
    ]);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.inventory, hasLength(3));
    final restored = HeroCharacter.fromJson(result.hero.toJson());
    expect(restored.spentSpellSlots, {'4': 1});
    expect(restored.inventory, hasLength(3));
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        result.hero,
        plan,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        auditedBindings: _bind('secret-large-chest', 'secret-tiny-replica'),
      ),
      throwsFormatException,
    );
  });

  test('unapproved effects or stale inventory do not consume slots', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = _hero(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Chest'),
        InventoryItem(id: 'stack-b', name: 'Replica'),
      ],
    );
    final plan = _secretPlan(hero, spell);
    final bindings = _bind('secret-large-chest', 'secret-tiny-replica');
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        hero,
        plan,
        spellEffectResolvedConfirmed: false,
        materialIdentityAndQuantityConfirmed: true,
        auditedBindings: bindings,
      ),
      throwsStateError,
    );
    final changed = hero.copyWith(
      inventory: const [
        InventoryItem(id: 'stack-a', name: 'Chest'),
        InventoryItem(id: 'stack-b', name: 'Replica', quantity: 2),
      ],
    );
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        changed,
        plan,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        auditedBindings: bindings,
      ),
      throwsFormatException,
    );
    expect(hero.spentSpellSlots, isEmpty);
    expect(changed.spentSpellSlots, isEmpty);
  });
}
