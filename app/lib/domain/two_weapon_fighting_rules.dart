import 'condition_rules.dart';
import 'class_resource_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_equipment_catalog.dart';

/// SRD 5.2.1, Light (p.89): two different Light weapons enable an extra
/// Bonus Action attack regardless of class. This increment covers melee only;
/// ranged Light weapons and Nick/Dual Wielder need their own action rules.
class TwoWeaponFightingRules {
  const TwoWeaponFightingRules._();

  static bool getStyle(HeroCharacter hero) =>
      ClassResourceRules.level(hero, 'Kämpfer') >= 1 &&
      hero.features.contains('Kampfstil: Kampf mit zwei Waffen');

  static EquipmentEntry? _lightWeapon(InventoryItem item) {
    if (item.quantity < 1) return null;
    final entry = SrdEquipmentCatalog.byId(item.catalogId);
    if (entry == null ||
        !entry.hasProperty('light') ||
        (entry.category != EquipmentCategory.simpleMelee &&
            entry.category != EquipmentCategory.martialMelee)) {
      return null;
    }
    return entry;
  }

  static bool eligiblePrimary(HeroCharacter hero) {
    if (hero.equippedShieldId.isNotEmpty) return false;
    final primary = hero.inventory.where(
      (item) => item.id == hero.equippedWeaponId && item.quantity > 0,
    );
    return hero.equippedWeaponId.isNotEmpty &&
        primary.length == 1 &&
        _lightWeapon(primary.single) != null;
  }

  static List<InventoryItem> offhandChoices(HeroCharacter hero) {
    if (!eligiblePrimary(hero)) return const [];
    final candidates = hero.inventory
        .where(
          (item) =>
              item.id != hero.equippedWeaponId && _lightWeapon(item) != null,
        )
        .toList();
    return candidates
        .where(
          (item) =>
              candidates.where((other) => other.id == item.id).length == 1,
        )
        .toList();
  }

  static EquipmentEntry? confirmedOffhand(HeroCharacter hero, String itemId) {
    final selected = offhandChoices(hero).where((item) => item.id == itemId);
    return selected.length == 1 ? _lightWeapon(selected.single) : null;
  }

  /// The extra attack is available only after the confirmed Attack action,
  /// while the hero still owns the turn and has a free Bonus Action.
  static bool canPrepare(Campaign campaign) {
    final fight = campaign.encounter;
    final hero = campaign.hero;
    return campaign.pendingRoll == null &&
        campaign.pendingDeathSave == null &&
        campaign.pendingEnemyShieldHit == null &&
        fight != null &&
        !fight.isFinished &&
        fight.activeParticipant == 'hero' &&
        fight.actionUsed &&
        fight.attacksRemaining == 0 &&
        !fight.bonusActionUsed &&
        fight.lightAttackAvailable &&
        !fight.surgeReserved &&
        hero.hitPoints != null &&
        hero.hitPoints! > 0 &&
        !hero.isDead &&
        ConditionRules.canTakeActions(hero) &&
        offhandChoices(hero).isNotEmpty;
  }

  static String ability(
    HeroCharacter hero,
    EquipmentEntry weapon, {
    String? attackAbility,
  }) {
    final selected =
        attackAbility ??
        (weapon.hasProperty('finesse') && hero.weaponAbility == 'dexterity'
            ? 'dexterity'
            : 'strength');
    if ((selected != 'strength' && selected != 'dexterity') ||
        (selected == 'dexterity' && !weapon.hasProperty('finesse')) ||
        hero.abilities[selected] == null) {
      throw const FormatException(
        'Das Nebenhand-Attribut muss bekannt und für diese Waffe zulässig sein.',
      );
    }
    return selected;
  }

  static int abilityModifier(
    HeroCharacter hero,
    EquipmentEntry weapon, {
    String? attackAbility,
  }) {
    final selected = ability(hero, weapon, attackAbility: attackAbility);
    return RulesEngine.abilityModifier(hero.abilities[selected]!);
  }

  static int attackBonus(
    HeroCharacter hero,
    EquipmentEntry weapon, {
    String? attackAbility,
    bool? proficient,
  }) {
    // The old path supported only Fighters, whose confirmed class grants all
    // weapon proficiencies. Other characters must confirm this weapon's own
    // proficiency instead of borrowing the primary weapon's flag.
    if (proficient == null && ClassResourceRules.level(hero, 'Kämpfer') < 1) {
      throw const FormatException(
        'Die Übung mit dieser Nebenhandwaffe muss bestätigt sein.',
      );
    }
    return abilityModifier(hero, weapon, attackAbility: attackAbility) +
        ((proficient ?? true) ? RulesEngine.proficiencyBonus(hero.level) : 0) +
        ExhaustionRules.d20Modifier(hero);
  }

  /// Light omits positive ability damage by default but always applies a
  /// negative modifier. The confirmed Fighting Style (SRD p.88) adds it once.
  static int damageModifier(
    HeroCharacter hero,
    EquipmentEntry weapon, {
    String? attackAbility,
  }) {
    final modifier = abilityModifier(
      hero,
      weapon,
      attackAbility: attackAbility,
    );
    return getStyle(hero) || modifier < 0 ? modifier : 0;
  }

  static int damage(
    HeroCharacter hero,
    EquipmentEntry weapon,
    int diceTotal, {
    String? attackAbility,
  }) {
    final result =
        diceTotal + damageModifier(hero, weapon, attackAbility: attackAbility);
    return result < 0 ? 0 : result;
  }
}
