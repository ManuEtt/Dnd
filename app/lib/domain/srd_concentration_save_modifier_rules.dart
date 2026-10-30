import 'dart:convert';

import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';

/// Evidence for a Constitution saving throw while concentrating.
///
/// This is an immutable PRE-ROLL snapshot, not a die result or spell effect.
/// The source character and all situational bonuses must be independently
/// confirmed before committing concentration loss in the game engine.
class SrdConcentrationSaveModifierEvidence {
  const SrdConcentrationSaveModifierEvidence({
    required this.sourceSnapshot,
    required this.baseModifier,
    required this.additionalModifier,
    required this.totalModifier,
    required this.advantage,
    required this.disadvantage,
  });

  final String sourceSnapshot;
  final int baseModifier;
  final int additionalModifier;
  final int totalModifier;
  final bool advantage;
  final bool disadvantage;

  /// Opposition cancels; multiple sources never grant multiple d20s.
  bool get isNormalRoll => advantage == disadvantage;

  void validateUnchanged(HeroCharacter hero) {
    if (jsonEncode(hero.toJson()) != sourceSnapshot) {
      throw const FormatException(
        'Konzentrationsrettung ist durch Charakteränderung veraltet.',
      );
    }
  }
}

/// SRD 5.2.1: the concentration save is a Constitution saving throw.
///
/// Delegate the *existing* class/feature/exhaustion formula to
/// CharacterRuleEngine.savingThrow rather than duplicating its arithmetic.
/// External feats, magic items and tactical effects have no inferred value.
/// The future controller must validate a matching hero snapshot and apply
/// the actual d20 result through a separately confirmed rule transition.
class SrdConcentrationSaveModifierRules {
  const SrdConcentrationSaveModifierRules._();

  static const _abilities = <String>{
    'strength',
    'dexterity',
    'constitution',
    'intelligence',
    'wisdom',
    'charisma',
  };

  static SrdConcentrationSaveModifierEvidence prepare(
    HeroCharacter hero, {
    required bool otherModifierSourcesReviewedConfirmed,
    required bool rollCircumstancesReviewedConfirmed,
    int confirmedAdditionalModifier = 0,
    bool additionalModifierIndependentlyConfirmed = false,
    bool situationalAdvantage = false,
    bool situationalDisadvantage = false,
  }) {
    if (!otherModifierSourcesReviewedConfirmed ||
        !rollCircumstancesReviewedConfirmed ||
        (confirmedAdditionalModifier != 0 &&
            !additionalModifierIndependentlyConfirmed)) {
      throw const FormatException(
        'Zusatzboni, Erschwernisse und Würfelumstände sind nicht bestätigt.',
      );
    }
    if (confirmedAdditionalModifier < -30 ||
        confirmedAdditionalModifier > 30) {
      throw RangeError.range(
        confirmedAdditionalModifier,
        -30,
        30,
        'confirmedAdditionalModifier',
      );
    }
    if (hero.concentratingOn.trim().isEmpty ||
        hero.concentratingOn != hero.concentratingOn.trim() ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.isDead ||
        !ConditionRules.canTakeActions(hero)) {
      throw StateError(
        'Ein aktiver, handlungsfähiger Konzentrationszauber ist erforderlich.',
      );
    }
    final primary = findSrdClass(hero.className)?.name;
    final secondary = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (primary == null ||
        hero.level < 1 ||
        hero.level > 20 ||
        hero.secondaryClassLevel < 0 ||
        hero.secondaryClassLevel >= hero.level ||
        (hero.hasSecondClass && (secondary == null || secondary == primary)) ||
        (!hero.hasSecondClass && hero.secondaryClassLevel != 0)) {
      throw const FormatException(
        'Die bestätigten Klassen und Stufen sind nicht konsistent.',
      );
    }
    final proficiencies = hero.savingThrowProficiencies;
    if (proficiencies.toSet().length != proficiencies.length ||
        proficiencies.any((ability) => !_abilities.contains(ability))) {
      throw const FormatException(
        'Die bestätigten Rettungswurf-Übungen sind nicht eindeutig.',
      );
    }
    final rule = CharacterRuleEngine.savingThrow(hero, 'constitution');
    if (rule.automaticallyFails) {
      throw StateError(
        'Die Konstitutionsrettung misslingt wegen eines Zustands.',
      );
    }
    final total = rule.modifier + confirmedAdditionalModifier;
    if (total < -60 || total > 60) {
      throw const FormatException(
        'Die vollständige Rettungswurfmodifikation ist ungültig.',
      );
    }
    return SrdConcentrationSaveModifierEvidence(
      sourceSnapshot: jsonEncode(hero.toJson()),
      baseModifier: rule.modifier,
      additionalModifier: confirmedAdditionalModifier,
      totalModifier: total,
      advantage: rule.advantage || situationalAdvantage,
      disadvantage: rule.disadvantage || situationalDisadvantage,
    );
  }
}
