import 'cover_rules.dart';
import 'damage_rules.dart';
import 'dice_engine.dart';
import 'rules_engine.dart';

/// Only a confirmed single non-spell weapon attack from a manually
/// controlled additional creature against ANOTHER HP-tracked creature.
/// No guessed statblocks, ranges, positions, reactions, or extra attacks.
class ConfirmedExtraCreatureAttack {
  const ConfirmedExtraCreatureAttack({
    required this.attackBonus,
    required this.weaponDamage,
    required this.damageType,
    required this.targetArmorClass,
    required this.targetCover,
    required this.coverOppositeAttacker,
    required this.targetInReachConfirmed,
    required this.attackerCanActConfirmed,
    required this.targetCanBeAttackedConfirmed,
    required this.noUnmodelledAttackModifiersConfirmed,
    required this.noUnmodelledDamageAdjustmentsConfirmed,
    required this.noTargetReactionConfirmed,
    required this.noAdditionalAttackEffectsConfirmed,
    this.advantage = false,
    this.disadvantage = false,
  });

  final int attackBonus, targetArmorClass;
  final String weaponDamage;
  final DamageType damageType;
  final CoverLevel targetCover;
  final bool coverOppositeAttacker;
  final bool targetInReachConfirmed, attackerCanActConfirmed;
  final bool targetCanBeAttackedConfirmed;
  final bool noUnmodelledAttackModifiersConfirmed;
  final bool noUnmodelledDamageAdjustmentsConfirmed;
  final bool noTargetReactionConfirmed, noAdditionalAttackEffectsConfirmed;
  final bool advantage, disadvantage;
}

class ExtraCreatureAttackResult {
  const ExtraCreatureAttackResult({
    required this.attackRoll,
    required this.hit,
    required this.critical,
    required this.effectiveArmorClass,
    required this.damageRoll,
    required this.criticalExtraRoll,
    required this.damage,
  });

  final DiceResult attackRoll;
  final bool hit, critical;
  final int effectiveArmorClass, damage;
  final DiceResult? damageRoll, criticalExtraRoll;
}

/// SRD 5.2.1 attack roll, natural-1/20, critical extra dice,
/// advantage/disadvantage cancellation, and explicit cover.
class SrdExtraCreatureAttackRules {
  const SrdExtraCreatureAttackRules._();

  static final _damagePattern = RegExp(
    r'^([1-9][0-9]?)[dDwW](4|6|8|10|12)([+-][0-9]{1,2})?$',
  );

  static ExtraCreatureAttackResult resolve(
    DiceEngine dice,
    ConfirmedExtraCreatureAttack input,
  ) {
    final match = _damagePattern.firstMatch(input.weaponDamage.trim());
    if (match == null ||
        int.parse(match.group(1)!) > 10 ||
        input.attackBonus < -30 ||
        input.attackBonus > 30 ||
        input.targetArmorClass < 1 ||
        input.targetArmorClass > 95 ||
        !input.targetInReachConfirmed ||
        !input.attackerCanActConfirmed ||
        !input.targetCanBeAttackedConfirmed ||
        !input.noUnmodelledAttackModifiersConfirmed ||
        !input.noUnmodelledDamageAdjustmentsConfirmed ||
        !input.noTargetReactionConfirmed ||
        !input.noAdditionalAttackEffectsConfirmed ||
        input.targetCover == CoverLevel.total) {
      throw const FormatException(
        'Angriff nur mit bestätigtem vollständigem Trefferbonus, '
        'Waffenschaden, Ziel-RK, Reichweite, Deckung und '
        'geprüften Fähigkeiten/Reaktionen.',
      );
    }
    final cover = input.coverOppositeAttacker
        ? CoverRules.getBonus(input.targetCover)
        : 0;
    if (input.targetArmorClass + cover > 100) {
      throw const FormatException('Ungültige Ziel-RK einschließlich Deckung.');
    }
    final effectiveAc = input.targetArmorClass + cover;
    // All eligibility validations happen before the first random draw.
    final attack = dice.check(
      modifier: input.attackBonus,
      advantage: input.advantage,
      disadvantage: input.disadvantage,
    );
    final outcome = RulesEngine.attack(roll: attack, armorClass: effectiveAc);
    if (!outcome.hit) {
      return ExtraCreatureAttackResult(
        attackRoll: attack,
        hit: false,
        critical: false,
        effectiveArmorClass: effectiveAc,
        damageRoll: null,
        criticalExtraRoll: null,
        damage: 0,
      );
    }
    final base = dice.roll(input.weaponDamage.trim());
    final extra = outcome.critical
        ? dice.roll('${match.group(1)}d${match.group(2)}')
        : null;
    final raw = base.total + (extra?.total ?? 0);
    final damage = DamageRules.resolve(
      [DamageComponent(input.damageType, raw < 0 ? 0 : raw)],
      defenses: DamageDefenses(),
    ).total;
    return ExtraCreatureAttackResult(
      attackRoll: attack,
      hit: true,
      critical: outcome.critical,
      effectiveArmorClass: effectiveAc,
      damageRoll: base,
      criticalExtraRoll: extra,
      damage: damage,
    );
  }
}
