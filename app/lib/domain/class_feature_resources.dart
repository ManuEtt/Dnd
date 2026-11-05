import 'dice_engine.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 fighter resources. No class features are granted from story text.
/// Fighter *class* level (not total level) determines both pools.
class ClassFeatureResources {
  const ClassFeatureResources._();

  /// Direct and legacy snapshots must not grant resources from duplicate,
  /// unknown or inconsistent class levels. The class alias is canonicalized
  /// before comparing both sides of a multiclass profile.
  static int fighterLevel(HeroCharacter hero) {
    if (hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        hero.secondaryClassLevel < 0) {
      return 0;
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
      return 0;
    }
    return (primary == 'Kämpfer' ? hero.primaryClassLevel : 0) +
        (secondary == 'Kämpfer' ? hero.secondaryClassLevel : 0);
  }

  static int secondWindMaximum(HeroCharacter hero) {
    final level = fighterLevel(hero);
    if (level == 0) return 0;
    if (level < 4) return 2;
    if (level < 10) return 3;
    return 4;
  }

  static int actionSurgeMaximum(HeroCharacter hero) {
    final level = fighterLevel(hero);
    if (level < 2) return 0;
    return level >= 17 ? 2 : 1;
  }

  /// Fail closed for malformed or forged resource counts, including imports.
  static void validate(HeroCharacter hero) {
    final wind = secondWindMaximum(hero);
    final surge = actionSurgeMaximum(hero);
    if (hero.spentSecondWind < 0 ||
        hero.spentSecondWind > wind ||
        hero.spentActionSurge < 0 ||
        hero.spentActionSurge > surge) {
      throw const FormatException('Ungültiger Klassenressourcenverbrauch.');
    }
  }

  static int remainingSecondWind(HeroCharacter hero) {
    validate(hero);
    return secondWindMaximum(hero) - hero.spentSecondWind;
  }

  static int remainingActionSurge(HeroCharacter hero) {
    validate(hero);
    return actionSurgeMaximum(hero) - hero.spentActionSurge;
  }

  /// This must be triggered by a confirmed Bonus Action. The GameEngine
  /// tracks per-turn Bonus Action expenditure separately from the resource.
  static SecondWindResult useSecondWind(HeroCharacter hero, DiceEngine dice) {
    if (fighterLevel(hero) < 1) {
      throw StateError('Second Wind erfordert mindestens eine Kämpferstufe.');
    }
    if (!ConditionRules.canTakeActions(hero) ||
        hero.hitPoints == null ||
        hero.hitPoints! < 1 ||
        hero.maxHitPoints == null) {
      throw StateError('Second Wind benötigt einen handlungsfähigen Helden.');
    }
    if (remainingSecondWind(hero) == 0) {
      throw StateError('Second Wind hat keine Nutzung mehr.');
    }
    final roll = dice.roll('1d10');
    final total = roll.total + fighterLevel(hero);
    final next = RulesEngine.heal(
      hero,
      total,
    ).copyWith(spentSecondWind: hero.spentSecondWind + 1);
    return SecondWindResult(
      next,
      roll,
      total,
      next.hitPoints! - hero.hitPoints!,
    );
  }

  /// Reserve one extra non-Magic action in a turn. The actual action is
  /// validated separately by the combat turn machine, never by free text.
  static HeroCharacter spendActionSurge(HeroCharacter hero) {
    if (fighterLevel(hero) < 2) {
      throw StateError('Action Surge erfordert Kämpferstufe 2.');
    }
    if (!ConditionRules.canTakeActions(hero) || hero.hitPoints == 0) {
      throw StateError(
        'Ein kampfunfähiger Held kann Action Surge nicht nutzen.',
      );
    }
    if (remainingActionSurge(hero) == 0) {
      throw StateError('Action Surge hat keine Nutzung mehr.');
    }
    return hero.copyWith(spentActionSurge: hero.spentActionSurge + 1);
  }

  /// 2024: Short Rest restores one Second Wind, all Action Surge uses.
  static HeroCharacter afterShortRest(HeroCharacter hero) {
    validate(hero);
    return hero.copyWith(
      spentSecondWind: hero.spentSecondWind > 0 ? hero.spentSecondWind - 1 : 0,
      spentActionSurge: 0,
    );
  }

  static HeroCharacter afterLongRest(HeroCharacter hero) {
    validate(hero);
    return hero.copyWith(spentSecondWind: 0, spentActionSurge: 0);
  }
}

class SecondWindResult {
  const SecondWindResult(
    this.hero,
    this.roll,
    this.totalHealing,
    this.hitPointsRestored,
  );
  final HeroCharacter hero;
  final DiceResult roll;
  final int totalHealing;
  final int hitPointsRestored;
}
