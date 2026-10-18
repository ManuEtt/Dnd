import 'class_resource_rules.dart';
import 'condition_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'saving_throw_class_actions.dart';
import 'srd_character_classes.dart';

/// A provisional death save, including the untouched state before the roll.
/// Persisting or accepting the result belongs to the game transaction. A class
/// reroll replaces these provisional consequences, including a third failure.
class DeathSavingThrowResult {
  const DeathSavingThrowResult._({
    required this.originalHero,
    required this.hero,
    required this.originalRoll,
    required this.roll,
    required this.passed,
    this.feature,
    this.resource,
    this.fighterLevelBonus = 0,
  });

  final HeroCharacter originalHero;
  final HeroCharacter hero;
  final DiceResult originalRoll;
  final DiceResult roll;
  final bool passed;
  final SavingThrowRerollFeature? feature;
  final String? resource;
  final int fighterLevelBonus;
  bool get rerolled => feature != null;
}

/// SRD 5.2.1 pp. 17–18, Fighter 9 and Monk 14. Death saves have no ability
/// modifier. Disciplined Survivor grants proficiency in *all* saving throws;
/// Exhaustion applies once. Natural 1 and 20 override the modified total.
class DeathSavingThrowRules {
  const DeathSavingThrowRules._();

  static int modifier(HeroCharacter hero) {
    _validateClassLevels(hero);
    final proficient = ClassResourceRules.level(hero, 'Mönch') >= 14;
    return (proficient ? RulesEngine.proficiencyBonus(hero.level) : 0) +
        ExhaustionRules.d20Modifier(hero);
  }

  static DeathSavingThrowResult resolve({
    required HeroCharacter hero,
    required int natural,
  }) {
    _validateEligibleHero(hero);
    return _resolve(originalHero: hero, hero: hero, natural: natural);
  }

  /// These features require no action or reaction and can be used at 0 HP.
  /// This exception is local to death saves: general resource spending keeps
  /// its normal living, conscious character restriction.
  static bool available(HeroCharacter hero, SavingThrowRerollFeature feature) {
    if (!_needsDeathSave(hero)) return false;
    _validateEligibleHero(hero);
    return switch (feature) {
      SavingThrowRerollFeature.disciplinedSurvivor =>
        ClassResourceRules.level(hero, 'Mönch') >= 14 &&
            ClassResourceRules.remaining(hero, 'focusPoints') > 0,
      SavingThrowRerollFeature.indomitable =>
        ClassResourceRules.level(hero, 'Kämpfer') >= 9 &&
            ClassResourceRules.remaining(hero, 'indomitable') > 0,
    };
  }

  static bool canReroll(
    DeathSavingThrowResult result,
    SavingThrowRerollFeature feature,
  ) =>
      !result.passed &&
      !result.rerolled &&
      available(result.originalHero, feature);

  static DeathSavingThrowResult rerollFailed({
    required DeathSavingThrowResult original,
    required int natural,
    required SavingThrowRerollFeature feature,
  }) {
    if (!canReroll(original, feature)) {
      throw StateError(
        'Dieser Todesrettungswurf kann nicht mit diesem Klassenmerkmal wiederholt werden.',
      );
    }
    final hero = original.originalHero;
    final resource = feature == SavingThrowRerollFeature.indomitable
        ? 'indomitable'
        : 'focusPoints';
    // Spend against the pre-save hero: the provisional result may already
    // contain a fatal third failure, which the replacement roll can avert.
    final spentHero = hero.copyWith(
      spentClassResources: {
        ...hero.spentClassResources,
        resource: (hero.spentClassResources[resource] ?? 0) + 1,
      },
    );
    ClassResourceRules.validate(spentHero);
    return _resolve(
      originalHero: hero,
      hero: spentHero,
      natural: natural,
      originalRoll: original.originalRoll,
      feature: feature,
      resource: resource,
      fighterLevelBonus: feature == SavingThrowRerollFeature.indomitable
          ? ClassResourceRules.level(hero, 'Kämpfer')
          : 0,
    );
  }

  static DeathSavingThrowResult _resolve({
    required HeroCharacter originalHero,
    required HeroCharacter hero,
    required int natural,
    DiceResult? originalRoll,
    SavingThrowRerollFeature? feature,
    String? resource,
    int fighterLevelBonus = 0,
  }) {
    if (natural < 1 || natural > 20) {
      throw RangeError.range(natural, 1, 20, 'natural');
    }
    final bonus = modifier(hero) + fighterLevelBonus;
    final roll = DiceResult(
      expression:
          '1d20${bonus == 0
              ? ''
              : bonus > 0
              ? '+$bonus'
              : '$bonus'}',
      rolls: [natural],
      modifier: bonus,
      total: natural + bonus,
      natural: natural,
    );
    final passed = natural == 20 || (natural != 1 && roll.total >= 10);
    final HeroCharacter next;
    if (natural == 20) {
      next = RulesEngine.heal(hero, 1);
    } else {
      final conditions = [...hero.manualConditions];
      if (!conditions.contains(RulesEngine.unconscious)) {
        conditions.add(RulesEngine.unconscious);
      }
      var successes = hero.deathSuccesses + (passed ? 1 : 0);
      var failures =
          hero.deathFailures +
          (passed
              ? 0
              : natural == 1
              ? 2
              : 1);
      if (failures >= 3) {
        if (!conditions.contains(RulesEngine.dead)) {
          conditions.add(RulesEngine.dead);
        }
        failures = 3;
      } else if (successes >= 3) {
        conditions.add(RulesEngine.stable);
        successes = 0;
        failures = 0;
      }
      next = hero.copyWith(
        conditions: conditions,
        deathSuccesses: successes,
        deathFailures: failures,
      );
    }
    return DeathSavingThrowResult._(
      originalHero: originalHero,
      hero: next,
      originalRoll: originalRoll ?? roll,
      roll: roll,
      passed: passed,
      feature: feature,
      resource: resource,
      fighterLevelBonus: fighterLevelBonus,
    );
  }

  static bool _needsDeathSave(HeroCharacter hero) =>
      hero.hitPoints == 0 &&
      !hero.isDead &&
      !hero.conditions.contains(RulesEngine.stable);

  static void _validateEligibleHero(HeroCharacter hero) {
    if (hero.hitPoints == null ||
        hero.maxHitPoints == null ||
        hero.maxHitPoints! < 1 ||
        !_needsDeathSave(hero)) {
      throw StateError('Dieser Charakter benötigt keinen Todesrettungswurf.');
    }
    if (hero.deathSuccesses < 0 ||
        hero.deathSuccesses > 2 ||
        hero.deathFailures < 0 ||
        hero.deathFailures > 2) {
      throw StateError('Die gespeicherten Todesrettungswürfe sind ungültig.');
    }
    _validateClassLevels(hero);
    ClassResourceRules.validate(hero);
  }

  static void _validateClassLevels(HeroCharacter hero) {
    final primary = findSrdClass(hero.className)?.name;
    final secondary = findSrdClass(hero.secondaryClassName)?.name;
    if (hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        hero.secondaryClassLevel < 0 ||
        (hero.hasSecondClass
            ? hero.secondaryClassLevel < 1 ||
                  (primary != null && primary == secondary)
            : hero.secondaryClassLevel != 0)) {
      throw StateError('Die gespeicherten Klassenstufen sind ungültig.');
    }
  }
}
