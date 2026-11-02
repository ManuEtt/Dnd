import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_spell_action_economy_rules.dart';
import 'srd_spell_catalog.dart';
import 'srd_spell_component_rules.dart';
import 'srd_spell_grid_target_rules.dart';
import 'srd_spell_preflight_rules.dart';
import 'srd_spell_target_rules.dart';

/// Two independent read-only proofs for a single intended spell and turn.
///
/// These plans must not be persisted as authoritative game state. A caller
/// commits the composed hero/encounter result in ONE campaign transaction.
class SrdSpellTurnPlan {
  const SrdSpellTurnPlan._({
    required this.spellPlan,
    required this.actionEvidence,
    required this.noSlotSpentOutsideEncounterConfirmed,
  });

  final SrdSpellCastPlan spellPlan;
  final SrdSpellTurnActionEvidence actionEvidence;
  final bool noSlotSpentOutsideEncounterConfirmed;
}

class SrdSpellTurnStagedResult {
  const SrdSpellTurnStagedResult({
    required this.cast,
    required this.encounter,
    required this.action,
  });

  final SpellCastResult cast;
  final Encounter? encounter;
  final SrdSpellTurnAction action;
  HeroCharacter get hero => cast.hero;
}

/// Compose the already validated spell preflight with the persisted combat
/// action economy. This creates a *staged* pair of immutable snapshots.
/// It never writes a database, appends events, or executes the spell effect.
///
/// In particular, an action and a bonus action must not be interchangeable.
/// Every attempted reuse after a change to the hero, encounter or spell
/// definition fails before consuming any resource.
class SrdSpellTurnTransactionRules {
  const SrdSpellTurnTransactionRules._();

  static SrdSpellTurnPlan prepare({
    required HeroCharacter hero,
    required SrdSpellDefinition spell,
    required String castingClass,
    required int slotLevel,
    required Encounter? encounter,
    required bool currentEncounterConfirmed,
    required bool noActiveEncounterConfirmed,
    required bool actionAvailableConfirmed,
    required bool targetRulesConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool materialComponentConfirmed,
    bool pactMagic = false,
    bool noSlotSpentOutsideEncounterConfirmed = false,
    SrdSpellTargetFacts? targetFacts,
    SrdSpellGridTargetRequest? gridTarget,
    SrdSpellMaterialSource materialSource =
        SrdSpellMaterialSource.specificComponents,
    bool focusUseAuthorizedConfirmed = false,
    bool costlyComponentAvailableConfirmed = false,
    bool consumedComponentReservedConfirmed = false,
    List<SrdMaterialItemConfirmation> confirmedMaterialItems = const [],
  }) {
    // The explicit action approval remains necessary; a valid turn snapshot
    // is NOT proof of player intention or of resolved target/effect rules.
    if (!actionAvailableConfirmed) {
      throw const FormatException(
        'Die geplante Zauberaktion wurde nicht ausdrücklich bestätigt.',
      );
    }
    final action = SrdSpellActionEconomyRules.inspect(
      hero: hero,
      spell: spell,
      encounter: encounter,
      currentEncounterConfirmed: currentEncounterConfirmed,
      noActiveEncounterConfirmed: noActiveEncounterConfirmed,
    );
    if (encounter == null &&
        spell.level > 0 &&
        !noSlotSpentOutsideEncounterConfirmed) {
      throw const FormatException(
        'Außerhalb eines Kampfes fehlt die bestätigte Zauberplatz-Zuggrenze.',
      );
    }

    final plan = SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: castingClass,
      slotLevel: slotLevel,
      pactMagic: pactMagic,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: targetRulesConfirmed,
      targetFacts: targetFacts,
      gridTarget: gridTarget,
      verbalComponentConfirmed: verbalComponentConfirmed,
      somaticComponentConfirmed: somaticComponentConfirmed,
      materialComponentConfirmed: materialComponentConfirmed,
      materialSource: materialSource,
      focusUseAuthorizedConfirmed: focusUseAuthorizedConfirmed,
      costlyComponentAvailableConfirmed: costlyComponentAvailableConfirmed,
      consumedComponentReservedConfirmed: consumedComponentReservedConfirmed,
      confirmedMaterialItems: confirmedMaterialItems,
      slotTurnLimitConfirmed:
          encounter != null || noSlotSpentOutsideEncounterConfirmed,
    );
    return SrdSpellTurnPlan._(
      spellPlan: plan,
      actionEvidence: action,
      noSlotSpentOutsideEncounterConfirmed:
          noSlotSpentOutsideEncounterConfirmed,
    );
  }

  /// A pure proposed transaction; the repository must persist the returned
  /// hero AND encounter together with events under a checked campaign revision.
  ///
  /// The required effect confirmation MUST come from a separate, authoritative
  /// spell-effect resolver; this API cannot verify an arbitrary true flag.
  static SrdSpellTurnStagedResult stageConfirmed({
    required HeroCharacter hero,
    required Encounter? encounter,
    required SrdSpellTurnPlan plan,
    required bool effectResolvedSeparatelyConfirmed,
    bool materialConsumptionResolvedSeparatelyConfirmed = false,
    bool outsideEncounterStillConfirmed = false,
  }) {
    final spell = plan.spellPlan.spell;
    plan.actionEvidence.validateUnchanged(
      hero: hero,
      spell: spell,
      encounter: encounter,
    );
    if (encounter == null &&
        (!outsideEncounterStillConfirmed ||
            (spell.level > 0 && !plan.noSlotSpentOutsideEncounterConfirmed))) {
      throw const FormatException(
        'Der kampffreie Zauberzug muss beim Abschluss erneut bestätigt werden.',
      );
    }

    // Re-check action permissions against current confirmed state, not only
    // against data in the previously minted proof.
    final currentAction = SrdSpellActionEconomyRules.inspect(
      hero: hero,
      spell: spell,
      encounter: encounter,
      currentEncounterConfirmed: encounter != null,
      noActiveEncounterConfirmed: encounter == null,
    );
    if (currentAction.action != plan.actionEvidence.action ||
        currentAction.expendSpellSlot != plan.actionEvidence.expendSpellSlot) {
      throw const FormatException('Zauber-Aktionsart hat sich verändert.');
    }

    final cast = SrdSpellPreflightRules.recordConfirmedResourceUse(
      hero,
      plan.spellPlan,
      effectResolvedSeparatelyConfirmed: effectResolvedSeparatelyConfirmed,
      materialConsumptionResolvedSeparatelyConfirmed:
          materialConsumptionResolvedSeparatelyConfirmed,
    );
    Encounter? nextEncounter;
    if (encounter != null) {
      nextEncounter = encounter.copyWith(
        actionUsed: currentAction.action == SrdSpellTurnAction.magicAction
            ? true
            : encounter.actionUsed,
        bonusActionUsed: currentAction.action == SrdSpellTurnAction.bonusAction
            ? true
            : encounter.bonusActionUsed,
        spellSlotExpendedThisTurn:
            encounter.spellSlotExpendedThisTurn ||
            currentAction.expendSpellSlot,
      );
    }

    return SrdSpellTurnStagedResult(
      cast: cast,
      encounter: nextEncounter,
      action: currentAction.action,
    );
  }
}
