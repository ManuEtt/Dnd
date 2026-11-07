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

  // Exact identity, level, casting time and class-list metadata of the 29
  // ritual-tagged entries in the current working SRD 5.2.1 spell index.
  // Class confirmation alone must never turn a forged non-ritual spell into
  // a slot-free ritual. This is not a full official spell-effect audit.
  static const _indexedRituals =
      <
        String,
        ({String id, int level, String castingTime, List<String> classes})
      >{
        'Alarm': (
          id: 'spell-alarm',
          level: 1,
          castingTime: '1 minute or Ritual',
          classes: ['Ranger', 'Wizard'],
        ),
        'Animal Messenger': (
          id: 'spell-animal-messenger',
          level: 2,
          castingTime: 'Action or Ritual',
          classes: ['Bard', 'Druid', 'Ranger'],
        ),
        'Augury': (
          id: 'spell-augury',
          level: 2,
          castingTime: '1 minute or Ritual',
          classes: ['Cleric', 'Druid', 'Wizard'],
        ),
        'Commune': (
          id: 'spell-commune',
          level: 5,
          castingTime: '1 minute or Ritual',
          classes: ['Cleric'],
        ),
        'Commune with Nature': (
          id: 'spell-commune-with-nature',
          level: 5,
          castingTime: '1 minute or Ritual',
          classes: ['Druid', 'Ranger'],
        ),
        'Comprehend Languages': (
          id: 'spell-comprehend-languages',
          level: 1,
          castingTime: 'Action or Ritual',
          classes: ['Bard', 'Sorcerer', 'Warlock', 'Wizard'],
        ),
        'Contact Other Plane': (
          id: 'spell-contact-other-plane',
          level: 5,
          castingTime: '1 minute or Ritual',
          classes: ['Warlock', 'Wizard'],
        ),
        'Detect Magic': (
          id: 'spell-detect-magic',
          level: 1,
          castingTime: 'Action or Ritual',
          classes: [
            'Bard',
            'Cleric',
            'Druid',
            'Paladin',
            'Ranger',
            'Sorcerer',
            'Warlock',
            'Wizard',
          ],
        ),
        'Detect Poison and Disease': (
          id: 'spell-detect-poison-and-disease',
          level: 1,
          castingTime: 'Action or Ritual',
          classes: ['Cleric', 'Druid', 'Paladin', 'Ranger'],
        ),
        'Divination': (
          id: 'spell-divination',
          level: 4,
          castingTime: 'Action or Ritual',
          classes: ['Cleric', 'Druid', 'Wizard'],
        ),
        'Find Familiar': (
          id: 'spell-find-familiar',
          level: 1,
          castingTime: '1 hour or Ritual',
          classes: ['Wizard'],
        ),
        'Floating Disk': (
          id: 'spell-floating-disk',
          level: 1,
          castingTime: 'Action or Ritual',
          classes: ['Wizard'],
        ),
        'Forbiddance': (
          id: 'spell-forbiddance',
          level: 6,
          castingTime: '10 minutes or Ritual',
          classes: ['Cleric'],
        ),
        'Gentle Repose': (
          id: 'spell-gentle-repose',
          level: 2,
          castingTime: 'Action or Ritual',
          classes: ['Cleric', 'Paladin', 'Wizard'],
        ),
        'Identify': (
          id: 'spell-identify',
          level: 1,
          castingTime: '1 minute or Ritual',
          classes: ['Bard', 'Wizard'],
        ),
        'Illusory Script': (
          id: 'spell-illusory-script',
          level: 1,
          castingTime: '1 minute or Ritual',
          classes: ['Bard', 'Warlock', 'Wizard'],
        ),
        'Instant Summons': (
          id: 'spell-instant-summons',
          level: 6,
          castingTime: '1 minute or Ritual',
          classes: ['Wizard'],
        ),
        'Locate Animals or Plants': (
          id: 'spell-locate-animals-or-plants',
          level: 2,
          castingTime: 'Action or Ritual',
          classes: ['Bard', 'Druid', 'Ranger'],
        ),
        'Magic Mouth': (
          id: 'spell-magic-mouth',
          level: 2,
          castingTime: '1 minute or Ritual',
          classes: ['Bard', 'Wizard'],
        ),
        'Meld into Stone': (
          id: 'spell-meld-into-stone',
          level: 3,
          castingTime: 'Action or Ritual',
          classes: ['Cleric', 'Druid', 'Ranger'],
        ),
        'Phantom Steed': (
          id: 'spell-phantom-steed',
          level: 3,
          castingTime: '1 minute or Ritual',
          classes: ['Wizard'],
        ),
        'Purify Food and Drink': (
          id: 'spell-purify-food-and-drink',
          level: 1,
          castingTime: 'Action or Ritual',
          classes: ['Cleric', 'Druid', 'Paladin'],
        ),
        'Silence': (
          id: 'spell-silence',
          level: 2,
          castingTime: 'Action or Ritual',
          classes: ['Bard', 'Cleric', 'Ranger'],
        ),
        'Speak with Animals': (
          id: 'spell-speak-with-animals',
          level: 1,
          castingTime: 'Action or Ritual',
          classes: ['Bard', 'Druid', 'Ranger', 'Warlock'],
        ),
        'Telepathic Bond': (
          id: 'spell-telepathic-bond',
          level: 5,
          castingTime: 'Action or Ritual',
          classes: ['Bard', 'Wizard'],
        ),
        'Tiny Hut': (
          id: 'spell-tiny-hut',
          level: 3,
          castingTime: '1 minute or Ritual',
          classes: ['Bard', 'Wizard'],
        ),
        'Unseen Servant': (
          id: 'spell-unseen-servant',
          level: 1,
          castingTime: 'Action or Ritual',
          classes: ['Bard', 'Warlock', 'Wizard'],
        ),
        'Water Breathing': (
          id: 'spell-water-breathing',
          level: 3,
          castingTime: 'Action or Ritual',
          classes: ['Druid', 'Ranger', 'Sorcerer', 'Wizard'],
        ),
        'Water Walk': (
          id: 'spell-water-walk',
          level: 3,
          castingTime: 'Action or Ritual',
          classes: ['Cleric', 'Druid', 'Ranger', 'Sorcerer'],
        ),
      };

  static void _validateIndexedRitual(SrdSpellDefinition spell) {
    final expected = _indexedRituals[spell.name];
    if (expected == null ||
        spell.id != expected.id ||
        spell.level != expected.level ||
        spell.castingTime != expected.castingTime ||
        spell.classes.length != expected.classes.length) {
      throw const FormatException(
        'Ritualzauber stimmt nicht mit dem SRD-Katalogeintrag überein.',
      );
    }
    for (var i = 0; i < expected.classes.length; i++) {
      if (spell.classes[i] != expected.classes[i]) {
        throw const FormatException(
          'Ritualzauber gehört nicht zur geprüften Klassenliste.',
        );
      }
    }
  }

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
    List<SrdMaterialItemConfirmation> confirmedMaterialItems = const [],
  }) {
    final ordinaryMinutes = _ordinaryMinutes(spell);
    _validateIndexedRitual(spell);
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
      confirmedMaterialItems: confirmedMaterialItems,
    );
    return SrdRitualCastPlan(
      sourceSnapshot: jsonEncode(hero.toJson()),
      spellName: spell.name,
      castingClass: canonical,
      spellLevel: spell.level,
      normalCastingTime: spell.castingTime,
      additionalMinutes: 10,
      totalCastingMinutes: ordinaryMinutes == null
          ? null
          : ordinaryMinutes + 10,
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
