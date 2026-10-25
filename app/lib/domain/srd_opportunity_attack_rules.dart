import 'condition_rules.dart';
import 'models.dart';
import 'srd_equipment_catalog.dart';

/// SRD 5.2.1, Playing the Game, p. 15, Opportunity Attacks.
/// Teleportation, forced movement and Disengage never provoke this attack.
enum OpportunityMovement { ordinary, disengage, teleport, forced }

/// Only the SRD melee-weapon attack or Unarmed Strike is allowed.
enum OpportunityStrike { equippedMeleeWeapon, unarmedStrike }

/// Explicit facts from a confirmed enemy movement segment. Narrative text is
/// not proof of reach, visibility, Disengage, or the player's consent.
class ConfirmedOpportunityTrigger {
  const ConfirmedOpportunityTrigger({
    required this.encounterId,
    required this.beforeDistanceFeet,
    required this.afterDistanceFeet,
    required this.reachFeet,
    required this.targetVisibleConfirmed,
    required this.playerAuthorizedReaction,
    required this.movement,
    required this.strike,
    this.weaponId = '',
  });

  final String encounterId;
  final int beforeDistanceFeet, afterDistanceFeet, reachFeet;
  final bool targetVisibleConfirmed, playerAuthorizedReaction;
  final OpportunityMovement movement;
  final OpportunityStrike strike;
  final String weaponId;
}

/// Read-only permission to offer a reaction. This is NOT a completed attack,
/// a damage roll, or a consumed reaction. The eventual controller must recheck
/// campaign.revision and encounter.reactionUsed in the same saved transaction.
class OpportunityAttackOffer {
  const OpportunityAttackOffer({
    required this.encounterId,
    required this.revision,
    required this.strike,
    required this.weaponId,
    required this.beforeDistanceFeet,
    required this.afterDistanceFeet,
    required this.reachFeet,
  });

  final String encounterId;
  final int revision;
  final OpportunityStrike strike;
  final String weaponId;

  /// The exact confirmed movement geometry this offer was issued for.
  final int beforeDistanceFeet, afterDistanceFeet, reachFeet;
}

/// Fail-closed opportunity-attack preflight, without changes to save formats.
/// No positions, reach, abilities or monster facts are inferred from the story.
class SrdOpportunityAttackRules {
  const SrdOpportunityAttackRules._();

  /// Rejects stale or substituted offers before a later confirmed action.
  /// This is read-only: callers must repeat the check in their atomic
  /// controller/repository transaction before spending a reaction.
  static OpportunityAttackOffer revalidate(
    Campaign campaign,
    ConfirmedOpportunityTrigger trigger,
    OpportunityAttackOffer offer,
  ) {
    if (campaign.revision != offer.revision ||
        campaign.encounter?.id != offer.encounterId ||
        trigger.encounterId != offer.encounterId ||
        trigger.strike != offer.strike ||
        trigger.weaponId != offer.weaponId ||
        trigger.beforeDistanceFeet != offer.beforeDistanceFeet ||
        trigger.afterDistanceFeet != offer.afterDistanceFeet ||
        trigger.reachFeet != offer.reachFeet) {
      throw const FormatException(
        'Das Gelegenheitsangriff-Angebot ist veraltet oder verändert.',
      );
    }

    return prepare(campaign, trigger);
  }

  static OpportunityAttackOffer prepare(
    Campaign campaign,
    ConfirmedOpportunityTrigger trigger,
  ) {
    final fight = campaign.encounter;
    final hero = campaign.hero;
    if (fight == null ||
        fight.isFinished ||
        fight.id != trigger.encounterId ||
        fight.activeParticipant != 'enemy' ||
        fight.reactionUsed ||
        campaign.pendingOpportunityAttack != null ||
        campaign.pendingRoll != null ||
        campaign.pendingDeathSave != null ||
        campaign.pendingEnemyShieldHit != null ||
        !hero.isComplete ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        !ConditionRules.canTakeActions(hero) ||
        !trigger.targetVisibleConfirmed ||
        !trigger.playerAuthorizedReaction ||
        trigger.movement != OpportunityMovement.ordinary ||
        trigger.reachFeet <= 0 ||
        trigger.beforeDistanceFeet < 0 ||
        trigger.afterDistanceFeet < 0 ||
        trigger.beforeDistanceFeet > trigger.reachFeet ||
        trigger.afterDistanceFeet <= trigger.reachFeet) {
      throw const FormatException(
        'Gelegenheitsangriff nur bei bestätigtem sichtbarem Verlassen '
        'der Reichweite, freier Reaktion und eigener Zustimmung.',
      );
    }

    if (trigger.strike == OpportunityStrike.equippedMeleeWeapon) {
      final matches = hero.inventory.where(
        (item) =>
            item.id == trigger.weaponId &&
            item.id == hero.equippedWeaponId &&
            item.quantity > 0,
      );
      if (trigger.weaponId.isEmpty || matches.length != 1) {
        throw const FormatException(
          'Die tatsächlich geführte Nahkampfwaffe muss eindeutig bestätigt sein.',
        );
      }
      final weapon = SrdEquipmentCatalog.byId(matches.single.catalogId);
      if (weapon == null ||
          (weapon.category != EquipmentCategory.simpleMelee &&
              weapon.category != EquipmentCategory.martialMelee)) {
        throw const FormatException(
          'Unbekannte oder Fernkampfwaffen sind nicht als Nahkampf bestätigt.',
        );
      }
    } else if (trigger.weaponId.isNotEmpty) {
      throw const FormatException(
        'Ein waffenloser Schlag darf keine Waffenreferenz enthalten.',
      );
    }

    return OpportunityAttackOffer(
      encounterId: fight.id,
      revision: campaign.revision,
      strike: trigger.strike,
      weaponId: trigger.weaponId,
      beforeDistanceFeet: trigger.beforeDistanceFeet,
      afterDistanceFeet: trigger.afterDistanceFeet,
      reachFeet: trigger.reachFeet,
    );
  }
}
