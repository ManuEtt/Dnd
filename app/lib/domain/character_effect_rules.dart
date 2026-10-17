import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'combat_class_actions.dart';
import 'damage_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'spellcasting_rules.dart';

/// Executable effects on one confirmed character, shared by encounters and
/// explicitly entered external sources. No effect is inferred from narration.
/// SRD 5.2.1 pp. 17–18, 187: damage, temporary HP and Concentration.
class CharacterEffectRules {
  const CharacterEffectRules._();

  /// Combine only confirmed defenses. Repeated sources never stack. The
  /// Petrified condition grants resistance to all damage (SRD glossary), while
  /// Rage requires an active encounter and no heavy armor.
  static DamageDefenses defensesFor(
    HeroCharacter hero, {
    Encounter? encounter,
    DamageDefenses? declared,
  }) {
    final raging =
        encounter != null &&
        !encounter.isFinished &&
        hero.hitPoints != 0 &&
        ConditionRules.canTakeActions(hero) &&
        CombatClassActions.rageActive(encounter) &&
        !CombatClassActions.hasHeavyArmor(hero);
    return DamageDefenses(
      resistances: [
        ...?declared?.resistances,
        if (raging) ...[
          DamageType.bludgeoning,
          DamageType.piercing,
          DamageType.slashing,
        ],
      ],
      vulnerabilities: declared?.vulnerabilities ?? const [],
      immunities: declared?.immunities ?? const [],
      resistAll:
          (declared?.resistAll ?? false) ||
          ConditionRules.has(hero, 'versteinert'),
      vulnerableToAll: declared?.vulnerableToAll ?? false,
      immuneToAll: declared?.immuneToAll ?? false,
    );
  }

  static CharacterDamageResult damage(
    HeroCharacter hero, {
    required List<DamageComponent> components,
    required DamageDefenses defenses,
    required DiceEngine dice,
    bool critical = false,
  }) {
    final resolution = DamageRules.resolve(components, defenses: defenses);
    return _applyDamage(
      hero,
      amount: resolution.total,
      dice: dice,
      critical: critical,
      resolution: resolution,
    );
  }

  /// Legacy demo encounters have no verified damage type. Keep their amount
  /// explicit without assigning a made-up SRD damage type or resistance.
  static CharacterDamageResult untypedDamage(
    HeroCharacter hero, {
    required int amount,
    required DiceEngine dice,
    bool critical = false,
  }) {
    if (amount < 0 || amount > 100000) {
      throw RangeError.range(amount, 0, 100000, 'amount');
    }
    // Resistance to ALL damage is applicable even to an untyped legacy source.
    // A damage-type-specific resistance (such as Rage) cannot be inferred.
    final applied = ConditionRules.has(hero, 'versteinert')
        ? amount ~/ 2
        : amount;
    return _applyDamage(hero, amount: applied, dice: dice, critical: critical);
  }

  static CharacterDamageResult _applyDamage(
    HeroCharacter hero, {
    required int amount,
    required DiceEngine dice,
    required bool critical,
    DamageResolution? resolution,
  }) {
    var next = RulesEngine.damage(hero, amount, critical: critical);
    DiceResult? save;
    int? dc;
    final wasConcentrating = hero.concentratingOn.isNotEmpty;
    if (wasConcentrating) {
      if (next.isDead ||
          next.hitPoints == 0 ||
          !ConditionRules.canTakeActions(next)) {
        next = SpellcastingRules.endConcentration(next);
      } else if (amount > 0) {
        // Damage absorbed by temporary HP still requires a save. The DC uses
        // actual damage after defenses, before the temporary-HP buffer.
        final rule = CharacterRuleEngine.savingThrow(next, 'constitution');
        save = dice.check(
          modifier: rule.modifier,
          advantage: rule.advantage,
          disadvantage: rule.disadvantage,
        );
        final concentration = SpellcastingRules.saveAfterDamage(
          next,
          damage: amount,
          d20: save.natural!,
        );
        next = concentration.hero;
        dc = concentration.dc;
      }
    }
    return CharacterDamageResult(
      hero: next,
      damage: amount,
      resolution: resolution,
      temporaryHitPointsAbsorbed:
          hero.temporaryHitPoints - next.temporaryHitPoints,
      hitPointDamage: hero.hitPoints! - next.hitPoints!,
      concentrationSave: save,
      concentrationDc: dc,
      concentrationLost: wasConcentrating && next.concentratingOn.isEmpty,
    );
  }
}

class CharacterDamageResult {
  const CharacterDamageResult({
    required this.hero,
    required this.damage,
    required this.resolution,
    required this.temporaryHitPointsAbsorbed,
    required this.hitPointDamage,
    required this.concentrationSave,
    required this.concentrationDc,
    required this.concentrationLost,
  });

  final HeroCharacter hero;
  final int damage, temporaryHitPointsAbsorbed, hitPointDamage;
  final DamageResolution? resolution;
  final DiceResult? concentrationSave;
  final int? concentrationDc;
  final bool concentrationLost;

  Map<String, dynamic> toJson() => {
    'damage': damage,
    'temporaryHitPointsAbsorbed': temporaryHitPointsAbsorbed,
    'hitPointDamage': hitPointDamage,
    'remainingTemporaryHitPoints': hero.temporaryHitPoints,
    if (resolution != null)
      'components': [
        for (final part in resolution!.parts)
          {
            'type': part.type.name,
            'incoming': part.incoming,
            'applied': part.applied,
            'immune': part.immune,
            'resistant': part.resistant,
            'vulnerable': part.vulnerable,
          },
      ],
    if (concentrationSave != null) ...{
      'concentrationSave': concentrationSave!.toJson(),
      'concentrationDc': concentrationDc,
      'concentrationMaintained': !concentrationLost,
    },
    if (concentrationLost) 'concentrationLost': true,
  };
}
