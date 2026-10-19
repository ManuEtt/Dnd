import 'condition_rules.dart';
import 'models.dart';
import 'class_resource_rules.dart';
import 'skill_check_passives.dart';
import 'srd_class_feature_catalog.dart';
import 'rules_engine.dart';
import 'srd_equipment_catalog.dart';

/// Shared, read-only SRD 5.2.1 view of confirmed character mechanics.
/// No narration, UI, or remote service may directly change these values.
/// Situational benefits needing a target, source or distance are NOT inferred.
class D20Rule {
  const D20Rule(
    this.modifier, {
    this.advantage = false,
    this.disadvantage = false,
    this.automaticallyFails = false,
    this.minimumNatural = 0,
  });
  final int modifier;

  /// Only for confirmed skill-based ability checks such as Rogue Reliable Talent.
  final int minimumNatural;
  final bool advantage;
  final bool disadvantage;

  /// A condition can determine the result without rolling. Keep the normal
  /// modifier for character-sheet display; callers must not consume dice.
  final bool automaticallyFails;
  bool get normalRoll => advantage == disadvantage;
  String get rollHint => automaticallyFails
      ? 'Automatisch misslungen'
      : normalRoll
      ? 'Normalwurf'
      : advantage
      ? 'Vorteil'
      : 'Nachteil';
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
    // SRD 5.2.1 Monk 14, Disciplined Survivor: proficiency in all saves.
    // This is a computed proficiency, not a mutation of the saved list.
    final proficient =
        hero.savingThrowProficiencies.contains(ability) ||
        ClassResourceRules.level(hero, 'Mönch') >= 14 ||
        (ClassResourceRules.level(hero, 'Schurke') >= 15 &&
            (ability == 'wisdom' || ability == 'charisma'));
    return mod +
        (proficient ? RulesEngine.proficiencyBonus(hero.level) : 0) +
        ExhaustionRules.d20Modifier(hero);
  }

  static D20Rule savingThrow(HeroCharacter hero, String ability) {
    final bonus = savingThrowBonus(hero, ability);
    if (bonus == null) {
      throw StateError('Das Attribut $ability ist nicht bestätigt.');
    }
    final untrainedArmor = _untrainedArmor(hero);
    return D20Rule(
      bonus,
      automaticallyFails: ConditionRules.hasAutomaticSavingThrowFailure(
        hero,
        ability,
      ),
      advantage:
          (ability == 'dexterity' &&
          ClassResourceRules.level(hero, 'Barbar') >= 2 &&
          ConditionRules.canTakeActions(hero)),
      disadvantage:
          (untrainedArmor &&
              (ability == 'strength' || ability == 'dexterity')) ||
          (ability == 'dexterity' && ConditionRules.has(hero, 'festgesetzt')),
    );
  }

  static D20Rule abilityCheck(
    HeroCharacter hero,
    String ability, {
    bool proficient = false,
    bool stealth = false,
    String? skill,
  }) {
    final mod = attributeModifier(hero, ability);
    if (mod == null) {
      throw StateError('Das Attribut $ability ist nicht bestätigt.');
    }
    final usesSkill = skill != null && skill.isNotEmpty;
    final confirmedProficiency = usesSkill && hero.skills.contains(skill);
    final prof = RulesEngine.proficiencyBonus(hero.level);
    final jack = SkillCheckPassives.jackOfAllTrades(
      bardClassLevel: ClassResourceRules.level(hero, 'Barde'),
      proficiencyBonus: prof,
      usesSkill: usesSkill,
      proficient: proficient || confirmedProficiency,
    );
    final minimumNatural = SkillCheckPassives.minimumNatural(
      rogueClassLevel: ClassResourceRules.level(hero, 'Schurke'),
      usesSkill: usesSkill,
      proficient: proficient && confirmedProficiency,
    );
    return D20Rule(
      mod + (proficient ? prof : 0) + jack + ExhaustionRules.d20Modifier(hero),
      minimumNatural: minimumNatural,
      disadvantage:
          ConditionRules.has(hero, 'vergiftet') ||
          (_untrainedArmor(hero) &&
              (ability == 'strength' || ability == 'dexterity')) ||
          (stealth && _stealthDisadvantage(hero)),
    );
  }

  static D20Rule perception(HeroCharacter hero) => abilityCheck(
    hero,
    'wisdom',
    proficient: hero.skills.contains('Wahrnehmung'),
    skill: 'Wahrnehmung',
  );

  static D20Rule initiative(HeroCharacter hero) {
    if (hero.isDead || hero.hitPoints == 0) {
      throw StateError(
        'Ein bewusstloser oder toter Held würfelt keine Initiative.',
      );
    }
    return D20Rule(
      RulesEngine.initiativeBonus(hero),
      advantage:
          ConditionRules.has(hero, 'unsichtbar') ||
          ClassResourceRules.level(hero, 'Barbar') >= 7 ||
          SrdClassFeatureCatalog.unlocked(
            hero,
          ).any((f) => f.name == 'Remarkable Athlete'),
      disadvantage:
          !ConditionRules.canTakeActions(hero) ||
          ConditionRules.has(hero, 'vergiftet') ||
          _untrainedArmor(hero),
    );
  }

  static D20Rule attack(HeroCharacter hero) {
    if (!ConditionRules.canTakeActions(hero)) {
      throw StateError('Dieser Zustand verhindert einen Angriff.');
    }
    var heavyDisadvantage = false;
    final equipped = hero.inventory.where(
      (e) => e.id == hero.equippedWeaponId && hero.equippedWeaponId.isNotEmpty,
    );
    if (equipped.length == 1) {
      final weapon = SrdEquipmentCatalog.byId(equipped.single.catalogId);
      if (weapon != null && weapon.hasProperty('heavy')) {
        final ranged =
            weapon.category == EquipmentCategory.simpleRanged ||
            weapon.category == EquipmentCategory.martialRanged;
        final score = hero.abilities[ranged ? 'dexterity' : 'strength'];
        heavyDisadvantage = score == null || score < 13;
      }
    }
    return D20Rule(
      RulesEngine.attackBonus(hero),
      disadvantage:
          ConditionRules.hasUnconditionalAttackDisadvantage(hero) ||
          heavyDisadvantage ||
          _untrainedArmor(hero),
    );
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
    // Both are passive features. They depend on the respective *class* level.
    // A heavy armor classification comes only from an equipped SRD item.
    final armorMatch = hero.inventory.where(
      (i) => i.id == hero.equippedArmorId && hero.equippedArmorId.isNotEmpty,
    );
    final equipped = armorMatch.length == 1
        ? SrdEquipmentCatalog.byId(armorMatch.single.catalogId)
        : null;
    final heavy = equipped?.category == EquipmentCategory.heavyArmor;
    var bonusMeters = 0.0;
    if (ClassResourceRules.level(hero, 'Barbar') >= 5 && !heavy) {
      bonusMeters += 3; // Fast Movement, 10 feet.
    }
    final monk = ClassResourceRules.level(hero, 'Mönch');
    if (monk >= 2 &&
        hero.equippedArmorId.isEmpty &&
        hero.equippedShieldId.isEmpty) {
      bonusMeters += ClassResourceRules.monkMovementBonusFeet(monk) * .3;
    }
    return (base - penaltyMeters + bonusMeters).clamp(0, 1000).toDouble();
  }

  static int? movementWholeMeters(HeroCharacter hero) =>
      speedMeters(hero)?.floor();

  /// Other optional equipment effects are left explicit, never invented.
  static bool _untrainedArmor(HeroCharacter hero) =>
      (hero.equippedArmorId.isNotEmpty && !hero.equippedArmorTrained) ||
      (hero.equippedShieldId.isNotEmpty && !hero.equippedShieldTrained);

  static bool _stealthDisadvantage(HeroCharacter hero) {
    final equipped = hero.inventory.where(
      (i) => i.id == hero.equippedArmorId && hero.equippedArmorId.isNotEmpty,
    );
    if (equipped.length != 1) return false;
    return SrdEquipmentCatalog.byId(
          equipped.single.catalogId,
        )?.stealthDisadvantage ??
        false;
  }
}
