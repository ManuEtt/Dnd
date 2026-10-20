import 'cover_rules.dart';
import 'dice_engine.dart';
import 'magic_missile_rules.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';
import 'srd_spell_saving_throw_rules.dart';

/// A creature explicitly confirmed to be INSIDE a 5-foot-radius Sphere.
/// Coordinates and monster save/trait values must never be invented.
class AcidSplashTarget {
  const AcidSplashTarget({
    required this.id,
    required this.name,
    required this.hitPoints,
    required this.maxHitPoints,
    required this.dexteritySaveModifier,
    required this.cover,
    required this.sourceOppositeCover,
    required this.coverRelationshipConfirmed,
    required this.inSphereConfirmed,
    required this.effectPathConfirmed,
    required this.noAcidDamageAdjustmentConfirmed,
    required this.saveCircumstancesConfirmed,
    this.saveAdvantage = false,
    this.saveDisadvantage = false,
  });

  final String id, name;
  final int hitPoints, maxHitPoints, dexteritySaveModifier;
  final CoverLevel cover;
  final bool sourceOppositeCover, coverRelationshipConfirmed;
  final bool inSphereConfirmed, effectPathConfirmed;
  final bool noAcidDamageAdjustmentConfirmed, saveCircumstancesConfirmed;
  final bool saveAdvantage, saveDisadvantage;
}

class AcidSplashImpact {
  const AcidSplashImpact({
    required this.id,
    required this.name,
    required this.hitPointsBefore,
    required this.hitPointsAfter,
    required this.coverBonus,
    required this.save,
    required this.damage,
  });

  final String id, name;
  final int hitPointsBefore, hitPointsAfter, coverBonus, damage;
  final SrdSpellSaveResolution save;

  Map<String, dynamic> toJson() => {
    'targetId': id,
    'targetName': name,
    'hitPointsBefore': hitPointsBefore,
    'hitPointsAfter': hitPointsAfter,
    'coverSaveBonus': coverBonus,
    'savingThrowModifier': save.modifier,
    'savingThrowDc': save.dc,
    'savingThrowRoll': save.roll.toJson(),
    'savingThrowSucceeded': save.succeeded,
    'damage': damage,
    'damageType': 'acid',
  };
}

class AcidSplashResult {
  const AcidSplashResult({
    required this.hero,
    required this.castingClass,
    required this.dc,
    required this.damageRoll,
    required this.targets,
  });

  final HeroCharacter hero;
  final String castingClass;
  final int dc;
  final DiceResult? damageRoll;
  final List<AcidSplashImpact> targets;
}

/// SRD 5.2.1 Acid Splash: Action, V/S, 60ft, 5ft-radius sphere, Dexterity
/// saving throw per creature, 1/2/3/4d6 acid by *character* level.
/// Simultaneous area damage is rolled ONCE and applied to all failed saves.
/// A result is pure: callers must persist the updated HP of every target.
class AcidSplashRules {
  const AcidSplashRules._();

  static const spellNames = <String>['Säurespritzer', 'Saeurespritzer', 'Acid Splash'];

  static String? preparedName(HeroCharacter hero) {
    for (final name in spellNames) {
      if (hero.spells.contains(name)) return name;
    }
    return null;
  }

  static List<String> castingClasses(HeroCharacter hero) =>
      MagicMissileRules.castingClasses(hero);

  static int damageDice(int characterLevel) {
    if (characterLevel < 1 || characterLevel > 20) {
      throw RangeError.range(characterLevel, 1, 20, 'characterLevel');
    }
    if (characterLevel >= 17) return 4;
    if (characterLevel >= 11) return 3;
    if (characterLevel >= 5) return 2;
    return 1;
  }

  static AcidSplashResult cast(
    HeroCharacter hero, {
    required DiceEngine dice,
    required String castingClass,
    required List<AcidSplashTarget> targets,
    required bool sphereOriginWithinRangeConfirmed,
    required bool everyCreatureInSphereIncludedConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noUnmodelledDcModifiersConfirmed,
  }) {
    final name = preparedName(hero);
    final selected = findSrdClass(castingClass)?.name;
    if (name == null ||
        selected == null ||
        !const {'Zauberer', 'Magier'}.contains(selected) ||
        !castingClasses(hero).contains(selected)) {
      throw const FormatException(
        'Säurespritzer erfordert einen vorbereiteten Zaubertrick '
        'eines eigenen Magiers oder Zauberers.',
      );
    }
    if (!sphereOriginWithinRangeConfirmed ||
        !everyCreatureInSphereIncludedConfirmed ||
        !verbalComponentConfirmed ||
        !somaticComponentConfirmed) {
      throw const FormatException(
        'Ursprung im 60-Fuß-Bereich, ALLE Kreaturen in der Kugel '
        'und V/S-Komponenten müssen bestätigt sein.',
      );
    }
    // Safety cap on manually resolved targets; NOT a limit on the SRD sphere.
    if (targets.isEmpty || targets.length > 20) {
      throw const FormatException(
        '1–20 bestätigte Kreaturen pro Prüfung erforderlich; '
        'größere Gruppen benötigen einen anderen Prüfpfad.',
      );
    }
    final ids = <String>{};
    for (final target in targets) {
      if (target.id.isEmpty ||
          target.id.length > 128 ||
          target.name.trim().isEmpty ||
          target.name.length > 128 ||
          !ids.add(target.id) ||
          target.maxHitPoints < 1 ||
          target.maxHitPoints > 1000000 ||
          target.hitPoints < 1 ||
          target.hitPoints > target.maxHitPoints ||
          target.dexteritySaveModifier < -30 ||
          target.dexteritySaveModifier > 30 ||
          !target.coverRelationshipConfirmed ||
          !target.inSphereConfirmed ||
          !target.effectPathConfirmed ||
          !target.noAcidDamageAdjustmentConfirmed ||
          !target.saveCircumstancesConfirmed ||
          target.cover == CoverLevel.total) {
        throw const FormatException(
          'Jede Kreatur benötigt eine eindeutige ID, gültige TP, '
          'bestätigten GES-Rettungswurf, Deckung, Wirkpfad und '
          'Säure-Schadensabwehr. Vollständige Deckung erfordert '
          'zuerst eine eigene Geometrieprüfung.',
        );
      }
    }
    final ability = selected == 'Magier' ? 'intelligence' : 'charisma';
    final dc = SrdSpellSavingThrowRules.spellSaveDc(
      hero,
      spellcastingAbility: ability,
      noUnmodelledDcModifiersConfirmed: noUnmodelledDcModifiersConfirmed,
    );

    // Check resources, armor and conditions before ANY roll.
    final normalized = MagicMissileRules.normalized(hero);
    final spent = SpellcastingRules.cast(
      normalized,
      spellName: name,
      spellLevel: 0,
    );

    final saves = <SrdSpellSaveResolution>[];
    final coverBonuses = <int>[];
    for (final target in targets) {
      final coverBonus = CoverRules.savingThrowBonus(
        target.cover,
        ability: 'dexterity',
        sourceOppositeCover: target.sourceOppositeCover,
      );
      coverBonuses.add(coverBonus);
      saves.add(
        SrdSpellSavingThrowRules.resolve(
          dice: dice,
          dc: dc,
          confirmedTargetModifier:
              target.dexteritySaveModifier + coverBonus,
          saveCircumstancesConfirmed: target.saveCircumstancesConfirmed,
          advantage: target.saveAdvantage,
          disadvantage: target.saveDisadvantage,
        ),
      );
    }
    final anyFailed = saves.any((save) => !save.succeeded);
    final damageRoll = anyFailed
        ? dice.roll('${damageDice(hero.level)}d6')
        : null;
    final sharedDamage = damageRoll?.total ?? 0;
    final impacts = <AcidSplashImpact>[];
    for (var i = 0; i < targets.length; i++) {
      final target = targets[i];
      final damage = saves[i].succeeded ? 0 : sharedDamage;
      impacts.add(
        AcidSplashImpact(
          id: target.id,
          name: target.name,
          hitPointsBefore: target.hitPoints,
          hitPointsAfter: RulesEngine.remainingHitPoints(
            hitPoints: target.hitPoints,
            damage: damage,
          ),
          coverBonus: coverBonuses[i],
          save: saves[i],
          damage: damage,
        ),
      );
    }
    return AcidSplashResult(
      hero: spent.hero.copyWith(
        className: hero.className,
        secondaryClassName: hero.secondaryClassName,
      ),
      castingClass: selected,
      dc: dc,
      damageRoll: damageRoll,
      targets: List.unmodifiable(impacts),
    );
  }
}
