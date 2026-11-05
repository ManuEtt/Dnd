import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'srd_concentration_save_modifier_rules.dart';

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
    // Reuse only the existing pure profile guard. No concentration, die,
    // situational bonus or player confirmation is inferred by this call.
    SrdConcentrationSaveModifierRules.validateClassAndProficiencies(hero);
    // Keep all proficiency, exhaustion and advantage arithmetic in one place.
    return CharacterRuleEngine.savingThrow(hero, ability);
  }
}
