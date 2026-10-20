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
  InitiativeRosterGroup(int total, List<InitiativeRosterEntry> entries)
    : total = total,
      entries = List.unmodifiable(entries);

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

  bool get hasUnresolvedTies =>
      groups.any((group) => group.hasUnresolvedTie);

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
}
