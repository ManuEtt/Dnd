import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter _cleric({List<InventoryItem>? inventory}) => HeroCharacter(
  id: 'inventory-caster',
  name: 'Materialmagie',
  className: 'Kleriker',
  level: 5,
  spells: const ['Revivify'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 18,
    'charisma': 12,
  },
  maxHitPoints: 32,
  hitPoints: 32,
  inventory:
      inventory ??
      const [
        InventoryItem(id: 'diamond', name: 'Bestätigter Diamant', quantity: 2),
        InventoryItem(id: 'rope', name: 'Seil', quantity: 1),
      ],
);

SrdSpellCastPlan _plan(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  int slotLevel = 3,
  bool consumed = true,
  bool costly = true,
}) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: hero.className,
  slotLevel: slotLevel,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: true,
  costlyComponentAvailableConfirmed: costly,
  consumedComponentReservedConfirmed: consumed,
  slotTurnLimitConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test(
    'confirmed spell consumes inventory and slot in one immutable result',
    () {
      final before = _cleric();
      final approved = _plan(before, catalog.find('Revivify')!);
      final result = SrdSpellInventoryRules.commitConfirmedCast(
        before,
        approved,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: const [
          SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
        ],
      );

      expect(result.hero.spentSpellSlots, {'3': 1});
      expect(result.hero.inventory.map((item) => item.id).toList(), [
        'diamond',
        'rope',
      ]);
      expect(result.hero.inventory.first.quantity, 1);
      expect(result.hero.inventory.last.quantity, 1);
      expect(before.inventory.first.quantity, 2);
      expect(before.spentSpellSlots, isEmpty);
      expect(
        HeroCharacter.fromJson(result.hero.toJson()).inventory.first.quantity,
        1,
      );
      expect(HeroCharacter.fromJson(result.hero.toJson()).spentSpellSlots, {
        '3': 1,
      });
      expect(
        () => SrdSpellInventoryRules.commitConfirmedCast(
          result.hero,
          approved,
          spellEffectResolvedConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: const [
            SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
          ],
        ),
        throwsFormatException,
      );
    },
  );

  test('entire confirmed stack is removed without touching other items', () {
    final before = _cleric(
      inventory: const [
        InventoryItem(id: 'diamond', name: 'Diamant'),
        InventoryItem(id: 'rope', name: 'Seil'),
      ],
    );
    final approved = _plan(before, catalog.find('Revivify')!);
    final after = SrdSpellInventoryRules.commitConfirmedCast(
      before,
      approved,
      spellEffectResolvedConfirmed: true,
      materialIdentityAndQuantityConfirmed: true,
      consumedMaterials: const [
        SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
      ],
    ).hero;
    expect(after.inventory.map((item) => item.id).toList(), ['rope']);
    expect(before.inventory, hasLength(2));
  });

  test('failed validation leaves slot and inventory untouched', () {
    final before = _cleric();
    final approved = _plan(before, catalog.find('Revivify')!);
    for (final used in [
      const <SrdConsumedMaterial>[],
      const [SrdConsumedMaterial(inventoryId: 'diamond', quantity: 3)],
      const [SrdConsumedMaterial(inventoryId: 'missing', quantity: 1)],
      const [SrdConsumedMaterial(inventoryId: 'diamond', quantity: 0)],
      const [SrdConsumedMaterial(inventoryId: ' diamond ', quantity: 1)],
      const [
        SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
        SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
      ],
    ]) {
      expect(
        () => SrdSpellInventoryRules.commitConfirmedCast(
          before,
          approved,
          spellEffectResolvedConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: used,
        ),
        throwsA(anyOf(isA<FormatException>(), isA<StateError>())),
        reason: '$used',
      );
      expect(before.inventory.first.quantity, 2);
      expect(before.spentSpellSlots, isEmpty);
    }
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        before,
        approved,
        spellEffectResolvedConfirmed: false,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: const [
          SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
        ],
      ),
      throwsStateError,
    );
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        before,
        approved,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: false,
        consumedMaterials: const [
          SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
        ],
      ),
      throwsFormatException,
    );
  });

  test('forged duplicate IDs and equipped material are rejected', () {
    final duplicate = _cleric(
      inventory: const [
        InventoryItem(id: 'diamond', name: 'Diamant'),
        InventoryItem(id: 'diamond', name: 'Zweiter Stapel'),
      ],
    );
    final dupPlan = _plan(duplicate, catalog.find('Revivify')!);
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        duplicate,
        dupPlan,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: const [
          SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
        ],
      ),
      throwsFormatException,
    );
    final equipped = _cleric().copyWith(equippedWeaponId: 'diamond');
    final equippedPlan = _plan(equipped, catalog.find('Revivify')!);
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        equipped,
        equippedPlan,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: const [
          SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
        ],
      ),
      throwsStateError,
    );
  });

  test('stale inventory, spell resource or class change cannot reuse plan', () {
    final before = _cleric();
    final approved = _plan(before, catalog.find('Revivify')!);
    for (final changed in [
      before.copyWith(
        inventory: [
          before.inventory.first.copyWith(quantity: 1),
          before.inventory.last,
        ],
      ),
      before.copyWith(spentSpellSlots: {'3': 1}),
      before.copyWith(className: 'Magier'),
    ]) {
      expect(
        () => SrdSpellInventoryRules.commitConfirmedCast(
          changed,
          approved,
          spellEffectResolvedConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: const [
            SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
          ],
        ),
        throwsFormatException,
      );
    }
  });

  test('unconsumed spell cannot silently consume arbitrary inventory', () {
    final wizard = _cleric().copyWith(
      className: 'Magier',
      spells: ['Chromatic Orb'],
    );
    final plan = _plan(
      wizard,
      catalog.find('Chromatic Orb')!,
      slotLevel: 1,
      consumed: false,
    );
    expect(plan.hasConsumedMaterial, isFalse);
    expect(
      () => SrdSpellInventoryRules.commitConfirmedCast(
        wizard,
        plan,
        spellEffectResolvedConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: const [
          SrdConsumedMaterial(inventoryId: 'diamond', quantity: 1),
        ],
      ),
      throwsFormatException,
    );
    final result = SrdSpellInventoryRules.commitConfirmedCast(
      wizard,
      plan,
      spellEffectResolvedConfirmed: true,
      materialIdentityAndQuantityConfirmed: false,
    );
    expect(result.hero.inventory.first.quantity, 2);
    expect(result.hero.spentSpellSlots, {'1': 1});
  });
}
