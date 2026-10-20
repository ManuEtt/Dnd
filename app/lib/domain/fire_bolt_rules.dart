import 'condition_rules.dart';
import 'cover_rules.dart';
import 'dice_engine.dart';
import 'magic_missile_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 Fire Bolt: one Magic action, 120 ft., V/S, ranged spell attack.
/// Limited to a confirmed single creature; flammable objects and unverified
/// defensive traits are NOT automated. Fire damage is never inferred from AI.
class FireBoltRules {
  const FireBoltRules._();

  static const spellNames = <String>['Feuerpfeil', 'Fire Bolt'];

  static String? preparedName(HeroCharacter hero) {
    for (final name in spellNames) {
      if (hero.spells.contains(name)) return name;
    }
    return null;
  }

  static List<String> castingClasses(HeroCharacter hero) =>
      MagicMissileRules.castingClasses(hero);

  static int diceCount(int characterLevel) {
    if (characterLevel < 1 || characterLevel > 20) {
      throw RangeError.range(characterLevel, 1, 20, 'characterLevel');
    }
    if (characterLevel >= 17) return 4;
    if (characterLevel >= 11) return 3;
    if (characterLevel >= 5) return 2;
    return 1;
  }

  static FireBoltResult cast(
    HeroCharacter hero, {
    required DiceEngine dice,
    required String castingClass,
    required int targetArmorClass,
    required CoverLevel targetCover,
    required bool targetVisibleConfirmed,
    required bool targetWithinRangeConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noFireResistanceOrImmunityConfirmed,
    required bool noUnresolvedShieldReactionConfirmed,
    required bool situationalAttackConditionsConfirmed,
    bool advantage = false,
    bool disadvantage = false,
    bool targetProne = false,
    bool targetWithinFiveFeet = false,
  }) {
    final known = preparedName(hero);
    final selected = findSrdClass(castingClass)?.name;
    if (known == null ||
        selected == null ||
        !castingClasses(hero).contains(selected)) {
      throw const FormatException(
        'Feuerpfeil benötigt eine bestätigte Vorbereitung und '
        'eine eigene Zauberer- oder Magierklasse.',
      );
    }
    if (!targetVisibleConfirmed ||
        !targetWithinRangeConfirmed ||
        !verbalComponentConfirmed ||
        !somaticComponentConfirmed ||
        !noFireResistanceOrImmunityConfirmed ||
        !noUnresolvedShieldReactionConfirmed ||
        !situationalAttackConditionsConfirmed) {
      throw const FormatException(
        'Sicht, Reichweite, Komponenten, gegnerische Abwehr '
        'und Angriffsumstände müssen bestätigt sein.',
      );
    }
    final effectiveArmorClass = CoverRules.armorClass(
      targetArmorClass,
      targetCover,
    );
    final ability = selected == 'Magier' ? 'intelligence' : 'charisma';
    final score = hero.abilities[ability];
    if (score == null || score < 1 || score > 30) {
      throw StateError('Das Zauberattribut ist nicht bestätigt.');
    }
    // Resource validation must happen before any random roll.
    final resource = MagicMissileRules.normalized(hero);
    final spent = SpellcastingRules.cast(
      resource,
      spellName: known,
      spellLevel: 0,
    );
    final forcedDisadvantage =
        ConditionRules.hasUnconditionalAttackDisadvantage(hero) ||
        (targetProne && !targetWithinFiveFeet);
    final attackBonus =
        RulesEngine.abilityModifier(score) +
        RulesEngine.proficiencyBonus(hero.level) +
        ExhaustionRules.d20Modifier(hero);
    final attack = dice.check(
      modifier: attackBonus,
      advantage: advantage,
      disadvantage: disadvantage || forcedDisadvantage,
    );
    final critical = attack.natural == 20;
    final hit =
        attack.natural != 1 &&
        (critical || attack.total >= effectiveArmorClass);
    final baseDice = diceCount(hero.level);
    final damageRoll = hit
        ? dice.roll('${critical ? 2 * baseDice : baseDice}d10')
        : null;
    return FireBoltResult(
      hero: spent.hero.copyWith(
        className: hero.className,
        secondaryClassName: hero.secondaryClassName,
      ),
      castingClass: selected,
      spellcastingAbility: ability,
      attackRoll: attack,
      damageRoll: damageRoll,
      attackBonus: attackBonus,
      effectiveArmorClass: effectiveArmorClass,
      hit: hit,
      critical: critical,
      damage: damageRoll?.total ?? 0,
    );
  }
}

class FireBoltResult {
  const FireBoltResult({
    required this.hero,
    required this.castingClass,
    required this.spellcastingAbility,
    required this.attackRoll,
    required this.damageRoll,
    required this.attackBonus,
    required this.effectiveArmorClass,
    required this.hit,
    required this.critical,
    required this.damage,
  });

  final HeroCharacter hero;
  final String castingClass, spellcastingAbility;
  final DiceResult attackRoll;
  final DiceResult? damageRoll;
  final int attackBonus, effectiveArmorClass, damage;
  final bool hit, critical;
}
