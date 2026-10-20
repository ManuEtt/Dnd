import 'damage_rules.dart';

/// Explicitly confirmed resistance status for Force damage of one encounter.
/// 'unknown' is the safe default for imported and historical encounters.
enum EnemyForceDefense { unknown, normal, resistant, immune, vulnerable }

class EnemyForceDefenseRules {
  const EnemyForceDefenseRules._();

  static EnemyForceDefense fromStorage(String value) {
    for (final defense in EnemyForceDefense.values) {
      if (defense.name == value) return defense;
    }
    throw const FormatException('Ungültige Gegner-Energieschaden-Abwehr.');
  }

  static String label(EnemyForceDefense defense) => switch (defense) {
    EnemyForceDefense.unknown => 'Nicht bestätigt',
    EnemyForceDefense.normal => 'Normaler Energieschaden',
    EnemyForceDefense.resistant => 'Resistenz gegen Energieschaden',
    EnemyForceDefense.immune => 'Immunität gegen Energieschaden',
    EnemyForceDefense.vulnerable => 'Verwundbarkeit gegen Energieschaden',
  };

  /// A missile is a separate damage instance. Resistance rounds down per
  /// instance rather than rounding once after summing all darts.
  static ForceMissileDamage apply(
    Iterable<int> missileDamage, {
    required EnemyForceDefense defense,
  }) {
    if (defense == EnemyForceDefense.unknown) {
      throw const FormatException(
        'Die Energieschaden-Abwehr des Gegners ist nicht bestätigt.',
      );
    }
    final values = missileDamage.toList(growable: false);
    final result = DamageRules.resolve(
      [for (final amount in values) DamageComponent(DamageType.force, amount)],
      defenses: DamageDefenses(
        resistances: defense == EnemyForceDefense.resistant
            ? const [DamageType.force]
            : const [],
        immunities: defense == EnemyForceDefense.immune
            ? const [DamageType.force]
            : const [],
        vulnerabilities: defense == EnemyForceDefense.vulnerable
            ? const [DamageType.force]
            : const [],
      ),
    );
    return ForceMissileDamage(
      rawTotal: values.fold<int>(0, (sum, n) => sum + n),
      appliedTotal: result.total,
      appliedPerMissile: List.unmodifiable(
        result.parts.map((part) => part.applied),
      ),
    );
  }
}

class ForceMissileDamage {
  const ForceMissileDamage({
    required this.rawTotal,
    required this.appliedTotal,
    required this.appliedPerMissile,
  });

  final int rawTotal;
  final int appliedTotal;
  final List<int> appliedPerMissile;
}
