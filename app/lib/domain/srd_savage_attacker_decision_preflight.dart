import 'models.dart';
import 'srd_savage_attacker_damage_comparison.dart';

/// A validated *preview* of one explicit Savage Attacker decision.
///
/// It is NOT proof that an attack occurred and is NOT a committed hit. A
/// trusted attack flow must establish the evidence before a controller may
/// apply damage or spend the feat in a revision-checked transaction.
class SavageAttackerDecisionPreview {
  const SavageAttackerDecisionPreview({
    required this.attackRollId,
    required this.encounterId,
    required this.expectedRevision,
    required this.chooseAlternative,
    required this.damageComparison,
  });

  final String attackRollId;
  final String encounterId;
  final int expectedRevision;
  final bool chooseAlternative;
  final SavageAttackerDamageComparison damageComparison;

  int get originalWeaponSubtotal => damageComparison.originalWeaponSubtotal;
  int get alternativeWeaponSubtotal =>
      damageComparison.alternativeWeaponSubtotal;
  int get selectedWeaponSubtotal => damageComparison.selectedWeaponSubtotal;
  int get weaponDamageDelta => damageComparison.selectedDifference;
}

/// Maps the UI's identity-only request to the *stored* pending dice evidence.
///
/// Critically, no dice, modifiers or damage numbers are accepted from the UI.
/// A stale, mismatched or previously spent request can never produce a preview.
class SrdSavageAttackerDecisionPreflight {
  const SrdSavageAttackerDecisionPreflight._();

  static SavageAttackerDecisionPreview preview({
    required Campaign campaign,
    required String attackRollId,
    required String encounterId,
    required int expectedRevision,
    required bool chooseAlternative,
  }) {
    final pending = campaign.pendingSavageAttackerHit;
    final fight = campaign.encounter;
    if (pending == null ||
        fight == null ||
        campaign.revision != expectedRevision ||
        pending.offeredAtRevision != expectedRevision ||
        pending.attackRollId != attackRollId ||
        pending.encounterId != encounterId ||
        fight.id != encounterId ||
        campaign.pendingRoll != null ||
        campaign.pendingDeathSave != null ||
        campaign.pendingEnemyShieldHit != null ||
        campaign.pendingOpportunityAttack != null ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(attackRollId) ||
        !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(encounterId)) {
      throw const FormatException(
        'Die Wilder-Angreifer-Entscheidung ist nicht mehr gültig.',
      );
    }

    // The stored JSON proposal must independently satisfy its strict source
    // checks; the selection widget's claimed validity is not authoritative.
    pending.validateAgainst(
      hero: campaign.hero,
      encounter: fight,
      revision: campaign.revision,
    );

    final compared = SrdSavageAttackerDamageComparisonRules.compare(
      hero: campaign.hero,
      encounter: fight,
      weaponDamageExpression: pending.weaponDamageExpression,
      original: pending.original,
      alternative: pending.alternative,
      confirmedWeaponHit: true,
      confirmedWeaponAttack: true,
      chooseAlternative: chooseAlternative,
      critical: pending.critical,
      originalCriticalExtra: pending.originalCriticalExtra,
      alternativeCriticalExtra: pending.alternativeCriticalExtra,
    );

    return SavageAttackerDecisionPreview(
      attackRollId: pending.attackRollId,
      encounterId: pending.encounterId,
      expectedRevision: campaign.revision,
      chooseAlternative: chooseAlternative,
      damageComparison: compared,
    );
  }
}
