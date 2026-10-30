import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../story/npc_story_selection.dart';

/// An explicit, accessible choice of one confirmed NPC identity.
///
/// Display names can be equal; only the saved ID is returned. No choice is
/// made from free-text player actions, inferred relationships or AI prose.
Future<NpcStorySelection?> showNpcStorySelectionDialog(
  BuildContext context,
  Campaign campaign,
) {
  final eligible = [
    for (final npc in campaign.npcs)
      if (campaign.npcs.where((item) => item.id == npc.id).length == 1 &&
          campaign.npcRelationshipNotes.any((note) => note.npcId == npc.id))
        npc,
  ];
  return showDialog<NpcStorySelection>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      // Scroll lengthy identity descriptions on short Android viewports.
      // The cancel action stays outside the scroll area.
      scrollable: true,
      title: const Text('Gesprächspartner auswählen'),
      content: SizedBox(
        width: 420,
        child: eligible.isEmpty
            ? const Text(
                'Noch keine bestätigten NPC-Erinnerungen vorhanden. '
                'Halte zuerst eine NPC-Beziehung im Tagebuch fest.',
                key: ValueKey('npc-picker-empty'),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Wähle die richtige Figur. Bei gleichen Namen unterscheidet '
                    'die gespeicherte Kennung die Personen.',
                  ),
                  const SizedBox(height: 12),
                  // The AlertDialog is the only scrolling viewport. A
                  // shrink-wrapped ListView here triggers intrinsic-height
                  // assertions and leaves the nested list off-screen.
                  Column(
                    key: const ValueKey('npc-picker-list'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final npc in eligible)
                        Semantics(
                          label:
                              '${npc.name}, Beziehung: ${npc.relationship}, '
                              'Kennung ${npc.id}',
                          button: true,
                          child: ListTile(
                            key: ValueKey('npc-picker-${npc.id}'),
                            leading: const Icon(Icons.person_outline),
                            title: Text(npc.name),
                            subtitle: Text(
                              'Beziehung: ${npc.relationship} · '
                              'Kennung: ${npc.id}',
                            ),
                            onTap: () => Navigator.of(
                              dialogContext,
                            ).pop(NpcStorySelection.choose(campaign, npc.id)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('npc-picker-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Abbrechen'),
        ),
      ],
    ),
  );
}
