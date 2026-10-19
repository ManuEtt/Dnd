/// Confirmed relative combat cover, not an inferred map/line-of-sight system.
///
/// Based on the D&D Starter Set (German), chapter 2, p. 12, and the
/// corresponding SRD 5.2.1 combat rule. Cover protects only against an
/// attack/effect originating on the OPPOSITE side of the obstacle.
/// Multiple sources never stack; the highest confirmed grade applies.
enum CoverLevel { none, half, threeQuarters, total }

class CoverRules {
  const CoverRules._();

  static CoverLevel fromStorage(String value) {
    for (final level in CoverLevel.values) {
      if (level.name == value) return level;
    }
    throw const FormatException('Unbekannter Deckungsgrad.');
  }

  static CoverLevel strongest(Iterable<CoverLevel> sources) {
    var strongest = CoverLevel.none;
    for (final grade in sources) {
      if (grade.index > strongest.index) strongest = grade;
    }
    return strongest;
  }

  static int getBonus(CoverLevel grade) => switch (grade) {
    CoverLevel.none => 0,
    CoverLevel.half => 2,
    CoverLevel.threeQuarters => 5,
    CoverLevel.total => 0, // Total cover forbids direct targeting, not +∞ AC.
  };

  static String label(CoverLevel grade) => switch (grade) {
    CoverLevel.none => 'keine Deckung',
    CoverLevel.half => 'halbe Deckung',
    CoverLevel.threeQuarters => 'Dreivierteldeckung',
    CoverLevel.total => 'vollständige Deckung',
  };

  static String commandValue(CoverLevel grade) => switch (grade) {
    CoverLevel.none => 'keine',
    CoverLevel.half => 'halb',
    CoverLevel.threeQuarters => 'dreiviertel',
    CoverLevel.total => 'voll',
  };

  static bool canTargetDirectly(CoverLevel grade) =>
      grade != CoverLevel.total;

  /// Effective AC for a direct attack from the opposite side. Natural-20
  /// critical hits still follow the attack engine; full cover cannot be
  /// attacked or bypassed by a natural 20.
  static int armorClass(int baseArmorClass, CoverLevel grade) {
    if (baseArmorClass < 1 || baseArmorClass > 100) {
      throw RangeError.range(baseArmorClass, 1, 100, 'baseArmorClass');
    }
    if (!canTargetDirectly(grade)) {
      throw const FormatException(
        'Ein Ziel hinter vollständiger Deckung kann nicht direkt angegriffen werden.',
      );
    }
    return (baseArmorClass + getBonus(grade)).clamp(1, 100).toInt();
  }

  /// Only a confirmed Dexterity save against a confirmed effect originating
  /// on the opposite side uses this bonus; unrelated spells/traps never do.
  /// Full cover does NOT automatically negate every possible area effect.
  static int savingThrowBonus(
    CoverLevel grade, {
    required String ability,
    required bool sourceOppositeCover,
  }) {
    if (!sourceOppositeCover || ability != 'dexterity') return 0;
    return getBonus(grade);
  }
}
