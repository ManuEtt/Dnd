import 'dart:convert';

import '../domain/models.dart';

/// One explicitly ID-bound NPC in a read-only confirmed campaign recap.
class ConfirmedNpcResumeEntry {
  ConfirmedNpcResumeEntry._({
    required this.npcId,
    required this.name,
    required this.alive,
    required this.relationship,
    required List<String> recentNotes,
  }) : recentNotes = List.unmodifiable(recentNotes);

  final String npcId;
  final String name;
  final bool alive;
  final String relationship;

  /// Confirmed saved notes, newest first. No free GM narration.
  final List<String> recentNotes;
}

/// Stable snapshot of the most recently confirmed NPC relationships.
///
/// The selection is not a provider payload, a rules update or a campaign
/// mutation. Consumers must revalidate before using it after another turn.
class ConfirmedNpcResumeSelection {
  ConfirmedNpcResumeSelection._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required List<ConfirmedNpcResumeEntry> entries,
    required String sourceStamp,
  }) : entries = List.unmodifiable(entries),
       _sourceStamp = sourceStamp;

  final String campaignId;
  final String sessionId;
  final int revision;
  final List<ConfirmedNpcResumeEntry> entries;
  final String _sourceStamp;

  /// At most 2,400 UTF-16 code units with explicit sources and saved IDs.
  String get playerOverview {
    final lines = <String>[
      'Bestätigte NPC-Beziehungen (Revision $revision):',
      for (final entry in entries) ...[
        'NPC: ${entry.name} (NPC-ID: ${entry.npcId}), '
            '${entry.alive ? 'lebendig' : 'tot'}, Beziehung: ${entry.relationship}',
        for (final note in entry.recentNotes) 'Bestätigte Notiz: $note',
      ],
    ];
    final result = lines.join('\n');
    if (result.length > 2400) {
      throw const FormatException('NPC-Rückblick überschreitet sein Limit.');
    }
    return result;
  }

  /// Rejects different campaign/session/revision and same-revision NPC edits.
  ///
  /// This does not authorize a rules or persistence write.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != _npcSourceStamp(campaign)) {
      throw const FormatException('Bestätigter NPC-Rückblick ist veraltet.');
    }
  }
}

/// Deterministic, bounded selection of saved NPC relationships for resuming.
///
/// Only locally stored relationship notes count as evidence for inclusion.
/// Latest note timestamp wins; equal times use the later saved note position,
/// then the stable NPC ID. Invalid/duplicate NPC and note IDs are excluded.
class ConfirmedNpcResumeSelector {
  const ConfirmedNpcResumeSelector._();

  static final RegExp _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _formatMarks = RegExp(
    r'[\u061c\u200b-\u200f\u202a-\u202e\u2060-\u2069\ufeff]',
  );
  static final RegExp _controls = RegExp(
    r'[\x00-\x1f\x7f-\x9f\u2028\u2029]',
  );

  static ConfirmedNpcResumeSelection read(
    Campaign campaign, {
    required int expectedRevision,
    int maxNpcs = 3,
    int maxNotesPerNpc = 2,
  }) {
    if (campaign.id.trim().isEmpty ||
        expectedRevision < 0 ||
        expectedRevision > 2147483647 ||
        campaign.revision != expectedRevision ||
        maxNpcs < 1 ||
        maxNpcs > 3 ||
        maxNotesPerNpc < 1 ||
        maxNotesPerNpc > 3) {
      throw const FormatException('Ungültige NPC-Wiederaufnahmegrenzen.');
    }

    final npcIdCounts = <String, int>{};
    for (final npc in campaign.npcs) {
      npcIdCounts[npc.id] = (npcIdCounts[npc.id] ?? 0) + 1;
    }
    final noteIdCounts = <String, int>{};
    for (final note in campaign.npcRelationshipNotes) {
      noteIdCounts[note.id] = (noteIdCounts[note.id] ?? 0) + 1;
    }

    final grouped = <String, List<({NpcRelationshipNote note, int order})>>{};
    for (var i = 0; i < campaign.npcRelationshipNotes.length; i++) {
      final note = campaign.npcRelationshipNotes[i];
      if (!_safeId.hasMatch(note.npcId) ||
          !_safeId.hasMatch(note.id) ||
          noteIdCounts[note.id] != 1 ||
          _oneLine(note.note, 140).isEmpty) {
        continue;
      }
      grouped.putIfAbsent(note.npcId, () => []).add((
        note: note,
        order: i,
      ));
    }

    final ranked =
        <({
          WorldNpc npc,
          String name,
          String relationship,
          DateTime latestAt,
          int latestOrder,
          List<String> notes,
        })>[];
    for (final npc in campaign.npcs) {
      if (!_safeId.hasMatch(npc.id) || npcIdCounts[npc.id] != 1) {
        continue;
      }
      final name = _oneLine(npc.name, 70, name: true);
      if (name.isEmpty) continue;
      final history = grouped[npc.id];
      if (history == null || history.isEmpty) continue;
      history.sort((a, b) {
        final byDate = b.note.recordedAt.compareTo(a.note.recordedAt);
        return byDate != 0 ? byDate : b.order.compareTo(a.order);
      });
      final notes = [
        for (final entry in history.take(maxNotesPerNpc))
          '${entry.note.recordedAt.toUtc().toIso8601String()}: '
              '${_oneLine(entry.note.note, 140)}',
      ];
      ranked.add((
        npc: npc,
        name: name,
        relationship: _oneLine(npc.relationship, 70),
        latestAt: history.first.note.recordedAt,
        latestOrder: history.first.order,
        notes: notes,
      ));
    }
    ranked.sort((a, b) {
      final byDate = b.latestAt.compareTo(a.latestAt);
      if (byDate != 0) return byDate;
      final byOrder = b.latestOrder.compareTo(a.latestOrder);
      return byOrder != 0 ? byOrder : a.npc.id.compareTo(b.npc.id);
    });

    final result = ConfirmedNpcResumeSelection._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      entries: [
        for (final item in ranked.take(maxNpcs))
          ConfirmedNpcResumeEntry._(
            npcId: item.npc.id,
            name: item.name,
            alive: item.npc.alive,
            relationship: item.relationship.isEmpty
                ? 'unbekannt'
                : item.relationship,
            recentNotes: item.notes,
          ),
      ],
      sourceStamp: _npcSourceStamp(campaign),
    );
    // Fail closed if a future field expansion exhausts the global budget.
    if (result.playerOverview.length > 2400) {
      throw const FormatException('NPC-Rückblick überschreitet sein Limit.');
    }
    return result;
  }

  static String _oneLine(String text, int limit, {bool name = false}) {
    final clean = text
        .replaceAll(_formatMarks, name ? '' : ' ')
        .replaceAll(_controls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= limit) return clean;
    final buffer = StringBuffer();
    var units = 0;
    for (final rune in clean.runes) {
      final size = rune > 0xffff ? 2 : 1;
      if (units + size > limit - 1) break;
      buffer.writeCharCode(rune);
      units += size;
    }
    return '${buffer.toString().trimRight()}…';
  }
}

/// Full original NPC source, not the truncated overview. This also detects
/// same-revision edits hidden beyond the visible character limits.
String _npcSourceStamp(Campaign campaign) => jsonEncode({
  'npcs': [for (final npc in campaign.npcs) npc.toJson()],
  'notes': [for (final note in campaign.npcRelationshipNotes) note.toJson()],
});
