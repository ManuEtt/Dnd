/// Identifiers of inventory stacks used as evidence for SRD spell materials.
///
/// The spell engine must never trust a visually ambiguous stack ID as an
/// independently verified material binding. This does not inspect item names,
/// confirm an item's value or migrate historical saved inventories.
class SrdSpellInventoryIdRules {
  const SrdSpellInventoryIdRules._();

  // Controls, invisible fillers and variation selectors can make distinct
  // inventory stack IDs look identical in material-confirmation audit trails.
  // Reject both BMP and supplementary variation selectors; ordinary Unicode
  // letters (including CJK) and internal ASCII spaces remain valid.
  static final RegExp _unsafe = RegExp(
    r'[\x00-\x1f\x7f-\x9f\u00ad\u034f\u061c'
    r'\u115f-\u1160\u17b4-\u17b5\u180e'
    r'\u200b-\u200f\u2028-\u202e\u2060-\u206f'
    r'\u2800\u3164\ufe00-\ufe0f\ufeff\uffa0'
    r'\ufff9-\ufffb\u{E0100}-\u{E01EF}]',
    unicode: true,
  );

  static bool isSafe(String id) =>
      id.isNotEmpty && id.trim() == id && !_unsafe.hasMatch(id);
}
