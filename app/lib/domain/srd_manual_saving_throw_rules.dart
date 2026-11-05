import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';

/// Preparation for an explicitly requested manual saving throw, not a sheet
/// preview. SRD 5.2.1: Saving Throws, class proficiencies and Conditions.
///
/// Null means an automatic failure: no modifier is invented and no d20 may be
/// rolled. The caller records that outcome separately. Old profiles remain
/// readable; this check only gates the confirmed rule action.
class SrdManualSavingThrowRules {
  const SrdManualSavingThrowRules._();

  static D20Rule? prepare(HeroCharacter hero, String ability) {
    if (!abilityNames.contains(ability)) {
      throw const FormatException('Unbekanntes Rettungswurf-Attribut.');
    }
    // Preserve the existing requirement even when a condition causes failure.
    if (hero.abilities[ability] == null) {
      throw StateError('Das Attribut $ability ist nicht bestätigt.');
    }
    if (ConditionRules.hasAutomaticSavingThrowFailure(hero, ability)) {
      return null;
    }
    final primary = findSrdClass(hero.className)?.name;
    final secondary = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (primary == null ||
        hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        hero.secondaryClassLevel < 0 ||
        (hero.hasSecondClass
            ? hero.secondaryClassLevel < 1 ||
                  secondary == null ||
                  secondary == primary
            : hero.secondaryClassLevel != 0)) {
      throw const FormatException(
        'Die bestätigten Klassen und Stufen sind nicht konsistent.',
      );
    }
    final proficiencies = hero.savingThrowProficiencies;
    if (proficiencies.toSet().length != proficiencies.length ||
        proficiencies.any((value) => !abilityNames.contains(value))) {
      throw const FormatException(
        'Die bestätigten Rettungswurf-Übungen sind nicht eindeutig.',
      );
    }
    // Keep all proficiency, exhaustion and advantage arithmetic in one place.
    return CharacterRuleEngine.savingThrow(hero, ability);
  }
}
