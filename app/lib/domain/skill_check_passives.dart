/// SRD 5.2.1: passive effects on confirmed skill-based ability checks.
///
/// These helpers are intentionally independent of the game and save models.
/// Initiative, saving throws, attacks and checks without a named skill must
/// never receive a 2024 Bard Jack of All Trades bonus or Rogue Reliable Talent
/// through this skill helper. Explicit typed tool checks handle Rogue's
/// tool-proficiency exception separately (SRD 5.2.1 p.63).
class SkillCheckPassives {
  const SkillCheckPassives._();

  /// Bard 2: half proficiency (rounded down) on checks using an untrained
  /// skill, provided that the check does not otherwise use proficiency.
  static int jackOfAllTrades({
    required int bardClassLevel,
    required int proficiencyBonus,
    required bool usesSkill,
    required bool proficient,
  }) {
    if (bardClassLevel < 2 || !usesSkill || proficient) return 0;
    return proficiencyBonus ~/ 2;
  }

  /// Rogue 7: for an ability check with a confirmed skill proficiency,
  /// a natural d20 result of 1–9 can be treated as 10. Never for initiative
  /// or an attack, and never solely because of a high total character level.
  static int minimumNatural({
    required int rogueClassLevel,
    required bool usesSkill,
    required bool proficient,
  }) => rogueClassLevel >= 7 && usesSkill && proficient ? 10 : 0;

  /// Keep the actual die roll for audit/history. Adjust only the effective
  /// result of the pending *skill* check; manual totals have no natural die.
  static int effectiveTotal({
    required int total,
    required int? natural,
    required int minimumNatural,
  }) {
    if (minimumNatural != 0 && minimumNatural != 10) {
      throw const FormatException('Ungültiger Fertigkeits-Mindestwurf.');
    }
    if (natural == null || natural >= minimumNatural) return total;
    if (natural < 1 || natural > 20) {
      throw const FormatException('Ungültiger natürlicher W20.');
    }
    return total + minimumNatural - natural;
  }
}
