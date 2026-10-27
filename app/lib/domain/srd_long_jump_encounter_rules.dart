import 'condition_rules.dart';
import 'cover_rules.dart';
import 'models.dart';
import 'srd_long_jump_rules.dart';

/// The uncommitted output of a confirmed SRD-5.2.1 Long Jump.
/// 
/// This is deliberately NOT a GameUpdate. No event, revision increment, or
/// SQLite transaction happens until the central engine/controller commits it.
class SrdLongJumpEncounterPlan {
  const SrdLongJumpEncounterPlan({
    required this.projectedCampaign,
    required this.assessment,
    required this.expectedRevision,
    required this.movementSpentDecimeters,
    required this.addsProne,
  });

  final Campaign projectedCampaign;
  final SrdLongJumpAssessment assessment;
  final int expectedRevision;
  final int movementSpentDecimeters;
  final bool addsProne;
}

/// Prepares the *single* candidate combat-state transition for a Long Jump.
///
/// The caller must independently establish the run-up's movement ledger,
/// authoritative d20 totals, event uniqueness, and atomic SQLite revision
/// check before committing this projection. A projection may be discarded.
class SrdLongJumpEncounterRules {
  const SrdLongJumpEncounterRules._();

  static SrdLongJumpEncounterPlan prepare({
    required Campaign campaign,
    required String expectedCampaignId,
    required String expectedEncounterId,
    required int expectedRevision,
    required int immediateRunUpFeet,
    required bool runUpAlreadySpentConfirmed,
    required int jumpDistanceCentimeters,
    required bool? landingInDifficultTerrainConfirmed,
    required bool obstacleFreePathConfirmed,
    int? lowObstacleHeightCentimeters,
    bool? dmRequiresAthleticsCheck,
    int? confirmedLandingAcrobaticsTotal,
    int? confirmedObstacleAthleticsTotal,
  }) {
    if (campaign.id != expectedCampaignId ||
        campaign.revision != expectedRevision ||
        expectedRevision < 0) {
      throw const FormatException(
        'Die Kampagnenkennung oder Revision ist nicht mehr aktuell.',
      );
    }
    final encounter = campaign.encounter;
    if (encounter == null ||
        encounter.id != expectedEncounterId ||
        encounter.isFinished ||
        encounter.activeParticipant != 'hero') {
      throw const FormatException(
        'Ein eigener aktiver Kampfzug muss bestätigt sein.',
      );
    }
    if (campaign.pendingRoll != null ||
        campaign.pendingDeathSave != null ||
        campaign.pendingEnemyShieldHit != null ||
        campaign.pendingOpportunityAttack != null) {
      throw const FormatException(
        'Ein offener Regelvorgang muss vor dem Sprung beendet werden.',
      );
    }
    final hero = campaign.hero;
    if (!ConditionRules.canMove(hero) ||
        hero.conditions.contains('liegend')) {
      throw const FormatException(
        'Der aktuelle Zustand verhindert diesen Weitsprung.',
      );
    }
    if (encounter.jumpDoubledThisTurn) {
      throw UnsupportedError(
        'Für aktive Sprungweitenboni fehlt eine gesonderte Bestätigung.',
      );
    }
    if (immediateRunUpFeet < 0 ||
        runUpAlreadySpentConfirmed != (immediateRunUpFeet > 0)) {
      throw const FormatException(
        'Ein Anlauf darf nur als bereits bezahlt bestätigt werden.',
      );
    }
    if (encounter.movementRemaining < 0 ||
        encounter.movementRemainderDecimeters < 0 ||
        encounter.movementRemainderDecimeters > 9) {
      throw const FormatException('Ungültiges Restbewegungsbudget.');
    }
    if (jumpDistanceCentimeters % 10 != 0) {
      throw const FormatException(
        'Die gespeicherte Bewegung unterstützt nur volle 10 Zentimeter. '
        'Eine halbe Fußstrecke benötigt zuerst höhere Speicherpräzision.',
      );
    }

    final assessment = SrdLongJumpRules.preflight(
      strengthScore: hero.abilities['strength'],
      runUpFeet: immediateRunUpFeet,
      immediateRunUpConfirmed: immediateRunUpFeet > 0,
      jumpDistanceCentimeters: jumpDistanceCentimeters,
      movementRemainingCentimeters:
          encounter.remainingMovementDecimeters * 10,
      landingInDifficultTerrainConfirmed:
          landingInDifficultTerrainConfirmed,
      obstacleFreePathConfirmed: obstacleFreePathConfirmed,
      lowObstacleHeightCentimeters: lowObstacleHeightCentimeters,
      dmRequiresAthleticsCheck: dmRequiresAthleticsCheck,
      confirmedLandingAcrobaticsTotal: confirmedLandingAcrobaticsTotal,
      confirmedObstacleAthleticsTotal: confirmedObstacleAthleticsTotal,
    );
    if (!assessment.readyForConfirmation) {
      throw const FormatException(
        'Die Landung oder eine Hindernisprobe ist noch nicht bestätigt '
        'oder das Hindernis wurde nicht überwunden.',
      );
    }

    final movementSpentDecimeters = jumpDistanceCentimeters ~/ 10;
    final afterDecimeters =
        encounter.remainingMovementDecimeters - movementSpentDecimeters;
    final updatedEncounter = encounter.copyWith(
      movementRemaining: afterDecimeters ~/ 10,
      movementRemainderDecimeters: afterDecimeters % 10,
      heroCover: CoverLevel.none,
    );
    final addsProne =
        assessment.wouldLandProne == true &&
        !hero.manualConditions.contains('liegend');
    final updatedHero = addsProne
        ? hero.copyWith(conditions: [...hero.manualConditions, 'liegend'])
        : hero;

    return SrdLongJumpEncounterPlan(
      projectedCampaign: campaign.copyWith(
        hero: updatedHero,
        encounter: updatedEncounter,
      ),
      assessment: assessment,
      expectedRevision: expectedRevision,
      movementSpentDecimeters: movementSpentDecimeters,
      addsProne: addsProne,
    );
  }
}
