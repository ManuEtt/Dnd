import 'dart:convert';

import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_sending_rules.dart';
import 'srd_spell_catalog.dart';
import 'srd_spell_component_rules.dart';
import 'srd_spell_preflight_rules.dart';

/// Narrow, READ-ONLY Sending integration preflight (SRD 5.2.1 / Sending).
///
/// This checks the message recipient and delivery facts *and* the existing
/// class/preparation/action/slot/component rules. It never casts, reserves
/// resources, produces an event, sends a message or grants an effect.
///
/// Unlike ordinary ranged spells, Sending has the spell-specific Unlimited
/// range. The validated recipient plan is the only target confirmation here;
/// generic spatial geometry is intentionally NOT treated as evidence.
class SrdSendingCastPreflightRules {
  const SrdSendingCastPreflightRules._();

  static SrdSendingCastPreview preview(
    HeroCharacter hero, {
    required SrdSpellDefinition spell,
    required String castingClass,
    required int slotLevel,
    required String recipientId,
    required String message,
    required SendingRecipientKnowledge recipientKnowledge,
    required bool recipientIsCreatureConfirmed,
    required SendingBlockStatus blockStatus,
    required SendingPlaneRelation planeRelation,
    int? percentileRoll,
    bool pactMagic = false,
    required bool actionAvailableConfirmed,
    required bool slotTurnLimitConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool materialComponentConfirmed,
    SrdSpellMaterialSource materialSource =
        SrdSpellMaterialSource.specificComponents,
    bool focusUseAuthorizedConfirmed = false,
  }) {
    // The ordinary preflight uses the caller's targetRulesConfirmed flag.
    // Only accept that flag internally after our specific Sending checks.
    // Spell metadata is pinned so a forged catalogue entry cannot erase
    // the required copper-wire V/S/M costs or instant duration.
    if (spell.id != 'spell-sending' ||
        spell.name != 'Sending' ||
        spell.school != 'Divination' ||
        spell.classes.length != 3 ||
        !const {'Bard', 'Cleric', 'Wizard'}.containsAll(spell.classes) ||
        spell.level != 3 ||
        spell.castingTime != 'Action' ||
        spell.range != 'Unlimited' ||
        spell.components != 'V, S, M (a copper wire)' ||
        !spell.verbal ||
        !spell.somatic ||
        !spell.material ||
        spell.concentration ||
        spell.ritual ||
        spell.duration != 'Instantaneous') {
      throw UnsupportedError(
        'Nur die belegte SRD-5.2.1-Sending-Definition ist zulässig.',
      );
    }

    final recipient = SrdSendingRules.prepare(
      spell: spell,
      recipientId: recipientId,
      message: message,
      knowledge: recipientKnowledge,
      recipientIsCreatureConfirmed: recipientIsCreatureConfirmed,
    );
    final resources = SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: castingClass,
      slotLevel: slotLevel,
      pactMagic: pactMagic,
      actionAvailableConfirmed: actionAvailableConfirmed,
      // This follows only from verified Sending-specific recipient facts.
      targetRulesConfirmed: true,
      verbalComponentConfirmed: verbalComponentConfirmed,
      somaticComponentConfirmed: somaticComponentConfirmed,
      materialComponentConfirmed: materialComponentConfirmed,
      materialSource: materialSource,
      focusUseAuthorizedConfirmed: focusUseAuthorizedConfirmed,
      slotTurnLimitConfirmed: slotTurnLimitConfirmed,
    );
    final assessment = SrdSendingRules.assessDelivery(
      recipient,
      blockStatus: blockStatus,
      planeRelation: planeRelation,
      percentileRoll: percentileRoll,
    );
    // A pure dry-run of the current casting rule also checks zero HP,
    // action-limiting conditions and untrained armor. Its hero is discarded.
    final hypothetical = SpellcastingRules.cast(
      hero,
      spellName: resources.preparedName,
      spellLevel: resources.spell.level,
      slotLevel: resources.slotLevel,
      pactMagic: resources.pactMagic,
    );
    final available = pactMagic
        ? SpellcastingRules.availablePactSlots(hypothetical.hero)
        : (SpellcastingRules.availableSlots(
                hypothetical.hero,
              )[resources.slotLevel] ??
              0);
    final remaining = available;
    if (remaining < 0) {
      throw StateError('Kein bestätigter Zauberplatz verfügbar.');
    }
    return SrdSendingCastPreview._(
      resourcePlan: resources,
      recipient: recipient,
      assessment: assessment,
      castingClass: resources.castingClass,
      slotLevel: resources.slotLevel,
      pactMagic: resources.pactMagic,
      remainingSlotsIfCommitted: remaining,
    );
  }

  /// Records the resource cost of an explicitly confirmed Sending attempt.
  ///
  /// This is still a PURE transition: only GameEngine/Controller may persist
  /// its result and event atomically. It does not deliver a message, generate
  /// an answer or turn an unresolved delivery assessment into success.
  static SpellCastResult confirmAttemptResourceUse(
    HeroCharacter hero,
    SrdSendingCastPreview preview, {
    required bool playerConfirmed,
  }) {
    if (!playerConfirmed) {
      throw const FormatException(
        'Der Sending-Zauberversuch muss ausdrücklich bestätigt werden.',
      );
    }
    final plan = preview._resourcePlan;
    if (jsonEncode(hero.toJson()) != plan.sourceSnapshot) {
      throw const FormatException(
        'Der Charakter wurde seit der Sending-Vorschau verändert.',
      );
    }
    return SpellcastingRules.cast(
      hero,
      spellName: plan.preparedName,
      spellLevel: 3,
      slotLevel: plan.slotLevel,
      pactMagic: plan.pactMagic,
    );
  }
}

/// An informational snapshot only: there is deliberately NO method to spend
/// the previewed resource or to send a message.
class SrdSendingCastPreview {
  const SrdSendingCastPreview._({
    required SrdSpellCastPlan resourcePlan,
    required this.recipient,
    required this.assessment,
    required this.castingClass,
    required this.slotLevel,
    required this.pactMagic,
    required this.remainingSlotsIfCommitted,
  }) : _resourcePlan = resourcePlan;

  final SrdSpellCastPlan _resourcePlan;
  final SendingMessagePlan recipient;
  final SendingDeliveryAssessment assessment;
  final String castingClass;
  final int slotLevel;
  final bool pactMagic;

  /// Hypothetical remaining slots; the original hero is NOT changed.
  final int remainingSlotsIfCommitted;
}
