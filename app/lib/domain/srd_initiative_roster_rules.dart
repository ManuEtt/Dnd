import 'models.dart';

/// A displayed initiative entry, NOT permission to take a combat turn.
class InitiativeRosterEntry {
  const InitiativeRosterEntry({
    required this.id,
    required this.name,
    required this.total,
    required this.controller,
    required this.kind,
  });

  final String id, name, controller, kind;
  final int total;
}

class InitiativeRosterGroup {
  InitiativeRosterGroup(this.total, List<InitiativeRosterEntry> entries)
    : entries = List.unmodifiable(entries);

  final int total;

  /// A group is unordered if its size is >1; the controlling players/GM
  /// must resolve SRD 5.2.1 ties, rather than using a hidden ID tiebreaker.
  final List<InitiativeRosterEntry> entries;
  bool get hasUnresolvedTie => entries.length > 1;
}

class InitiativeRoster {
  InitiativeRoster({
    required List<InitiativeRosterGroup> groups,
    required List<TrackedAreaCreature> missing,
    required this.baseInitiativeConfirmed,
  }) : groups = List.unmodifiable(groups),
       missing = List.unmodifiable(missing);

  final List<InitiativeRosterGroup> groups;
  final List<TrackedAreaCreature> missing;
  final bool baseInitiativeConfirmed;

  bool get hasUnresolvedTies => groups.any((group) => group.hasUnresolvedTie);

  /// Only a preview. Even a ready list never activates autonomous turns.
  bool get readyForManualAdjudication =>
      baseInitiativeConfirmed && missing.isEmpty && !hasUnresolvedTies;
}

/// SRD 5.2.1 initiative: descending check totals, with ties explicitly
/// chosen by the GM / players. An identical-monster group can share a roll.
/// The initiative roster is advisory while the one-foe engine remains active.
class SrdInitiativeRosterRules {
  const SrdInitiativeRosterRules._();

  static InitiativeRoster preview(
    Campaign campaign, {
    required bool baseInitiativeConfirmed,
  }) {
    final encounter = campaign.encounter;
    if (encounter == null || encounter.isFinished) {
      throw const FormatException('Kein laufender Kampf für die Initiative.');
    }
    final entries = <InitiativeRosterEntry>[
      InitiativeRosterEntry(
        id: campaign.hero.id,
        name: campaign.hero.name,
        total: encounter.heroInitiative,
        controller: 'player',
        kind: 'hero',
      ),
      InitiativeRosterEntry(
        id: encounter.id,
        name: encounter.enemyName,
        total: encounter.enemyInitiative,
        controller: 'gm',
        kind: 'mainFoe',
      ),
    ];
    final missing = <TrackedAreaCreature>[];
    for (final creature in campaign.trackedAreaCreatures) {
      // Defeated creatures have no future initiative turns.
      if (creature.hitPoints <= 0) continue;
      if (creature.initiativeTotal == null ||
          creature.initiativeController == null) {
        missing.add(creature);
      } else {
        entries.add(
          InitiativeRosterEntry(
            id: creature.id,
            name: creature.name,
            total: creature.initiativeTotal!,
            controller: creature.initiativeController!,
            kind: 'additional',
          ),
        );
      }
    }
    // The source roster can contain an explicit confirmed group tie.
    // Sorting groups is fine, sorting tied actors is NOT adjudication.
    final totals = entries.map((entry) => entry.total).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    final groups = [
      for (final total in totals)
        InitiativeRosterGroup(
          total,
          entries.where((entry) => entry.total == total).toList(),
        ),
    ];
    return InitiativeRoster(
      groups: groups,
      missing: missing,
      baseInitiativeConfirmed: baseInitiativeConfirmed,
    );
  }

  /// A separate manual sequence deliberately does not control Encounter
  /// actions. Order is explicit: ties cannot be silently resolved.
  static ManualCombatTurnQueue createManualQueue(
    Campaign campaign, {
    required List<String> orderedActorIds,
    required bool baseInitiativeConfirmed,
    required bool tiedOrderConfirmed,
  }) {
    final roster = preview(
      campaign,
      baseInitiativeConfirmed: baseInitiativeConfirmed,
    );
    final fight = campaign.encounter!;
    if (!baseInitiativeConfirmed ||
        roster.missing.isNotEmpty ||
        (roster.hasUnresolvedTies && !tiedOrderConfirmed)) {
      throw const FormatException(
        'Vor dem Speichern alle Initiativen und jede Reihenfolge '
        'bei Gleichstand ausdrücklich bestätigen.',
      );
    }
    final expected = [
      for (final group in roster.groups)
        for (final actor in group.entries) actor.id,
    ];
    if (orderedActorIds.length != expected.length ||
        orderedActorIds.toSet().length != expected.length ||
        orderedActorIds.toSet().difference(expected.toSet()).isNotEmpty) {
      throw const FormatException(
        'Jeder lebende Akteur muss genau einmal in der Zugfolge stehen.',
      );
    }
    final totals = {
      for (final group in roster.groups)
        for (final actor in group.entries) actor.id: actor.total,
    };
    for (var i = 1; i < orderedActorIds.length; i++) {
      if (totals[orderedActorIds[i - 1]]! <
          totals[orderedActorIds[i]]!) {
        throw const FormatException(
          'Initiativen müssen absteigend sortiert sein; '
          'nur Gleichstände dürfen vertauscht werden.',
        );
      }
    }
    return ManualCombatTurnQueue(
      encounterId: fight.id,
      actorIds: orderedActorIds,
      activeIndex: 0,
      round: 1,
    );
  }

  static bool isCurrent(
    Campaign campaign,
    ManualCombatTurnQueue queue,
  ) {
    final fight = campaign.encounter;
    if (fight == null ||
        fight.isFinished ||
        fight.id != queue.encounterId) {
      return false;
    }
    final roster = preview(campaign, baseInitiativeConfirmed: true);
    if (roster.missing.isNotEmpty) return false;
    final living = {
      for (final group in roster.groups)
        for (final actor in group.entries) actor.id: actor.total,
    };
    final present = queue.actorIds.where(living.containsKey).toList();
    if (present.length != living.length ||
        present.toSet().length != living.length) {
      return false;
    }
    for (var i = 1; i < present.length; i++) {
      if (living[present[i - 1]]! < living[present[i]]!) return false;
    }
    return true;
  }

  /// Move only the advisory marker. A dead tracked area creature is skipped.
  /// Real actor action economy is intentionally left to legacy combat.
  static ManualCombatTurnQueue nextManualActor(
    Campaign campaign,
    ManualCombatTurnQueue queue,
  ) {
    if (!isCurrent(campaign, queue)) {
      throw const FormatException(
        'Manuelle Zugfolge ist nach Kampf-/Initiativänderungen '
        'nicht mehr aktuell. Bitte neu festlegen.',
      );
    }
    final livingIds = <String>{
      campaign.hero.id,
      campaign.encounter!.id,
      for (final creature in campaign.trackedAreaCreatures)
        if (creature.hitPoints > 0) creature.id,
    };
    for (var step = 1; step <= queue.actorIds.length; step++) {
      final candidate = (queue.activeIndex + step) % queue.actorIds.length;
      if (livingIds.contains(queue.actorIds[candidate])) {
        final nextRound =
            queue.round + (candidate <= queue.activeIndex ? 1 : 0);
        if (nextRound > 1000000) {
          throw const FormatException('Maximale manuelle Rundenzahl erreicht.');
        }
        return queue.copyWith(activeIndex: candidate, round: nextRound);
      }
    }
    throw const FormatException('Keine lebenden Akteure in der Zugfolge.');
  }
}
