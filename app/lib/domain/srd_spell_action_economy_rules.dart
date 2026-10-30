import 'dart:convert';

import 'combat_class_actions.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'srd_spell_catalog.dart';

/// A normal Magic action and a Bonus Action are separate turn resources.
enum SrdSpellTurnAction { magicAction, bonusAction }

/// Read-only proof of the available action for exactly one spell and turn.
///
/// No action is reserved or spent here. The caller must revalidate this
/// evidence at the same atomic transaction that commits the spell and turn.
class SrdSpellTurnActionEvidence {
  const SrdSpellTurnActionEvidence({
    required this.action,
    required this.spellSnapshot,
    required this.heroSnapshot,
    required this.encounterSnapshot,
    required this.inCombat,
    required this.expendSpellSlot,
  });

  final SrdSpellTurnAction action;
  final String spellSnapshot;
  final String heroSnapshot;
  final String? encounterSnapshot;
  final bool inCombat;
  final bool expendSpellSlot;

  void validateUnchanged({
    required HeroCharacter hero,
    required SrdSpellDefinition spell,
    required Encounter? encounter,
  }) {
    if (jsonEncode(hero.toJson()) != heroSnapshot ||
        SrdSpellActionEconomyRules._spellSnapshot(spell) != spellSnapshot ||
        (encounter == null ? null : jsonEncode(encounter.toJson())) !=
            encounterSnapshot) {
      throw const FormatException(
        'Die bestätigte Zauber-Aktionsberechtigung ist veraltet.',
      );
    }
  }
}

/// SRD 5.2.1 (2024): action/bonus-action economy and one expended spell
/// slot per turn, using the already persisted encounter flags.
///
/// This is not a spell-effect, reaction, or combat-state executor. It never
/// infers that an encounter ended or that a turn was actually committed.
class SrdSpellActionEconomyRules {
  const SrdSpellActionEconomyRules._();

  static String _spellSnapshot(SrdSpellDefinition spell) => jsonEncode({
    'id': spell.id,
    'name': spell.name,
    'level': spell.level,
    'school': spell.school,
    'classes': spell.classes,
    'castingTime': spell.castingTime,
    'range': spell.range,
    'components': spell.components,
    'duration': spell.duration,
    'verbal': spell.verbal,
    'somatic': spell.somatic,
    'material': spell.material,
    'concentration': spell.concentration,
    'ritual': spell.ritual,
  });

  static SrdSpellTurnActionEvidence inspect({
    required HeroCharacter hero,
    required SrdSpellDefinition spell,
    Encounter? encounter,
    bool currentEncounterConfirmed = false,
    bool noActiveEncounterConfirmed = false,
  }) {
    if ((encounter == null && !noActiveEncounterConfirmed) ||
        (encounter != null && !currentEncounterConfirmed) ||
        (currentEncounterConfirmed && noActiveEncounterConfirmed)) {
      throw const FormatException(
        'Kampfzustand muss widerspruchsfrei bestätigt werden.',
      );
    }
    if (spell.level < 0 || spell.level > 9) {
      throw const FormatException('Unbekannter Zaubergrad.');
    }
    // Permit only the exact canonical ordinary action forms. In particular,
    // a triggered Bonus Action or Reaction must use its own trigger rules.
    final SrdSpellTurnAction action;
    switch (spell.castingTime) {
      case 'Action':
        if (spell.ritual) {
          throw const FormatException(
            'Wirkzeit und Ritualkennzeichen widersprechen sich.',
          );
        }
        action = SrdSpellTurnAction.magicAction;
      case 'Action or Ritual':
        if (!spell.ritual) {
          throw const FormatException(
            'Wirkzeit und Ritualkennzeichen widersprechen sich.',
          );
        }
        action = SrdSpellTurnAction.magicAction;
      case 'Bonus Action':
        if (spell.ritual) {
          throw const FormatException(
            'Bonusaktion darf nicht als Ritual bestätigt sein.',
          );
        }
        action = SrdSpellTurnAction.bonusAction;
      default:
        throw UnsupportedError(
          'Zauberwirkzeit benötigt einen eigenständigen Regelpfad.',
        );
    }
    if (hero.isDead ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        !ConditionRules.canTakeActions(hero)) {
      throw StateError('Der Held kann derzeit keine Zauberaktion ausführen.');
    }

    if (encounter != null) {
      if (encounter.isFinished || encounter.activeParticipant != 'hero') {
        throw StateError('Der bestätigte eigene Kampfzug ist nicht aktiv.');
      }
      if (CombatClassActions.rageActive(encounter)) {
        throw StateError('Aktiver Kampfrausch verhindert Zauberwirken.');
      }
      if (action == SrdSpellTurnAction.magicAction &&
          (encounter.actionUsed ||
              encounter.surgeReserved ||
              encounter.surgeUsedThisTurn)) {
        throw StateError('Keine gültige normale Magieaktion verfügbar.');
      }
      if (action == SrdSpellTurnAction.bonusAction &&
          encounter.bonusActionUsed) {
        throw StateError('Bonusaktion ist bereits verbraucht.');
      }
      if (spell.level > 0 && encounter.spellSlotExpendedThisTurn) {
        throw StateError('Ein Zauberplatz wurde in diesem Zug verbraucht.');
      }
    }

    return SrdSpellTurnActionEvidence(
      action: action,
      spellSnapshot: _spellSnapshot(spell),
      heroSnapshot: jsonEncode(hero.toJson()),
      encounterSnapshot:
          encounter == null ? null : jsonEncode(encounter.toJson()),
      inCombat: encounter != null,
      expendSpellSlot: spell.level > 0,
    );
  }
}
