import 'dart:convert';

import 'condition_rules.dart';
import 'healing_spell_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_spell_catalog.dart';
import 'srd_spell_component_rules.dart';

/// SRD 5.2.1, Spells / Casting without Slots / Rituals.
///
/// A conservative, read-only eligibility and casting-time preflight. This
/// neither completes a spell nor spends time, materials or spell slots.
class SrdRitualCastingRules {
  const SrdRitualCastingRules._();

  static const _spellLists = <String, String>{
    'Barde': 'Bard',
    'Kleriker': 'Cleric',
    'Druide': 'Druid',
    'Paladin': 'Paladin',
    'Waldläufer': 'Ranger',
    'Zauberer': 'Sorcerer',
    'Hexenmeister': 'Warlock',
    'Magier': 'Wizard',
  };

  /// The exact catalog time is used rather than assuming a Magic action is
  /// precisely six seconds. A ritual takes its ordinary time plus 10 minutes.
  /// Null [SrdRitualCastPlan.totalCastingMinutes] means an Action + 10 min.
  static int? _ordinaryMinutes(SrdSpellDefinition spell) {
    if (!spell.ritual) {
      throw const FormatException('Der Zauber besitzt keinen Ritual-Tag.');
    }
    switch (spell.castingTime) {
      case 'Action or Ritual':
        return null;
      case '1 minute or Ritual':
        return 1;
      case '10 minutes or Ritual':
        return 10;
      case '1 hour or Ritual':
        return 60;
      default:
        throw UnsupportedError(
          'Unbekannte SRD-Ritualzauberzeit: ${spell.castingTime}',
        );
    }
  }

  /// No unverified subclass features, spellbook exceptions, class switches
  /// or ritual-only spell preparation are inferred.
  static SrdRitualCastPlan preflight(
    HeroCharacter hero, {
    required SrdSpellDefinition spell,
    required String castingClass,
    required bool preparedForSelectedClassConfirmed,
    required bool uninterruptedTimeAvailableConfirmed,
    required bool castingConcentrationAvailableConfirmed,
    required bool targetRulesConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool materialComponentConfirmed,
    SrdSpellMaterialSource materialSource =
        SrdSpellMaterialSource.specificComponents,
    bool focusUseAuthorizedConfirmed = false,
    bool costlyComponentAvailableConfirmed = false,
    bool consumedComponentReservedConfirmed = false,
  }) {
    final ordinaryMinutes = _ordinaryMinutes(spell);
    if (spell.level < 1 || spell.level > 9) {
      throw const FormatException(
        'Ritualzauber benötigen einen gültigen Zaubergrad ab 1.',
      );
    }
    if (!hero.spells.contains(spell.name) ||
        !preparedForSelectedClassConfirmed) {
      throw const FormatException(
        'Der Ritualzauber muss für die ausgewählte Klasse '
        'ausdrücklich vorbereitet sein.',
      );
    }
    final canonical = findSrdClass(castingClass)?.name;
    final spellList = _spellLists[canonical];
    if (canonical == null ||
        spellList == null ||
        !spell.classes.contains(spellList) ||
        hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        hero.secondaryClassLevel < 0 ||
        (hero.hasSecondClass && hero.secondaryClassLevel < 1) ||
        (!hero.hasSecondClass && hero.secondaryClassLevel != 0)) {
      throw const FormatException(
        'Ritualzauber und Klassenstufen sind nicht gültig bestätigt.',
      );
    }
    final primary = findSrdClass(hero.className)?.name;
    final secondary = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (primary == null ||
        (hero.hasSecondClass && (secondary == null || secondary == primary)) ||
        (canonical != primary && canonical != secondary) ||
        HealingSpellRules.maximumPreparedSpellLevel(hero, canonical) <
            spell.level) {
      throw const FormatException(
        'Der Ritualzauber gehört nicht zur ausreichend hohen eigenen Klasse.',
      );
    }
    if (hero.isDead ||
        (hero.hitPoints != null && hero.hitPoints! <= 0) ||
        !ConditionRules.canTakeActions(hero) ||
        (hero.equippedArmorId.isNotEmpty && !hero.equippedArmorTrained) ||
        (hero.equippedShieldId.isNotEmpty && !hero.equippedShieldTrained)) {
      throw StateError('Der Charakter kann derzeit kein Ritual wirken.');
    }
    if (!uninterruptedTimeAvailableConfirmed ||
        !castingConcentrationAvailableConfirmed ||
        !targetRulesConfirmed) {
      throw const FormatException(
        'Zusätzliche Ritualzeit, Konzentration während der langen '
        'Zauberzeit und Zielregeln müssen bestätigt sein.',
      );
    }
    if ((spell.verbal && !verbalComponentConfirmed) ||
        (spell.somatic && !somaticComponentConfirmed)) {
      throw const FormatException(
        'Die benötigten V-/S-Komponenten sind nicht bestätigt.',
      );
    }
    final materials = SrdSpellComponentRules.validateMaterial(
      spell,
      materialComponentConfirmed: materialComponentConfirmed,
      source: materialSource,
      focusUseAuthorizedConfirmed: focusUseAuthorizedConfirmed,
      costlyComponentAvailableConfirmed: costlyComponentAvailableConfirmed,
      consumedComponentReservedConfirmed: consumedComponentReservedConfirmed,
    );
    return SrdRitualCastPlan(
      sourceSnapshot: jsonEncode(hero.toJson()),
      spellName: spell.name,
      castingClass: canonical,
      spellLevel: spell.level,
      normalCastingTime: spell.castingTime,
      additionalMinutes: 10,
      totalCastingMinutes:
          ordinaryMinutes == null ? null : ordinaryMinutes + 10,
      hasConsumedMaterial: materials.isConsumed,
    );
  }
}

/// Approval metadata only. Never treat this plan as a completed spell effect.
class SrdRitualCastPlan {
  const SrdRitualCastPlan({
    required this.sourceSnapshot,
    required this.spellName,
    required this.castingClass,
    required this.spellLevel,
    required this.normalCastingTime,
    required this.additionalMinutes,
    required this.totalCastingMinutes,
    required this.hasConsumedMaterial,
  });

  final String sourceSnapshot;
  final String spellName;
  final String castingClass;
  final int spellLevel;
  final String normalCastingTime;

  /// Rituals do not spend ordinary or Pact Magic slots; upcasting is forbidden.
  int get spellSlotCost => 0;

  final int additionalMinutes;

  /// Null for an ordinary Action + 10 minutes: no fictitious 6-second clock.
  final int? totalCastingMinutes;
  final bool hasConsumedMaterial;

  /// Prevent a once-checked ritual plan being reused after an unrelated
  /// character change. This does not itself authorize or commit the ritual.
  void validateUnchanged(HeroCharacter hero) {
    if (jsonEncode(hero.toJson()) != sourceSnapshot) {
      throw const FormatException(
        'Ritualvorprüfung ist durch eine Charakteränderung veraltet.',
      );
    }
  }
}
