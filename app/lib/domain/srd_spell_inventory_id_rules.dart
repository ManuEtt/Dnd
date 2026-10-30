/// Identifiers of inventory stacks used as evidence for SRD spell materials.
///
/// The spell engine must never trust a visually ambiguous stack ID as an
/// independently verified material binding. This does not inspect item names,
/// confirm an item's value or migrate historical saved inventories.
class SrdSpellInventoryIdRules {
  const SrdSpellInventoryIdRules._();

  // Control codes, Unicode directional formatting, invisible separators and
  // soft hyphens can make two distinct IDs look identical in an audit trail.
  // Keep international letters and ordinary internal spaces valid.
  static final RegExp _unsafe = RegExp(
    r'[\x00-\x1f\x7f-\x9f\u00ad\u034f\u061c\u180e\u200b-\u200f\u2028-\u202e\u2060-\u2069\ufeff]',
  );

  static bool isSafe(String id) =>
      id.isNotEmpty && id.trim() == id && !_unsafe.hasMatch(id);
}
