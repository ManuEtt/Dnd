import 'dice_engine.dart';
import 'models.dart';
import 'srd_savage_attacker_damage_comparison.dart';

/// Typed, restart-safe *proposal* for a future Savage Attacker decision.
///
/// This stores independently rolled dice and a bounded encounter/revision
/// identity. It cannot by itself assert a hit, spend a feat, change HP,
/// authenticate randomness, or prove that a game-engine attack occurred.
/// Only a trusted attack flow may create an actionable proposal.
class PendingSavageAttackerHit {
  const PendingSavageAttackerHit({
    required this.attackRollId,
    required this.encounterId,
    required this.offeredAtRevision,
    required this.round,
    required this.weaponDamageExpression,
    required this.original,
    required this.alternative,
    required this.critical,
    this.originalCriticalExtra,
    this.alternativeCriticalExtra,
  });

  final String attackRollId, encounterId, weaponDamageExpression;
  final int offeredAtRevision, round;
  final DiceResult original, alternative;
  final bool critical;
  final DiceResult? originalCriticalExtra, alternativeCriticalExtra;

  Map<String, dynamic> toJson() => {
    'attackRollId': attackRollId,
    'encounterId': encounterId,
    'offeredAtRevision': offeredAtRevision,
    'round': round,
    'weaponDamageExpression': weaponDamageExpression,
    'original': original.toJson(),
    'alternative': alternative.toJson(),
    'critical': critical,
    if (originalCriticalExtra != null)
      'originalCriticalExtra': originalCriticalExtra!.toJson(),
    if (alternativeCriticalExtra != null)
      'alternativeCriticalExtra': alternativeCriticalExtra!.toJson(),
  };

  factory PendingSavageAttackerHit.fromJson(Map<String, dynamic> json) {
    String identifier(String key) {
      final value = json[key];
      if (value is! String ||
          !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(value)) {
        throw FormatException('Ungültige Wilder-Angreifer-Kennung: $key.');
      }
      return value;
    }

    int positive(String key) {
      final value = json[key];
      if (value is! int || value < 1 || value > 1000000) {
        throw FormatException('Ungültige Wilder-Angreifer-Zahl: $key.');
      }
      return value;
    }

    final expression = json['weaponDamageExpression'];
    if (expression is! String ||
        expression.length > 30 ||
        !RegExp(r'^[1-9][0-9]{0,2}d(4|6|8|10|12)([+-][1-9][0-9]{0,3})?$')
            .hasMatch(expression)) {
      throw const FormatException('Ungültige Waffenschadensnotation.');
    }
    final critical = json['critical'];
    if (critical is! bool) {
      throw const FormatException('Kritischer Treffer muss bestätigt sein.');
    }
    DiceResult roll(String key) {
      final raw = json[key];
      if (raw is! Map<String, dynamic> ||
          raw['expression'] != expression ||
          raw['natural'] != null ||
          raw['rolls'] is! List ||
          raw['modifier'] is! int ||
          raw['total'] is! int) {
        throw FormatException('Ungültiger Waffenschadensnachweis: $key.');
      }
      final match = RegExp(r'^(\d+)d(4|6|8|10|12)([+-]\d+)?$')
          .firstMatch(expression)!;
      final count = int.parse(match.group(1)!);
      final sides = int.parse(match.group(2)!);
      final modifier = int.parse(match.group(3) ?? '0');
      final faces = raw['rolls'] as List<dynamic>;
      if (count < 1 ||
          count > DiceEngine.maxDice ||
          modifier.abs() > DiceEngine.maxModifier ||
          raw['modifier'] != modifier ||
          faces.length != count ||
          faces.any((v) => v is! int || v < 1 || v > sides)) {
        throw FormatException('Manipulierte Waffenwürfel: $key.');
      }
      final verified = faces.cast<int>();
      final total = verified.fold<int>(modifier, (sum, face) => sum + face);
      if (raw['total'] != total) {
        throw FormatException('Manipulierte Waffenwürfelsumme: $key.');
      }
      return DiceResult(
        expression: expression,
        rolls: verified,
        modifier: modifier,
        total: total,
      );
    }

    final original = roll('original');
    final alternative = roll('alternative');
    final firstCrit = json['originalCriticalExtra'] == null
        ? null
        : roll('originalCriticalExtra');
    final secondCrit = json['alternativeCriticalExtra'] == null
        ? null
        : roll('alternativeCriticalExtra');
    if (critical != (firstCrit != null && secondCrit != null) ||
        (!critical && (firstCrit != null || secondCrit != null))) {
      throw const FormatException('Ungültige kritische Waffenwürfel.');
    }

    return PendingSavageAttackerHit(
      attackRollId: identifier('attackRollId'),
      encounterId: identifier('encounterId'),
      offeredAtRevision: positive('offeredAtRevision'),
      round: positive('round'),
      weaponDamageExpression: expression,
      original: original,
      alternative: alternative,
      critical: critical,
      originalCriticalExtra: firstCrit,
      alternativeCriticalExtra: secondCrit,
    );
  }

  /// Called on imported and resumed Campaigns; never causes game effects.
  void validateAgainst({
    required HeroCharacter hero,
    required Encounter? encounter,
    required int revision,
  }) {
    if (encounter == null ||
        encounter.id != encounterId ||
        encounter.round != round ||
        offeredAtRevision != revision) {
      throw const FormatException(
        'Die Waffenwürfel gehören nicht zum aktuellen Kampfstand.',
      );
    }
    SrdSavageAttackerDamageComparisonRules.compare(
      hero: hero,
      encounter: encounter,
      weaponDamageExpression: weaponDamageExpression,
      original: original,
      alternative: alternative,
      confirmedWeaponHit: true,
      confirmedWeaponAttack: true,
      chooseAlternative: false,
      critical: critical,
      originalCriticalExtra: originalCriticalExtra,
      alternativeCriticalExtra: alternativeCriticalExtra,
    );
  }
}
