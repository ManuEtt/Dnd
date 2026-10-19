import 'dart:convert';
import 'dart:math' as math;

import 'character_creation_progression.dart';
import 'class_progression_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';
import 'srd_class_feature_catalog.dart';

/// SRD 5.2.1, Character Advancement: fixed Hit Die increase for one confirmed
/// class level. A choice/feature listing is NOT permission to invent effects.
/// The same-class path intentionally does not grant new class-1 equipment,
/// saving throw training, spells, subclass effects or feat benefits.
enum LevelUpMethod { experience, milestone }

class SrdClassLevelUpProposal {
  const SrdClassLevelUpProposal({
    required this.sourceSnapshot,
    required this.className,
    required this.classLevel,
    required this.totalLevel,
    required this.hitDie,
    required this.hpGain,
    required this.method,
    required this.features,
    required this.requiredChoices,
    required this.chosenSubclass,
    required this.isSecondary,
    required this.abilityIncreases,
  });

  final String sourceSnapshot;
  final String className;
  final int classLevel, totalLevel, hitDie, hpGain;
  final LevelUpMethod method;
  final List<SrdClassFeature> features;
  final List<String> requiredChoices;
  final String chosenSubclass;
  final bool isSecondary;
  final Map<String, int> abilityIncreases;

  HeroCharacter applyTo(HeroCharacter hero) {
    if (jsonEncode(hero.toJson()) != sourceSnapshot) {
      throw const FormatException(
        'Der Charakter hat sich seit dem Stufenvorschlag verändert.',
      );
    }
    final unresolved = requiredChoices.where(
      (choice) =>
          (!choice.startsWith('Unterklasse wählen') ||
              chosenSubclass.isEmpty) &&
          (!choice.startsWith('Talent oder Attributsverbesserung wählen') ||
              abilityIncreases.isEmpty) &&
          (!choice.startsWith('Zusätzliche Kämpfer-Talentauswahl') ||
              abilityIncreases.isEmpty) &&
          (!choice.startsWith('Zusätzliche Schurken-Talentauswahl') ||
              abilityIncreases.isEmpty),
    );
    final notes = <String>[
      ...hero.unverifiedNotes,
      for (final choice in unresolved)
        'OFFENE SRD-STUFENWAHL: $className $classLevel – $choice',
    ];
    final resulting = hero.copyWith(
      level: totalLevel,
      secondaryClassLevel: isSecondary
          ? hero.secondaryClassLevel + 1
          : hero.secondaryClassLevel,
      subclass: chosenSubclass.isNotEmpty ? chosenSubclass : hero.subclass,
      abilities: {
        ...hero.abilities,
        for (final change in abilityIncreases.entries)
          change.key: hero.abilities[change.key]! + change.value,
      },
      maxHitPoints: hero.maxHitPoints! + hpGain,
      hitPoints: hero.hitPoints! + hpGain,
      unverifiedNotes: notes,
      // DO NOT silently credit feats, subclass rules, spells or resources.
    );
    HeroCharacter.fromJson(resulting.toJson());
    return resulting;
  }
}

class SrdClassLevelUpRules {
  const SrdClassLevelUpRules._();

  static SrdClassLevelUpProposal propose({
    required HeroCharacter hero,
    required String className,
    required LevelUpMethod method,
    String chosenSubclass = '',
    Map<String, int> abilityIncreases = const {},
  }) {
    final first = findSrdClass(hero.className);
    final other = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)
        : null;
    final selected = findSrdClass(className);
    if (selected == null || first == null) {
      throw const FormatException('Klasse ist nicht im SRD 5.2.1 hinterlegt.');
    }
    final isSecondary = other != null && selected.name == other.name;
    if (selected.name != first.name && !isSecondary) {
      throw const FormatException(
        'Eine neue Zweitklasse benötigt den Mehrklassen-Assistenten.',
      );
    }
    if (hero.level < 1 || hero.level >= 20) {
      throw const FormatException('Gesamtstufe muss zwischen 1 und 19 liegen.');
    }
    if (hero.isDead) {
      throw const FormatException('Tote Charaktere können nicht aufsteigen.');
    }
    if (hero.maxHitPoints == null ||
        hero.hitPoints == null ||
        hero.hitPoints! > hero.maxHitPoints!) {
      throw const FormatException(
        'Aktuelle und maximale Trefferpunkte müssen bestätigt sein.',
      );
    }
    final con = hero.abilities['constitution'];
    if (con == null) {
      throw const FormatException(
        'Für einen Stufenaufstieg Konstitution bestätigen.',
      );
    }
    if (method == LevelUpMethod.experience) {
      final threshold = CharacterCreationProgression.startingExperience(
        hero.level + 1,
      );
      if (hero.experience == null || hero.experience! < threshold) {
        throw FormatException(
          'Für Stufe ${hero.level + 1} sind mindestens $threshold EP erforderlich. '
          'Alternativ einen bestätigten Meilenstein auswählen.',
        );
      }
    }
    final classLevel =
        (isSecondary ? hero.secondaryClassLevel : hero.primaryClassLevel) + 1;
    final supportedSubclass =
        SrdClassFeatureCatalog.defaultSubclass[selected.name] ?? '';
    if (chosenSubclass.isNotEmpty &&
        (isSecondary ||
            classLevel != 3 ||
            hero.subclass.isNotEmpty ||
            chosenSubclass != supportedSubclass)) {
      throw const FormatException(
        'Nur die ausdrücklich gewählte lizenzierte SRD-Unterklasse '
        'der Hauptklasse auf Klassenstufe 3 ist hier zulässig.',
      );
    }
    final classFeatures = SrdClassFeatureCatalog.atClassLevel(
      selected.name,
      classLevel,
      subclass: chosenSubclass.isNotEmpty ? chosenSubclass : hero.subclass,
    );
    final milestones = ClassProgressionRules.milestonesForClass(selected.name)
        .where(
          (m) =>
              m.classLevel == classLevel &&
              (m.type == ClassMilestoneType.subclassChoice ||
                  m.type == ClassMilestoneType.featChoice ||
                  m.type == ClassMilestoneType.epicBoon),
        )
        .map((m) => m.label);
    final featDue = ClassProgressionRules.milestonesForClass(selected.name).any(
      (m) =>
          m.classLevel == classLevel && m.type == ClassMilestoneType.featChoice,
    );
    if (!featDue && abilityIncreases.isNotEmpty) {
      throw const FormatException(
        'Auf dieser Klassenstufe ist keine Attributsverbesserung vorgesehen.',
      );
    }
    if (abilityIncreases.isNotEmpty) {
      final values = abilityIncreases.values.toList();
      final validShape =
          (values.length == 1 && values.single == 2) ||
          (values.length == 2 && values.every((v) => v == 1));
      if (!validShape) {
        throw const FormatException(
          'Attributsverbesserung muss +2 oder +1/+1 betragen.',
        );
      }
      for (final entry in abilityIncreases.entries) {
        if (!abilityNames.contains(entry.key) ||
            hero.abilities[entry.key] == null ||
            hero.abilities[entry.key]! + entry.value > 20) {
          throw const FormatException(
            'Die gewählten bestätigten Attribute dürfen 20 nicht überschreiten.',
          );
        }
      }
    }
    final choices = <String>{
      ...milestones,
      for (final feature in classFeatures)
        if (feature.automation == FeatureAutomation.choiceRequired &&
            !feature.name.contains('Subclass') &&
            feature.name != 'Ability Score Improvement' &&
            feature.name != 'Epic Boon')
          'Klassenwahl: ${feature.name}',
    };
    final oldConModifier = RulesEngine.abilityModifier(con);
    final newConModifier = RulesEngine.abilityModifier(
      con + (abilityIncreases['constitution'] ?? 0),
    );
    final fixedHpGain = math.max(1, selected.hitDie ~/ 2 + 1 + oldConModifier);
    // A Constitution modifier change affects HP for every total level,
    // including the newly gained one (SRD 5.2.1 Ability Scores).
    final hpGain =
        fixedHpGain + (newConModifier - oldConModifier) * (hero.level + 1);
    if (hero.maxHitPoints! + hpGain < 1) {
      throw const FormatException('Ungültige neue maximale Trefferpunkte.');
    }
    return SrdClassLevelUpProposal(
      sourceSnapshot: jsonEncode(hero.toJson()),
      className: selected.name,
      classLevel: classLevel,
      totalLevel: hero.level + 1,
      hitDie: selected.hitDie,
      hpGain: hpGain,
      method: method,
      features: List.unmodifiable(classFeatures),
      requiredChoices: List.unmodifiable(choices),
      chosenSubclass: chosenSubclass,
      isSecondary: isSecondary,
      abilityIncreases: Map.unmodifiable(abilityIncreases),
    );
  }
}
