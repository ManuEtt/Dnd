import 'models.dart';
import 'srd_spell_audited_inventory_rules.dart';
import 'srd_spell_component_rules.dart';
import 'srd_spell_inventory_id_rules.dart';
import 'spellcasting_rules.dart';
import 'srd_spell_preflight_rules.dart';

/// A specific, manually verified inventory stack that a spell consumes.
/// IDs identify inventory instances, never names or free-text descriptions.
class SrdConsumedMaterial {
  const SrdConsumedMaterial({
    required this.inventoryId,
    required this.quantity,
  });

  final String inventoryId;
  final int quantity;
}

/// Pure, atomic domain transition: the caller persists the returned hero
/// together with its event using the existing controller/repository contract.
///
/// This deliberately does NOT infer a component's identity from a translated
/// inventory name or item description, or pretend to have resolved a spell.
/// The caller must independently verify the spell's consumed materials and
/// their required amounts. Inventory mutations never happen in-place.
class SrdSpellInventoryRules {
  const SrdSpellInventoryRules._();

  static SpellCastResult commitConfirmedCast(
    HeroCharacter hero,
    SrdSpellCastPlan plan, {
    required bool spellEffectResolvedConfirmed,
    required bool materialIdentityAndQuantityConfirmed,
    List<SrdConsumedMaterial> consumedMaterials = const [],
    List<SrdAuditedInventoryBinding> auditedBindings = const [],
    int? confirmedTargetCount,
  }) {
    if (!spellEffectResolvedConfirmed) {
      throw StateError('Die Zauberwirkung ist nicht regelgeprüft.');
    }
    final audited = SrdSpellComponentRules.auditedItems(plan.spell);
    final List<SrdConsumedMaterial> actualConsumption;
    if (audited.isNotEmpty) {
      if (!materialIdentityAndQuantityConfirmed ||
          consumedMaterials.isNotEmpty) {
        throw const FormatException(
          'Auditierte Materialien müssen einzeln zugeordnet werden.',
        );
      }
      final quantities = SrdSpellAuditedInventoryRules.consumedQuantities(
        hero,
        plan.spell,
        bindings: auditedBindings,
        confirmedTargetCount: confirmedTargetCount,
      );
      actualConsumption = [
        for (final entry in quantities.entries)
          SrdConsumedMaterial(inventoryId: entry.key, quantity: entry.value),
      ];
    } else {
      if (auditedBindings.isNotEmpty || confirmedTargetCount != null) {
        throw const FormatException(
          'Einzelmaterial-Bindungen sind für diesen Zauber unbekannt.',
        );
      }
      actualConsumption = consumedMaterials;
    }
    if (plan.hasConsumedMaterial) {
      if (!materialIdentityAndQuantityConfirmed || actualConsumption.isEmpty) {
        throw const FormatException(
          'Verbrauchsmaterial und benötigte Anzahl sind nicht bestätigt.',
        );
      }
    } else if (actualConsumption.isNotEmpty) {
      throw const FormatException(
        'Für diesen Zauber ist kein Materialverbrauch dokumentiert.',
      );
    }

    final amounts = <String, int>{};
    for (final entry in actualConsumption) {
      if (!SrdSpellInventoryIdRules.isSafe(entry.inventoryId) ||
          entry.quantity < 1) {
        throw const FormatException('Ungültige Material-ID oder Stückzahl.');
      }
      if (amounts.containsKey(entry.inventoryId)) {
        throw const FormatException('Material-ID mehrfach angegeben.');
      }
      amounts[entry.inventoryId] = entry.quantity;
    }

    final usedIds = <String>{};
    final inventoryAfter = <InventoryItem>[];
    for (final item in hero.inventory) {
      if (!SrdSpellInventoryIdRules.isSafe(item.id) || !usedIds.add(item.id)) {
        throw const FormatException('Inventar-ID ist nicht eindeutig.');
      }
      final amount = amounts[item.id];
      if (amount == null) {
        inventoryAfter.add(item);
        continue;
      }
      if (item.id == hero.equippedWeaponId ||
          item.id == hero.equippedArmorId ||
          item.id == hero.equippedShieldId) {
        throw StateError(
          'Ausgerüstete Gegenstände können nicht verbraucht werden.',
        );
      }
      if (item.quantity < 1 || amount > item.quantity) {
        throw StateError('Nicht genügend bestätigtes Material im Inventar.');
      }
      if (amount < item.quantity) {
        inventoryAfter.add(item.copyWith(quantity: item.quantity - amount));
      }
    }
    if (!usedIds.containsAll(amounts.keys)) {
      throw const FormatException('Ein Materialgegenstand fehlt im Inventar.');
    }

    // Only after ALL inventory checks, the existing preflight verifies the
    // original hero snapshot and charges the slot/pact pool. The new hero
    // combines both changes; failures cannot partially mutate the old hero.
    final spent = SrdSpellPreflightRules.recordConfirmedResourceUse(
      hero,
      plan,
      effectResolvedSeparatelyConfirmed: true,
      materialConsumptionResolvedSeparatelyConfirmed: plan.hasConsumedMaterial,
    );
    return SpellCastResult(
      hero: spent.hero.copyWith(inventory: inventoryAfter),
      spellName: spent.spellName,
      slotLevel: spent.slotLevel,
      pactMagic: spent.pactMagic,
    );
  }
}
