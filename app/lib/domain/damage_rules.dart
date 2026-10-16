// Deterministic, typed SRD 5.2.1 damage resolution.
// Source: https://www.dndbeyond.com/sources/dnd/br-2024/playing-the-game
// Damage adjustments from spells, saves, features and other multipliers must
// be applied before calling this resolver. This module does not infer them.
// Damage immunity is checked first, then Resistance, then Vulnerability.

enum DamageType {
  acid,
  bludgeoning,
  cold,
  fire,
  force,
  lightning,
  necrotic,
  piercing,
  poison,
  psychic,
  radiant,
  slashing,
  thunder,
}

/// One amount of damage with one known type, after other damage modifiers.
class DamageComponent {
  const DamageComponent(this.type, this.amount);
  final DamageType type;
  final int amount;
}

/// Explicitly known defenses; never inferred from a name or story narration.
/// Sets ensure that duplicate resistance/vulnerability sources don't stack.
class DamageDefenses {
  DamageDefenses({
    Iterable<DamageType> resistances = const [],
    Iterable<DamageType> vulnerabilities = const [],
    Iterable<DamageType> immunities = const [],
    this.resistAll = false,
    this.vulnerableToAll = false,
    this.immuneToAll = false,
  }) : resistances = Set<DamageType>.unmodifiable(resistances),
       vulnerabilities = Set<DamageType>.unmodifiable(vulnerabilities),
       immunities = Set<DamageType>.unmodifiable(immunities);

  final Set<DamageType> resistances;
  final Set<DamageType> vulnerabilities;
  final Set<DamageType> immunities;
  final bool resistAll;
  final bool vulnerableToAll;
  final bool immuneToAll;
}

/// Auditable single-type result; retains input and output separately.
class DamagePartResult {
  const DamagePartResult({
    required this.type,
    required this.incoming,
    required this.applied,
    required this.immune,
    required this.resistant,
    required this.vulnerable,
  });

  final DamageType type;
  final int incoming;
  final int applied;
  final bool immune, resistant, vulnerable;
}

/// A packet can contain different damage types; each is resolved on its own.
class DamageResolution {
  DamageResolution._(List<DamagePartResult> resolved)
      : parts = List<DamagePartResult>.unmodifiable(resolved),
        total = resolved.fold<int>(0, (sum, part) => sum + part.applied);

  final List<DamagePartResult> parts;
  final int total;
}

class DamageRules {
  const DamageRules._();

  static DamageResolution resolve(
    Iterable<DamageComponent> components, {
    required DamageDefenses defenses,
  }) {
    final entries = components.toList(growable: false);
    if (entries.isEmpty) {
      throw ArgumentError('Mindestens eine Schadenskomponente ist nötig.');
    }
    if (entries.length > 100) {
      throw RangeError.range(entries.length, 1, 100, 'components.length');
    }
    final results = <DamagePartResult>[];
    for (final entry in entries) {
      if (entry.amount < 0 || entry.amount > 100000) {
        throw RangeError.range(entry.amount, 0, 100000, 'damage');
      }
      final immune = defenses.immuneToAll ||
          defenses.immunities.contains(entry.type);
      final resistant = defenses.resistAll ||
          defenses.resistances.contains(entry.type);
      final vulnerable = defenses.vulnerableToAll ||
          defenses.vulnerabilities.contains(entry.type);

      // 2024 SRD order is consequential for odd numbers: 23 / 2 * 2 = 22.
      // Immunity overrides other defenses. Resistance and Vulnerability are
      // each applied at most once per instance, even with multiple sources.
      var applied = immune ? 0 : entry.amount;
      if (!immune && resistant) applied ~/= 2;
      if (!immune && vulnerable) applied *= 2;
      results.add(DamagePartResult(
        type: entry.type,
        incoming: entry.amount,
        applied: applied,
        immune: immune,
        resistant: resistant,
        vulnerable: vulnerable,
      ));
    }
    return DamageResolution._(results);
  }
}
