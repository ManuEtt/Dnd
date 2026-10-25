import 'cover_rules.dart';
import 'dice_engine.dart';
import 'rules_engine.dart';

/// SRD 5.2.1: Spell Attack Rolls, Attack Rolls, Cover and D20 Tests.
///
/// Pure roll resolver for a *separately authorized* spell attack. It does not
/// establish whether a spell requires an attack roll, whether it is prepared,
/// whether the target is within range or whether casting costs were paid.
/// Those facts, including applicable roll modifiers, must be independently
/// confirmed before this function is called.
class SrdSpellAttackRollRules {
  const SrdSpellAttackRollRules._();

  /// [confirmedTargetArmorClass] is the base AC, *without* the cover bonus.
  /// [targetCover] only applies when the attack originates opposite the cover.
  /// Both the grade and its relation to the caster must be confirmed.
  ///
  /// [confirmedAttackModifier] includes the spellcasting ability, total-level
  /// proficiency and any separately confirmed flat bonuses or penalties.
  /// The corresponding class-bound base calculation is a separate rule step.
  ///
  /// A manually supplied natural d20 is permitted only for a normal roll.
  /// Advantage/disadvantage require both actual dice to be resolved by [dice].
  static SrdSpellAttackRollResolution resolve({
    required DiceEngine dice,
    required int confirmedAttackModifier,
    required int confirmedTargetArmorClass,
    required CoverLevel targetCover,
    required bool coverCircumstancesConfirmed,
    required bool sourceOppositeCover,
    required bool spellAndTargetAuthorizedConfirmed,
    required bool attackCircumstancesConfirmed,
    bool advantage = false,
    bool disadvantage = false,
    int? confirmedNaturalRoll,
  }) {
    if (!spellAndTargetAuthorizedConfirmed ||
        !attackCircumstancesConfirmed ||
        !coverCircumstancesConfirmed) {
      throw const FormatException(
        'Zauber, Ziel, Angriffsbedingungen und Deckung müssen '
        'ausdrücklich bestätigt sein.',
      );
    }
    if (confirmedAttackModifier < -30 || confirmedAttackModifier > 30) {
      throw RangeError.range(
        confirmedAttackModifier,
        -30,
        30,
        'confirmedAttackModifier',
      );
    }
    if (confirmedTargetArmorClass < 1 || confirmedTargetArmorClass > 100) {
      throw RangeError.range(
        confirmedTargetArmorClass,
        1,
        100,
        'confirmedTargetArmorClass',
      );
    }
    if (confirmedNaturalRoll != null && (advantage || disadvantage)) {
      throw const FormatException(
        'Ein einzelner manueller W20 belegt keinen Vorteils- '
        'oder Nachteilswurf.',
      );
    }
    if (confirmedNaturalRoll != null &&
        (confirmedNaturalRoll < 1 || confirmedNaturalRoll > 20)) {
      throw RangeError.range(confirmedNaturalRoll, 1, 20, 'confirmedNaturalRoll');
    }

    // Cover is relative to the attack origin, never inferred from narration.
    // Full cover rejects direct targeting *before* any die can be consumed.
    final applicableCover = sourceOppositeCover
        ? targetCover
        : CoverLevel.none;
    final effectiveArmorClass = CoverRules.armorClass(
      confirmedTargetArmorClass,
      applicableCover,
    );
    final roll = dice.check(
      modifier: confirmedAttackModifier,
      natural: confirmedNaturalRoll,
      advantage: advantage,
      disadvantage: disadvantage,
    );
    final outcome = RulesEngine.attack(
      roll: roll,
      armorClass: effectiveArmorClass,
    );
    return SrdSpellAttackRollResolution(
      roll: roll,
      effectiveArmorClass: effectiveArmorClass,
      appliedCover: applicableCover,
      hit: outcome.hit,
      critical: outcome.critical,
    );
  }
}

/// One resolved attack roll, not an authorized spell effect or campaign event.
class SrdSpellAttackRollResolution {
  const SrdSpellAttackRollResolution({
    required this.roll,
    required this.effectiveArmorClass,
    required this.appliedCover,
    required this.hit,
    required this.critical,
  });

  final DiceResult roll;
  final int effectiveArmorClass;
  final CoverLevel appliedCover;
  final bool hit;
  final bool critical;
}
