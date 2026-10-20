import 'cover_rules.dart';
import 'dice_engine.dart';
import 'magic_missile_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';
import 'srd_spell_saving_throw_rules.dart';

/// SRD 5.2.1 Sacred Flame: action, 60 ft., V/S, one visible creature,
/// Dexterity save; no cover bonus for half/three-quarter cover.
/// A creature's verified full Dexterity save bonus MUST be supplied by the
/// player/monster catalogue. This feature never invents a monster save.
class SacredFlameRules {
  const SacredFlameRules._();

  static const spellNames = <String>['Heilige Flamme', 'Sacred Flame'];

  static String? preparedName(HeroCharacter hero) {
    for (final name in spellNames) {
      if (hero.spells.contains(name)) return name;
    }
    return null;
  }

  static bool isClericCaster(HeroCharacter hero) {
    final primary = findSrdClass(hero.className)?.name == 'Kleriker' &&
        hero.primaryClassLevel >= 1;
    final secondary = hero.hasSecondClass &&
        findSrdClass(hero.secondaryClassName)?.name == 'Kleriker' &&
        hero.secondaryClassLevel >= 1;
    return hero.level >= 1 &&
        hero.level <= 20 &&
        (primary || secondary);
  }

  static int diceCount(int totalCharacterLevel) {
    if (totalCharacterLevel < 1 || totalCharacterLevel > 20) {
      throw RangeError.range(totalCharacterLevel, 1, 20);
    }
    if (totalCharacterLevel >= 17) return 4;
    if (totalCharacterLevel >= 11) return 3;
    if (totalCharacterLevel >= 5) return 2;
    return 1;
  }

  static SacredFlameResult cast(
    HeroCharacter hero, {
    required DiceEngine dice,
    required int confirmedTargetDexteritySaveModifier,
    required CoverLevel targetCover,
    required bool targetVisibleConfirmed,
    required bool targetWithinRangeConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noRadiantDamageAdjustmentConfirmed,
    required bool noUnmodelledDcModifiersConfirmed,
    required bool saveCircumstancesConfirmed,
    bool saveAdvantage = false,
    bool saveDisadvantage = false,
  }) {
    final name = preparedName(hero);
    if (name == null || !isClericCaster(hero)) {
      throw const FormatException(
        'Heilige Flamme erfordert einen bestätigten vorbereiteten '
        'Zaubertrick eines eigenen Klerikers.',
      );
    }
    if (!targetVisibleConfirmed ||
        !targetWithinRangeConfirmed ||
        !verbalComponentConfirmed ||
        !somaticComponentConfirmed ||
        !noRadiantDamageAdjustmentConfirmed) {
      throw const FormatException(
        'Sicht, Reichweite (60 Fuß), V/S-Komponenten und '
        'feuerähnlicher Strahlenschaden ohne ungeprüfte Modifikatoren '
        'müssen bestätigt sein.',
      );
    }
    if (targetCover == CoverLevel.total) {
      throw const FormatException(
        'Vollständige Deckung wird nicht durch Heilige Flamme ignoriert.',
      );
    }
    // All static inputs are checked before RNG and HP/resource changes.
    final dc = SrdSpellSavingThrowRules.spellSaveDc(
      hero,
      spellcastingAbility: 'wisdom',
      noUnmodelledDcModifiersConfirmed:
          noUnmodelledDcModifiersConfirmed,
    );
    if (!saveCircumstancesConfirmed ||
        confirmedTargetDexteritySaveModifier < -30 ||
        confirmedTargetDexteritySaveModifier > 30) {
      throw const FormatException(
        'Den vollständigen gegnerischen Geschicklichkeits-Rettungswurf '
        'sowie Vorteil/Nachteil und automatische Fehlschläge bestätigen.',
      );
    }
    final resourceHero = MagicMissileRules.normalized(hero);
    final cast = SpellcastingRules.cast(
      resourceHero,
      spellName: name,
      spellLevel: 0,
    );
    final save = SrdSpellSavingThrowRules.resolve(
      dice: dice,
      dc: dc,
      confirmedTargetModifier: confirmedTargetDexteritySaveModifier,
      saveCircumstancesConfirmed: saveCircumstancesConfirmed,
      advantage: saveAdvantage,
      disadvantage: saveDisadvantage,
    );
    // On a successful save Sacred Flame deals zero damage; don't roll dice.
    final damageRoll = save.succeeded
        ? null
        : dice.roll('${diceCount(hero.level)}d8');
    return SacredFlameResult(
      hero: cast.hero.copyWith(
        className: hero.className,
        secondaryClassName: hero.secondaryClassName,
      ),
      savingThrow: save,
      damageRoll: damageRoll,
      damage: damageRoll?.total ?? 0,
      preparedName: name,
    );
  }
}

class SacredFlameResult {
  const SacredFlameResult({
    required this.hero,
    required this.savingThrow,
    required this.damageRoll,
    required this.damage,
    required this.preparedName,
  });

  final HeroCharacter hero;
  final SrdSpellSaveResolution savingThrow;
  final DiceResult? damageRoll;
  final int damage;
  final String preparedName;
}
