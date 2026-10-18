import 'condition_rules.dart';
import 'class_resource_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_equipment_catalog.dart';

/// SRD 5.2.1: a confirmed Fighter style and two different Light melee weapons.
/// Nick/Dual Wielder and other classes are deliberately not enabled yet.
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
    if (!getStyle(hero) || hero.equippedShieldId.isNotEmpty) return false;
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

  static String ability(HeroCharacter hero, EquipmentEntry weapon) =>
      weapon.hasProperty('finesse') && hero.weaponAbility == 'dexterity'
      ? 'dexterity'
      : 'strength';

  static int abilityModifier(HeroCharacter hero, EquipmentEntry weapon) {
    final score = hero.abilities[ability(hero, weapon)];
    if (score == null) throw StateError('Nebenhand-Attribut fehlt.');
    return RulesEngine.abilityModifier(score);
  }

  static int attackBonus(HeroCharacter hero, EquipmentEntry weapon) =>
      abilityModifier(hero, weapon) +
      RulesEngine.proficiencyBonus(hero.level) +
      ExhaustionRules.d20Modifier(hero);

  static int damage(HeroCharacter hero, EquipmentEntry weapon, int diceTotal) {
    final result = diceTotal + abilityModifier(hero, weapon);
    return result < 0 ? 0 : result;
  }
}
