import 'dart:convert';

import 'class_resource_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';

/// SRD 5.2.1, Bard level 5, Font of Inspiration:
/// expend one confirmed spell slot (no action) to recover one previously
/// expended Bardic Inspiration use. The actual creation/transfer of an
/// inspiration die to a target is deliberately a separate rule action.
class SrdBardFontProposal {
  const SrdBardFontProposal({
    required this.sourceSnapshot,
    required this.slotLevel,
    required this.usePactSlot,
  });

  final String sourceSnapshot;
  final int slotLevel;
  final bool usePactSlot;

  /// One atomic, replay-safe state transition. The caller must save the
  /// resulting HeroCharacter via the existing confirmed-event transaction.
  HeroCharacter applyTo(HeroCharacter current) {
    if (jsonEncode(current.toJson()) != sourceSnapshot) {
      throw const FormatException('Veralteter Vorschlag zur Bardischen Inspiration.');
    }
    // Validation is repeated: never trust a fabricated proposal.
    SrdBardFontOfInspirationRules._validate(
      current,
      slotLevel: slotLevel,
      usePactSlot: usePactSlot,
    );
    final spent = current.spentClassResources['bardicInspiration'] ?? 0;
    final nextResources = {...current.spentClassResources};
    if (spent == 1) {
      nextResources.remove('bardicInspiration');
    } else {
      nextResources['bardicInspiration'] = spent - 1;
    }
    final next = usePactSlot
        ? current.copyWith(
            spentPactSlots: current.spentPactSlots + 1,
            spentClassResources: nextResources,
          )
        : current.copyWith(
            spentSpellSlots: {
              ...current.spentSpellSlots,
              '$slotLevel': (current.spentSpellSlots['$slotLevel'] ?? 0) + 1,
            },
            spentClassResources: nextResources,
          );
    // Reject invalid imports or counters before a controller persists the
    // result; no intermediate change to the original immutable character.
    HeroCharacter.fromJson(next.toJson());
    return next;
  }
}

class SrdBardFontOfInspirationRules {
  const SrdBardFontOfInspirationRules._();

  static SrdBardFontProposal propose({
    required HeroCharacter hero,
    required int slotLevel,
    bool usePactSlot = false,
  }) {
    _validate(hero, slotLevel: slotLevel, usePactSlot: usePactSlot);
    return SrdBardFontProposal(
      sourceSnapshot: jsonEncode(hero.toJson()),
      slotLevel: slotLevel,
      usePactSlot: usePactSlot,
    );
  }

  static void _validate(
    HeroCharacter hero, {
    required int slotLevel,
    required bool usePactSlot,
  }) {
    if (ClassResourceRules.level(hero, 'Barde') < 5) {
      throw StateError('Inspiration regenerieren benötigt Bardenstufe 5.');
    }
    if (hero.isDead || hero.hitPoints == null || hero.hitPoints! <= 0) {
      throw StateError('Der Charakter kann das Merkmal derzeit nicht nutzen.');
    }
    ClassResourceRules.validate(hero);
    if ((hero.spentClassResources['bardicInspiration'] ?? 0) < 1) {
      throw StateError('Es ist keine Bardische Inspiration verbraucht.');
    }
    if (slotLevel < 1 || slotLevel > 9) {
      throw RangeError.range(slotLevel, 1, 9, 'slotLevel');
    }
    if (usePactSlot) {
      if (slotLevel != SpellcastingRules.pactSlotLevel(hero) ||
          SpellcastingRules.availablePactSlots(hero) < 1) {
        throw StateError('Kein passender bestätigter Paktplatz vorhanden.');
      }
    } else if ((SpellcastingRules.availableSlots(hero)[slotLevel] ?? 0) < 1) {
      throw StateError('Kein Zauberplatz dieses Grades verfügbar.');
    }
  }
}
