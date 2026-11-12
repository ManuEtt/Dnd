import 'class_resource_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1, Ranger level 18: Feral Senses grants Blindsight (30 feet).
///
/// This is only the character's *granted sense and range*. A distance check
/// is not proof that any particular creature is perceived: obstacles,
/// location, concealment and any competing rules require confirmed context.
class SrdRangerFeralSensesRules {
  const SrdRangerFeralSensesRules._();

  static const int grantedRangeFeet = 30;
  static const int grantedRangeDecimeters = 90;

  /// No stored feature flag is needed. Multiclass levels are checked against
  /// the confirmed Ranger *class* level, not total character level. Invalid
  /// direct/legacy class snapshots cannot grant a creature a new sense.
  static int? blindsightRangeFeet(HeroCharacter hero) {
    if (hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        hero.secondaryClassLevel < 0) {
      return null;
    }
    final primary = findSrdClass(hero.className)?.name;
    final secondary = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (primary == null ||
        (hero.hasSecondClass
            ? hero.secondaryClassLevel < 1 ||
                  secondary == null ||
                  secondary == primary
            : hero.secondaryClassLevel != 0)) {
      return null;
    }
    return ClassResourceRules.level(hero, 'Waldläufer') >= 18
        ? grantedRangeFeet
        : null;
  }

  /// Only answers whether a *confirmed distance* falls within this sense's
  /// range. It never asserts detection through cover, darkness or hiding.
  /// null denotes insufficient/unavailable evidence, not a false detection.
  static bool? withinConfirmedRange(
    HeroCharacter hero, {
    required int? distanceFeet,
    required bool distanceConfirmed,
  }) {
    final range = blindsightRangeFeet(hero);
    if (range == null ||
        !distanceConfirmed ||
        distanceFeet == null ||
        distanceFeet < 1 ||
        distanceFeet > 1000000) {
      return null;
    }
    return distanceFeet <= range;
  }
}
