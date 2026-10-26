import 'package:flutter/material.dart';

import 'fantasy_ui.dart';

/// Read-only turn order from a confirmed encounter. An initiative value of
/// zero denotes an unrolled/unknown roll in the existing Encounter schema.
/// Neither turn order nor the next action is advanced by this widget.
class FantasyCombatTurnTracker extends StatelessWidget {
  const FantasyCombatTurnTracker({
    super.key,
    required this.round,
    required this.heroName,
    required this.enemyName,
    required this.heroInitiative,
    required this.enemyInitiative,
    required this.activeParticipant,
    required this.isFinished,
  });

  final int round;
  final String heroName;
  final String enemyName;
  final int heroInitiative;
  final int enemyInitiative;
  final String activeParticipant;
  final bool isFinished;

  bool get hasConfirmedOrder =>
      heroInitiative > 0 &&
      enemyInitiative > 0 &&
      heroInitiative != enemyInitiative;

  bool get heroGoesFirst =>
      hasConfirmedOrder && heroInitiative > enemyInitiative;

  @override
  Widget build(BuildContext context) {
    // When initiatives are unknown or tied, display the active participant
    // first without claiming this is a mechanically confirmed initiative order.
    final heroFirst = hasConfirmedOrder
        ? heroGoesFirst
        : activeParticipant != 'enemy';
    final sides = heroFirst ? [true, false] : [false, true];

    return FantasyPanel(
      key: const ValueKey('combat-turn-tracker'),
      title: 'Runde $round · Zugfolge',
      icon: Icons.account_tree_outlined,
      accent: FantasyPalette.gold,
      material: FantasyPanelMaterial.iron,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasConfirmedOrder) ...[
            Text(
              heroInitiative <= 0 || enemyInitiative <= 0
                  ? 'Initiative noch nicht vollständig bestätigt'
                  : 'Initiative-Gleichstand: aktiver Zug ist maßgeblich',
              style: const TextStyle(color: FantasyPalette.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
          ],
          for (var index = 0; index < sides.length; index++) ...[
            _TurnEntry(
              key: ValueKey(
                sides[index] ? 'combat-turn-hero' : 'combat-turn-enemy',
              ),
              name: sides[index] ? heroName : enemyName,
              hero: sides[index],
              initiative: sides[index] ? heroInitiative : enemyInitiative,
              active:
                  !isFinished &&
                  activeParticipant == (sides[index] ? 'hero' : 'enemy'),
              finished: isFinished,
            ),
            if (index == 0)
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: SizedBox(
                  height: 13,
                  child: VerticalDivider(
                    color: FantasyPalette.gold.withValues(alpha: .5),
                    thickness: 1,
                    width: 1,
                  ),
                ),
              ),
          ],
          if (isFinished) ...[
            const SizedBox(height: 10),
            const Text(
              'Begegnung beendet',
              style: TextStyle(
                color: FantasyPalette.gold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TurnEntry extends StatelessWidget {
  const _TurnEntry({
    super.key,
    required this.name,
    required this.hero,
    required this.initiative,
    required this.active,
    required this.finished,
  });

  final String name;
  final bool hero;
  final int initiative;
  final bool active;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    final accent = hero ? FantasyPalette.gold : FantasyPalette.danger;
    final initiativeLabel = initiative > 0 ? '$initiative' : '?';
    final turnLabel = active ? 'Jetzt am Zug' : 'Nicht am Zug';
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.8;

    final participant = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: largeText ? null : 2,
          overflow: largeText ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          hero ? 'Held' : 'Gegner',
          style: const TextStyle(
            color: FantasyPalette.muted,
            fontSize: 11,
          ),
        ),
      ],
    );
    final initiativeDisplay = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('INI $initiativeLabel'),
        if (active)
          const Text(
            'AM ZUG',
            key: ValueKey('turn-tracker-active-marker'),
            style: TextStyle(
              color: FantasyPalette.gold,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
    final participantIcon = Icon(
      hero ? Icons.person_outline : Icons.shield_outlined,
      color: accent,
      size: 21,
    );

    return Semantics(
      label:
          '${hero ? 'Held' : 'Gegner'}: $name. Initiative '
          '${initiative > 0 ? initiativeLabel : 'unbekannt'}. '
          '${finished ? 'Begegnung beendet' : turnLabel}.',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? accent.withValues(alpha: .18)
                : FantasyPalette.night.withValues(alpha: .65),
            border: Border.all(
              color: accent.withValues(alpha: active ? .88 : .25),
              width: active ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On compact Android screens at 200% text, show complete names
              // first. The initiative and active-turn marker follow below.
              final stackDetails = largeText && constraints.maxWidth < 500;
              if (stackDetails) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        participantIcon,
                        const SizedBox(width: 8),
                        Expanded(child: participant),
                      ],
                    ),
                    const SizedBox(height: 8),
                    initiativeDisplay,
                  ],
                );
              }
              return Row(
                children: [
                  participantIcon,
                  const SizedBox(width: 8),
                  Expanded(child: participant),
                  const SizedBox(width: 5),
                  initiativeDisplay,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
