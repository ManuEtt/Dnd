import 'ability_generation.dart';
import 'dice_engine.dart';
import 'models.dart';

/// SRD 5.2.1, Origin Feat "Savage Attacker" (Wilder Angreifer).
///
/// This is a pure, non-mutating rule boundary. The combat controller must
/// confirm the weapon hit, eligible weapon and once-per-turn state from its
/// authoritative encounter before it may commit this optional choice.
/// It does not consume an action, spend a turn resource or alter a campaign.
class SrdSavageAttackerRules {
  const SrdSavageAttackerRules._();

  static bool hasConfirmedFeat(HeroCharacter hero) =>
      hero.background == SrdBackground.soldier.label &&
      hero.startingBackgroundPackage?.background == SrdBackground.soldier;

  /// Select either *weapon* dice result, without touching ability modifiers,
  /// Sneak Attack, Rage, fighting styles, enemy defences or hit points.
  ///
  /// The two candidates MUST have been rolled independently and confirmed
  /// for the same weapon expression. On a critical hit each candidate also
  /// includes a separate roll of the weapon's doubled critical dice.
  /// Only the calling, revision-checked combat engine can book usage.
  static SavageAttackerChoice choose({
    required HeroCharacter hero,
    required String weaponDamageExpression,
    required DiceResult original,
    required DiceResult alternative,
    required bool confirmedWeaponHit,
    required bool confirmedWeaponAttack,
    required bool alreadyUsedThisTurn,
    required bool chooseAlternative,
    bool critical = false,
    DiceResult? originalCriticalExtra,
    DiceResult? alternativeCriticalExtra,
  }) {
    if (!hasConfirmedFeat(hero)) {
      throw const FormatException(
        'Wilder Angreifer benötigt ein bestätigtes Soldaten-Herkunftspaket.',
      );
    }
    if (!confirmedWeaponHit || !confirmedWeaponAttack) {
      throw const FormatException(
        'Nur ein bestätigter Waffentreffer ist zulässig.',
      );
    }
    if (alreadyUsedThisTurn) {
      throw const FormatException(
        'Wilder Angreifer wurde in diesem Zug benutzt.',
      );
    }
    if (critical !=
        (originalCriticalExtra != null && alternativeCriticalExtra != null)) {
      throw const FormatException(
        'Kritische Waffenschadenswürfel sind unvollständig.',
      );
    }
    if (!critical &&
        (originalCriticalExtra != null || alternativeCriticalExtra != null)) {
      throw const FormatException(
        'Zusätzliche Schadenswürfel ohne kritischen Treffer.',
      );
    }

    final parsed = _parseWeaponExpression(weaponDamageExpression);
    _verifyRoll(original, parsed);
    _verifyRoll(alternative, parsed);
    if (critical) {
      _verifyRoll(originalCriticalExtra!, parsed);
      _verifyRoll(alternativeCriticalExtra!, parsed);
    }

    final firstDice =
        _diceSum(original) + (critical ? _diceSum(originalCriticalExtra!) : 0);
    final secondDice =
        _diceSum(alternative) +
        (critical ? _diceSum(alternativeCriticalExtra!) : 0);
    return SavageAttackerChoice(
      original: original,
      alternative: alternative,
      originalCriticalExtra: originalCriticalExtra,
      alternativeCriticalExtra: alternativeCriticalExtra,
      originalWeaponDiceTotal: firstDice,
      alternativeWeaponDiceTotal: secondDice,
      weaponFlatModifier: parsed.modifier,
      usedAlternative: chooseAlternative,
      critical: critical,
    );
  }

  static ({int count, int sides, int modifier, String canonical})
  _parseWeaponExpression(String expression) {
    final match = RegExp(
      r'^(\d{1,3})d(4|6|8|10|12)([+-]\d{1,4})?$',
    ).firstMatch(expression);
    if (match == null) {
      throw const FormatException('Unbestätigter Waffenschadensausdruck.');
    }
    final count = int.parse(match.group(1)!);
    final sides = int.parse(match.group(2)!);
    final modifier = int.tryParse(match.group(3) ?? '') ?? 0;
    if (count < 1 ||
        count > DiceEngine.maxDice ||
        modifier.abs() > DiceEngine.maxModifier) {
      throw const FormatException(
        'Waffenschadenswürfel außerhalb der Grenzen.',
      );
    }
    final suffix = modifier == 0
        ? ''
        : modifier > 0
        ? '+$modifier'
        : '$modifier';
    final canonical = '${count}d$sides$suffix';
    if (canonical != expression) {
      throw const FormatException('Waffenschadensausdruck nicht kanonisch.');
    }
    return (
      count: count,
      sides: sides,
      modifier: modifier,
      canonical: canonical,
    );
  }

  static int _diceSum(DiceResult roll) =>
      roll.rolls.fold<int>(0, (sum, face) => sum + face);

  static void _verifyRoll(
    DiceResult roll,
    ({int count, int sides, int modifier, String canonical}) expected,
  ) {
    if (roll.expression != expected.canonical ||
        roll.modifier != expected.modifier ||
        roll.natural != null ||
        roll.rolls.length != expected.count ||
        roll.rolls.any((face) => face < 1 || face > expected.sides) ||
        roll.total != _diceSum(roll) + expected.modifier) {
      throw const FormatException(
        'Würfelnachweis passt nicht zu den bestätigten Waffenwürfeln.',
      );
    }
  }
}

/// Two verified weapon-dice candidates; *not* a committed combat action.
class SavageAttackerChoice {
  const SavageAttackerChoice({
    required this.original,
    required this.alternative,
    required this.originalCriticalExtra,
    required this.alternativeCriticalExtra,
    required this.originalWeaponDiceTotal,
    required this.alternativeWeaponDiceTotal,
    required this.weaponFlatModifier,
    required this.usedAlternative,
    required this.critical,
  });

  final DiceResult original;
  final DiceResult alternative;
  final DiceResult? originalCriticalExtra;
  final DiceResult? alternativeCriticalExtra;
  final int originalWeaponDiceTotal;
  final int alternativeWeaponDiceTotal;
  final int weaponFlatModifier;
  final bool usedAlternative;
  final bool critical;

  /// Only the base weapon dice are substituted. A flat weapon modifier is
  /// added exactly once; other confirmed damage sources remain untouched.
  int get selectedWeaponDiceTotal =>
      usedAlternative ? alternativeWeaponDiceTotal : originalWeaponDiceTotal;

  int get selectedWeaponSubtotal =>
      selectedWeaponDiceTotal + weaponFlatModifier;
}
