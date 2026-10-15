import 'condition_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_equipment_catalog.dart';

/// Shared, read-only SRD 5.2.1 view of confirmed character mechanics.
/// No narration, UI, or remote service may directly change these values.
/// Situational benefits needing a target, source or distance are NOT inferred.
class D20Rule {
  const D20Rule(this.modifier, {this.advantage = false,
    this.disadvantage = false});
  final int modifier;
  final bool advantage;
  final bool disadvantage;
  bool get normalRoll => advantage == disadvantage;
  String get rollHint => normalRoll ? 'Normalwurf'
      : advantage ? 'Vorteil' : 'Nachteil';
}

class CharacterRuleEngine {
  const CharacterRuleEngine._();

  static int? attributeModifier(HeroCharacter hero, String ability) {
    final value = hero.abilities[ability];
    return value == null ? null : RulesEngine.abilityModifier(value);
  }

  static int? savingThrowBonus(HeroCharacter hero, String ability) {
    final mod = attributeModifier(hero, ability);
    if (mod == null) return null;
    return mod + (hero.savingThrowProficiencies.contains(ability)
        ? RulesEngine.proficiencyBonus(hero.level) : 0) +
        ExhaustionRules.d20Modifier(hero);
  }

  static D20Rule savingThrow(HeroCharacter hero, String ability) {
    final bonus = savingThrowBonus(hero, ability);
    if (bonus == null) throw StateError('Das Attribut $ability ist nicht bestätigt.');
    final untrainedArmor = _untrainedArmor(hero);
    return D20Rule(bonus,
      disadvantage: (untrainedArmor && (ability == 'strength' || ability == 'dexterity')) ||
          (ability == 'dexterity' && ConditionRules.has(hero, 'festgesetzt')));
  }

  static D20Rule abilityCheck(HeroCharacter hero, String ability,
      {bool proficient = false, bool stealth = false}) {
    final mod = attributeModifier(hero, ability);
    if (mod == null) throw StateError('Das Attribut $ability ist nicht bestätigt.');
    return D20Rule(mod + (proficient ? RulesEngine.proficiencyBonus(hero.level) : 0)
        + ExhaustionRules.d20Modifier(hero),
      disadvantage: ConditionRules.has(hero, 'vergiftet') ||
        (_untrainedArmor(hero) && (ability == 'strength' || ability == 'dexterity')) ||
        (stealth && _stealthDisadvantage(hero)));
  }

  static D20Rule perception(HeroCharacter hero) => abilityCheck(hero, 'wisdom',
      proficient: hero.skills.contains('Wahrnehmung'));

  static D20Rule initiative(HeroCharacter hero) {
    if (hero.isDead || hero.hitPoints == 0) {
      throw StateError('Ein bewusstloser oder toter Held würfelt keine Initiative.');
    }
    return D20Rule(RulesEngine.initiativeBonus(hero),
      advantage: ConditionRules.has(hero, 'unsichtbar'),
      disadvantage: !ConditionRules.canTakeActions(hero) ||
          ConditionRules.has(hero, 'vergiftet') || _untrainedArmor(hero));
  }

  static D20Rule attack(HeroCharacter hero) {
    if (!ConditionRules.canTakeActions(hero)) {
      throw StateError('Dieser Zustand verhindert einen Angriff.');
    }
    var heavyDisadvantage = false;
    final equipped = hero.inventory.where((e) =>
        e.id == hero.equippedWeaponId && hero.equippedWeaponId.isNotEmpty);
    if (equipped.length == 1) {
      final weapon = SrdEquipmentCatalog.byId(equipped.single.catalogId);
      if (weapon != null && weapon.hasProperty('heavy')) {
        final ranged = weapon.category == EquipmentCategory.simpleRanged ||
            weapon.category == EquipmentCategory.martialRanged;
        final score = hero.abilities[ranged ? 'dexterity' : 'strength'];
        heavyDisadvantage = score == null || score < 13;
      }
    }
    return D20Rule(RulesEngine.attackBonus(hero),
      disadvantage: ConditionRules.hasUnconditionalAttackDisadvantage(hero) ||
          heavyDisadvantage || _untrainedArmor(hero));
  }

  /// The existing speed field uses meters. Exhaustion costs 1.5m/level,
  /// heavy armor Strength requirement costs 3m (10 feet). Neither changes
  /// the stored base speed. Round down only when whole-meter movement is asked.
  static double? speedMeters(HeroCharacter hero) {
    final base = ExhaustionRules.effectiveSpeedMeters(hero);
    if (base == null) return null;
    if (!ConditionRules.canMove(hero)) return 0;
    var penaltyMeters = 0;
    if (hero.equippedArmorId.isNotEmpty) {
      final armor = hero.inventory.where((i) => i.id == hero.equippedArmorId);
      if (armor.length == 1) {
        final item = SrdEquipmentCatalog.byId(armor.single.catalogId);
        if (item?.strengthMin != null &&
            (hero.abilities['strength'] ?? 0) < item!.strengthMin!) {
          penaltyMeters = 3;
        }
      }
    }
    return (base - penaltyMeters).clamp(0, 1000).toDouble();
  }

  static int? movementWholeMeters(HeroCharacter hero) =>
      speedMeters(hero)?.floor();

  /// Other optional equipment effects are left explicit, never invented.
  static bool _untrainedArmor(HeroCharacter hero) =>
      (hero.equippedArmorId.isNotEmpty && !hero.equippedArmorTrained) ||
      (hero.equippedShieldId.isNotEmpty && !hero.equippedShieldTrained);

  static bool _stealthDisadvantage(HeroCharacter hero) {
    final equipped = hero.inventory.where((i) =>
        i.id == hero.equippedArmorId && hero.equippedArmorId.isNotEmpty);
    if (equipped.length != 1) return false;
    return SrdEquipmentCatalog.byId(equipped.single.catalogId)
        ?.stealthDisadvantage ?? false;
  }
}
