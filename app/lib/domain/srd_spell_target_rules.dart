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
    this.withinTouchReachConfirmed = false,
  });

  final SrdSpellOriginMode mode;
  final int? originDistanceFeet;
  final bool clearPathConfirmed;
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
/// Supports Self, Touch and fixed distances in feet or miles.
///
/// This is a *limited, conservative* preflight, NOT a full target engine:
/// spell-specific targeting, creature types, invalid targets, areas of
/// effect, movable effects and obstacles that relocate an unseen AoE origin
/// must be checked by the caller's separately confirmed spell effect rules.
/// Unhandled catalogue ranges fail closed rather than masquerading as 0 feet.
class SrdSpellTargetRules {
  const SrdSpellTargetRules._();

  static int? maxRangeFeet(String range) {
    final match = RegExp(
      r'^(\d+) (feet|foot|mile|miles)$',
      caseSensitive: false,
    ).firstMatch(range.trim());
    if (match == null) return null;
    final value = int.parse(match.group(1)!);
    return value * (match.group(2)!.toLowerCase().startsWith('mile') ? 5280 : 1);
  }

  static SrdSpellTargetAssessment validateOrigin(
    SrdSpellDefinition spell,
    SrdSpellTargetFacts facts,
  ) {
    final range = spell.range.trim();
    final distance = facts.originDistanceFeet;
    if (distance != null && distance < 0) {
      throw const FormatException('Der Ursprungabstand darf nicht negativ sein.');
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
