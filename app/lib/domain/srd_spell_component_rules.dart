import 'srd_spell_catalog.dart';

/// A material source for a spell that explicitly requires an M component.
///
/// A focus is only an alternative if the caster's class or another feature
/// permits it. The existence of a focus never proves such permission.
enum SrdSpellMaterialSource {
  specificComponents,
  componentPouch,
  spellcastingFocus,
}

/// Metadata-only classification: no currency or inventory is spent here.
///
/// The spell catalogue is still awaiting full reconciliation with the official
/// SRD. Only explicit entries in its components field are interpreted.
class SrdSpellMaterialRequirements {
  const SrdSpellMaterialRequirements({
    required this.hasMaterial,
    required this.hasSpecifiedCost,
    required this.isConsumed,
  });

  final bool hasMaterial;
  final bool hasSpecifiedCost;
  final bool isConsumed;

  bool get maySubstitute => hasMaterial && !hasSpecifiedCost && !isConsumed;
}

/// SRD 5.2.1, Spells / Casting Spells / Components: a component pouch or an
/// authorized focus can replace ONLY unpriced, non-consumed materials.
///
/// This validator checks explicit player/engine confirmations; it does not
/// claim to inspect the inventory, reserve an object or spend money. Those
/// operations must be handled by the future transactional inventory engine.
class SrdSpellComponentRules {
  const SrdSpellComponentRules._();

  static final RegExp _price = RegExp(
    r'\b\d[\d,]*\+?\s*(?:CP|SP|EP|GP|PP|Copper Pieces?|Silver Pieces?|Electrum Pieces?|Gold Pieces?|Platinum Pieces?)\b',
    caseSensitive: false,
  );
  static final RegExp _consumption = RegExp(
    r'\b(?:consume|consumes|consumed|consuming|expended)\b',
    caseSensitive: false,
  );
  static final RegExp _ambiguousPrice = RegExp(
    r'\b(?:worth|costs?|priced)\b',
    caseSensitive: false,
  );

  static SrdSpellMaterialRequirements requirements(SrdSpellDefinition spell) {
    if (!spell.material) {
      return const SrdSpellMaterialRequirements(
        hasMaterial: false,
        hasSpecifiedCost: false,
        isConsumed: false,
      );
    }
    final match = RegExp(r'\(([^()]*)\)\s*$').firstMatch(spell.components);
    if (match == null || match.group(1)!.trim().isEmpty) {
      throw const FormatException(
        'SRD-Materialkomponenten fehlen oder sind nicht eindeutig.',
      );
    }
    final description = match.group(1)!;
    return SrdSpellMaterialRequirements(
      hasMaterial: true,
      hasSpecifiedCost:
          _price.hasMatch(description) || _ambiguousPrice.hasMatch(description),
      isConsumed: _consumption.hasMatch(description),
    );
  }

  static SrdSpellMaterialRequirements validateMaterial(
    SrdSpellDefinition spell, {
    required bool materialComponentConfirmed,
    SrdSpellMaterialSource source = SrdSpellMaterialSource.specificComponents,
    bool focusUseAuthorizedConfirmed = false,
    bool costlyComponentAvailableConfirmed = false,
    bool consumedComponentReservedConfirmed = false,
  }) {
    final needed = requirements(spell);
    if (!needed.hasMaterial) return needed;
    if (!materialComponentConfirmed) {
      throw const FormatException(
        'Materielle Komponente und Zugriff darauf sind nicht bestätigt.',
      );
    }
    if (source != SrdSpellMaterialSource.specificComponents &&
        !needed.maySubstitute) {
      throw const FormatException(
        'Kostenpflichtige oder verbrauchte Materialien sind nicht ersetzbar.',
      );
    }
    if (source == SrdSpellMaterialSource.spellcastingFocus &&
        !focusUseAuthorizedConfirmed) {
      throw const FormatException(
        'Nutzung des Zauberfokus ist nicht regelbestätigt.',
      );
    }
    if (needed.hasSpecifiedCost && !costlyComponentAvailableConfirmed) {
      throw const FormatException(
        'Die vorgeschriebenen kostspieligen Materialien sind nicht bestätigt.',
      );
    }
    if (needed.isConsumed && !consumedComponentReservedConfirmed) {
      throw const FormatException(
        'Material für jeden Zaubervorgang muss verfügbar sein.',
      );
    }
    return needed;
  }
}
