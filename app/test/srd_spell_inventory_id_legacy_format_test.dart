import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_audited_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_inventory_id_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

const _hiddenCodePoints = <int>[
  0x206a,
  0x206b,
  0x206c,
  0x206d,
  0x206e,
  0x206f,
  0xfff9,
  0xfffa,
  0xfffb,
];

HeroCharacter _cleric(String inventoryId) => HeroCharacter(
  id: 'material-legacy-format-test',
  name: 'Materialkontrolle',
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
  inventory: [
    InventoryItem(id: inventoryId, name: 'Bestätigter Diamant', quantity: 2),
  ],
);

SrdSpellCastPlan _plan(HeroCharacter hero, SrdSpellDefinition spell) =>
    SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: 'Kleriker',
      slotLevel: 3,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      materialComponentConfirmed: true,
      costlyComponentAvailableConfirmed: true,
      consumedComponentReservedConfirmed: true,
      slotTurnLimitConfirmed: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('ordinary international inventory IDs remain valid', () {
    for (final id in ['diamond', 'Diamant № 1', 'réplique-2', '材料-1']) {
      expect(SrdSpellInventoryIdRules.isSafe(id), isTrue, reason: id);
    }
    for (final codePoint in [0x2069, 0xfeff, 0x200b]) {
      expect(
        SrdSpellInventoryIdRules.isSafe(
          'diamond-${String.fromCharCode(codePoint)}',
        ),
        isFalse,
        reason: codePoint.toRadixString(16),
      );
    }
  });

  test('all nine obsolete format controls are rejected as material IDs', () {
    for (final codePoint in _hiddenCodePoints) {
      final invisible = String.fromCharCode(codePoint);
      for (final id in ['dia${invisible}mond', 'diamond$invisible']) {
        expect(
          SrdSpellInventoryIdRules.isSafe(id),
          isFalse,
          reason: codePoint.toRadixString(16),
        );
      }
    }
  });

  test('invalid saved inventory IDs cannot consume a slot or a diamond', () {
    final spell = catalog.find('Revivify')!;
    for (final codePoint in _hiddenCodePoints) {
      final materialId = 'diamond-${String.fromCharCode(codePoint)}';
      final hero = _cleric(materialId);
      final before = jsonEncode(hero.toJson());
      final plan = _plan(hero, spell);

      expect(
        () => SrdSpellInventoryRules.commitConfirmedCast(
          hero,
          plan,
          spellEffectResolvedConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: [
            SrdConsumedMaterial(inventoryId: materialId, quantity: 1),
          ],
        ),
        throwsFormatException,
        reason: codePoint.toRadixString(16),
      );
      expect(jsonEncode(hero.toJson()), before);
      expect(hero.spentSpellSlots, isEmpty);
      expect(hero.inventory.single.quantity, 2);
    }
  });

  test('audited multi-material binding refuses hidden ID', () {
    final spell = catalog.find('Secret Chest')!;
    final hidden = 'chest${String.fromCharCode(0xfff9)}';
    final hero = _cleric(hidden).copyWith(
      className: 'Magier',
      level: 9,
      spells: ['Secret Chest'],
      inventory: [
        InventoryItem(id: hidden, name: 'Truhe'),
        const InventoryItem(id: 'replica', name: 'Replik'),
      ],
    );
    final before = jsonEncode(hero.toJson());

    expect(
      () => SrdSpellAuditedInventoryRules.consumedQuantities(
        hero,
        spell,
        bindings: [
          SrdAuditedInventoryBinding(
            materialId: 'secret-large-chest',
            inventoryId: hidden,
            identityAndValueConfirmed: true,
            requiredQuantityConfirmed: true,
          ),
          const SrdAuditedInventoryBinding(
            materialId: 'secret-tiny-replica',
            inventoryId: 'replica',
            identityAndValueConfirmed: true,
            requiredQuantityConfirmed: true,
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(jsonEncode(hero.toJson()), before);
  });

  test('a valid localized material ID still permits confirmed consumption', () {
    final spell = catalog.find('Revivify')!;
    final hero = _cleric('Diamant № 1');
    final result = SrdSpellInventoryRules.commitConfirmedCast(
      hero,
      _plan(hero, spell),
      spellEffectResolvedConfirmed: true,
      materialIdentityAndQuantityConfirmed: true,
      consumedMaterials: const [
        SrdConsumedMaterial(inventoryId: 'Diamant № 1', quantity: 1),
      ],
    );

    expect(result.hero.spentSpellSlots, {'3': 1});
    expect(result.hero.inventory.single.quantity, 1);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.inventory.single.quantity, 2);
  });
}
