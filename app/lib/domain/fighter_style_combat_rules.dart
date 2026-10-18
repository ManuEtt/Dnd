import 'class_resource_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'srd_equipment_catalog.dart';

/// Deterministic SRD 5.2.1 Fighting Style effects used by the live combat
/// rules. The choice must be explicitly saved on a Fighter's character sheet.
/// The confirmed two-weapon extra attack is implemented separately.
class FighterStyleCombatRules {
  const FighterStyleCombatRules._();

  static bool _hasStyle(HeroCharacter hero, String label) =>
      ClassResourceRules.level(hero, 'Kämpfer') >= 1 &&
      hero.features.contains('Kampfstil: $label');

  /// Archery: +2 to attacks with a *ranged weapon*, not a thrown melee weapon.
  /// Returns zero if the style, class level or catalog weapon is unconfirmed.
  static int archeryBonus(HeroCharacter hero, EquipmentEntry? weapon) {
    if (!_hasStyle(hero, 'Bogenschießen') || weapon == null) return 0;
    return weapon.category == EquipmentCategory.simpleRanged ||
            weapon.category == EquipmentCategory.martialRanged
        ? 2
        : 0;
  }

  /// Defense: +1 AC while wearing light, medium or heavy armor. Merely having
  /// armor in the backpack or carrying a shield does not satisfy the rule.
  static int defenseBonus(HeroCharacter hero, EquipmentEntry? armor) {
    if (!_hasStyle(hero, 'Verteidigung') || armor == null) return 0;
    return armor.isArmor ? 1 : 0;
  }

  /// SRD 5.2.1: each 1 or 2 on a two-handed melee weapon's damage dice
  /// counts as 3. Critical weapon damage dice receive the same treatment.
  /// Additional damage sources such as Sneak Attack are never modified.
  static int greatWeaponDamageBonus(HeroCharacter hero, DiceResult damageRoll) {
    if (!_hasStyle(hero, 'Kampf mit großen Waffen') ||
        hero.equippedShieldId.isNotEmpty) {
      return 0;
    }
    final weapon = equippedWeapon(hero);
    if (weapon == null ||
        (weapon.category != EquipmentCategory.simpleMelee &&
            weapon.category != EquipmentCategory.martialMelee) ||
        weapon.hasProperty('thrown')) {
      return 0;
    }
    String? expected;
    if (weapon.hasProperty('two-handed')) {
      expected = weapon.damage;
    } else if (weapon.hasProperty('versatile')) {
      expected = weapon.twoHandDamage;
    }
    if (expected == null ||
        _dice(hero.weaponDamage) != _dice(expected) ||
        _dice(damageRoll.expression) != _dice(expected)) {
      return 0;
    }
    return damageRoll.rolls.fold<int>(
      0,
      (bonus, die) => bonus + (die < 3 ? 3 - die : 0),
    );
  }

  static String _dice(String value) =>
      value.toLowerCase().replaceAll('w', 'd').replaceAll(' ', '');

  /// Resolve only one *unique* equipped inventory instance, with a confirmed
  /// catalog reference. Names and free-text fields never grant bonuses.
  static EquipmentEntry? equippedWeapon(HeroCharacter hero) {
    if (hero.equippedWeaponId.isEmpty) return null;
    final matches = hero.inventory.where(
      (item) => item.id == hero.equippedWeaponId && item.quantity > 0,
    );
    if (matches.length != 1) return null;
    final catalog = SrdEquipmentCatalog.byId(matches.single.catalogId);
    return catalog?.isWeapon == true ? catalog : null;
  }
}
