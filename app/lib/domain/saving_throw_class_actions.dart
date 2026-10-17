import 'character_rule_engine.dart';
import 'class_resource_rules.dart';
import 'dice_engine.dart';
import 'models.dart';

/// Explicit, deterministic rerolls after a *confirmed failed* saving throw.
/// The new result always replaces the old result, even if it is lower.
/// SRD 5.2.1: Monk 14 (1 Focus) and Fighter 9 (Indomitable, Fighter-level bonus).
/// No rule effect is inferred from narration or an unverified spell DC.
enum SavingThrowRerollFeature { disciplinedSurvivor, indomitable }

class SavingThrowClassActions {
  const SavingThrowClassActions._();

  static bool available(HeroCharacter hero, SavingThrowRerollFeature feature) {
    final currentHp = hero.hitPoints;
    if (hero.isDead || currentHp == null || currentHp <= 0) {
      return false;
    }
    return switch (feature) {
      SavingThrowRerollFeature.disciplinedSurvivor =>
        ClassResourceRules.level(hero, 'Mönch') >= 14 &&
            ClassResourceRules.remaining(hero, 'focusPoints') >= 1,
      SavingThrowRerollFeature.indomitable =>
        ClassResourceRules.level(hero, 'Kämpfer') >= 9 &&
            ClassResourceRules.remaining(hero, 'indomitable') >= 1,
    };
  }

  static SavingThrowRerollResult rerollFailed({
    required HeroCharacter hero,
    required DiceEngine dice,
    required String ability,
    required int difficulty,
    required int originalTotal,
    required SavingThrowRerollFeature feature,
  }) {
    if (difficulty < 1 || difficulty > 30) {
      throw RangeError.range(difficulty, 1, 30, 'difficulty');
    }
    if (originalTotal >= difficulty) {
      throw StateError(
        'Ein erfolgreicher Rettungswurf kann nicht wiederholt werden.',
      );
    }
    if (!const {
      'strength',
      'dexterity',
      'constitution',
      'intelligence',
      'wisdom',
      'charisma',
    }.contains(ability)) {
      throw ArgumentError.value(ability, 'ability', 'Unbekanntes Attribut');
    }
    if (!available(hero, feature)) {
      throw StateError(
        'Klassenmerkmal oder Nutzung für diesen Wiederholungswurf fehlt.',
      );
    }
    final savedRule = CharacterRuleEngine.savingThrow(hero, ability);
    if (savedRule.automaticallyFails) {
      throw StateError(
        'Dieser Rettungswurf misslingt durch den Zustand automatisch und kann nicht wiederholt werden.',
      );
    }
    final fighterBonus = feature == SavingThrowRerollFeature.indomitable
        ? ClassResourceRules.level(hero, 'Kämpfer')
        : 0;
    final resource = feature == SavingThrowRerollFeature.indomitable
        ? 'indomitable'
        : 'focusPoints';
    final spentHero = ClassResourceRules.spend(hero, resource);
    final newRoll = dice.check(
      modifier: savedRule.modifier + fighterBonus,
      advantage: savedRule.advantage,
      disadvantage: savedRule.disadvantage,
    );
    return SavingThrowRerollResult(
      hero: spentHero,
      roll: newRoll,
      passed: newRoll.total >= difficulty,
      fighterLevelBonus: fighterBonus,
      resource: resource,
    );
  }
}

class SavingThrowRerollResult {
  const SavingThrowRerollResult({
    required this.hero,
    required this.roll,
    required this.passed,
    required this.fighterLevelBonus,
    required this.resource,
  });
  final HeroCharacter hero;
  final DiceResult roll;
  final bool passed;
  final int fighterLevelBonus;
  final String resource;
}
