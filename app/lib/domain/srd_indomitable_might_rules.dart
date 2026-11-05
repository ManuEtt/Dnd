import 'class_resource_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1: Barbarian 18, Indomitable Might (CC BY 4.0).
///
/// https://www.dndbeyond.com/srd — Classes / Barbarian / Indomitable Might.
/// The player may replace a lower Strength check or Strength saving throw
/// total with their confirmed Strength score. No dice, HP or saves are mutated.
/// An attack, initiative, a death save or a different ability is never eligible.
enum SrdD20CheckKind {
  abilityCheck,
  savingThrow,
  attack,
  initiative,
  deathSave,
}

class SrdIndomitableMightRules {
  const SrdIndomitableMightRules._();

  /// Invalid direct/legacy multiclass profiles must not unlock a level-18
  /// feature by adding duplicate aliases or trusting an unknown other class.
  static bool isEligible(HeroCharacter hero) {
    if (hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        hero.secondaryClassLevel < 0) {
      return false;
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
      return false;
    }
    return ClassResourceRules.level(hero, 'Barbar') >= 18;
  }

  static int effectiveTotal({
    required HeroCharacter hero,
    required String ability,
    required SrdD20CheckKind kind,
    required int rolledTotal,
  }) {
    if (!isEligible(hero) ||
        ability != 'strength' ||
        (kind != SrdD20CheckKind.abilityCheck &&
            kind != SrdD20CheckKind.savingThrow)) {
      return rolledTotal;
    }
    final strength = hero.abilities['strength'];
    if (strength == null) {
      throw StateError('Stärke muss für Unbezwingbare Stärke bestätigt sein.');
    }
    return rolledTotal < strength ? strength : rolledTotal;
  }
}
