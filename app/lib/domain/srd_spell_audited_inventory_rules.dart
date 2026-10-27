import 'models.dart';
import 'srd_spell_catalog.dart';
import 'srd_spell_component_rules.dart';

/// One explicitly verified link between a catalogue material requirement
/// and an existing inventory stack. No inventory name or prose is trusted.
class SrdAuditedInventoryBinding {
  const SrdAuditedInventoryBinding({
    required this.materialId,
    required this.inventoryId,
    required this.identityAndValueConfirmed,
    required this.requiredQuantityConfirmed,
  });

  final String materialId;
  final String inventoryId;
  final bool identityAndValueConfirmed;
  final bool requiredQuantityConfirmed;
}

/// Read-only quantity resolution for the four audited multi-material recipes.
///
/// Item prices and identities are independently confirmed by the caller.
/// The inventory model has no verified currency value for arbitrary items.
/// This resolver never invents a price from an item name or spends a slot.
class SrdSpellAuditedInventoryRules {
  const SrdSpellAuditedInventoryRules._();

  /// A confirmed target count is mandatory for Astral Projection because
  /// each affected target needs a separate jacinth and silver bar.
  /// Target eligibility and the spell's target limit are checked separately.
  static Map<String, int> consumedQuantities(
    HeroCharacter hero,
    SrdSpellDefinition spell, {
    required List<SrdAuditedInventoryBinding> bindings,
    int? confirmedTargetCount,
  }) {
    final recipe = SrdSpellComponentRules.auditedItems(spell);
    if (recipe.isEmpty) {
      throw UnsupportedError(
        'Für diesen Zauber ist keine Einzelmaterialprüfung hinterlegt.',
      );
    }
    if (spell.name == 'Astral Projection') {
      if (confirmedTargetCount == null || confirmedTargetCount < 1) {
        throw const FormatException(
          'Die Zahl bestätigter Astral-Projection-Ziele fehlt.',
        );
      }
    } else if (confirmedTargetCount != null) {
      throw const FormatException(
        'Für diesen Zauber ist keine zielabhängige Materialmenge vorgesehen.',
      );
    }

    final available = <String, InventoryItem>{};
    for (final item in hero.inventory) {
      if (item.id.isEmpty ||
          item.id.trim() != item.id ||
          available.containsKey(item.id) ||
          item.quantity < 1) {
        throw const FormatException(
          'Inventar enthält ungültige oder doppelte Stapel-IDs.',
        );
      }
      available[item.id] = item;
    }

    final declared = <String, SrdAuditedInventoryBinding>{};
    final assignedStacks = <String>{};
    for (final binding in bindings) {
      if (!recipe.any((item) => item.id == binding.materialId) ||
          declared.containsKey(binding.materialId) ||
          binding.inventoryId.isEmpty ||
          binding.inventoryId.trim() != binding.inventoryId ||
          !assignedStacks.add(binding.inventoryId) ||
          !binding.identityAndValueConfirmed ||
          !binding.requiredQuantityConfirmed) {
        throw const FormatException(
          'Materialzuordnung ist unbekannt, doppelt oder nicht bestätigt.',
        );
      }
      declared[binding.materialId] = binding;
    }
    if (declared.length != recipe.length) {
      throw const FormatException(
        'Nicht alle Materialpositionen sind einem Inventarstapel zugeordnet.',
      );
    }

    final consumed = <String, int>{};
    for (final item in recipe) {
      final binding = declared[item.id]!;
      final inventory = available[binding.inventoryId];
      if (inventory == null) {
        throw const FormatException(
          'Ein bestätigter Materialstapel existiert nicht im Inventar.',
        );
      }
      final count = item.id == 'legend-ivory-strips'
          ? 4
          : spell.name == 'Astral Projection'
          ? confirmedTargetCount!
          : 1;
      if (inventory.quantity < count) {
        throw StateError(
          'Für eine Materialposition sind zu wenige Stücke vorhanden.',
        );
      }
      if (item.isConsumed) {
        if (binding.inventoryId == hero.equippedWeaponId ||
            binding.inventoryId == hero.equippedArmorId ||
            binding.inventoryId == hero.equippedShieldId) {
          throw StateError(
            'Ausgerüstete Gegenstände können nicht verbraucht werden.',
          );
        }
        consumed[binding.inventoryId] = count;
      }
    }
    return Map.unmodifiable(consumed);
  }
}
