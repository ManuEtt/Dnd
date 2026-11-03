import 'character_rule_engine.dart';
import 'class_resource_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'srd_character_classes.dart';

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
    // This read-only query also supplies suggestions after an ordinary save.
    // An unconfirmed historical profile must hide the feature, not throw after
    // the caller has already rolled that separate, ordinary saving throw.
    try {
      _validateProfile(hero);
    } on FormatException {
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
    int extraModifier = 0,
  }) {
    if (!const {0, 2, 5}.contains(extraModifier)) {
      throw const FormatException('Unzulässiger situativer Rettungswurfbonus.');
    }
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
    _validateProfile(hero);
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
      modifier: savedRule.modifier + fighterBonus + extraModifier,
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

  /// Validate this explicit class reroll before deriving bonuses or spending.
  /// Keep old profiles readable; never repair classes or saved training here.
  /// The existing resolver accepts aliases and the existing rule engine remains
  /// the sole source of modifier arithmetic (SRD 5.2.1 pp. 48 and 52).
  static void _validateProfile(HeroCharacter hero) {
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
        proficiencies.any(
          (ability) => !const {
            'strength',
            'dexterity',
            'constitution',
            'intelligence',
            'wisdom',
            'charisma',
          }.contains(ability),
        )) {
      throw const FormatException(
        'Die bestätigten Rettungswurf-Übungen sind nicht eindeutig.',
      );
    }
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
