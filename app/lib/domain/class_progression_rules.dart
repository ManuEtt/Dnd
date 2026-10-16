import 'models.dart';
import 'srd_character_classes.dart';

/// Confirmed SRD 5.2.1 class-level milestones and basic Extra Attack rules.
///
/// Only the Attack action of a character on their own turn is covered by
/// [attacksPerAttackAction]. Subclasses, magical bonus attacks, off-hand
/// attacks, Haste and Action Surge require separate action/effect systems.
/// See docs/CLASS_PROGRESSION_0_6_6.md for precise implementation boundaries.
enum ClassMilestoneType {
  subclassChoice,
  featChoice,
  epicBoon,
  extraAttack,
  fighterFeature,
}

class ClassMilestone {
  const ClassMilestone(this.className, this.classLevel, this.type, this.label);

  final String className;
  final int classLevel;
  final ClassMilestoneType type;
  final String label;
}

class ClassProgressionRules {
  const ClassProgressionRules._();

  static const _extraAttackClasses = <String>{
    'Barbar', 'Kämpfer', 'Mönch', 'Paladin', 'Waldläufer',
  };

  static int _validatedLevel(int level) {
    if (level < 0 || level > 20) {
      throw RangeError.range(level, 0, 20, 'classLevel');
    }
    return level;
  }

  /// Number of attacks in a single, ordinary Attack action.
  /// Fighter level 11/20 overrides the common two-attack feature.
  /// Multiclass Extra Attack features don't stack: use the highest count.
  static int attacksPerAttackAction(HeroCharacter hero) {
    final primary = _attacksForClass(hero.className, hero.primaryClassLevel);
    final secondary = hero.hasSecondClass
        ? _attacksForClass(hero.secondaryClassName, hero.secondaryClassLevel)
        : 1;
    return primary > secondary ? primary : secondary;
  }

  static int _attacksForClass(String raw, int classLevel) {
    _validatedLevel(classLevel);
    final className = findSrdClass(raw)?.name;
    if (className == null || classLevel < 5 ||
        !_extraAttackClasses.contains(className)) {
      return 1;
    }
    if (className == 'Kämpfer' && classLevel >= 20) return 4;
    if (className == 'Kämpfer' && classLevel >= 11) return 3;
    return 2;
  }

  /// Milestones needing an explicit player choice. These indicate when a
  /// decision is due, not that a feature's full effect is implemented.
  /// "Feat choice" can be an eligible feat, not automatically an ASI.
  static List<ClassMilestone> milestonesForClass(String raw) {
    final className = findSrdClass(raw)?.name;
    if (className == null) return const [];
    final result = <ClassMilestone>[
      ClassMilestone(className, 3, ClassMilestoneType.subclassChoice,
          'Unterklasse wählen'),
      for (final level in const [4, 8, 12, 16])
        ClassMilestone(className, level, ClassMilestoneType.featChoice,
            'Talent oder Attributsverbesserung wählen'),
      ClassMilestone(className, 19, ClassMilestoneType.epicBoon,
          'Epische Gabe oder zulässiges Talent wählen'),
    ];
    if (className == 'Kämpfer') {
      for (final level in const [6, 14]) {
        result.add(ClassMilestone(className, level, ClassMilestoneType.featChoice,
            'Zusätzliche Kämpfer-Talentauswahl'));
      }
      for (final entry in const [(2, 'Action Surge'), (9, 'Indomitable'),
          (13, 'Studied Attacks'), (17, 'Action Surge (zweite Nutzung)')]) {
        result.add(ClassMilestone(className, entry.$1,
            ClassMilestoneType.fighterFeature, entry.$2));
      }
      result.add(ClassMilestone(className, 11,
          ClassMilestoneType.extraAttack, 'Drei Angriffe pro Angriffsaktion'));
      result.add(ClassMilestone(className, 20,
          ClassMilestoneType.extraAttack, 'Vier Angriffe pro Angriffsaktion'));
    }
    if (className == 'Schurke') {
      result.add(ClassMilestone(className, 10, ClassMilestoneType.featChoice,
          'Zusätzliche Schurken-Talentauswahl'));
    }
    if (_extraAttackClasses.contains(className)) {
      result.add(ClassMilestone(className, 5,
          ClassMilestoneType.extraAttack, 'Zwei Angriffe pro Angriffsaktion'));
    }
    result.sort((a, b) => a.classLevel.compareTo(b.classLevel));
    return List.unmodifiable(result);
  }

  /// Future milestones for the existing class(es), without inventing a
  /// future multiclass distribution or automatically granting feats.
  static List<ClassMilestone> nextMilestones(HeroCharacter hero,
      {int limit = 4}) {
    if (limit < 1 || limit > 40) {
      throw RangeError.range(limit, 1, 40, 'limit');
    }
    if (hero.level >= 20) return const [];
    final options = <ClassMilestone>[
      ...milestonesForClass(hero.className).where(
        (m) => m.classLevel > hero.primaryClassLevel &&
               hero.level + m.classLevel - hero.primaryClassLevel <= 20,
      ),
      if (hero.hasSecondClass)
        ...milestonesForClass(hero.secondaryClassName).where(
          (m) => m.classLevel > hero.secondaryClassLevel &&
                 hero.level + m.classLevel - hero.secondaryClassLevel <= 20,
        ),
    ];
    // Stable order: upcoming total levels first, then class name and type.
    options.sort((a, b) {
      final aCurrent = a.className == findSrdClass(hero.className)?.name
          ? hero.primaryClassLevel : hero.secondaryClassLevel;
      final bCurrent = b.className == findSrdClass(hero.className)?.name
          ? hero.primaryClassLevel : hero.secondaryClassLevel;
      final byDistance = (a.classLevel - aCurrent)
          .compareTo(b.classLevel - bCurrent);
      if (byDistance != 0) return byDistance;
      final byClass = a.className.compareTo(b.className);
      return byClass != 0 ? byClass : a.type.index.compareTo(b.type.index);
    });
    return List.unmodifiable(options.take(limit));
  }
}
