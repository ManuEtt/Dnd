import 'dart:convert';

import 'healing_spell_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';
import 'srd_spell_catalog.dart';

/// Conservative validation before explicitly confirmed resource-only casting.
///
/// This is NOT a generic spell effect executor. Reactions, conditional bonus
/// actions and multi-turn spells still need dedicated rule/event handling.
class SrdSpellPreflightRules {
  const SrdSpellPreflightRules._();

  static const _classes = <String, String>{
    'Barde': 'Bard',
    'Kleriker': 'Cleric',
    'Druide': 'Druid',
    'Paladin': 'Paladin',
    'Waldläufer': 'Ranger',
    'Zauberer': 'Sorcerer',
    'Hexenmeister': 'Warlock',
    'Magier': 'Wizard',
  };

  /// Existing German player spell names stay supported without modifying
  /// old save games. This is intentionally not an unverified full translation.
  static const _knownAliases = <String, String>{
    'Magisches Geschoss': 'Magic Missile',
    'Wunden heilen': 'Cure Wounds',
    'Heilendes Wort': 'Healing Word',
    'Licht': 'Light',
    'Unsichtbarkeit': 'Invisibility',
  };

  static String? _preparedName(
    HeroCharacter hero,
    SrdSpellDefinition spell,
  ) {
    for (final known in hero.spells) {
      if (known == spell.name || _knownAliases[known] == spell.name) {
        return known;
      }
    }
    return null;
  }

  static SrdSpellCastPlan preflight(
    HeroCharacter hero, {
    required SrdSpellDefinition spell,
    required String castingClass,
    required int slotLevel,
    bool pactMagic = false,
    bool actionAvailableConfirmed = false,
    bool targetRulesConfirmed = false,
    bool verbalComponentConfirmed = false,
    bool somaticComponentConfirmed = false,
    bool materialComponentConfirmed = false,
    bool slotTurnLimitConfirmed = false,
  }) {
    final knownName = _preparedName(hero, spell);
    if (knownName == null) {
      throw const FormatException('Zauber ist nicht als vorbereitet bestätigt.');
    }
    final chosenClass = findSrdClass(castingClass)?.name;
    final englishClass = _classes[chosenClass];
    final hasClass = chosenClass != null &&
        ((findSrdClass(hero.className)?.name == chosenClass &&
                hero.primaryClassLevel > 0) ||
            (hero.hasSecondClass &&
                findSrdClass(hero.secondaryClassName)?.name == chosenClass &&
                hero.secondaryClassLevel > 0));
    if (!hasClass ||
        englishClass == null ||
        !spell.classes.contains(englishClass) ||
        HealingSpellRules.maximumPreparedSpellLevel(hero, chosenClass) <
            spell.level) {
      throw const FormatException(
        'Zauber ist für diese eigene Klasse und deren Stufe nicht bestätigt.',
      );
    }
    if (!spell.supportsSingleTurnPreparation) {
      throw UnsupportedError(
        'Reaktionen, bedingte Bonusaktionen und längere Zauberzeiten '
        'benötigen eine eigene Regelaktion.',
      );
    }
    if (!actionAvailableConfirmed || !targetRulesConfirmed) {
      throw const FormatException(
        'Aktion/Bonusaktion und Zielbedingungen müssen bestätigt sein.',
      );
    }
    if ((spell.verbal && !verbalComponentConfirmed) ||
        (spell.somatic && !somaticComponentConfirmed) ||
        (spell.material && !materialComponentConfirmed)) {
      throw const FormatException(
        'Alle erforderlichen Zauberkomponenten sind zu bestätigen.',
      );
    }
    if (spell.level == 0) {
      if (slotLevel != 0 || pactMagic) {
        throw const FormatException(
          'Ein Zaubertrick kann keinen Zauberplatz verbrauchen.',
        );
      }
    } else {
      if (!slotTurnLimitConfirmed) {
        throw const FormatException(
          'Nur ein Zauberplatz pro Zug darf verbraucht werden.',
        );
      }
      if (slotLevel < spell.level || slotLevel > 9) {
        throw const FormatException('Zauberplatzgrad ist zu niedrig oder ungültig.');
      }
      if (pactMagic) {
        if (SpellcastingRules.availablePactSlots(hero) == 0 ||
            slotLevel != SpellcastingRules.pactSlotLevel(hero)) {
          throw StateError('Kein passender Paktmagieplatz verfügbar.');
        }
      } else if ((SpellcastingRules.availableSlots(hero)[slotLevel] ?? 0) < 1) {
        throw StateError('Kein passender Zauberplatz verfügbar.');
      }
    }
    return SrdSpellCastPlan._(
      sourceSnapshot: jsonEncode(hero.toJson()),
      spell: spell,
      preparedName: knownName,
      castingClass: chosenClass,
      slotLevel: slotLevel,
      pactMagic: pactMagic,
    );
  }

  /// Charge costs only after the caller has separately resolved the actual
  /// spell effect. Does not change HP, conditions, targets or world state.
  static SpellCastResult recordConfirmedResourceUse(
    HeroCharacter hero,
    SrdSpellCastPlan plan, {
    required bool effectResolvedSeparatelyConfirmed,
  }) {
    if (jsonEncode(hero.toJson()) != plan.sourceSnapshot) {
      throw const FormatException(
        'Charakter wurde seit der Zauberprüfung verändert.',
      );
    }
    if (!effectResolvedSeparatelyConfirmed) {
      throw StateError(
        'Die eigentliche Zauberwirkung ist noch nicht regelgeprüft.',
      );
    }
    return SpellcastingRules.cast(
      hero,
      spellName: plan.preparedName,
      spellLevel: plan.spell.level,
      slotLevel: plan.spell.level == 0 ? null : plan.slotLevel,
      pactMagic: plan.pactMagic,
      concentration: plan.spell.concentration,
    );
  }
}

/// A plan is minted only by `preflight`; the originating snapshot prevents
/// reusing a stale approval after unrelated changes to the character.
class SrdSpellCastPlan {
  const SrdSpellCastPlan._({
    required this.sourceSnapshot,
    required this.spell,
    required this.preparedName,
    required this.castingClass,
    required this.slotLevel,
    required this.pactMagic,
  });

  final String sourceSnapshot;
  final SrdSpellDefinition spell;
  final String preparedName;
  final String castingClass;
  final int slotLevel;
  final bool pactMagic;
}
