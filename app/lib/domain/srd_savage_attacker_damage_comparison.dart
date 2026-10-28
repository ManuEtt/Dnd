import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_savage_attacker_rules.dart';

/// A read-only comparison of two rule-verified *primary weapon* damage rolls.
///
/// This is NOT a finished attack result. Sneak Attack, Rage, defenses, target
/// HP, and the once-per-turn feat consumption remain the responsibility of a
/// future revision-checked, atomic combat action.
class SavageAttackerDamageComparison {
  const SavageAttackerDamageComparison({
    required this.choice,
    required this.originalWeaponSubtotal,
    required this.alternativeWeaponSubtotal,
  });

  final SavageAttackerChoice choice;
  final int originalWeaponSubtotal;
  final int alternativeWeaponSubtotal;

  int get selectedWeaponSubtotal => choice.usedAlternative
      ? alternativeWeaponSubtotal
      : originalWeaponSubtotal;

  int get selectedDifference => selectedWeaponSubtotal - originalWeaponSubtotal;
}

/// Bridges validated Savage Attacker evidence to the existing weapon-damage
/// calculation without duplicating ability or Fighting Style arithmetic.
///
/// Scope is deliberately limited to the main-hand weapon expression saved on
/// the character. Confirmed offhand attacks require their own damage formula.
class SrdSavageAttackerDamageComparisonRules {
  const SrdSavageAttackerDamageComparisonRules._();

  static SavageAttackerDamageComparison compare({
    required HeroCharacter hero,
    required Encounter encounter,
    required String weaponDamageExpression,
    required DiceResult original,
    required DiceResult alternative,
    required bool confirmedWeaponHit,
    required bool confirmedWeaponAttack,
    required bool chooseAlternative,
    bool critical = false,
    DiceResult? originalCriticalExtra,
    DiceResult? alternativeCriticalExtra,
  }) {
    if (!SrdSavageAttackerRules.canOfferOnTurn(hero, encounter)) {
      throw const FormatException(
        'Wilder Angreifer ist in diesem Kampfzug nicht verfügbar.',
      );
    }
    if (weaponDamageExpression.isEmpty ||
        hero.weaponDamage != weaponDamageExpression) {
      throw const FormatException(
        'Der Waffenschaden stimmt nicht mit der bestätigten Hauptwaffe überein.',
      );
    }

    final choice = SrdSavageAttackerRules.choose(
      hero: hero,
      weaponDamageExpression: weaponDamageExpression,
      original: original,
      alternative: alternative,
      confirmedWeaponHit: confirmedWeaponHit,
      confirmedWeaponAttack: confirmedWeaponAttack,
      alreadyUsedThisTurn: encounter.savageAttackerUsedThisTurn,
      chooseAlternative: chooseAlternative,
      critical: critical,
      originalCriticalExtra: originalCriticalExtra,
      alternativeCriticalExtra: alternativeCriticalExtra,
    );

    // Reuse the real combat calculation for EACH complete weapon dice pool.
    // Great Weapon Fighting can correct 1s and 2s differently in each pool;
    // adding the raw-dice difference to the first subtotal would be wrong.
    final first = RulesEngine.weaponDamageSubtotal(
      hero,
      baseRoll: original,
      criticalExtra: originalCriticalExtra,
    );
    final second = RulesEngine.weaponDamageSubtotal(
      hero,
      baseRoll: alternative,
      criticalExtra: alternativeCriticalExtra,
    );
    return SavageAttackerDamageComparison(
      choice: choice,
      originalWeaponSubtotal: first,
      alternativeWeaponSubtotal: second,
    );
  }
}
