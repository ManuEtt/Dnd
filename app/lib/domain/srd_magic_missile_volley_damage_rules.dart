import 'enemy_force_defense.dart';

/// Confirmed state of Shield for ONE creature, not inferred from narration.
/// An available reaction is not the same as an already active Shield.
enum SrdMissileShieldState {
  unverified,
  absentConfirmed,
  activeConfirmed,
}

/// A previously allocated dart. The d4 result is absent if Shield blocks
/// that creature: no otherwise unnecessary random draw is authorized.
class SrdMissileDartEvidence {
  const SrdMissileDartEvidence({
    required this.targetId,
    required this.naturalD4,
  });

  final String targetId;
  final int? naturalD4;
}

/// Rules evidence for one target, independent of other targets in the volley.
class SrdMissileTargetDefense {
  const SrdMissileTargetDefense({
    required this.targetId,
    required this.shieldState,
    required this.forceDefense,
  });

  final String targetId;
  final SrdMissileShieldState shieldState;
  final EnemyForceDefense forceDefense;
}

/// One immutable per-dart damage result. All darts land simultaneously.
class SrdMissileDartDamage {
  const SrdMissileDartDamage({
    required this.targetId,
    required this.naturalD4,
    required this.rawDamage,
    required this.appliedDamage,
    required this.blockedByShield,
  });

  final String targetId;
  final int? naturalD4;
  final int rawDamage;
  final int appliedDamage;
  final bool blockedByShield;
}

/// Read-only damage totals; this is not an HP update or cast transaction.
class SrdMagicMissileVolleyDamage {
  SrdMagicMissileVolleyDamage._({
    required this.slotLevel,
    required List<SrdMissileDartDamage> darts,
    required Map<String, int> rawPerTarget,
    required Map<String, int> appliedPerTarget,
  }) : darts = List.unmodifiable(darts),
       rawPerTarget = Map.unmodifiable(rawPerTarget),
       appliedPerTarget = Map.unmodifiable(appliedPerTarget);

  final int slotLevel;
  final List<SrdMissileDartDamage> darts;
  final Map<String, int> rawPerTarget;
  final Map<String, int> appliedPerTarget;

  int get dartCount => slotLevel + 2;
  int get shieldBlockedCount =>
      darts.where((dart) => dart.blockedByShield).length;
  int get rawTotal => rawPerTarget.values.fold(0, (sum, n) => sum + n);
  int get appliedTotal => appliedPerTarget.values.fold(
    0,
    (sum, n) => sum + n,
  );
}

/// SRD 5.2.1 pp. 146, 161-162: simultaneous Magic Missile darts, Shield
/// blocks damage for its bearer, Force defenses apply to each dart separately.
///
/// This method REQUIRES separately confirmed spell preparation, target sight,
/// 120-foot range, allocation and completed reaction decisions. It does not
/// roll dice, authorize Shield reactions, deduct slots, change HP, or persist
/// anything. The previous allocation preflight is tracked in PR #375.
class SrdMagicMissileVolleyDamageRules {
  const SrdMagicMissileVolleyDamageRules._();

  static final RegExp _stableId = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9_.:-]{0,159}$',
  );

  static SrdMagicMissileVolleyDamage resolve({
    required int slotLevel,
    required bool allocationAndReactionsConfirmed,
    required List<SrdMissileDartEvidence> darts,
    required Iterable<SrdMissileTargetDefense> targetDefenses,
  }) {
    if (!allocationAndReactionsConfirmed) {
      throw const FormatException(
        'Geschossverteilung und Schildreaktionen sind nicht bestätigt.',
      );
    }
    if (slotLevel < 1 || slotLevel > 9) {
      throw const FormatException('Ungültiger Zauberplatzgrad.');
    }
    final count = slotLevel + 2;
    if (darts.length != count) {
      throw const FormatException(
        'Genau ein Ziel pro gleichzeitigem Geschoss erforderlich.',
      );
    }
    final defenses = <String, SrdMissileTargetDefense>{};
    for (final target in targetDefenses) {
      if (!_stableId.hasMatch(target.targetId) ||
          defenses.containsKey(target.targetId)) {
        throw const FormatException('Doppelte oder ungültige Zielkennung.');
      }
      if (target.shieldState == SrdMissileShieldState.unverified) {
        throw const FormatException(
          'Schildstatus muss für jede Kreatur bestätigt sein.',
        );
      }
      if (target.shieldState == SrdMissileShieldState.absentConfirmed &&
          target.forceDefense == EnemyForceDefense.unknown) {
        throw const FormatException(
          'Ohne Schild ist die Energieschaden-Abwehr zu bestätigen.',
        );
      }
      defenses[target.targetId] = target;
    }
    if (defenses.isEmpty || defenses.length > count) {
      throw const FormatException(
        'Ungültige Anzahl bestätigter Kreaturen.',
      );
    }

    // Validate the ENTIRE volley before computing any damage or totals.
    final used = <String>{};
    for (final dart in darts) {
      final defense = defenses[dart.targetId];
      if (defense == null) {
        throw const FormatException(
          'Geschoss verweist auf keine bestätigte Kreatur.',
        );
      }
      used.add(dart.targetId);
      final blocked =
          defense.shieldState == SrdMissileShieldState.activeConfirmed;
      if (blocked && dart.naturalD4 != null) {
        throw const FormatException(
          'Für ein von Schild blockiertes Geschoss darf kein W4 vorliegen.',
        );
      }
      if (!blocked &&
          (dart.naturalD4 == null ||
              dart.naturalD4! < 1 ||
              dart.naturalD4! > 4)) {
        throw const FormatException(
          'Jedes ungeschützte Geschoss benötigt einen bestätigten W4.',
        );
      }
    }
    if (used.length != defenses.length) {
      throw const FormatException(
        'Jede angegebene Kreatur benötigt mindestens ein Geschoss.',
      );
    }

    final resolved = <SrdMissileDartDamage>[];
    final raw = <String, int>{for (final id in defenses.keys) id: 0};
    final applied = <String, int>{for (final id in defenses.keys) id: 0};
    for (final dart in darts) {
      final target = defenses[dart.targetId]!;
      final blocked =
          target.shieldState == SrdMissileShieldState.activeConfirmed;
      final incoming = blocked ? 0 : dart.naturalD4! + 1;
      final damage = blocked
          ? 0
          : EnemyForceDefenseRules.apply(
              [incoming],
              defense: target.forceDefense,
            ).appliedTotal;
      resolved.add(
        SrdMissileDartDamage(
          targetId: dart.targetId,
          naturalD4: dart.naturalD4,
          rawDamage: incoming,
          appliedDamage: damage,
          blockedByShield: blocked,
        ),
      );
      raw[dart.targetId] = raw[dart.targetId]! + incoming;
      applied[dart.targetId] = applied[dart.targetId]! + damage;
    }
    return SrdMagicMissileVolleyDamage._(
      slotLevel: slotLevel,
      darts: resolved,
      rawPerTarget: raw,
      appliedPerTarget: applied,
    );
  }
}
