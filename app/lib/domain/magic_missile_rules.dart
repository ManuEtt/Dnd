import 'dice_engine.dart';
import 'healing_spell_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 Magic Missile, p. 146: one action, 120 feet, V/S,
/// 3 + (slot level - 1) simultaneous darts, each 1d4+1 Force damage.
/// Restricted to an explicitly confirmed single opponent. No unverified
/// spellbook entry, target position or defensive trait is inferred.
class MagicMissileRules {
  const MagicMissileRules._();

  static const spellNames = ['Magisches Geschoss', 'Magic Missile'];

  static String? preparedName(HeroCharacter hero) {
    for (final name in spellNames) {
      if (hero.spells.contains(name)) return name;
    }
    return null;
  }

  static List<String> castingClasses(HeroCharacter hero) {
    final first = findSrdClass(hero.className)?.name;
    final second = findSrdClass(hero.secondaryClassName)?.name;
    if (hero.level < 1 ||
        hero.level > 20 ||
        first == null ||
        hero.primaryClassLevel < 1 ||
        (hero.hasSecondClass &&
            (second == null ||
                second == first ||
                hero.secondaryClassLevel < 1)) ||
        (!hero.hasSecondClass && hero.secondaryClassLevel != 0)) {
      throw const FormatException('Die Klassenstufen sind ungültig.');
    }
    return [
      for (final name in [first, if (hero.hasSecondClass) second])
        if (name != null &&
            const ['Magier', 'Zauberer'].contains(name) &&
            HealingSpellRules.maximumPreparedSpellLevel(hero, name) >= 1)
          name,
    ];
  }

  static HeroCharacter normalized(HeroCharacter hero) => hero.copyWith(
    className: findSrdClass(hero.className)?.name ?? hero.className,
    secondaryClassName: hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name ?? hero.secondaryClassName
        : '',
  );

  static List<MagicMissileSlot> slots(HeroCharacter hero) {
    final resource = normalized(hero);
    final regular = SpellcastingRules.availableSlots(resource);
    final pact = SpellcastingRules.availablePactSlots(resource);
    return [
      for (final entry in regular.entries)
        if (entry.value > 0)
          MagicMissileSlot(
            level: entry.key,
            remaining: entry.value,
            pactMagic: false,
          ),
      if (pact > 0)
        MagicMissileSlot(
          level: SpellcastingRules.pactSlotLevel(resource),
          remaining: pact,
          pactMagic: true,
        ),
    ];
  }

  static MagicMissileResult cast(
    HeroCharacter hero, {
    required DiceEngine dice,
    required String castingClass,
    required int slotLevel,
    required bool pactMagic,
    required bool targetVisibleConfirmed,
    required bool targetWithinRangeConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noProtectionConfirmed,
    bool blockedByShield = false,
  }) {
    final knownName = preparedName(hero);
    if (knownName == null ||
        !castingClasses(hero).contains(findSrdClass(castingClass)?.name)) {
      throw const FormatException(
        'Nur ein bestätigter Zauber eines eigenen Magiers oder Zauberers '
        'darf gewirkt werden.',
      );
    }
    if (!targetVisibleConfirmed ||
        !targetWithinRangeConfirmed ||
        !verbalComponentConfirmed ||
        !somaticComponentConfirmed ||
        (!noProtectionConfirmed && !blockedByShield)) {
      throw const FormatException(
        'Sicht, Reichweite (120 Fuß), verbale und gestische Komponenten '
        'sowie fehlende bekannte Schutzwirkungen müssen bestätigt sein.',
      );
    }
    if (slotLevel < 1 || slotLevel > 9) {
      throw const FormatException('Ungültiger Zauberplatzgrad.');
    }
    final available = slots(hero);
    if (!available.any(
      (slot) =>
          slot.level == slotLevel &&
          slot.pactMagic == pactMagic &&
          slot.remaining > 0,
    )) {
      throw const FormatException('Der bestätigte Zauberplatz fehlt.');
    }
    final spent = SpellcastingRules.cast(
      normalized(hero),
      spellName: knownName,
      spellLevel: 1,
      slotLevel: slotLevel,
      pactMagic: pactMagic,
    );
    final count = 2 + spent.slotLevel;
    final rolls = [
      if (!blockedByShield)
        for (var i = 0; i < count; i++) dice.roll('1d4+1'),
    ];
    final damage = rolls.fold<int>(0, (sum, roll) => sum + roll.total);
    // Normalization is temporary: historic/localized class names are kept.
    return MagicMissileResult(
      hero: spent.hero.copyWith(
        className: hero.className,
        secondaryClassName: hero.secondaryClassName,
      ),
      slotLevel: spent.slotLevel,
      pactMagic: spent.pactMagic,
      castingClass: findSrdClass(castingClass)!.name,
      rolls: List.unmodifiable(rolls),
      damage: damage,
    );
  }
}

class MagicMissileSlot {
  const MagicMissileSlot({
    required this.level,
    required this.remaining,
    required this.pactMagic,
  });
  final int level, remaining;
  final bool pactMagic;
  String get key => pactMagic ? 'pact' : 'regular-$level';
}

class MagicMissileResult {
  const MagicMissileResult({
    required this.hero,
    required this.slotLevel,
    required this.pactMagic,
    required this.castingClass,
    required this.rolls,
    required this.damage,
  });
  final HeroCharacter hero;
  final int slotLevel, damage;
  final bool pactMagic;
  final String castingClass;
  final List<DiceResult> rolls;
}
