import 'dart:convert';
import 'dart:math' as math;

import 'character_creation_progression.dart';
import 'class_progression_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';
import 'srd_class_feature_catalog.dart';

/// A confirmed advancement of the existing *primary* class by exactly one
/// level. Features already encoded in SrdClassFeatureCatalog are read from
/// class level; choices are never granted without an explicit selection.
/// Other classes' levels and spent resources remain untouched.
class PrimaryClassLevelUp {
  const PrimaryClassLevelUp._();

  static bool needsAbilityFeat(String className, int newClassLevel) =>
      ClassProgressionRules.milestonesForClass(className).any(
        (m) =>
            m.classLevel == newClassLevel &&
            m.type == ClassMilestoneType.featChoice,
      );

  static SrdPrimaryLevelUpProposal propose({
    required HeroCharacter hero,
    required bool milestoneAdvancement,
    String? chosenSubclass,
    Map<String, int> abilityIncreases = const {},
    bool deferFeat = false,
  }) {
    final cls = findSrdClass(hero.className);
    if (cls == null) {
      throw const FormatException(
        'Für die Ausgangsklasse liegen keine geprüften SRD-Regeln vor.',
      );
    }
    if (hero.level < 1 || hero.level >= 20 ||
        hero.primaryClassLevel < 1 || hero.primaryClassLevel >= 20) {
      throw const FormatException('Die zulässige Gesamtstufe ist 1 bis 20.');
    }
    if (hero.maxHitPoints == null || hero.hitPoints == null) {
      throw const FormatException(
        'Bestätige aktuelle und maximale Trefferpunkte vor dem Aufstieg.',
      );
    }
    final conScore = hero.abilities['constitution'];
    if (conScore == null) {
      throw const FormatException(
        'Bestätige die Konstitution vor dem Stufenaufstieg.',
      );
    }
    final nextLevel = hero.level + 1;
    final nextClassLevel = hero.primaryClassLevel + 1;
    final threshold = CharacterCreationProgression.startingExperience(nextLevel);
    if (!milestoneAdvancement &&
        (hero.experience == null || hero.experience! < threshold)) {
      throw FormatException(
        'Stufe $nextLevel erfordert mindestens $threshold EP. '
        'Ohne diese EP ist nur ein ausdrücklich bestätigter Meilenstein möglich.',
      );
    }
    if (chosenSubclass != null && nextClassLevel != 3) {
      throw const FormatException('Unterklassenwahl ist hier nicht vorgesehen.');
    }
    final allowedSubclass = SrdClassFeatureCatalog.defaultSubclass[cls.name]!;
    final originalSubclass = hero.subclass.trim();
    final String nextSubclass;
    if (nextClassLevel == 3 && originalSubclass.isEmpty) {
      if (chosenSubclass != allowedSubclass) {
        throw FormatException(
          'Auf Klassenstufe 3 ausdrücklich eine SRD-Unterklasse wählen '
          '($allowedSubclass).',
        );
      }
      nextSubclass = allowedSubclass;
    } else {
      nextSubclass = originalSubclass;
      if (chosenSubclass != null) {
        throw const FormatException('Unterklasse wurde bereits gewählt.');
      }
    }

    final featDue = needsAbilityFeat(cls.name, nextClassLevel);
    if (!featDue && (abilityIncreases.isNotEmpty || deferFeat)) {
      throw const FormatException(
        'Auf dieser Klassenstufe steht keine Talentauswahl an.',
      );
    }
    if (featDue && deferFeat && abilityIncreases.isNotEmpty) {
      throw const FormatException(
        'Talent nicht gleichzeitig wählen und aufschieben.',
      );
    }
    if (featDue && !deferFeat) {
      final increases = abilityIncreases.values.toList();
      final validShape = increases.length == 1 && increases.single == 2 ||
          increases.length == 2 && increases.every((v) => v == 1);
      if (!validShape) {
        throw const FormatException(
          'Attributsverbesserung: entweder +2 auf ein Attribut oder '
          '+1 auf zwei verschiedene Attribute. Anderes Talent ausdrücklich aufschieben.',
        );
      }
    }
    final nextScores = <String, int?>{...hero.abilities};
    for (final e in abilityIncreases.entries) {
      if (!nextScores.containsKey(e.key) || nextScores[e.key] == null ||
          nextScores[e.key]! + e.value > 20) {
        throw const FormatException(
          'Für die Attributsverbesserung sind bestätigte Werte bis 20 erforderlich.',
        );
      }
      nextScores[e.key] = nextScores[e.key]! + e.value;
    }
    final oldConMod = RulesEngine.abilityModifier(conScore);
    final nextConMod = RulesEngine.abilityModifier(nextScores['constitution']!);
    final fixedHitPoints = math.max(1, cls.hitDie ~/ 2 + 1 + oldConMod);
    // If CON rises during level-up, SRD retroactively raises maximum HP for
    // all levels, including the newly gained class level.
    final retroactiveConGain = (nextConMod - oldConMod) * nextLevel;
    final totalGain = fixedHitPoints + retroactiveConGain;
    if (hero.maxHitPoints! + totalGain < 1) {
      throw const FormatException('Ungültige neue maximale Trefferpunkte.');
    }
    final due = SrdClassFeatureCatalog.atClassLevel(
      cls.name,
      nextClassLevel,
      subclass: nextSubclass,
    );
    final pending = <String>[
      if (featDue && deferFeat)
        'Klassenstufe $nextClassLevel: Talent/Attributsverbesserung noch wählen',
      for (final feature in due)
        if (feature.automation == FeatureAutomation.choiceRequired &&
            feature.name != 'Ability Score Improvement' &&
            !feature.name.contains('Subclass'))
          'Klassenstufe $nextClassLevel: Auswahl ${feature.name} offen',
    ];
    final notes = <String>[...hero.unverifiedNotes, ...pending];
    final nextHero = hero.copyWith(
      level: nextLevel,
      subclass: nextSubclass,
      abilities: nextScores,
      maxHitPoints: hero.maxHitPoints! + totalGain,
      hitPoints: math.min(
        hero.maxHitPoints! + totalGain,
        math.max(0, hero.hitPoints! + totalGain),
      ),
      unverifiedNotes: notes,
      // XP is never invented when milestone advancement was confirmed.
      // New class features are derived by SrdClassFeatureCatalog.unlocked.
    );
    return SrdPrimaryLevelUpProposal(
      previousSnapshot: jsonEncode(hero.toJson()),
      resultingHero: nextHero,
      newClassLevel: nextClassLevel,
      hitPointGain: totalGain,
      fixedHitPointGain: fixedHitPoints,
      pendingSelections: List.unmodifiable(pending),
      newlyUnlocked: List.unmodifiable(due),
    );
  }
}

class SrdPrimaryLevelUpProposal {
  const SrdPrimaryLevelUpProposal({
    required this.previousSnapshot,
    required this.resultingHero,
    required this.newClassLevel,
    required this.hitPointGain,
    required this.fixedHitPointGain,
    required this.pendingSelections,
    required this.newlyUnlocked,
  });
  final String previousSnapshot;
  final HeroCharacter resultingHero;
  final int newClassLevel, hitPointGain, fixedHitPointGain;
  final List<String> pendingSelections;
  final List<SrdClassFeature> newlyUnlocked;

  HeroCharacter applyTo(HeroCharacter current) {
    if (jsonEncode(current.toJson()) != previousSnapshot) {
      throw const FormatException(
        'Der Charakter wurde seit der Vorschau verändert. '
        'Bitte den Aufstieg erneut vorbereiten.',
      );
    }
    return HeroCharacter.fromJson(resultingHero.toJson());
  }
}
