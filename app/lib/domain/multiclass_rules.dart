import 'dart:math' as math;

import 'models.dart';
import 'character_creation_progression.dart';
import 'srd_class_level_up.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';

/// D&D SRD 5.2.1: a new class is acquired on level-up, not at character creation.
/// Only confirmed attributes and the documented fixed HP option are applied.
/// Class features, resource pools and equipment are NEVER invented here.
class MulticlassRules {
  const MulticlassRules._();

  // A class has one or more alternative prerequisite *sets*. E.g. a fighter
  // requires STR 13 OR DEX 13, whereas a ranger needs DEX 13 AND WIS 13.
  static const prerequisites = <String, List<List<String>>>{
    'Barbar': [
      ['strength'],
    ],
    'Barde': [
      ['charisma'],
    ],
    'Kleriker': [
      ['wisdom'],
    ],
    'Druide': [
      ['wisdom'],
    ],
    'Kämpfer': [
      ['strength'],
      ['dexterity'],
    ],
    'Mönch': [
      ['dexterity', 'wisdom'],
    ],
    'Paladin': [
      ['strength', 'charisma'],
    ],
    'Waldläufer': [
      ['dexterity', 'wisdom'],
    ],
    'Schurke': [
      ['dexterity'],
    ],
    'Zauberer': [
      ['charisma'],
    ],
    'Hexenmeister': [
      ['charisma'],
    ],
    'Magier': [
      ['intelligence'],
    ],
  };

  static String? prerequisiteError(HeroCharacter hero, String target) {
    final first = findSrdClass(hero.className);
    final second = findSrdClass(target);
    if (first == null || second == null) {
      return 'Die Klasse ist nicht im SRD-Assistenten hinterlegt.';
    }
    final missing = <String>[];
    for (final chosen in {first.name, second.name}) {
      final alternatives = prerequisites[chosen];
      if (alternatives == null) {
        return 'Die Klasse ist nicht im Mehrklassen-Assistenten hinterlegt.';
      }
      final qualified = alternatives.any(
        (group) => group.every((stat) => (hero.abilities[stat] ?? 0) >= 13),
      );
      if (!qualified) missing.add(chosen);
    }
    return missing.isEmpty
        ? null
        : 'Für Mehrklassen müssen die Hauptattribute der Klassen '
              '${missing.join(' und ')} jeweils mindestens 13 erreichen. '
              'Auch die Voraussetzungen der Ausgangsklasse gelten.';
  }

  static bool requiresSkill(String name) =>
      const ['Barde', 'Schurke', 'Waldläufer'].contains(name);

  static List<String> availableSkills(HeroCharacter hero, String newClass) {
    final definition = findSrdClass(newClass);
    if (definition == null || !requiresSkill(definition.name)) return const [];
    return definition.skillChoices
        .where((skill) => !hero.skills.contains(skill))
        .toList();
  }

  static MulticlassProposal propose({
    required HeroCharacter hero,
    required String newClass,
    String? selectedSkill,
    LevelUpMethod method = LevelUpMethod.milestone,
  }) {
    if (hero.isDead) {
      throw const FormatException('Tote Charaktere können nicht aufsteigen.');
    }
    if (hero.level >= 20) {
      throw const FormatException('Die maximale Gesamtstufe beträgt 20.');
    }
    if (hero.level < 1 ||
        (hero.hasSecondClass &&
            (hero.secondaryClassLevel < 1 || hero.primaryClassLevel < 1)) ||
        (!hero.hasSecondClass && hero.secondaryClassLevel != 0)) {
      throw const FormatException('Ungültige Klassenstufen.');
    }
    final first = findSrdClass(hero.className);
    final next = findSrdClass(newClass);
    if (first == null || next == null) {
      throw const FormatException(
        'Für die ausgewählte Klasse fehlen SRD-Regeldaten.',
      );
    }
    if (first.name == next.name) {
      throw const FormatException(
        'Die zweite Klasse muss sich von der ersten unterscheiden.',
      );
    }
    if (hero.hasSecondClass && hero.secondaryClassName != next.name) {
      throw const FormatException(
        'Der Assistent unterstützt derzeit genau zwei Klassen.',
      );
    }
    if (method == LevelUpMethod.experience) {
      final needed = CharacterCreationProgression.startingExperience(
        hero.level + 1,
      );
      if (hero.experience == null || hero.experience! < needed) {
        throw FormatException(
          'Für Stufe ${hero.level + 1} sind mindestens $needed EP erforderlich. '
          'Alternativ kann ein bestätigter Meilenstein gewählt werden.',
        );
      }
    }
    if (hero.hitPoints == null ||
        hero.maxHitPoints == null ||
        hero.hitPoints! > hero.maxHitPoints!) {
      throw const FormatException(
        'Aktuelle und maximale Trefferpunkte müssen für den Aufstieg '
        'zuerst bestätigt werden.',
      );
    }
    final error = prerequisiteError(hero, next.name);
    if (error != null) throw FormatException(error);

    final choices = availableSkills(hero, next.name);
    if (!hero.hasSecondClass && requiresSkill(next.name)) {
      if (choices.isEmpty) {
        throw const FormatException('Keine zusätzliche Fertigkeit verfügbar.');
      }
      if (selectedSkill == null || !choices.contains(selectedSkill)) {
        throw const FormatException(
          'Bitte eine neue zulässige Fertigkeit auswählen.',
        );
      }
    } else if (selectedSkill != null) {
      throw const FormatException(
        'Zusätzliche Fertigkeiten nur beim ersten Stufenaufstieg in die Zweitklasse.',
      );
    }
    final con = hero.abilities['constitution'];
    if (con == null) {
      throw const FormatException(
        'Für die Trefferpunkte muss Konstitution bestätigt sein.',
      );
    }
    final constitutionModifier = RulesEngine.abilityModifier(con);
    // SRD 5.2.1: fixed HP at higher levels = Hit Die midpoint+1 + CON,
    // but never less than one point. Do not apply first-level maximum twice.
    final hpGain = math.max(1, next.hitDie ~/ 2 + 1 + constitutionModifier);
    return MulticlassProposal(
      firstClass: first.name,
      secondClass: next.name,
      totalLevel: hero.level + 1,
      secondaryLevel: hero.hasSecondClass ? hero.secondaryClassLevel + 1 : 1,
      hitDie: next.hitDie,
      hpGain: hpGain,
      gainedSkill: selectedSkill,
      sourceHeroId: hero.id,
      sourceExperience: hero.experience,
      sourceAbilities: Map<String, int?>.unmodifiable(hero.abilities),
      sourceSkills: List<String>.unmodifiable(hero.skills),
      sourceMaxHitPoints: hero.maxHitPoints,
    );
  }

  // Per SRD 5.2.1 Multiclass Spellcaster, 2024 rules. Hexenmeister's Pact
  // Magic slots are separate, and fighter/rogue subclass casters are not
  // silently approximated. Informational only; no spell resources invented.
  static int combinedSpellcasterLevel(HeroCharacter hero) {
    int contribution(String name, int levels) {
      if (const [
        'Barde',
        'Kleriker',
        'Druide',
        'Magier',
        'Zauberer',
      ].contains(name)) {
        return levels;
      }
      if (const ['Paladin', 'Waldläufer'].contains(name)) {
        return (levels + 1) ~/ 2;
      }
      return 0;
    }

    return contribution(hero.className, hero.primaryClassLevel) +
        contribution(hero.secondaryClassName, hero.secondaryClassLevel);
  }

  static const _spellSlots = <List<int>>[
    [0, 0, 0, 0, 0, 0, 0, 0, 0],
    [2, 0, 0, 0, 0, 0, 0, 0, 0],
    [3, 0, 0, 0, 0, 0, 0, 0, 0],
    [4, 2, 0, 0, 0, 0, 0, 0, 0],
    [4, 3, 0, 0, 0, 0, 0, 0, 0],
    [4, 3, 2, 0, 0, 0, 0, 0, 0],
    [4, 3, 3, 0, 0, 0, 0, 0, 0],
    [4, 3, 3, 1, 0, 0, 0, 0, 0],
    [4, 3, 3, 2, 0, 0, 0, 0, 0],
    [4, 3, 3, 3, 1, 0, 0, 0, 0],
    [4, 3, 3, 3, 2, 0, 0, 0, 0],
    [4, 3, 3, 3, 2, 1, 0, 0, 0],
    [4, 3, 3, 3, 2, 1, 0, 0, 0],
    [4, 3, 3, 3, 2, 1, 1, 0, 0],
    [4, 3, 3, 3, 2, 1, 1, 0, 0],
    [4, 3, 3, 3, 2, 1, 1, 1, 0],
    [4, 3, 3, 3, 2, 1, 1, 1, 0],
    [4, 3, 3, 3, 2, 1, 1, 1, 1],
    [4, 3, 3, 3, 3, 1, 1, 1, 1],
    [4, 3, 3, 3, 3, 2, 1, 1, 1],
    [4, 3, 3, 3, 3, 2, 2, 1, 1],
  ];

  static List<int> spellSlots(HeroCharacter hero) =>
      _spellSlots[combinedSpellcasterLevel(hero).clamp(0, 20).toInt()];
}

class MulticlassProposal {
  const MulticlassProposal({
    required this.firstClass,
    required this.secondClass,
    required this.totalLevel,
    required this.secondaryLevel,
    required this.hitDie,
    required this.hpGain,
    this.gainedSkill,
    required this.sourceHeroId,
    required this.sourceExperience,
    required this.sourceAbilities,
    required this.sourceSkills,
    required this.sourceMaxHitPoints,
  });
  final String firstClass, secondClass;
  final int totalLevel, secondaryLevel, hitDie, hpGain;
  final String? gainedSkill;
  // The proposal belongs to exactly one confirmed character-sheet snapshot.
  // HP damage taken meanwhile is permitted, but maximum HP, attributes and
  // existing trained skills must still match the values used for the proposal.
  final String sourceHeroId;
  final int? sourceExperience;
  final Map<String, int?> sourceAbilities;
  final List<String> sourceSkills;
  final int? sourceMaxHitPoints;

  bool _hasOriginalSkills(List<String> current) {
    if (current.length != sourceSkills.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != sourceSkills[i]) return false;
    }
    return true;
  }

  HeroCharacter applyTo(HeroCharacter hero) {
    if (hero.id != sourceHeroId ||
        hero.experience != sourceExperience ||
        hero.isDead ||
        hero.maxHitPoints != sourceMaxHitPoints ||
        hero.abilities.length != sourceAbilities.length ||
        sourceAbilities.entries.any(
          (entry) =>
              !hero.abilities.containsKey(entry.key) ||
              hero.abilities[entry.key] != entry.value,
        ) ||
        !_hasOriginalSkills(hero.skills) ||
        hero.level + 1 != totalLevel ||
        hero.className != firstClass ||
        (hero.hasSecondClass &&
            (hero.secondaryClassName != secondClass ||
                hero.secondaryClassLevel + 1 != secondaryLevel)) ||
        (!hero.hasSecondClass && secondaryLevel != 1)) {
      throw const FormatException(
        'Der Heldenstand hat sich seit dem Vorschlag verändert.',
      );
    }
    return hero.copyWith(
      level: totalLevel,
      secondaryClassName: secondClass,
      secondaryClassLevel: secondaryLevel,
      maxHitPoints: hero.maxHitPoints == null
          ? null
          : hero.maxHitPoints! + hpGain,
      hitPoints: hero.hitPoints == null ? null : hero.hitPoints! + hpGain,
      skills: gainedSkill == null
          ? hero.skills
          : [...hero.skills, gainedSkill!],
      // No new saving-throw training, class-1 starting equipment or gold.
    );
  }
}
