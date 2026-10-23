import 'srd_spell_catalog.dart';

/// SRD 5.2.1, Spells / Sending (p. 161): a recipient must be a creature
/// personally met by the caster OR described by someone who has met it.
enum SendingRecipientKnowledge {
  unverified,
  personallyMet,
  describedByEyewitness,
}

/// Do not infer an 8-hour spell block from narrative text or an absent
/// game-state flag. Both positive and negative evidence must be confirmed.
enum SendingBlockStatus { unverified, blockedConfirmed, notBlockedConfirmed }

/// The 5% failure chance only applies when planes are CONFIRMED different.
enum SendingPlaneRelation {
  unverified,
  samePlaneConfirmed,
  differentPlaneConfirmed,
}

enum SendingDeliveryOutcome {
  unresolved,
  blocked,
  planarFailure,
  deliverable,
}

/// Read-only candidate. This is not a spell action or permission to subtract
/// slots, transmit chat messages, invent recipient knowledge or record events.
class SendingMessagePlan {
  const SendingMessagePlan._({
    required this.recipientId,
    required this.message,
    required this.wordCount,
    required this.recipientKnowledge,
  });

  final String recipientId;
  final String message;
  final int wordCount;
  final SendingRecipientKnowledge recipientKnowledge;
}

class SendingDeliveryAssessment {
  const SendingDeliveryAssessment._(this.outcome, this.percentileRoll);

  final SendingDeliveryOutcome outcome;
  final int? percentileRoll;
}

/// A narrow, auditable Sending validator and outcome *preview*.
/// Other spells with 'Unlimited' or 'Special' remain unsupported by the
/// generic target engine, and this code never produces a magical effect.
class SrdSendingRules {
  const SrdSendingRules._();

  static SendingMessagePlan prepare({
    required SrdSpellDefinition spell,
    required String recipientId,
    required String message,
    required SendingRecipientKnowledge knowledge,
    required bool recipientIsCreatureConfirmed,
  }) {
    if (spell.name != 'Sending' ||
        spell.level != 3 ||
        spell.range != 'Unlimited' ||
        spell.castingTime != 'Action' ||
        spell.concentration) {
      throw UnsupportedError(
        'Nur der konkret bestätigte SRD-Zauber Sending wird unterstützt.',
      );
    }
    final id = recipientId.trim();
    if (id.isEmpty || id.length > 160) {
      throw const FormatException(
        'Eine eindeutige bestätigte Empfängerkennung ist erforderlich.',
      );
    }
    if (!recipientIsCreatureConfirmed ||
        knowledge == SendingRecipientKnowledge.unverified) {
      throw const FormatException(
        'Sending benötigt eine bestätigte Kreatur, die du getroffen hast '
        'oder die von einem Zeugen beschrieben wurde.',
      );
    }
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Sending benötigt eine Nachricht.');
    }
    // Deliberate whitespace-token interpretation. No translation or
    // free-form AI rewrite is permitted to add words after confirmation.
    final count = trimmed.split(RegExp(r'\s+')).length;
    if (count > 25) {
      throw const FormatException(
        'Eine Sending-Nachricht darf höchstens 25 Wörter enthalten.',
      );
    }
    return SendingMessagePlan._(
      recipientId: id,
      message: trimmed,
      wordCount: count,
      recipientKnowledge: knowledge,
    );
  }

  /// Preview only; an actual cast would separately validate class, spell
  /// preparation, slot, components, action economy and revision/commit.
  /// The caller supplies an auditable percentile result (1..100) ONLY for
  /// confirmed different planes. 1–5 fail; 6–100 are deliverable.
  /// Unknown block/plane status is NOT secretly assumed favorable.
  static SendingDeliveryAssessment assessDelivery(
    SendingMessagePlan plan, {
    required SendingBlockStatus blockStatus,
    required SendingPlaneRelation planeRelation,
    int? percentileRoll,
  }) {
    if (plan.wordCount < 1 || plan.wordCount > 25) {
      throw const FormatException('Ungültiger Sending-Plan.');
    }
    if (blockStatus == SendingBlockStatus.blockedConfirmed) {
      if (percentileRoll != null) {
        throw const FormatException(
          'Bei einer bekannten Blockade darf kein Ebenenwurf erfolgen.',
        );
      }
      return const SendingDeliveryAssessment._(
        SendingDeliveryOutcome.blocked,
        null,
      );
    }
    if (blockStatus == SendingBlockStatus.unverified ||
        planeRelation == SendingPlaneRelation.unverified) {
      if (percentileRoll != null) {
        throw const FormatException(
          'Unbestätigte Ebenen oder Blockaden erlauben keinen Zufallswurf.',
        );
      }
      return const SendingDeliveryAssessment._(
        SendingDeliveryOutcome.unresolved,
        null,
      );
    }
    if (planeRelation == SendingPlaneRelation.samePlaneConfirmed) {
      if (percentileRoll != null) {
        throw const FormatException(
          'Auf derselben Ebene ist kein Sending-Ebenenwurf zulässig.',
        );
      }
      return const SendingDeliveryAssessment._(
        SendingDeliveryOutcome.deliverable,
        null,
      );
    }
    if (percentileRoll == null ||
        percentileRoll < 1 ||
        percentileRoll > 100) {
      throw const FormatException(
        'Für bestätigte verschiedene Ebenen ist ein W100-Wurf erforderlich.',
      );
    }
    return SendingDeliveryAssessment._(
      percentileRoll <= 5
          ? SendingDeliveryOutcome.planarFailure
          : SendingDeliveryOutcome.deliverable,
      percentileRoll,
    );
  }
}
