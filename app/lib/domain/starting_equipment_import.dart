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

  /// All data fields originate from an exact SRD entry, never from prose.
  /// A 20-arrow starting stack is one catalog bundle of 20 arrows, NOT
  /// twenty separate bundles containing 400 arrows.
  static InventoryItem fromStartingItem(SrdStartingItem item, String id) {
    final entry = catalogEntry(item.name);
    if (entry == null) {
      return InventoryItem(
        id: id,
        name: item.name,
        quantity: item.quantity,
      );
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
