import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../services/game_controller.dart';

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
          title: Text(existing == null
              ? 'Handlungsstrang anlegen'
              : 'Handlungsstrang bearbeiten'),
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
                      value: 'abandoned', child: Text('Aufgegeben'),
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              key: const ValueKey('save-story-thread'),
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
              child: const Text('Speichern'),
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              key: const ValueKey('save-npc-relationship'),
              onPressed: () {
                if (relationship.trim().isEmpty || note.trim().isEmpty) return;
                Navigator.pop(dialogContext);
                controller.recordNpcRelationship(
                  npcId: npcId,
                  relationship: relationship.trim(),
                  note: note.trim(),
                );
              },
              child: const Text('Bestätigen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, IconData icon,
      List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(child: Text(title,
                style: Theme.of(context).textTheme.titleLarge)),
          ]),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final campaign = controller.currentCampaign;
    if (campaign == null) return const SizedBox.shrink();
    return Column(
      children: [
        if (campaign.storyBible['mode'] == 'ai')
          _section(context, 'KI-Kampagnenchronik', Icons.auto_awesome, [
            Text('Ausgangslage: ${campaign.storyBible['premise'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Übergeordnetes Ziel: ${campaign.storyBible['goal'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Fortgeschriebene Entscheidungen: '
              '${campaign.storyBible['turnCount'] ?? '0'}'),
            const SizedBox(height: 8),
            const Text('Die KI berücksichtigt frühere Spielerentscheidungen, '
              'NPC-Beziehungen und Handlungsstränge. Sie trainiert dabei kein '
              'eigenes Modell. Das geheime Story-Ziel bleibt vorerst verborgen.'),
          ]),
        _section(context, 'Sitzungsrückblicke', Icons.auto_stories_outlined, [
          const Text('Aus bestätigten Fakten, Quest- und NPC-Status; '
              'keine KI-Erfindungen oder unverifizierten Dialoge.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const ValueKey('create-session-recap'),
            onPressed: controller.busy ? null : controller.saveSessionRecap,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Rückblick dauerhaft speichern'),
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
          OutlinedButton.icon(
            key: const ValueKey('create-story-thread'),
            onPressed: controller.busy ? null : () => _newThread(context),
            icon: const Icon(Icons.add),
            label: const Text('Handlungsstrang anlegen'),
          ),
          if (campaign.storyThreads.isEmpty)
            const Text('Noch keine selbst verwalteten Handlungsstränge.'),
          for (final thread in campaign.storyThreads) ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(thread.title),
            subtitle: Text('${switch (thread.status) {
              'open' => 'Offen',
              'resolved' => 'Gelöst',
              _ => 'Aufgegeben',
            }} · ${thread.description}'),
            trailing: IconButton(
              key: ValueKey('edit-story-thread-${thread.id}'),
              tooltip: 'Handlungsstrang bearbeiten',
              onPressed: controller.busy
                  ? null : () => _newThread(context, existing: thread),
              icon: const Icon(Icons.edit_outlined),
            ),
          ),
        ]),
        _section(context, 'NPC-Beziehungen', Icons.people_outline, [
          OutlinedButton.icon(
            key: const ValueKey('edit-npc-relationship'),
            onPressed: controller.busy || campaign.npcs.isEmpty
                ? null : () => _recordNpc(context, campaign),
            icon: const Icon(Icons.edit_note_outlined),
            label: const Text('Beziehung und Begründung festhalten'),
          ),
          for (final npc in campaign.npcs)
            Text('${npc.name}: ${npc.relationship}'),
          for (final note in campaign.npcRelationshipNotes.reversed.take(12))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('${campaign.npcs.firstWhere(
                (npc) => npc.id == note.npcId).name}: '
                '${note.relationship} – ${note.note}'),
            ),
        ]),
      ],
    );
  }
}
