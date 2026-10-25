import 'models.dart';
import 'class_resource_rules.dart';
import 'damage_rules.dart';
import 'srd_equipment_catalog.dart';

/// SRD 5.2.1 – conservative combat effects requiring an explicit combat state.
/// The current enemy model does not confirm damage types, positions or allies.
class CombatClassActions {
  const CombatClassActions._();

  static bool rageActive(Encounter fight) =>
      fight.rageUntilRound > 0 && fight.rageUntilRound >= fight.round;

  static bool hasHeavyArmor(HeroCharacter hero) {
    if (hero.equippedArmorId.isEmpty) return false;
    final items = hero.inventory.where((i) => i.id == hero.equippedArmorId);
    if (items.length != 1) {
      throw StateError('Ausgerüstete Rüstung ist nicht eindeutig bestätigt.');
    }
    final armor = SrdEquipmentCatalog.byId(items.single.catalogId);
    if (armor == null) {
      throw StateError('Rüstung muss erst im SRD-Katalog bestätigt werden.');
    }
    return armor.category == EquipmentCategory.heavyArmor;
  }

  /// No Rage bonus on ranged or Dexterity attacks, and no invented weapons.
  static int rageDamageBonus(
    HeroCharacter hero,
    Encounter fight, {
    String? attackAbility,
    String? attackingWeaponId,
  }) {
    if (!rageActive(fight) ||
        (attackAbility ?? hero.weaponAbility) != 'strength' ||
        hasHeavyArmor(hero)) {
      return 0;
    }
    final weaponId = attackingWeaponId ?? hero.equippedWeaponId;
    final items = hero.inventory.where(
      (i) => i.id == weaponId && weaponId.isNotEmpty && i.quantity > 0,
    );
    if (items.length != 1) {
      return 0;
    }
    final weapon = SrdEquipmentCatalog.byId(items.single.catalogId);
    if (weapon == null ||
        !(weapon.category == EquipmentCategory.simpleMelee ||
            weapon.category == EquipmentCategory.martialMelee)) {
      return 0;
    }
    return ClassResourceRules.rageDamageBonus(
      ClassResourceRules.level(hero, 'Barbar'),
    );
  }

  /// Only known typed damage can be halved. Never invent enemy damage types.
  static int effectiveIncomingDamage(
    Encounter fight,
    HeroCharacter hero,
    int amount,
  ) {
    if (amount < 0) {
      throw RangeError.value(amount, 'damage');
    }
    if (!rageActive(fight) ||
        fight.enemyDamageType.isEmpty ||
        hasHeavyArmor(hero)) {
      return amount;
    }
    final kind = DamageType.values.byName(fight.enemyDamageType);
    final physical =
        kind == DamageType.bludgeoning ||
        kind == DamageType.piercing ||
        kind == DamageType.slashing;
    return DamageRules.resolve([
      DamageComponent(kind, amount),
    ], defenses: DamageDefenses(resistances: physical ? [kind] : [])).total;
  }

  /// Attack rolls extend Rage through the end of the following turn.
  /// A maximum of 100 rounds from first activation is preserved.
  static Encounter onAttackRoll(Encounter fight) {
    if (!rageActive(fight)) return fight;
    final until = fight.round + 1;
    final hardEnd = fight.rageStartedRound + 99;
    return fight.copyWith(rageUntilRound: until < hardEnd ? until : hardEnd);
  }

  /// Called exactly once at the end of the hero turn, before next round.
  static Encounter afterHeroTurn(Encounter fight) {
    if (!rageActive(fight) || fight.rageUntilRound > fight.round) return fight;
    return fight.copyWith(rageUntilRound: 0, rageStartedRound: 0);
  }
}
