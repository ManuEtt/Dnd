import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';

/// SRD 5.2.1 Spellcasting: 8 + ability modifier + proficiency bonus.
/// No equipment, subclass, magical focus or GM-confirmed bonus is inferred.
class SrdSpellSavingThrowRules {
  const SrdSpellSavingThrowRules._();

  static int spellSaveDc(
    HeroCharacter caster, {
    required String spellcastingAbility,
    required bool noUnmodelledDcModifiersConfirmed,
  }) {
    if (!noUnmodelledDcModifiersConfirmed) {
      throw const FormatException(
        'Ungeprüfte Gegenstände oder Merkmale könnten den Zauber-SG verändern.',
      );
    }
    final score = caster.abilities[spellcastingAbility];
    if (caster.level < 1 ||
        caster.level > 20 ||
        score == null ||
        score < 1 ||
        score > 30) {
      throw const FormatException(
        'Zauberstufe und Zauberattribut müssen bestätigt sein.',
      );
    }
    return 8 +
        RulesEngine.proficiencyBonus(caster.level) +
        RulesEngine.abilityModifier(score);
  }

  /// For monster stat blocks, the *full* save modifier (not just the ability
  /// modifier) must be explicitly supplied. Saving throws do not have an
  /// automatic success on natural 20 or failure on natural 1.
  static SrdSpellSaveResolution resolve({
    required DiceEngine dice,
    required int dc,
    required int confirmedTargetModifier,
    required bool saveCircumstancesConfirmed,
    bool advantage = false,
    bool disadvantage = false,
  }) {
    if (dc < 1 || dc > 50) {
      throw RangeError.range(dc, 1, 50, 'dc');
    }
    if (confirmedTargetModifier < -30 || confirmedTargetModifier > 30) {
      throw RangeError.range(
        confirmedTargetModifier,
        -30,
        30,
        'confirmedTargetModifier',
      );
    }
    if (!saveCircumstancesConfirmed) {
      throw const FormatException(
        'Rettungswurf-Vorteile, -Nachteile und automatische Fehlschläge '
        'müssen anhand bestätigter Gegnerwerte geklärt sein.',
      );
    }
    final roll = dice.check(
      modifier: confirmedTargetModifier,
      advantage: advantage,
      disadvantage: disadvantage,
    );
    return SrdSpellSaveResolution(
      dc: dc,
      modifier: confirmedTargetModifier,
      roll: roll,
      succeeded: roll.total >= dc,
    );
  }
}

class SrdSpellSaveResolution {
  const SrdSpellSaveResolution({
    required this.dc,
    required this.modifier,
    required this.roll,
    required this.succeeded,
  });

  final int dc, modifier;
  final DiceResult roll;
  final bool succeeded;
}
