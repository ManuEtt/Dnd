import 'srd_spell_casting_time_rules.dart';
import 'srd_spell_catalog.dart';

/// Read-only timing for the optional ritual form of a verified SRD spell.
///
/// Ritual casting adds ten minutes to the ordinary casting time. An Action
/// does not have a confirmed minute duration, so its precise total remains
/// unknown rather than being rounded to ten minutes.
class SrdRitualCastingTimePreview {
  const SrdRitualCastingTimePreview({
    required this.additionalMinutes,
    required this.ordinaryMinutes,
    required this.totalMinutes,
  });

  final int additionalMinutes;
  final int? ordinaryMinutes;
  final int? totalMinutes;
}

class SrdRitualCastingTimeRules {
  const SrdRitualCastingTimeRules._();

  static SrdRitualCastingTimePreview preview(
    SrdSpellDefinition spell, {
    required bool ritualCastingAuthorizedConfirmed,
  }) {
    if (!ritualCastingAuthorizedConfirmed) {
      throw const FormatException(
        'Ritualwirken muss für diesen Charakter bestätigt sein.',
      );
    }
    final assessment = SrdSpellCastingTimeRules.inspect(spell);
    if (!assessment.ritualOption) {
      throw const FormatException(
        'Dieser Zauber besitzt keine bestätigte Ritualoption.',
      );
    }
    if (assessment.kind != SrdSpellCastingTimeKind.action &&
        assessment.kind != SrdSpellCastingTimeKind.extended) {
      throw const FormatException(
        'Die Ritualwirkzeit kann nicht sicher berechnet werden.',
      );
    }
    final ordinary = assessment.ordinaryMinutes;
    return SrdRitualCastingTimePreview(
      additionalMinutes: 10,
      ordinaryMinutes: ordinary,
      totalMinutes: ordinary == null ? null : ordinary + 10,
    );
  }
}
