import 'models.dart';
import 'srd_magic_missile_multi_target_rules.dart';
import 'srd_magic_missile_volley_damage_rules.dart';

/// Immutable preview of damage to one CONFIRMED encounter creature.
/// This is not an applied hit point change, event, or monster turn.
class SrdMissileHitPointPreview {
  const SrdMissileHitPointPreview({
    required this.targetId,
    required this.targetName,
    required this.hitPointsBefore,
    required this.hitPointsAfter,
    required this.appliedDamage,
    required this.primaryOpponent,
  });

  final String targetId, targetName;
  final int hitPointsBefore, hitPointsAfter, appliedDamage;
  final bool primaryOpponent;
}

/// Read-only snapshot bound to a specific campaign revision and encounter.
///
/// A defeated primary opponent with living tracked creatures requires a
/// separately designed multi-actor victory/turn resolution. Do not convert
/// this result into a legacy encounter completion automatically.
class SrdMagicMissileEncounterHpPreview {
  SrdMagicMissileEncounterHpPreview._({
    required this.encounterId,
    required this.expectedRevision,
    required List<SrdMissileHitPointPreview> targets,
    required this.primaryDefeated,
    required this.livingTrackedCreaturesRemain,
  }) : targets = List.unmodifiable(targets);

  final String encounterId;
  final int expectedRevision;
  final List<SrdMissileHitPointPreview> targets;
  final bool primaryDefeated;
  final bool livingTrackedCreaturesRemain;

  bool get requiresMultiActorVictoryResolution =>
      primaryDefeated && livingTrackedCreaturesRemain;

  int? remainingHitPoints(String targetId) {
    for (final target in targets) {
      if (target.targetId == targetId) return target.hitPointsAfter;
    }
    return null;
  }
}

/// SRD 5.2.1 Magic Missile (p. 146), CC BY 4.0.
///
/// Binds one already validated allocation and damage volley to exactly those
/// creatures tracked in the CURRENT campaign and encounter. Explicit target
/// identities are used; names and narration never resolve combat identities.
///
/// No resource spending, dice, mutation, event, revision increment, victory,
/// or persistence occurs here. GameEngine/Controller must still check action
/// economy and atomically commit the resulting rule decision.
class SrdMagicMissileEncounterHpRules {
  const SrdMagicMissileEncounterHpRules._();

  static SrdMagicMissileEncounterHpPreview preview({
    required Campaign campaign,
    required String encounterId,
    required int expectedRevision,
    required bool currentTargetEvidenceConfirmed,
    required SrdMagicMissileAllocation allocation,
    required SrdMagicMissileVolleyDamage damage,
  }) {
    final fight = campaign.encounter;
    if (!currentTargetEvidenceConfirmed ||
        expectedRevision != campaign.revision ||
        encounterId.isEmpty ||
        fight == null ||
        fight.id != encounterId ||
        fight.isFinished ||
        fight.activeParticipant != 'hero' ||
        campaign.pendingRoll != null ||
        campaign.pendingDeathSave != null ||
        campaign.pendingEnemyShieldHit != null ||
        campaign.pendingOpportunityAttack != null ||
        campaign.pendingSavageAttackerHit != null) {
      throw const FormatException(
        'Mehrziel-Trefferpunkte benötigen einen aktuellen, freien Kampfzustand.',
      );
    }
    if (allocation.slotLevel != damage.slotLevel ||
        allocation.dartCount != damage.dartCount ||
        allocation.dartTargetIds.length != damage.darts.length ||
        allocation.dartsPerTarget.length != damage.appliedPerTarget.length ||
        allocation.dartsPerTarget.keys.toSet().difference(
          damage.appliedPerTarget.keys.toSet(),
        ).isNotEmpty) {
      throw const FormatException(
        'Zauberplatz, Geschossverteilung und Schadensziele widersprechen sich.',
      );
    }
    for (var i = 0; i < damage.darts.length; i++) {
      if (allocation.dartTargetIds[i] != damage.darts[i].targetId) {
        throw const FormatException(
          'Der Schaden gehört zu einer anderen Geschossverteilung.',
        );
      }
    }

    // A main encounter opponent and a tracked creature must never share an ID.
    // The supplementary list is not guaranteed valid until a save is checked.
    final byId = <String, TrackedAreaCreature>{};
    for (final creature in campaign.trackedAreaCreatures) {
      if (creature.id == fight.id || byId.containsKey(creature.id)) {
        throw const FormatException('Doppelte Gegneridentität im Spielstand.');
      }
      if (creature.hitPoints < 0 ||
          creature.maxHitPoints < 1 ||
          creature.hitPoints > creature.maxHitPoints) {
        throw const FormatException('Ungültige Trefferpunkte im Spielstand.');
      }
      byId[creature.id] = creature;
    }
    if (fight.enemyHitPoints < 1 ||
        fight.enemyHitPoints > fight.enemyMaxHitPoints) {
      throw const FormatException('Ungültige Gegner-Trefferpunkte.');
    }

    final results = <SrdMissileHitPointPreview>[];
    for (final id in allocation.dartsPerTarget.keys) {
      final primary = id == fight.id;
      final creature = byId[id];
      if (!primary && creature == null) {
        throw const FormatException(
          'Geschossziel ist nicht als lebende Kreatur gespeichert.',
        );
      }
      final before = primary ? fight.enemyHitPoints : creature!.hitPoints;
      final maxHp = primary ? fight.enemyMaxHitPoints : creature!.maxHitPoints;
      if (before < 1 || before > maxHp) {
        throw const FormatException(
          'Bereits besiegte oder unbestätigte Kreatur ist kein gültiges Ziel.',
        );
      }
      final amount = damage.appliedPerTarget[id];
      if (amount == null || amount < 0) {
        throw const FormatException(
          'Für das Ziel fehlt der gültige Energieschaden.',
        );
      }
      results.add(
        SrdMissileHitPointPreview(
          targetId: id,
          targetName: primary ? fight.enemyName : creature!.name,
          hitPointsBefore: before,
          hitPointsAfter: amount >= before ? 0 : before - amount,
          appliedDamage: amount,
          primaryOpponent: primary,
        ),
      );
    }
    final primaryResult = results.where((hit) => hit.primaryOpponent);
    final primaryRemaining = primaryResult.isEmpty
        ? fight.enemyHitPoints
        : primaryResult.single.hitPointsAfter;
    final remaining = <String, int>{
      for (final creature in campaign.trackedAreaCreatures)
        creature.id: creature.hitPoints,
      for (final hit in results)
        if (!hit.primaryOpponent) hit.targetId: hit.hitPointsAfter,
    };
    return SrdMagicMissileEncounterHpPreview._(
      encounterId: encounterId,
      expectedRevision: expectedRevision,
      targets: results,
      primaryDefeated: primaryRemaining == 0,
      livingTrackedCreaturesRemain: remaining.values.any((hp) => hp > 0),
    );
  }
}
