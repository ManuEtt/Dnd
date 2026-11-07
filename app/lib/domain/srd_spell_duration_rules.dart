import 'srd_spell_catalog.dart';

/// Metadata-only duration classification for SRD 5.2.1 spell descriptions.
///
/// Source: SRD 5.2.1, "Spells / Duration", p. 106 (CC BY 4.0).
/// https://www.dndbeyond.com/srd
///
/// No clock, turn progression, concentration state or spell effect is changed.
/// A time span alone does not authorize automatic effect expiration: some
/// spells also end on spell-specific conditions or dispelling.
enum SrdSpellDurationKind {
  instantaneous,
  fixedTime,
  upTo,
  concentration,
  untilDispelled,
  conditional,
}

enum SrdSpellDurationUnit { round, minute, hour, day }

class SrdSpellDurationAssessment {
  const SrdSpellDurationAssessment({
    required this.kind,
    this.amount,
    this.unit,
  });

  final SrdSpellDurationKind kind;
  final int? amount;
  final SrdSpellDurationUnit? unit;

  bool get hasTimeLimit => amount != null && unit != null;
  bool get requiresConcentration => kind == SrdSpellDurationKind.concentration;

  /// "Up to" is only a ceiling; the spell-specific ending rule is separate.
  bool get hasExplicitEarlyEnding =>
      kind == SrdSpellDurationKind.upTo ||
      kind == SrdSpellDurationKind.concentration ||
      kind == SrdSpellDurationKind.conditional;

  /// Only the metadata names dispelling; it does not confirm a dispel event.
  bool get explicitlyEndsOnDispel =>
      kind == SrdSpellDurationKind.untilDispelled ||
      kind == SrdSpellDurationKind.conditional;
}

/// Read-only interpretation of catalogue duration metadata. Unknown wording
/// deliberately fails closed rather than manufacturing a game-time deadline.
class SrdSpellDurationRules {
  const SrdSpellDurationRules._();

  // The 339-entry working SRD 5.2.1 catalogue uses 24 distinct duration
  // strings. "Special" requires individual spell rules; the other 23 are
  // the only text forms this metadata interpreter has actually classified.
  // A plausible time like "999 days" must not mint an unaudited rule.
  static const _knownDurationForms = <String>{
    'Instantaneous',
    '8 hours',
    'Concentration, up to 1 hour',
    '24 hours',
    'Concentration, up to 1 minute',
    '10 days',
    'Until dispelled',
    'Concentration, up to 10 minutes',
    '1 hour',
    '1 minute',
    '7 days',
    'Concentration, up to 8 hours',
    'Up to 8 hours',
    'Concentration, up to 1 day',
    '10 minutes',
    '1 day',
    '30 days',
    'Until dispelled or triggered',
    '1 round',
    'Concentration, up to 2 hours',
    'Up to 1 hour',
    'Up to 1 minute',
    'Concentration, up to 6 rounds',
  };

  // A public SrdSpellDefinition constructor bypasses the catalogue loader.
  // Pin independently reviewed, duration-sensitive spells to both their
  // stable catalogue identity and exact duration metadata. This is a scoped
  // integrity guard, NOT proof that all 339 spell effects were audited.
  // Source: SRD 5.2.1 / Spells / Duration and individual spell entries,
  // Wizards of the Coast LLC, CC BY 4.0, https://www.dndbeyond.com/srd.
  static const _pinnedDurations = <String, ({String id, String duration})>{
    'Aid': (id: 'spell-aid', duration: '8 hours'),
    'Arcane Lock': (id: 'spell-arcane-lock', duration: 'Until dispelled'),
    'Bless': (id: 'spell-bless', duration: 'Concentration, up to 1 minute'),
    'Counterspell': (id: 'spell-counterspell', duration: 'Instantaneous'),
    'Fly': (id: 'spell-fly', duration: 'Concentration, up to 10 minutes'),
    'Geas': (id: 'spell-geas', duration: '30 days'),
    'Glyph of Warding': (
      id: 'spell-glyph-of-warding',
      duration: 'Until dispelled or triggered',
    ),
    'Haste': (id: 'spell-haste', duration: 'Concentration, up to 1 minute'),
    'Hex': (id: 'spell-hex', duration: 'Concentration, up to 1 hour'),
    'Invisibility': (
      id: 'spell-invisibility',
      duration: 'Concentration, up to 1 hour',
    ),
    'Mage Armor': (id: 'spell-mage-armor', duration: '8 hours'),
    'Magic Missile': (id: 'spell-magic-missile', duration: 'Instantaneous'),
    'Shield': (id: 'spell-shield', duration: '1 round'),
    'Tsunami': (
      id: 'spell-tsunami',
      duration: 'Concentration, up to 6 rounds',
    ),
  };

  static SrdSpellDurationAssessment inspect(SrdSpellDefinition spell) {
    final pinned = _pinnedDurations[spell.name];
    if (pinned != null) {
      if (spell.id != pinned.id || spell.duration != pinned.duration) {
        throw const FormatException(
          'Die SRD-Zauberdauer passt nicht zur bestätigten Zauberidentität.',
        );
      }
    } else if (_pinnedDurations.values.any((item) => item.id == spell.id)) {
      // A forged display name must not bypass a pinned catalogue ID.
      throw const FormatException(
        'Die SRD-Zauberidentität passt nicht zur geprüften Zauberdauer.',
      );
    }
    return parse(spell.duration, concentrationRequired: spell.concentration);
  }

  static SrdSpellDurationAssessment parse(
    String duration, {
    required bool concentrationRequired,
  }) {
    // Do not silently turn an unverified catalogue value into an approved
    // duration. Whitespace/control characters can hide an altered rule entry.
    if (duration != duration.trim()) {
      throw const FormatException(
        'Zauberdauer enthält nicht bestätigte Randzeichen.',
      );
    }
    final value = duration;
    const concentrationPrefix = 'Concentration, up to ';
    const upToPrefix = 'Up to ';
    final concentration = value.startsWith(concentrationPrefix);
    if (concentration != concentrationRequired) {
      throw const FormatException(
        'Konzentration und Zauberdauer widersprechen sich.',
      );
    }
    if (!_knownDurationForms.contains(value)) {
      throw UnsupportedError('Ungeprüfte SRD-Zauberdauer: $value');
    }

    if (value == 'Instantaneous') {
      return const SrdSpellDurationAssessment(
        kind: SrdSpellDurationKind.instantaneous,
      );
    }
    if (value == 'Until dispelled') {
      return const SrdSpellDurationAssessment(
        kind: SrdSpellDurationKind.untilDispelled,
      );
    }
    if (value == 'Until dispelled or triggered') {
      return const SrdSpellDurationAssessment(
        kind: SrdSpellDurationKind.conditional,
      );
    }

    final upTo = !concentration && value.startsWith(upToPrefix);
    final numeric = concentration
        ? value.substring(concentrationPrefix.length)
        : upTo
        ? value.substring(upToPrefix.length)
        : value;
    final match = RegExp(
      r'^([1-9][0-9]*) (rounds?|minutes?|hours?|days?)$',
    ).firstMatch(numeric);
    if (match == null) {
      throw UnsupportedError('Ungeprüfte Zauberdauer: $value');
    }

    final count = int.tryParse(match.group(1)!);
    if (count == null) {
      throw const FormatException('Zauberdauer liegt außerhalb des Bereichs.');
    }
    final word = match.group(2)!;
    if ((count == 1) == word.endsWith('s')) {
      throw const FormatException('Singular/Plural der Zauberdauer ungültig.');
    }
    final unit = switch (word) {
      'round' || 'rounds' => SrdSpellDurationUnit.round,
      'minute' || 'minutes' => SrdSpellDurationUnit.minute,
      'hour' || 'hours' => SrdSpellDurationUnit.hour,
      _ => SrdSpellDurationUnit.day,
    };
    return SrdSpellDurationAssessment(
      kind: concentration
          ? SrdSpellDurationKind.concentration
          : upTo
          ? SrdSpellDurationKind.upTo
          : SrdSpellDurationKind.fixedTime,
      amount: count,
      unit: unit,
    );
  }
}
