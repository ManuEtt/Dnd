import 'srd_concentration_damage_rules.dart';

/// Read-only concentration DC for one independently confirmed damage event.
class SrdConcentrationDamageDcEntry {
  const SrdConcentrationDamageDcEntry({
    required this.sourceId,
    required this.damageTaken,
    required this.difficultyClass,
  });

  final String sourceId;
  final int damageTaken;
  final int difficultyClass;
}

class SrdConcentrationDamageDcPreview {
  const SrdConcentrationDamageDcPreview({
    required this.checks,
    required this.highestDifficultyClass,
  });

  final List<SrdConcentrationDamageDcEntry> checks;
  final int highestDifficultyClass;
}

/// Each separate damage source requires its own Constitution save.
/// This helper only prepares the DCs; it does not roll, resolve or end
/// concentration, and never combines damage across separate sources.
class SrdConcentrationDamageDcRules {
  const SrdConcentrationDamageDcRules._();

  static final RegExp _unsafeId = RegExp(
    r'[\x00-\x1f\x7f-\x9f\u00ad\u034f\u061c\u180e\u200b-\u200f\u2028-\u202e\u2060-\u206f\ufeff\ufff9-\ufffb]',
  );

  static SrdConcentrationDamageDcPreview preview({
    required List<SrdConcentrationDamageSource> sources,
  }) {
    if (sources.isEmpty) {
      throw const FormatException('Keine Schadensquelle bestätigt.');
    }
    final ids = <String>{};
    final checks = <SrdConcentrationDamageDcEntry>[];
    var highest = 0;
    for (final source in sources) {
      if (!source.damageConfirmed ||
          source.sourceId.isEmpty ||
          source.sourceId.length > 128 ||
          source.sourceId != source.sourceId.trim() ||
          _unsafeId.hasMatch(source.sourceId) ||
          !ids.add(source.sourceId)) {
        throw const FormatException(
          'Schadensquelle ist unbekannt, doppelt oder nicht bestätigt.',
        );
      }
      final dc = SrdConcentrationDamageRules.difficultyClass(
        source.damageTaken,
      );
      if (dc > highest) highest = dc;
      checks.add(SrdConcentrationDamageDcEntry(
        sourceId: source.sourceId,
        damageTaken: source.damageTaken,
        difficultyClass: dc,
      ));
    }
    return SrdConcentrationDamageDcPreview(
      checks: List.unmodifiable(checks),
      highestDifficultyClass: highest,
    );
  }
}
