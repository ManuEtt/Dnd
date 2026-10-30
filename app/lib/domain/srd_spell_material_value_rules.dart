import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_spell_audited_inventory_rules.dart';
import 'srd_spell_catalog.dart';
import 'srd_spell_component_rules.dart';
import 'srd_spell_inventory_rules.dart';
import 'srd_spell_preflight_rules.dart';

/// Independently confirmed value of ONE material unit in a bound inventory
/// stack. The caller must obtain identity and price from a trusted rule check;
/// a player-entered inventory name, description or price is not proof.
class SrdSpellMaterialValueEvidence {
  const SrdSpellMaterialValueEvidence({
    required this.materialId,
    required this.inventoryId,
    required this.confirmedUnitValueCp,
    required this.identityIndependentlyConfirmed,
    required this.valueIndependentlyConfirmed,
  });

  final String materialId;
  final String inventoryId;
  final int confirmedUnitValueCp;
  final bool identityIndependentlyConfirmed;
  final bool valueIndependentlyConfirmed;
}

/// Strict opt-in value gate for the four individually audited SRD recipes.
///
/// Prices are per material UNIT, in copper pieces (100 CP = 1 GP). Never
/// multiply the unit price by the stack size to meet a per-unit minimum.
/// The existing audited inventory resolver independently checks every
/// material binding, availability, consumption and target-dependent count.
class SrdSpellMaterialValueRules {
  const SrdSpellMaterialValueRules._();

  // Checked against the four exact component texts in
  // SrdSpellComponentRules.auditedItems. Unknown recipes fail closed.
  static const _minimumUnitValueCp = <String, int>{
    'astral-jacinth': 100000,
    'astral-silver-bar': 10000,
    'clone-diamond': 100000,
    'clone-vessel': 200000,
    'legend-incense': 25000,
    'legend-ivory-strips': 5000,
    'secret-large-chest': 500000,
    'secret-tiny-replica': 5000,
  };

  static Map<String, int> validatedConsumption(
    HeroCharacter hero,
    SrdSpellDefinition spell, {
    required List<SrdAuditedInventoryBinding> bindings,
    required List<SrdSpellMaterialValueEvidence> values,
    int? confirmedTargetCount,
  }) {
    final requirements = SrdSpellComponentRules.auditedItems(spell);
    if (requirements.isEmpty ||
        requirements.any(
          (item) => !_minimumUnitValueCp.containsKey(item.id),
        )) {
      throw UnsupportedError(
        'Für diesen Zauber gibt es keine überprüften Materialpreise.',
      );
    }
    final consumption = SrdSpellAuditedInventoryRules.consumedQuantities(
      hero,
      spell,
      bindings: bindings,
      confirmedTargetCount: confirmedTargetCount,
    );

    if (values.length != requirements.length) {
      throw const FormatException(
        'Nicht alle Materialwerte sind einzeln bestätigt.',
      );
    }
    final bindingByMaterial = <String, String>{
      for (final binding in bindings) binding.materialId: binding.inventoryId,
    };
    final inventoryById = <String, InventoryItem>{
      for (final item in hero.inventory) item.id: item,
    };
    final seen = <String>{};
    for (final evidence in values) {
      final minimum = _minimumUnitValueCp[evidence.materialId];
      final boundId = bindingByMaterial[evidence.materialId];
      if (minimum == null ||
          !seen.add(evidence.materialId) ||
          boundId == null ||
          boundId != evidence.inventoryId ||
          !evidence.identityIndependentlyConfirmed ||
          !evidence.valueIndependentlyConfirmed ||
          evidence.confirmedUnitValueCp < minimum) {
        throw const FormatException(
          'Materialidentität oder einzelner Mindestwert nicht bestätigt.',
        );
      }

      // Typed inventory prices are OPTIONAL metadata, not independent proof.
      // Reject inconsistent records; never treat a matching user-entered
      // price as a substitute for separately confirmed evidence.
      final storedPrice = inventoryById[boundId]!.stats?.priceCp;
      if (storedPrice != null && storedPrice != evidence.confirmedUnitValueCp) {
        throw const FormatException(
          'Bestätigter Materialwert widerspricht Inventarmetadaten.',
        );
      }
    }
    return Map.unmodifiable(consumption);
  }

  /// Atomic resource/inventory transition only AFTER an independent,
  /// previously approved spell effect and a freshly minted cast plan.
  ///
  /// Old call sites are preserved; they are NOT automatically migrated to
  /// this strict value-evidence path. Persistence remains the controller's
  /// responsibility and no effect is inferred from this method.
  static SpellCastResult commitConfirmedCast(
    HeroCharacter hero,
    SrdSpellCastPlan plan, {
    required bool spellEffectResolvedConfirmed,
    required List<SrdAuditedInventoryBinding> bindings,
    required List<SrdSpellMaterialValueEvidence> values,
    int? confirmedTargetCount,
  }) {
    validatedConsumption(
      hero,
      plan.spell,
      bindings: bindings,
      values: values,
      confirmedTargetCount: confirmedTargetCount,
    );
    return SrdSpellInventoryRules.commitConfirmedCast(
      hero,
      plan,
      spellEffectResolvedConfirmed: spellEffectResolvedConfirmed,
      materialIdentityAndQuantityConfirmed: true,
      auditedBindings: bindings,
      confirmedTargetCount: confirmedTargetCount,
    );
  }
}
