import 'magic_missile_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 Shield. A player's explicit advance authorization is used
/// only if a subsequent enemy attack actually hits and +5 AC would stop it.
class HeroShieldReactionPlan {
  const HeroShieldReactionPlan({
    required this.castingClass,
    required this.slotLevel,
    required this.pactMagic,
    required this.verbalConfirmed,
    required this.somaticConfirmed,
  });
  final String castingClass;
  final int slotLevel;
  final bool pactMagic, verbalConfirmed, somaticConfirmed;
}

class HeroShieldReactionRules {
  const HeroShieldReactionRules._();
  static const spellNames = ['Schild', 'Shield'];

  static String? preparedName(HeroCharacter hero) {
    for (final name in spellNames) {
      if (hero.spells.contains(name)) return name;
    }
    return null;
  }

  static List<String> castingClasses(HeroCharacter hero) =>
      MagicMissileRules.castingClasses(hero);

  static List<MagicMissileSlot> slots(HeroCharacter hero) =>
      MagicMissileRules.slots(hero);

  static void validate(
    HeroCharacter hero,
    Encounter encounter,
    HeroShieldReactionPlan plan,
  ) {
    final selected = findSrdClass(plan.castingClass)?.name;
    if (preparedName(hero) == null ||
        selected == null ||
        !castingClasses(hero).contains(selected) ||
        !plan.verbalConfirmed ||
        !plan.somaticConfirmed ||
        encounter.reactionUsed ||
        hero.isDead ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        !hero.isComplete) {
      throw const FormatException(
        'Schildreaktion erfordert vorbereiteten Zauber, eigene Zauberklasse, '
        'freie Reaktion und ausdrücklich bestätigte V/S-Komponenten.',
      );
    }
    if (!slots(hero).any(
      (slot) =>
          slot.level == plan.slotLevel &&
          slot.pactMagic == plan.pactMagic &&
          slot.remaining > 0,
    )) {
      throw const FormatException(
        'Kein bestätigter freier Schild-Zauberplatz.',
      );
    }
  }

  /// Critical hits still hit regardless of the bonus to Armor Class.
  static bool preventsHit({
    required bool hit,
    required bool critical,
    required int attackTotal,
    required int effectiveArmorClass,
  }) => hit && !critical && attackTotal < effectiveArmorClass + 5;

  static HeroCharacter spend(HeroCharacter hero, HeroShieldReactionPlan plan) {
    final resource = MagicMissileRules.normalized(hero);
    final cast = SpellcastingRules.cast(
      resource,
      spellName: preparedName(hero)!,
      spellLevel: 1,
      slotLevel: plan.slotLevel,
      pactMagic: plan.pactMagic,
    );
    return cast.hero.copyWith(
      className: hero.className,
      secondaryClassName: hero.secondaryClassName,
    );
  }
}
