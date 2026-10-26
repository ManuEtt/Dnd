import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../services/game_controller.dart';
import 'fantasy_ui.dart';
import 'fantasy_buttons.dart';

/// Editable, confirmed campaign notes. Never calls a narrator or changes rules.
class CampaignMemoryPanel extends StatelessWidget {
  const CampaignMemoryPanel({super.key, required this.controller});

  final GameController controller;

  Future<void> _newThread(BuildContext context, {StoryThread? existing}) async {
    var title = existing?.title ?? '';
    var description = existing?.description ?? '';
    var status = existing?.status ?? 'open';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null
                ? 'Handlungsstrang anlegen'
                : 'Handlungsstrang bearbeiten',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const ValueKey('story-thread-title'),
                  initialValue: title,
                  onChanged: (value) => title = value,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'Titel'),
                ),
                TextFormField(
                  key: const ValueKey('story-thread-description'),
                  initialValue: description,
                  onChanged: (value) => description = value,
                  maxLength: 1000,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Was ist daran noch offen?',
                  ),
                ),
                DropdownButtonFormField<String>(
                  key: const ValueKey('story-thread-status'),
                  initialValue: status,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Offen')),
                    DropdownMenuItem(value: 'resolved', child: Text('Gelöst')),
                    DropdownMenuItem(
                      value: 'abandoned',
                      child: Text('Aufgegeben'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => status = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            FantasyTextButton(
              label: 'Abbrechen',
              style: FantasyButtonStyle.iron,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            FantasyTextButton(
              key: const ValueKey('save-story-thread'),
              label: 'Speichern',
              style: FantasyButtonStyle.woodGold,
              onPressed: () {
                final heading = title.trim();
                if (heading.isEmpty) return;
                Navigator.pop(dialogContext);
                controller.saveStoryThread(
                  threadId: existing?.id,
                  title: heading,
                  description: description.trim(),
                  status: status,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _recordNpc(BuildContext context, Campaign campaign) async {
    if (campaign.npcs.isEmpty) return;
    var npcId = campaign.npcs.first.id;
    var relationship = campaign.npcs.first.relationship;
    var note = '';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('NPC-Beziehung festhalten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: const ValueKey('npc-relationship-target'),
                  initialValue: npcId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Person'),
                  items: [
                    for (final npc in campaign.npcs)
                      DropdownMenuItem(value: npc.id, child: Text(npc.name)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      npcId = value;
                      relationship = campaign.npcs
                          .firstWhere((npc) => npc.id == value)
                          .relationship;
                    });
                  },
                ),
                const SizedBox(height: 12),
                KeyedSubtree(
                  key: ValueKey('relation-field-$npcId'),
                  child: TextFormField(
                    key: const ValueKey('npc-relationship-value'),
                    initialValue: relationship,
                    onChanged: (value) => relationship = value,
                    maxLength: 80,
                    decoration: const InputDecoration(labelText: 'Beziehung'),
                  ),
                ),
                TextFormField(
                  key: const ValueKey('npc-relationship-note'),
                  initialValue: note,
                  onChanged: (value) => note = value,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Warum hat sich die Beziehung geändert?',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FantasyTextButton(
              label: 'Abbrechen',
              style: FantasyButtonStyle.iron,
              onPressed: () => Navigator.pop(dialogContext),
            ),
            FantasyTextButton(
              key: const ValueKey('save-npc-relationship'),
              label: 'Bestätigen',
              style: FantasyButtonStyle.woodGold,
              onPressed: () {
                if (relationship.trim().isEmpty || note.trim().isEmpty) return;
                Navigator.pop(dialogContext);
                controller.recordNpcRelationship(
                  npcId: npcId,
                  relationship: relationship.trim(),
                  note: note.trim(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FantasyPanel(
      title: title,
      icon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final campaign = controller.currentCampaign;
    if (campaign == null) return const SizedBox.shrink();
    // Historical notes may outlive their referenced NPC in memory.
    // Rendering must not mutate, discard, or reinterpret these notes.
    final npcNamesById = {for (final npc in campaign.npcs) npc.id: npc.name};
    return Column(
      children: [
        if (campaign.storyBible['mode'] == 'ai')
          _section(context, 'KI-Kampagnenchronik', Icons.auto_awesome, [
            Text('Ausgangslage: ${campaign.storyBible['premise'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Übergeordnetes Ziel: ${campaign.storyBible['goal'] ?? ''}'),
            const SizedBox(height: 8),
            Text(
              'Fortgeschriebene Entscheidungen: '
              '${campaign.storyBible['turnCount'] ?? '0'}',
            ),
            const SizedBox(height: 8),
            const Text(
              'Die KI berücksichtigt frühere Spielerentscheidungen, '
              'NPC-Beziehungen und Handlungsstränge. Sie trainiert dabei kein '
              'eigenes Modell. Das geheime Story-Ziel bleibt vorerst verborgen.',
            ),
          ]),
        _section(context, 'Sitzungsrückblicke', Icons.auto_stories_outlined, [
          const Text(
            'Aus bestätigten Fakten, Quest- und NPC-Status; '
            'keine KI-Erfindungen oder unverifizierten Dialoge.',
          ),
          const SizedBox(height: 8),
          FantasyTextButton(
            key: const ValueKey('create-session-recap'),
            label: 'Rückblick dauerhaft speichern',
            icon: Icons.bookmark_add_outlined,
            style: FantasyButtonStyle.woodGold,
            onPressed: controller.busy ? null : controller.saveSessionRecap,
          ),
          if (campaign.sessionRecaps.isEmpty)
            const Text('Noch kein gespeicherter Rückblick.'),
          for (final recap in campaign.sessionRecaps.reversed.take(8)) ...[
            const Divider(),
            Text(recap.title, style: Theme.of(context).textTheme.titleMedium),
            Text(recap.summary),
          ],
        ]),
        _section(context, 'Offene Handlungsstränge', Icons.route_outlined, [
          FantasyTextButton(
            key: const ValueKey('create-story-thread'),
            label: 'Handlungsstrang anlegen',
            icon: Icons.add,
            style: FantasyButtonStyle.woodGold,
            onPressed: controller.busy ? null : () => _newThread(context),
          ),
          if (campaign.storyThreads.isEmpty)
            const Text('Noch keine selbst verwalteten Handlungsstränge.'),
          for (final thread in campaign.storyThreads)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(thread.title),
              subtitle: Text(
                '${switch (thread.status) {
                  'open' => 'Offen',
                  'resolved' => 'Gelöst',
                  _ => 'Aufgegeben',
                }} · ${thread.description}',
              ),
              trailing: IconButton(
                key: ValueKey('edit-story-thread-${thread.id}'),
                tooltip: 'Handlungsstrang bearbeiten',
                onPressed: controller.busy
                    ? null
                    : () => _newThread(context, existing: thread),
                icon: const Icon(Icons.edit_outlined),
              ),
            ),
        ]),
        _section(context, 'NPC-Beziehungen', Icons.people_outline, [
          FantasyTextButton(
            key: const ValueKey('edit-npc-relationship'),
            label: 'Beziehung und Begründung festhalten',
            icon: Icons.edit_note_outlined,
            style: FantasyButtonStyle.iron,
            onPressed: controller.busy || campaign.npcs.isEmpty
                ? null
                : () => _recordNpc(context, campaign),
          ),
          for (final npc in campaign.npcs)
            Text('${npc.name}: ${npc.relationship}'),
          for (final note in campaign.npcRelationshipNotes.reversed.take(12))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${npcNamesById[note.npcId] ?? 'NPC nicht mehr vorhanden'}: '
                '${note.relationship} – ${note.note}',
              ),
            ),
        ]),
      ],
    );
  }
}
