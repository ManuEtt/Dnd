import 'class_resource_rules.dart';
import 'models.dart';
import 'srd_equipment_catalog.dart';

/// Two deterministic SRD 5.2.1 Fighting Style effects used by the live combat
/// rules. The choice must be explicitly saved on a Fighter's character sheet.
/// Other styles remain selectable but are not silently treated as implemented.
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
