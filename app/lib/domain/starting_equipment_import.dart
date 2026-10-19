import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_equipment_catalog.dart';

/// Transfers confirmed SRD starting gear into typed inventory data.
/// The class kit's labels may be editorial aliases; never guess the actual
/// instrument, holy symbol, tool, or other unresolved player choice.
class StartingEquipmentImport {
  const StartingEquipmentImport._();

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

  /// The three known class starter labels with an unresolved player choice.
  /// Only SRD catalog entries from the matching mundane item categories
  /// can be chosen. A holy symbol has no matching catalog entries yet;
  /// it stays explicitly unresolved rather than creating invented stats.
  static List<EquipmentEntry> optionsFor(SrdStartingItem item) {
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
        .where((entry) => categories.contains(entry.category))
        .toList(growable: false);
  }

  /// Validates the complete explicit kit choice before any character is
  /// mutated. Unknown IDs and a selection for another kit fail closed.
  static void validateKitChoices(
    SrdStartingKit kit,
    Map<String, String> selected,
  ) {
    final expected = <String, List<EquipmentEntry>>{
      for (final item in kit.items)
        if (optionsFor(item).isNotEmpty) item.name: optionsFor(item),
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
  }) {
    final options = optionsFor(item);
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
