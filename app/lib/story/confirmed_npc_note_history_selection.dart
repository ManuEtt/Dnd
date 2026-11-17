import 'dart:convert';

import '../domain/models.dart';

/// Read-only history of one saved NPC relationship note.
///
/// Historical context, not a claim about the NPC's current relationship
/// or authorization to modify quests, rewards or rules.
class ConfirmedNpcNoteHistorySelection {
  ConfirmedNpcNoteHistorySelection._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required this.noteId,
    required this.npcId,
    required this.npcName,
    required this.relationship,
    required this.note,
    required this.recordedAt,
    required String sourceStamp,
  }) : _sourceStamp = sourceStamp;

  final String campaignId;
  final String sessionId;
  final int revision;
  final String noteId;
  final String npcId;
  final String npcName;
  final String relationship;
  final String note;
  final DateTime recordedAt;
  final String _sourceStamp;

  /// Bounded player-facing excerpt with explicit historical trust labels.
  String get playerOverview {
    final overview = [
      'Historische NPC-Beziehungsnotiz (ID: $noteId; Revision $revision):',
      'Gespeicherter NPC: $npcName (NPC-ID: $npcId)',
      'Notizdatum: ${recordedAt.toUtc().toIso8601String()}',
      'Damals gespeicherte Beziehung: $relationship',
      'Damals gespeicherte Notiz: $note',
      'Kein Nachweis für den aktuellen NPC-, Quest- oder Regelzustand.',
    ].join('\n');
    if (overview.length > 1000) {
      throw const FormatException('NPC-Notizrückblick überschreitet das Limit.');
    }
    return overview;
  }

  /// Reject edits to any saved NPC or note, including invisible changes.
  ///
  /// No story update, event, resource booking or persistence write occurs.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != ConfirmedNpcNoteHistorySelector._sourceStamp(campaign)) {
      throw const FormatException('NPC-Notizrückblick ist veraltet.');
    }
  }
}

/// Select an older confirmed relationship note by its exact saved ID.
///
/// Unlike a recent-N overview, this permits access to older entries without
/// treating an old relationship as current.
class ConfirmedNpcNoteHistorySelector {
  const ConfirmedNpcNoteHistorySelector._();

  static final RegExp _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _formatMarks = RegExp(
    r'[\u00ad\u034f\u061c\u180e\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]',
  );
  static final RegExp _controls = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');

  static ConfirmedNpcNoteHistorySelection readSelected(
    Campaign campaign, {
    required int expectedRevision,
    required String noteId,
  }) {
    if (campaign.id.trim().isEmpty ||
        campaign.sessionId.trim().isEmpty ||
        expectedRevision < 0 ||
        expectedRevision > 2147483647 ||
        campaign.revision != expectedRevision ||
        _safeId.stringMatch(noteId) != noteId) {
      throw const FormatException('Ungültige historische NPC-Notizauswahl.');
    }

    NpcRelationshipNote? chosen;
    for (final entry in campaign.npcRelationshipNotes) {
      if (entry.id != noteId) continue;
      if (chosen != null) {
        throw const FormatException('NPC-Notiz-ID ist nicht eindeutig.');
      }
      chosen = entry;
    }
    if (chosen == null || _safeId.stringMatch(chosen.npcId) != chosen.npcId) {
      throw const FormatException('NPC-Notiz hat keine eindeutige Herkunft.');
    }

    WorldNpc? npc;
    for (final entry in campaign.npcs) {
      if (entry.id != chosen.npcId) continue;
      if (npc != null) {
        throw const FormatException('NPC-Identität ist nicht eindeutig.');
      }
      npc = entry;
    }
    if (npc == null) {
      throw const FormatException('NPC zur historischen Notiz fehlt.');
    }

    final npcName = _oneLine(npc.name, 72, name: true);
    final relationship = _oneLine(chosen.relationship, 80);
    final note = _oneLine(chosen.note, 400);
    if (npcName.isEmpty || relationship.isEmpty || note.isEmpty) {
      throw const FormatException('NPC-Notiz ist nicht sicher darstellbar.');
    }

    final selection = ConfirmedNpcNoteHistorySelection._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      noteId: chosen.id,
      npcId: npc.id,
      npcName: npcName,
      relationship: relationship,
      note: note,
      recordedAt: chosen.recordedAt,
      sourceStamp: _sourceStamp(campaign),
    );
    if (selection.playerOverview.length > 1000) {
      throw const FormatException('NPC-Notizrückblick überschreitet das Limit.');
    }
    return selection;
  }

  static String _sourceStamp(Campaign campaign) => jsonEncode({
    'npcs': [for (final npc in campaign.npcs) npc.toJson()],
    'npcRelationshipNotes': [
      for (final entry in campaign.npcRelationshipNotes) entry.toJson(),
    ],
  });

  // Sanitize only the visible excerpt. Stored strings remain unchanged.
  // Rune-wise truncation preserves emoji surrogate pairs.
  static String _oneLine(String original, int maxUnits, {bool name = false}) {
    final cleaned = original
        .replaceAll(_formatMarks, name ? '' : ' ')
        .replaceAll(_controls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= maxUnits) return cleaned;

    final buffer = StringBuffer();
    var used = 0;
    for (final rune in cleaned.runes) {
      final size = rune > 0xffff ? 2 : 1;
      if (used + size > maxUnits - 1) break;
      buffer.writeCharCode(rune);
      used += size;
    }
    return '${buffer.toString().trimRight()}…';
  }
}
