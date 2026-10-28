import 'class_resource_rules.dart';
import 'models.dart';

/// SRD 5.2.1: Barbarian 18, Indomitable Might (CC BY 4.0).
///
/// https://www.dndbeyond.com/srd — Classes / Barbarian / Indomitable Might.
/// The player may replace a lower Strength check or Strength saving throw
/// total with their confirmed Strength score. No dice, HP or saves are mutated.
/// An attack, initiative, a death save or a different ability is never eligible.
enum SrdD20CheckKind { abilityCheck, savingThrow, attack, initiative, deathSave }

class SrdIndomitableMightRules {
  const SrdIndomitableMightRules._();

  static bool isEligible(HeroCharacter hero) =>
      ClassResourceRules.level(hero, 'Barbar') >= 18;

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
