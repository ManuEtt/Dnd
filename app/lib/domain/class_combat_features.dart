import 'dice_engine.dart';
import 'models.dart';
import 'class_resource_rules.dart';
import 'srd_class_feature_catalog.dart';
import 'srd_equipment_catalog.dart';

/// Fully deterministic feature helpers. Context that has not been confirmed
/// (allied positions, turn ownership, target states) must be passed explicitly.
class ClassCombatFeatures {
  const ClassCombatFeatures._();

  /// Only weapon / unarmed attack rolls qualify for Champion Improved Critical.
  /// Spell attack rolls must continue using the default natural-20 threshold.
  static int weaponCriticalThreshold(HeroCharacter hero) {
    final features = SrdClassFeatureCatalog.unlocked(hero);
    if (features.any((f) => f.name == 'Superior Critical')) return 18;
    if (features.any((f) => f.name == 'Improved Critical')) return 19;
    return 20;
  }

  /// SRD 5.2.1, Rogue Sneak Attack: finesse or ranged weapon, once
  /// per turn; advantage OR an ally within 5 feet OF THE TARGET who lacks
  /// the Incapacitated condition. No disadvantage for the ally alternative.
  /// Both ally facts must be confirmed independently. Conscious alone is
  /// insufficient: an ally can be conscious but Stunned/Incapacitated.
  /// Still requires a separately confirmed hit and turn-use guard.
  static int eligibleSneakAttackDice(
    HeroCharacter hero, {
    required bool hasAdvantage,
    required bool hasDisadvantage,
    required bool adjacentConsciousAlly,
    bool allyWithinFiveFeetOfTargetConfirmed = false,
    bool allyNotIncapacitatedConfirmed = false,
    required bool alreadyUsedThisTurn,
  }) {
    final level = ClassResourceRules.level(hero, 'Schurke');
    if (level == 0 || alreadyUsedThisTurn) return 0;
    final items = hero.inventory.where(
      (i) => i.id == hero.equippedWeaponId && hero.equippedWeaponId.isNotEmpty,
    );
    if (items.length != 1) return 0;
    final weapon = SrdEquipmentCatalog.byId(items.single.catalogId);
    if (weapon == null) return 0;
    final qualifies =
        weapon.hasProperty('finesse') ||
        weapon.category == EquipmentCategory.simpleRanged ||
        weapon.category == EquipmentCategory.martialRanged;
    if (!qualifies) return 0;
    // Equal sources cancel: when both exist, the final roll has neither.
    final effectiveDisadvantage = hasDisadvantage && !hasAdvantage;
    final advantage = hasAdvantage && !hasDisadvantage;
    final ally =
        adjacentConsciousAlly &&
        allyWithinFiveFeetOfTargetConfirmed &&
        allyNotIncapacitatedConfirmed &&
        !effectiveDisadvantage;
    return (advantage || ally) ? ClassResourceRules.sneakAttackDice(level) : 0;
  }

  /// Use after verifying the target, hit, once-per-turn state, and eligibility.
  /// Critical hits double the number of rolled damage dice.
  static DiceResult rollSneakAttack(
    DiceEngine dice,
    int diceCount, {
    bool critical = false,
  }) {
    if (diceCount < 1 || diceCount > 10) {
      throw RangeError.range(diceCount, 1, 10, 'sneakAttackDice');
    }
    return dice.roll('${diceCount * (critical ? 2 : 1)}d6');
  }
}
