import 'srd_spell_catalog.dart';

/// The spell's origin is not always its eventual affected target.
/// For Self cones/emanations, the origin is the caster, not a remote creature.
enum SrdSpellOriginMode { caster, touched, distant }

/// Explicitly supplied spatial facts; no position or visibility is guessed.
/// Clear path is a separate requirement from visibility.
class SrdSpellTargetFacts {
  const SrdSpellTargetFacts({
    required this.mode,
    this.originDistanceFeet,
    this.clearPathConfirmed = false,
    this.visibleOriginConfirmed = false,
    this.withinTouchReachConfirmed = false,
  });

  final SrdSpellOriginMode mode;
  final int? originDistanceFeet;
  final bool clearPathConfirmed;

  /// True only after sight of the spell origin was explicitly confirmed.
  /// A clear ray through surveyed obstacles does not establish visibility.
  final bool visibleOriginConfirmed;
  final bool withinTouchReachConfirmed;
}

/// Auditable result from spell-range metadata and declared geometry.
/// This does not determine what creatures or objects the spell may affect.
class SrdSpellTargetAssessment {
  const SrdSpellTargetAssessment({
    required this.mode,
    required this.range,
    this.maxOriginDistanceFeet,
    this.originDistanceFeet,
  });

  final SrdSpellOriginMode mode;
  final String range;
  final int? maxOriginDistanceFeet;
  final int? originDistanceFeet;
}

/// SRD 5.2.1: Range, Targets, and clear path to the target.
/// Supports Self, Touch, fixed distances and explicitly verified Sight.
/// 'Unlimited' and 'Special' remain unsupported until their own spell rules
/// can validate the target, not merely the range description.
///
/// This is a *limited, conservative* preflight, NOT a full target engine:
/// spell-specific targeting, creature types, invalid targets, areas of
/// effect, movable effects and obstacles that relocate an unseen AoE origin
/// must be checked by the caller's separately confirmed spell effect rules.
/// Unhandled catalogue ranges fail closed rather than masquerading as 0 feet.
class SrdSpellTargetRules {
  const SrdSpellTargetRules._();

  // The working 339-spell SRD 5.2.1 index contains exactly these 18 range
  // entries. Numeric conversion below stays general-purpose, but a plausible
  // invented range must not be accepted as audited spell metadata.
  // Source: SRD 5.2.1 / Spells / Range (CC BY 4.0).
  // https://www.dndbeyond.com/srd
  static const _knownRangeForms = <String>{
    'Self',
    'Touch',
    'Sight',
    'Special',
    'Unlimited',
    '5 feet',
    '10 feet',
    '15 feet',
    '30 feet',
    '60 feet',
    '90 feet',
    '100 feet',
    '120 feet',
    '150 feet',
    '300 feet',
    '500 feet',
    '1 mile',
    '500 miles',
  };

  // These identity/range pairs are separately checked against the indexed
  // SRD spell descriptions. Public constructors must not silently substitute
  // another spell's range for one of these known entries. Other spells
  // still need individual verification; this is NOT a full target engine.
  static const _pinnedRanges = <String, ({String id, String range})>{
    'Aid': (id: 'spell-aid', range: '30 feet'),
    'Burning Hands': (id: 'spell-burning-hands', range: 'Self'),
    'Counterspell': (id: 'spell-counterspell', range: '60 feet'),
    'Cure Wounds': (id: 'spell-cure-wounds', range: 'Touch'),
    'Dimension Door': (id: 'spell-dimension-door', range: '500 feet'),
    'Fireball': (id: 'spell-fireball', range: '150 feet'),
    'Magic Missile': (id: 'spell-magic-missile', range: '120 feet'),
    'Mirage Arcane': (id: 'spell-mirage-arcane', range: 'Sight'),
    'Project Image': (id: 'spell-project-image', range: '500 miles'),
    'Sending': (id: 'spell-sending', range: 'Unlimited'),
    'Shield': (id: 'spell-shield', range: 'Self'),
    'Word of Recall': (id: 'spell-word-of-recall', range: '5 feet'),
  };

  static int? maxRangeFeet(String range) {
    final match = RegExp(
      r'^([1-9][0-9]*) (foot|feet|mile|miles)$',
    ).firstMatch(range);
    // Some regular expressions allow $ before a final newline.
    // Require the entire metadata value, not merely a matching prefix.
    if (match == null || match.group(0) != range) return null;

    final amount = int.tryParse(match.group(1)!);
    if (amount == null) return null;
    final unit = match.group(2)!.toLowerCase();
    final isSingular = unit == 'foot' || unit == 'mile';
    if ((amount == 1) != isSingular) return null;

    // Avoid signed 64-bit overflow when untrusted metadata uses miles.
    final multiplier = unit.startsWith('mile') ? 5280 : 1;
    if (amount > 0x7fffffffffffffff ~/ multiplier) return null;
    return amount * multiplier;
  }

  static SrdSpellTargetAssessment validateOrigin(
    SrdSpellDefinition spell,
    SrdSpellTargetFacts facts,
  ) {
    final range = spell.range;
    if (range != range.trim()) {
      throw const FormatException(
        'Zauberreichweite enthält nicht bestätigte Randzeichen.',
      );
    }
    final pinned = _pinnedRanges[spell.name];
    if (pinned != null) {
      if (spell.id != pinned.id || range != pinned.range) {
        throw const FormatException(
          'Die SRD-Zauberreichweite passt nicht zur Zauberidentität.',
        );
      }
    } else if (_pinnedRanges.values.any((entry) => entry.id == spell.id)) {
      throw const FormatException(
        'Die SRD-Zauberidentität passt nicht zur geprüften Reichweite.',
      );
    }
    if (!_knownRangeForms.contains(range)) {
      throw UnsupportedError('Ungeprüfte SRD-Zauberreichweite: $range');
    }
    final distance = facts.originDistanceFeet;
    if (distance != null && distance < 0) {
      throw const FormatException(
        'Der Ursprungabstand darf nicht negativ sein.',
      );
    }

    if (range == 'Self') {
      if (facts.mode != SrdSpellOriginMode.caster || distance != 0) {
        throw const FormatException(
          'Bei Reichweite Selbst muss der Zauber am Wirker beginnen.',
        );
      }
      return SrdSpellTargetAssessment(
        mode: facts.mode,
        range: range,
        originDistanceFeet: 0,
      );
    }

    if (range == 'Touch') {
      if (facts.mode != SrdSpellOriginMode.touched ||
          distance != null ||
          !facts.withinTouchReachConfirmed ||
          !facts.clearPathConfirmed) {
        throw const FormatException(
          'Berührung benötigt eine bestätigte erreichbare Berührungsstelle '
          'ohne vollständige Deckung.',
        );
      }
      return SrdSpellTargetAssessment(mode: facts.mode, range: range);
    }

    if (range == 'Sight') {
      // "Sight" has no numeric maximum: known distance does not establish
      // visibility. Conversely a clear grid ray alone is not sufficient.
      if (facts.mode != SrdSpellOriginMode.distant ||
          !facts.visibleOriginConfirmed ||
          !facts.clearPathConfirmed) {
        throw const FormatException(
          'Reichweite Sicht benötigt einen ausdrücklich sichtbaren '
          'Zauberursprung und einen bestätigten freien Weg.',
        );
      }
      return SrdSpellTargetAssessment(
        mode: facts.mode,
        range: range,
        originDistanceFeet: distance,
      );
    }

    final maximum = maxRangeFeet(range);
    if (maximum == null) {
      throw UnsupportedError(
        'Die Reichweite $range benötigt eine spezielle SRD-Regel.',
      );
    }
    if (facts.mode != SrdSpellOriginMode.distant ||
        distance == null ||
        distance > maximum ||
        !facts.clearPathConfirmed) {
      throw const FormatException(
        'Zauberursprung außerhalb der Reichweite oder ohne freien Weg.',
      );
    }
    return SrdSpellTargetAssessment(
      mode: facts.mode,
      range: range,
      maxOriginDistanceFeet: maximum,
      originDistanceFeet: distance,
    );
  }
}
