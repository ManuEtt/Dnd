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

/// One independently identified component of a manually audited SRD spell.
///
/// These IDs refer to catalogue requirements, never to inventory item IDs.
/// An inventory adapter must separately verify exact items and amounts.
class SrdAuditedMaterialItem {
  const SrdAuditedMaterialItem({
    required this.id,
    required this.label,
    required this.isConsumed,
  });

  final String id;
  final String label;
  final bool isConsumed;
}

/// Confirmation of a specific, audited component and its full required count.
///
/// This is a declared fact, not evidence of inventory access or payment.
class SrdMaterialItemConfirmation {
  const SrdMaterialItemConfirmation({
    required this.id,
    required this.identityAndCostConfirmed,
    required this.requiredQuantityConfirmed,
    this.consumptionReservedConfirmed = false,
  });

  final String id;
  final bool identityAndCostConfirmed;
  final bool requiredQuantityConfirmed;
  final bool consumptionReservedConfirmed;
}

class _AuditedMaterialRecipe {
  const _AuditedMaterialRecipe(this.catalogueText, this.items);

  final String catalogueText;
  final List<SrdAuditedMaterialItem> items;
}

typedef _AuditedSpellIdentity = ({
  String id,
  int level,
  String school,
  String castingTime,
  String range,
  String duration,
  List<String> classes,
});

/// SRD 5.2.1, Spells / Casting Spells / Components: a component pouch or an
/// authorized focus can replace ONLY unpriced, non-consumed materials.
///
/// This validator checks explicit player/engine confirmations; it does not
/// claim to inspect the inventory, reserve an object or spend money. Those
/// operations must be handled by the future transactional inventory engine.
class SrdSpellComponentRules {
  const SrdSpellComponentRules._();

  // These four expensive multi-material recipes are security-sensitive:
  // a component text match must not authorize a forged spell level, class,
  // casting time or stable catalogue identity. Match the working SRD index
  // byte-for-byte for each audited spell; a future reconciliation requires
  // an explicit recipe review before admitting changed metadata.
  static const _auditedSpellIdentities = <String, _AuditedSpellIdentity>{
    'Astral Projection': (
      id: 'spell-astral-projection',
      level: 9,
      school: 'Necromancy',
      castingTime: '1 hour',
      range: '10 feet',
      duration: 'Until dispelled',
      classes: ['Cleric', 'Warlock', 'Wizard'],
    ),
    'Clone': (
      id: 'spell-clone',
      level: 8,
      school: 'Necromancy',
      castingTime: '1 hour',
      range: 'Touch',
      duration: 'Instantaneous',
      classes: ['Wizard'],
    ),
    'Legend Lore': (
      id: 'spell-legend-lore',
      level: 5,
      school: 'Divination',
      castingTime: '10 minutes',
      range: 'Self',
      duration: 'Instantaneous',
      classes: ['Bard', 'Cleric', 'Wizard'],
    ),
    'Secret Chest': (
      id: 'spell-secret-chest',
      level: 4,
      school: 'Conjuration',
      castingTime: 'Action',
      range: 'Touch',
      duration: 'Until dispelled',
      classes: ['Wizard'],
    ),
  };

  // These four multi-priced recipes have been checked against the exact
  // catalogue metadata. Unknown or edited recipes are never guessed.
  static const _auditedRecipes = <String, _AuditedMaterialRecipe>{
    'Astral Projection': _AuditedMaterialRecipe(
      "V, S, M (for each of the spell's targets, one jacinth worth 1,000+ GP "
      'and one silver bar worth 100+ GP, all of which the spell consumes)',
      [
        SrdAuditedMaterialItem(
          id: 'astral-jacinth',
          label: 'one jacinth per target (1,000+ GP each)',
          isConsumed: true,
        ),
        SrdAuditedMaterialItem(
          id: 'astral-silver-bar',
          label: 'one silver bar per target (100+ GP each)',
          isConsumed: true,
        ),
      ],
    ),
    'Clone': _AuditedMaterialRecipe(
      'V, S, M (a diamond worth 1,000+ GP, which the spell consumes, '
      'and a sealable vessel worth 2,000+ GP that is large enough to hold '
      'the creature being cloned)',
      [
        SrdAuditedMaterialItem(
          id: 'clone-diamond',
          label: 'diamond (1,000+ GP)',
          isConsumed: true,
        ),
        SrdAuditedMaterialItem(
          id: 'clone-vessel',
          label: 'sealable vessel (2,000+ GP)',
          isConsumed: false,
        ),
      ],
    ),
    'Legend Lore': _AuditedMaterialRecipe(
      'V, S, M (incense worth 250+ GP, which the spell consumes, '
      'and four ivory strips worth 50+ GP each)',
      [
        SrdAuditedMaterialItem(
          id: 'legend-incense',
          label: 'incense (250+ GP)',
          isConsumed: true,
        ),
        SrdAuditedMaterialItem(
          id: 'legend-ivory-strips',
          label: 'four ivory strips (50+ GP each)',
          isConsumed: false,
        ),
      ],
    ),
    'Secret Chest': _AuditedMaterialRecipe(
      'V, S, M (a chest, 3 feet by 2 feet by 2 feet, constructed from '
      'rare materials worth 5,000+ GP, and a Tiny replica of the chest '
      'made from the same materials worth 50+ GP)',
      [
        SrdAuditedMaterialItem(
          id: 'secret-large-chest',
          label: 'large chest (5,000+ GP)',
          isConsumed: false,
        ),
        SrdAuditedMaterialItem(
          id: 'secret-tiny-replica',
          label: 'tiny replica (50+ GP)',
          isConsumed: false,
        ),
      ],
    ),
  };

  /// Only a verified exact metadata match can mint this item list.
  /// A changed transcription must be audited before it is accepted.
  static List<SrdAuditedMaterialItem> auditedItems(SrdSpellDefinition spell) {
    final recipe = _auditedRecipes[spell.name];
    if (recipe == null) {
      // Do not downgrade one of the audited spell IDs to a free-form recipe
      // merely by changing the publicly constructed spell's display name.
      if (_auditedSpellIdentities.values.any(
        (identity) => identity.id == spell.id,
      )) {
        throw const FormatException(
          'SRD-Zauber-ID und geprüfter Materialzauber widersprechen sich.',
        );
      }
      return const [];
    }
    final expected = _auditedSpellIdentities[spell.name]!;
    if (spell.id != expected.id ||
        spell.level != expected.level ||
        spell.school != expected.school ||
        spell.castingTime != expected.castingTime ||
        spell.range != expected.range ||
        spell.duration != expected.duration ||
        !spell.verbal ||
        !spell.somatic ||
        !spell.material ||
        spell.concentration ||
        spell.ritual ||
        spell.components != recipe.catalogueText ||
        spell.classes.length != expected.classes.length) {
      throw const FormatException(
        'Geprüfter SRD-Materialzauber besitzt abweichende Metadaten.',
      );
    }
    for (var i = 0; i < expected.classes.length; i++) {
      if (spell.classes[i] != expected.classes[i]) {
        throw const FormatException(
          'Die Klassenliste des geprüften SRD-Materialzaubers weicht ab.',
        );
      }
    }
    return recipe.items;
  }

  static void _validateItemConfirmations(
    List<SrdAuditedMaterialItem> items,
    List<SrdMaterialItemConfirmation> confirmations,
  ) {
    if (items.isEmpty) {
      if (confirmations.isNotEmpty) {
        throw const FormatException(
          'Für diesen Zauber sind keine Einzelbestätigungen definiert.',
        );
      }
      return;
    }
    final approvals = <String, SrdMaterialItemConfirmation>{};
    for (final confirmation in confirmations) {
      if (approvals.containsKey(confirmation.id)) {
        throw const FormatException('Materialanforderung doppelt bestätigt.');
      }
      approvals[confirmation.id] = confirmation;
    }
    if (approvals.length != items.length ||
        !approvals.keys.toSet().containsAll(items.map((item) => item.id))) {
      throw const FormatException(
        'Nicht alle einzelnen Zaubermaterialien sind bestätigt.',
      );
    }
    for (final item in items) {
      final confirmation = approvals[item.id]!;
      if (!confirmation.identityAndCostConfirmed ||
          !confirmation.requiredQuantityConfirmed ||
          (item.isConsumed && !confirmation.consumptionReservedConfirmed) ||
          (!item.isConsumed && confirmation.consumptionReservedConfirmed)) {
        throw const FormatException(
          'Identität, Preis, Anzahl oder Verbrauch eines Materials '
          'sind nicht korrekt bestätigt.',
        );
      }
    }
  }

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
    // Directly constructed definitions bypass fromJson validation: reject
    // inconsistent V/S/M flags before component confirmations are assessed.
    SrdSpellDefinition.validateComponentMetadata(
      components: spell.components,
      verbal: spell.verbal,
      somatic: spell.somatic,
      material: spell.material,
    );
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
    List<SrdMaterialItemConfirmation> confirmedMaterialItems = const [],
  }) {
    final needed = requirements(spell);
    _validateItemConfirmations(auditedItems(spell), confirmedMaterialItems);
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
