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
  bool get requiresConcentration =>
      kind == SrdSpellDurationKind.concentration;

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

  static SrdSpellDurationAssessment inspect(SrdSpellDefinition spell) =>
      parse(spell.duration, concentrationRequired: spell.concentration);

  static SrdSpellDurationAssessment parse(
    String duration, {
    required bool concentrationRequired,
  }) {
    final value = duration.trim();
    const concentrationPrefix = 'Concentration, up to ';
    const upToPrefix = 'Up to ';
    final concentration = value.startsWith(concentrationPrefix);
    if (concentration != concentrationRequired) {
      throw const FormatException(
        'Konzentration und Zauberdauer widersprechen sich.',
      );
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
