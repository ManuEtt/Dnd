import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_equipment_catalog.dart';

/// Transfers confirmed SRD starting gear into typed inventory data.
/// The class kit's labels may be editorial aliases; never guess the actual
/// instrument, holy symbol, tool, or other unresolved player choice.
class StartingEquipmentImport {
  const StartingEquipmentImport._();

  static const monkToolLabel = 'Handwerkszeug oder Musikinstrument (nach Wahl)';

  static List<EquipmentEntry> get monkTools =>
      optionsFor(const SrdStartingItem(monkToolLabel));

  static const Map<String, String> _aliases = {
    'Zweihänder': 'weapon-greatsword',
    'Kräuterkunde-Ausrüstung': 'item-herbalism-kit',
    'Arkaner Fokus (Kristall)': 'item-arcane-focus-crystal',
    'Arkaner Fokus (Kugel)': 'item-arcane-focus-orb',
    'Arkaner Fokus (Kampfstab)': 'item-arcane-focus-staff',
    'Buch (okkultes Wissen)': 'item-book',
    // The catalog lists arrows per bundle of 20. See bundle conversion below.
    'Pfeil': 'item-arrows-20',
  };

  /// Match only an exact SRD label or a reviewed, unambiguous alias.
  /// Names such as "Heiliges Symbol" or "Musikinstrument (nach Wahl)"
  /// remain unresolved and must be selected by the player.
  static EquipmentEntry? catalogEntry(String name) {
    final alias = _aliases[name];
    if (alias != null) return SrdEquipmentCatalog.byId(alias);
    final matches = SrdEquipmentCatalog.all.where(
      (entry) => entry.name == name,
    );
    return matches.length == 1 ? matches.single : null;
  }

  // SRD 5.2.1 Equipment / Artisan's Tools, pp. 93–94. Other tools (for
  // example Thieves' Tools) are not interchangeable with artisan's tools.
  static const _artisanToolIds = {
    'item-alchemist-s-supplies',
    'item-brewer-s-supplies',
    'item-calligrapher-s-supplies',
    'item-carpenter-s-tools',
    'item-cartographer-s-tools',
    'item-cobbler-s-tools',
    'item-cook-s-utensils',
    'item-glassblower-s-tools',
    'item-jeweler-s-tools',
    'item-leatherworker-s-tools',
    'item-mason-s-tools',
    'item-painter-s-supplies',
    'item-potter-s-tools',
    'item-smith-s-tools',
    'item-tinker-s-tools',
    'item-weaver-s-tools',
    'item-woodcarver-s-tools',
  };

  /// Explicit class-kit choices. Version 1 predates holy-symbol selection;
  /// keep its historical unresolved item readable without inventing a grant.
  /// Version 2 resolves holy symbols; version 3 also binds Monk equipment
  /// to its separately confirmed training in StartingClassChoice.
  static List<EquipmentEntry> optionsFor(
    SrdStartingItem item, {
    int choiceVersion = 2,
  }) {
    if (choiceVersion < 1 || choiceVersion > 3) {
      throw const FormatException('Unbekannte Startausrüstungsregelversion.');
    }
    // SRD 5.2.1, Equipment / Holy Symbol, p.97. Arcane and druidic
    // foci are not substitutes, even though all use the focus category.
    if (item.name == 'Heiliges Symbol' && choiceVersion >= 2) {
      return [
        for (final id in const [
          'item-holy-symbol-amulet',
          'item-holy-symbol-emblem',
          'item-holy-symbol-reliquary',
        ])
          SrdEquipmentCatalog.byId(id)!,
      ];
    }
    final categories = switch (item.name) {
      'Musikinstrument (nach Wahl)' => const {EquipmentCategory.instrument},
      'Handwerkszeug oder Musikinstrument (nach Wahl)' => const {
        EquipmentCategory.tool,
        EquipmentCategory.instrument,
      },
      _ => const <EquipmentCategory>{},
    };
    if (categories.isEmpty) return const [];
    return SrdEquipmentCatalog.all
        .where(
          (entry) =>
              categories.contains(entry.category) &&
              (item.name != 'Handwerkszeug oder Musikinstrument (nach Wahl)' ||
                  entry.category == EquipmentCategory.instrument ||
                  _artisanToolIds.contains(entry.id)),
        )
        .toList(growable: false);
  }

  /// Validates the complete explicit kit choice before any character is
  /// mutated. Unknown IDs and a selection for another kit fail closed.
  static void validateKitChoices(
    SrdStartingKit kit,
    Map<String, String> selected, {
    int choiceVersion = 2,
  }) {
    if (choiceVersion < 1 || choiceVersion > 3) {
      throw const FormatException('Unbekannte Startausrüstungsregelversion.');
    }
    final expected = <String, List<EquipmentEntry>>{
      for (final item in kit.items)
        if (optionsFor(item, choiceVersion: choiceVersion).isNotEmpty)
          item.name: optionsFor(item, choiceVersion: choiceVersion),
    };
    for (final entry in selected.entries) {
      final options = expected[entry.key];
      if (options == null || !options.any((item) => item.id == entry.value)) {
        throw const FormatException(
          'Ungültige Startausrüstungswahl im SRD-Katalog.',
        );
      }
    }
    for (final name in expected.keys) {
      if (!selected.containsKey(name)) {
        throw FormatException(
          'Bitte für „$name“ einen konkreten SRD-Gegenstand wählen.',
        );
      }
    }
  }

  /// Resolve player-selected starter gear to the chosen *typed* catalog item.
  /// Never grant a category's first default instrument or tool automatically.
  static InventoryItem fromSelectedStartingItem(
    SrdStartingItem item,
    String id, {
    String? selectedCatalogId,
    int choiceVersion = 2,
  }) {
    final options = optionsFor(item, choiceVersion: choiceVersion);
    if (options.isEmpty) {
      if (selectedCatalogId != null) {
        throw const FormatException(
          'Für diesen Gegenstand gibt es keine freie Startausrüstungswahl.',
        );
      }
      return fromStartingItem(item, id);
    }
    if (selectedCatalogId == null) {
      throw FormatException(
        'Für „${item.name}“ ist eine Auswahl erforderlich.',
      );
    }
    for (final entry in options) {
      if (entry.id != selectedCatalogId) continue;
      return InventoryItem(
        id: id,
        name: entry.name,
        quantity: item.quantity,
        description: entry.note ?? '',
        catalogId: entry.id,
        stats: InventoryItemStats.fromCatalog(entry),
      );
    }
    throw const FormatException('Ungültiger SRD-Startgegenstand.');
  }

  /// All data fields originate from an exact SRD entry, never from prose.
  /// A 20-arrow starting stack is one catalog bundle of 20 arrows, NOT
  /// twenty separate bundles containing 400 arrows.
  static InventoryItem fromStartingItem(SrdStartingItem item, String id) {
    final entry = catalogEntry(item.name);
    if (entry == null) {
      return InventoryItem(id: id, name: item.name, quantity: item.quantity);
    }
    final arrowBundle = entry.id == 'item-arrows-20';
    if (arrowBundle && item.quantity % 20 != 0) {
      throw const FormatException(
        'Pfeilanzahl ist nicht in SRD-Katalogpaketen zu 20 enthalten.',
      );
    }
    return InventoryItem(
      id: id,
      name: arrowBundle ? entry.name : item.name,
      quantity: arrowBundle ? item.quantity ~/ 20 : item.quantity,
      description: entry.note ?? '',
      catalogId: entry.id,
      stats: InventoryItemStats.fromCatalog(entry),
    );
  }

  /// Explicitly approved migration for older start equipment without stats.
  /// Preserve original IDs, quantities, descriptions, custom values and
  /// unknown/ambiguous items. Do not replace a user-selected catalog entry.
  static InventoryItem enrichLegacyItem(InventoryItem item) {
    if (item.catalogId.isNotEmpty || item.stats != null) return item;
    final entry = catalogEntry(item.name);
    if (entry == null) return item;
    if (entry.id == 'item-arrows-20' && item.quantity % 20 != 0) {
      return item;
    }
    final isArrowPack = entry.id == 'item-arrows-20';
    return InventoryItem(
      id: item.id,
      name: isArrowPack ? entry.name : item.name,
      quantity: isArrowPack ? item.quantity ~/ 20 : item.quantity,
      description: item.description,
      catalogId: entry.id,
      stats: InventoryItemStats.fromCatalog(entry),
    );
  }
}
