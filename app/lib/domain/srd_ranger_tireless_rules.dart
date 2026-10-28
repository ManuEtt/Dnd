import 'condition_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 Ranger 10, Tireless — Short Rest and Magic action (CC BY 4.0).
/// Effects require confirmed rest completion or an explicit player command;
/// narrative prose never grants temporary HP or consumes class resources.
///
/// Source: https://www.dndbeyond.com/srd
class SrdRangerTirelessRules {
  const SrdRangerTirelessRules._();

  static const resourceKey = 'tirelessTemporaryHitPoints';

  /// A missing confirmed Wisdom score never grants fabricated uses.
  static int maximumTemporaryHitPointUses(HeroCharacter hero) {
    if (_rangerClassLevel(hero) < 10) return 0;
    final wisdom = hero.abilities['wisdom'];
    if (wisdom == null) return 0;
    final modifier = RulesEngine.abilityModifier(wisdom);
    return modifier < 1 ? 1 : modifier;
  }

  static int remainingTemporaryHitPointUses(HeroCharacter hero) {
    final maximum = maximumTemporaryHitPointUses(hero);
    final spent = hero.spentClassResources[resourceKey] ?? 0;
    if (spent < 0 || spent > maximum) {
      throw const FormatException('Ungültige Unermüdlich-Nutzungen.');
    }
    return maximum - spent;
  }

  /// The caller confirms Magic action economy. Every call spends one use.
  /// Temporary HP do not stack; explicit consent is needed to replace more.
  static SrdRangerTirelessMagicResult useTemporaryHitPoints(
    HeroCharacter hero,
    DiceEngine dice, {
    bool replaceExisting = false,
  }) {
    if (_rangerClassLevel(hero) < 10) {
      throw StateError('Unermüdlich erfordert Waldläufer-Klassenstufe 10.');
    }
    if (hero.abilities['wisdom'] == null) {
      throw StateError('Weisheit ist noch nicht bestätigt.');
    }
    if (hero.isDead ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.maxHitPoints == null ||
        hero.maxHitPoints! < hero.hitPoints! ||
        !ConditionRules.canTakeActions(hero)) {
      throw StateError('Dieser Charakter kann keine Magieaktion ausführen.');
    }
    final remaining = remainingTemporaryHitPointUses(hero);
    if (remaining < 1) {
      throw StateError('Alle Nutzungen von Unermüdlich sind verbraucht.');
    }
    final roll = dice.roll('1d8');
    final modifier = RulesEngine.abilityModifier(hero.abilities['wisdom']!);
    final total = roll.total + modifier;
    final granted = total < 1 ? 1 : total;
    final oldTemporaryHitPoints = hero.temporaryHitPoints;
    final spent = (hero.spentClassResources[resourceKey] ?? 0) + 1;
    final resources = <String, int>{
      ...hero.spentClassResources,
      resourceKey: spent,
    };
    final updated = RulesEngine.grantTemporaryHitPoints(
      hero.copyWith(spentClassResources: resources),
      granted,
      replaceExisting: replaceExisting,
    );
    return SrdRangerTirelessMagicResult(
      hero: updated,
      roll: roll,
      wisdomModifier: modifier,
      rolledTemporaryHitPoints: granted,
      previousTemporaryHitPoints: oldTemporaryHitPoints,
      usesRemaining: remaining - 1,
    );
  }


  static int _rangerClassLevel(HeroCharacter hero) {
    final primary = findSrdClass(hero.className)?.name == 'Waldläufer'
        ? hero.primaryClassLevel
        : 0;
    final secondary =
        hero.hasSecondClass &&
            findSrdClass(hero.secondaryClassName)?.name == 'Waldläufer'
        ? hero.secondaryClassLevel
        : 0;
    return primary + secondary;
  }

  /// Eligibility is tied to class levels, never total multiclass levels.
  static bool canReduceExhaustion(HeroCharacter hero) =>
      !hero.isDead &&
      hero.hitPoints != null &&
      hero.hitPoints! > 0 &&
      hero.maxHitPoints != null &&
      hero.maxHitPoints! >= hero.hitPoints! &&
      _rangerClassLevel(hero) >= 10 &&
      hero.exhaustionLevel > 0;

  /// Pure state transition; cannot be called by an AI narrative decision.
  /// Exactly one exhaustion level is removed per completed Short Rest.
  static HeroCharacter afterShortRest(HeroCharacter hero) {
    if (!canReduceExhaustion(hero)) return hero;
    return hero.copyWith(exhaustionLevel: hero.exhaustionLevel - 1);
  }
}

/// The rolled amount and actual resulting HP pool are both audit-visible.
class SrdRangerTirelessMagicResult {
  const SrdRangerTirelessMagicResult({
    required this.hero,
    required this.roll,
    required this.wisdomModifier,
    required this.rolledTemporaryHitPoints,
    required this.previousTemporaryHitPoints,
    required this.usesRemaining,
  });

  final HeroCharacter hero;
  final DiceResult roll;
  final int wisdomModifier;
  final int rolledTemporaryHitPoints;
  final int previousTemporaryHitPoints;
  final int usesRemaining;
}
