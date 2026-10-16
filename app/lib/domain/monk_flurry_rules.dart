import 'class_combat_features.dart';
import 'class_resource_rules.dart';
import 'combat_class_actions.dart';
import 'condition_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';

/// SRD 5.2.1 Monk's Focus: Flurry of Blows is independent of the Attack action.
/// Each Unarmed Strike has its own D20 test and damage roll. An unconfirmed
/// target state or ally position must not affect an attack roll.
class FlurryStrike {
  const FlurryStrike({required this.attack, required this.hit,
      required this.critical, required this.damage,
      required this.enemyHitPoints, this.damageRoll, this.criticalExtra});

  final DiceResult attack;
  final DiceResult? damageRoll, criticalExtra;
  final bool hit, critical;
  final int damage, enemyHitPoints;

  Map<String, dynamic> toJson() => {
    'attack': attack.toJson(),
    'damageType': 'bludgeoning',
    'hit': hit,
    'critical': critical,
    'damage': damage,
    'enemyHitPoints': enemyHitPoints,
    if (damageRoll != null) 'damageRoll': damageRoll!.toJson(),
    if (criticalExtra != null) 'criticalExtra': criticalExtra!.toJson(),
  };
}

class FlurryResult {
  const FlurryResult({required this.hero, required this.encounter,
      required this.strikes, required this.damageTotal});
  final HeroCharacter hero;
  final Encounter encounter;
  final List<FlurryStrike> strikes;
  final int damageTotal;
}

class MonkFlurryRules {
  const MonkFlurryRules._();

  static int strikeCount(HeroCharacter hero) {
    final level = ClassResourceRules.level(hero, 'Mönch');
    if (level < 2) {
      return 0;
    }
    return level >= 10 ? 3 : 2;
  }

  static bool canUse(HeroCharacter hero, Encounter encounter) =>
      strikeCount(hero) > 0 && !hero.isDead &&
      ConditionRules.canTakeActions(hero) &&
      !encounter.isFinished && encounter.activeParticipant == 'hero' &&
      !encounter.bonusActionUsed &&
      ClassResourceRules.remaining(hero, 'focusPoints') >= 1 &&
      hero.equippedArmorId.isEmpty && hero.equippedShieldId.isEmpty &&
      (hero.abilities['strength'] != null ||
          hero.abilities['dexterity'] != null);

  /// In this combat model a Monk uses Martial Arts while unarmored and without
  /// a shield. Armored Unarmed Strikes and Grapple/Shove choices need separate
  /// confirmation and are deliberately not estimated here.
  static FlurryResult use(HeroCharacter hero, Encounter encounter,
      DiceEngine dice) {
    if (strikeCount(hero) == 0) {
      throw StateError('Schlaghagel ist erst ab Mönchsstufe 2 möglich.');
    }
    if (encounter.isFinished || encounter.activeParticipant != 'hero' ||
        !ConditionRules.canTakeActions(hero)) {
      throw StateError('In diesem Zustand ist Schlaghagel nicht möglich.');
    }
    if (encounter.bonusActionUsed) {
      throw StateError('Deine Bonusaktion ist bereits verbraucht.');
    }
    if (hero.equippedArmorId.isNotEmpty || hero.equippedShieldId.isNotEmpty) {
      throw StateError('Die automatische Kampfkunst setzt keine Rüstung und keinen Schild voraus.');
    }
    final strength = hero.abilities['strength'];
    final dexterity = hero.abilities['dexterity'];
    if (strength == null && dexterity == null) {
      throw StateError('Bitte Stärke oder Geschicklichkeit bestätigen.');
    }
    // Martial Arts permits Dexterity instead of Strength. Use the larger
    // confirmed modifier for this automatic roll, never a missing score.
    final useStrength = strength != null &&
        (dexterity == null || strength >= dexterity);
    final score = useStrength ? strength! : dexterity;
    final modifier = RulesEngine.abilityModifier(score);
    final attackBonus = modifier + RulesEngine.proficiencyBonus(hero.level) +
        ExhaustionRules.d20Modifier(hero);
    final sides = ClassResourceRules.martialArtsDie(
        ClassResourceRules.level(hero, 'Mönch'));
    final updatedHero = ClassResourceRules.spend(hero, 'focusPoints');
    var updatedEncounter = encounter.copyWith(bonusActionUsed: true);
    final strikes = <FlurryStrike>[];
    var damageTotal = 0;
    final count = strikeCount(hero);
    for (var i = 0; i < count && !updatedEncounter.isFinished; i++) {
      final roll = dice.check(modifier: attackBonus,
          disadvantage: ConditionRules.hasUnconditionalAttackDisadvantage(hero));
      final outcome = RulesEngine.attack(roll: roll,
          armorClass: updatedEncounter.enemyArmorClass,
          criticalThreshold: ClassCombatFeatures.weaponCriticalThreshold(hero));
      var damage = 0;
      DiceResult? damageRoll;
      DiceResult? criticalExtra;
      if (outcome.hit) {
        damageRoll = dice.roll('1d$sides');
        if (outcome.critical) {
          criticalExtra = dice.roll('1d$sides');
        }
        final rageBonus = useStrength && CombatClassActions.rageActive(updatedEncounter)
            ? ClassResourceRules.rageDamageBonus(
                ClassResourceRules.level(hero, 'Barbar')) : 0;
        damage = (damageRoll.total + (criticalExtra?.total ?? 0) +
            modifier + rageBonus).clamp(0, 100000).toInt();
        damageTotal += damage;
        updatedEncounter = updatedEncounter.copyWith(
            enemyHitPoints: RulesEngine.remainingHitPoints(
                hitPoints: updatedEncounter.enemyHitPoints, damage: damage));
      }
      updatedEncounter = CombatClassActions.onAttackRoll(updatedEncounter);
      strikes.add(FlurryStrike(attack: roll, hit: outcome.hit,
          critical: outcome.critical, damage: damage,
          damageRoll: damageRoll, criticalExtra: criticalExtra,
          enemyHitPoints: updatedEncounter.enemyHitPoints));
    }
    return FlurryResult(hero: updatedHero, encounter: updatedEncounter,
        strikes: List.unmodifiable(strikes), damageTotal: damageTotal);
  }
}
