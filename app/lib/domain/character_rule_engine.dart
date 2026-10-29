import 'condition_rules.dart';
import 'models.dart';
import 'class_resource_rules.dart';
import 'skill_check_passives.dart';
import 'srd_class_feature_catalog.dart';
import 'rules_engine.dart';
import 'srd_equipment_catalog.dart';
import 'tool_proficiency_rules.dart';
import 'srd_skill_ability_catalog.dart';

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

  /// A preview for an explicitly chosen ability and relevant trained skill.
  /// Learned proficiency survives sale of the item. This does not confirm
  /// possession, the tool's use, a target, difficulty or a completed roll.
  static D20Rule toolCheck(
    HeroCharacter hero,
    String ability, {
    required String toolCatalogId,
    String? relevantSkill,
  }) {
    if (!ToolProficiencyRules.catalogIds(hero).contains(toolCatalogId)) {
      throw const FormatException(
        'Keine bestätigte Übung für dieses Werkzeug.',
      );
    }
    String? recordedSkill;
    if (relevantSkill != null) {
      var canonical = relevantSkill;
      for (final alias in srdLegacySkillAliases.entries) {
        if (alias.value == canonical) canonical = alias.key;
      }
      if (!srdSkillAbilities.any((skill) => skill.name == canonical)) {
        throw const FormatException('Unbekannte relevante SRD-Fertigkeit.');
      }
      recordedSkill = hero.skills.contains(canonical)
          ? canonical
          : srdLegacySkillAliases[canonical] ?? canonical;
    }
    final base = abilityCheck(
      hero,
      ability,
      proficient: true,
      skill: recordedSkill,
      stealth: ability == 'dexterity' && recordedSkill == 'Heimlichkeit',
    );
    return D20Rule(
      base.modifier,
      // SRD p.63: Reliable Talent also covers confirmed tool proficiency,
      // even without a relevant trained skill. Generic free checks do not.
      minimumNatural: ClassResourceRules.level(hero, 'Schurke') >= 7
          ? 10
          : base.minimumNatural,
      advantage:
          base.advantage ||
          (recordedSkill != null && hero.skills.contains(recordedSkill)),
      disadvantage: base.disadvantage,
      automaticallyFails: base.automaticallyFails,
    );
  }

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

  /// A passive Wisdom (Perception) check needs no d20. The character's
  /// *confirmed* current skill rule supplies ability, proficiency, Bard
  /// Jack of All Trades and exhaustion; a situational advantage or
  /// disadvantage adjusts the result by 5, never 5 per source.
  ///
  /// The caller must still confirm the sense, target, lighting, obstacles
  /// and difficulty: a passive total alone never invents a hidden clue.
  /// Unconfirmed Wisdom and unconscious/dead characters cannot perceive.
  ///
  /// The uploaded German starter-set book covers the passive-check arithmetic
  /// in chapter 1, "Verstecken und Sehen" (p. 6). Edition-specific 2014
  /// surprise/exhaustion rules are NOT imported into the SRD 5.2.1 engine.
  static int? passivePerception(
    HeroCharacter hero, {
    bool situationalAdvantage = false,
    bool situationalDisadvantage = false,
  }) {
    if (hero.abilities['wisdom'] == null ||
        hero.isDead ||
        hero.hitPoints == 0 ||
        ConditionRules.has(hero, 'bewusstlos')) {
      return null;
    }
    final rule = perception(hero);
    if (rule.automaticallyFails) return null;
    // Multiple advantages/disadvantages never stack, and opposing sources
    // cancel even when one originates in a condition such as Poisoned.
    final advantage = rule.advantage || situationalAdvantage;
    final disadvantage = rule.disadvantage || situationalDisadvantage;
    final situationalBonus = advantage == disadvantage
        ? 0
        : advantage
        ? 5
        : -5;
    return 10 + rule.modifier + situationalBonus;
  }

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
    // Ranger 6 (Roving): +10 ft only without Heavy armor. An unknown
    // equipped catalog item must not be assumed to be light armor.
    final armorConfirmed = hero.equippedArmorId.isEmpty || equipped != null;
    if (ClassResourceRules.level(hero, 'Waldläufer') >= 6 &&
        armorConfirmed &&
        !heavy) {
      bonusMeters += 3;
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

  /// SRD 5.2.1 Ranger 6 (Roving): both movement types match the effective
  /// Speed, including exhaustion, conditions and verified armor penalties.
  /// Heavy armor stops only the +10-foot bonus, not these two speeds.
  /// Null means the character has no confirmed Roving speed from this class;
  /// it does not assert they lack climb/swim speeds from other sources.
  static double? rovingClimbSpeedMeters(HeroCharacter hero) =>
      ClassResourceRules.level(hero, 'Waldläufer') < 6
      ? null
      : speedMeters(hero);

  static double? rovingSwimSpeedMeters(HeroCharacter hero) =>
      ClassResourceRules.level(hero, 'Waldläufer') < 6
      ? null
      : speedMeters(hero);

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
