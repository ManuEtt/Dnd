import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';

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

  /// Canonical SRD spellcasting abilities for the eight spellcasting classes.
  /// Subclass-only spells, magic items and unverified overrides are not
  /// automatically authorized by this restricted class-based calculator.
  static const _classSpellAbilities = <String, String>{
    'Barde': 'charisma',
    'Kleriker': 'wisdom',
    'Druide': 'wisdom',
    'Paladin': 'charisma',
    'Waldläufer': 'wisdom',
    'Zauberer': 'charisma',
    'Hexenmeister': 'charisma',
    'Magier': 'intelligence',
  };

  /// SRD 5.2.1: Spell Save DC / Spell Attack Rolls and multiclass spells.
  ///
  /// Read-only: this calculates class-specific base numbers but DOES NOT
  /// confirm that an individual spell is prepared, legal or successfully cast.
  /// A multiclass spell uses its own class's spellcasting ability, while
  /// proficiency is based on the total character level.
  ///
  /// The caller must explicitly confirm that no unmodelled item/feature
  /// modifies either number. No class or ability is inferred from narration.
  static SrdClassSpellStats statsForClass(
    HeroCharacter caster, {
    required String castingClass,
    required bool noUnmodelledModifiersConfirmed,
  }) {
    if (!noUnmodelledModifiersConfirmed) {
      throw const FormatException(
        'Ungeprüfte Merkmale oder Gegenstände könnten Zauberwerte verändern.',
      );
    }
    final canonical = findSrdClass(castingClass)?.name;
    final ability = _classSpellAbilities[canonical];
    if (ability == null) {
      throw const FormatException(
        'Keine bestätigte SRD-Zauberklasse ausgewählt.',
      );
    }
    final secondarySelected = caster.secondaryClassName.trim().isNotEmpty;
    if (caster.level < 1 ||
        caster.level > 20 ||
        caster.secondaryClassLevel < 0 ||
        caster.secondaryClassLevel >= caster.level ||
        (secondarySelected && caster.secondaryClassLevel == 0) ||
        (!secondarySelected && caster.secondaryClassLevel != 0)) {
      throw const FormatException(
        'Klassenstufen sind für die Zauberwerte ungültig.',
      );
    }

    final primary = findSrdClass(caster.className)?.name;
    final secondary = secondarySelected
        ? findSrdClass(caster.secondaryClassName)?.name
        : null;
    if (primary == null ||
        (secondarySelected && (secondary == null || primary == secondary)) ||
        (canonical != primary && canonical != secondary)) {
      throw const FormatException(
        'Die gewählte Zauberklasse gehört nicht zum Charakter.',
      );
    }

    final score = caster.abilities[ability];
    if (score == null || score < 1 || score > 30) {
      throw const FormatException(
        'Das Zauberattribut ist nicht regelkonform bestätigt.',
      );
    }
    final modifier = RulesEngine.abilityModifier(score);
    final proficiency = RulesEngine.proficiencyBonus(caster.level);
    return SrdClassSpellStats(
      castingClass: canonical!,
      ability: ability,
      abilityScore: score,
      abilityModifier: modifier,
      proficiencyBonus: proficiency,
      spellAttackModifier: modifier + proficiency,
      spellSaveDc: 8 + modifier + proficiency,
    );
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

/// Validated, immutable class-specific base spell numbers.
///
/// An attack still needs its own authorized d20 roll, target AC and modifiers.
/// These values do not spend slots, roll dice or apply spell effects.
class SrdClassSpellStats {
  const SrdClassSpellStats({
    required this.castingClass,
    required this.ability,
    required this.abilityScore,
    required this.abilityModifier,
    required this.proficiencyBonus,
    required this.spellAttackModifier,
    required this.spellSaveDc,
  });

  final String castingClass, ability;
  final int abilityScore, abilityModifier, proficiencyBonus;
  final int spellAttackModifier, spellSaveDc;
}
