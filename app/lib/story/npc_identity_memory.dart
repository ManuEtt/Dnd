import 'dart:convert';

import '../domain/models.dart';

/// Confirmed, locally derived NPC history tied to one campaign session
/// and revision.
///
/// This is a read-only projection, not an instruction to change D&D rules or
/// evidence that untrusted text from an AI provider is a confirmed fact.
class NpcIdentityContext {
  NpcIdentityContext._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required this.npcId,
    required this.npcName,
    required this.alive,
    required this.relationship,
    required List<NpcRelationshipNote> notes,
    required String sourceStamp,
  }) : notes = List.unmodifiable(notes),
       _sourceStamp = sourceStamp;

  final String campaignId;
  // Local snapshot boundary only; the existing Story API map is unchanged.
  final String sessionId;
  final int revision;
  final String npcId;
  final String npcName;
  final bool alive;
  final String relationship;
  final List<NpcRelationshipNote> notes;

  /// Full selected-NPC history, including notes omitted from the preview.
  final String _sourceStamp;

  /// Typed, bounded context for a future explicitly ID-based Story transport.
  ///
  /// This map must not be submitted to the current string-only backend API:
  /// adding an ID-aware API and validating it server-side is separate work.
  // The read-only context must remain immutable at *every* depth. A
  // mutable nested note map or list could otherwise be changed after the
  // confirmed snapshot was prepared, without updating the saved campaign.
  Map<String, Object> toContextMap() => Map<String, Object>.unmodifiable({
    'campaignId': campaignId,
    'campaignRevision': revision,
    'npcId': npcId,
    'npcName': _oneLine(npcName),
    'alive': alive,
    'relationship': _oneLine(relationship),
    'notes': List<Map<String, Object>>.unmodifiable([
      for (final note in notes)
        Map<String, Object>.unmodifiable({
          'id': note.id,
          'npcId': note.npcId,
          'relationship': _oneLine(note.relationship),
          'note': _oneLine(note.note),
          'recordedAt': note.recordedAt.toUtc().toIso8601String(),
        }),
    ]),
  });
}

/// Reads and revalidates confirmed NPC identity without name-based guesses.
///
/// Caller-supplied expectedRevision must match the authoritative local
/// campaign at the moment the snapshot is prepared or revalidated.
class NpcIdentityMemory {
  const NpcIdentityMemory._();

  static NpcIdentityContext read(
    Campaign campaign, {
    required String npcId,
    required int expectedRevision,
    int maxNotes = 3,
  }) {
    if (campaign.id.trim().isEmpty ||
        npcId.trim() != npcId ||
        npcId.isEmpty ||
        npcId.length > 128 ||
        expectedRevision < 0 ||
        campaign.revision != expectedRevision ||
        maxNotes < 1 ||
        maxNotes > 20) {
      throw const FormatException('Veralteter oder ungültiger NPC-Kontext.');
    }

    final matches = campaign.npcs.where((npc) => npc.id == npcId).toList();
    if (matches.length != 1) {
      throw const FormatException('NPC-ID nicht eindeutig bestätigt.');
    }
    final npc = matches.single;
    final history = <({NpcRelationshipNote note, int order})>[
      for (var i = 0; i < campaign.npcRelationshipNotes.length; i++)
        if (campaign.npcRelationshipNotes[i].npcId == npcId)
          (note: campaign.npcRelationshipNotes[i], order: i),
    ];
    // Legacy JSON can contain duplicate or malformed note IDs. A preview
    // limited to maxNotes must not hide an identity collision in older notes.
    // Check the *entire selected NPC history*, not unrelated NPC histories.
    final noteIds = <String>{};
    final safeNoteId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
    for (final entry in history) {
      final id = entry.note.id;
      if (!safeNoteId.hasMatch(id) || !noteIds.add(id)) {
        throw const FormatException(
          'Mehrdeutige oder ungültige bestätigte NPC-Notiz-ID.',
        );
      }
    }
    history.sort((a, b) {
      final dateOrder = b.note.recordedAt.compareTo(a.note.recordedAt);
      return dateOrder != 0 ? dateOrder : b.order.compareTo(a.order);
    });

    return NpcIdentityContext._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      npcId: npc.id,
      npcName: npc.name,
      alive: npc.alive,
      relationship: npc.relationship,
      notes: history.take(maxNotes).map((item) => item.note).toList(),
      sourceStamp: jsonEncode([
        npc.toJson(),
        for (final note in campaign.npcRelationshipNotes)
          if (note.npcId == npcId) note.toJson(),
      ]),
    );
  }

  /// Rejects a revision/session change, another campaign, or amended values.
  /// Even older notes omitted by maxNotes must remain unchanged.
  ///
  /// No implicit refresh: the caller must explicitly re-read current state.
  static void requireCurrent(Campaign campaign, NpcIdentityContext context) {
    if (campaign.id != context.campaignId ||
        campaign.sessionId != context.sessionId ||
        campaign.revision != context.revision) {
      throw const FormatException('NPC-Kontext ist nicht mehr aktuell.');
    }
    final actual = read(
      campaign,
      npcId: context.npcId,
      expectedRevision: context.revision,
      maxNotes: context.notes.isEmpty ? 1 : context.notes.length,
    );
    if (actual._sourceStamp != context._sourceStamp ||
        actual.npcName != context.npcName ||
        actual.alive != context.alive ||
        actual.relationship != context.relationship ||
        actual.notes.length != context.notes.length) {
      throw const FormatException(
        'NPC-Kontext wurde zwischenzeitlich geändert.',
      );
    }
    for (var i = 0; i < actual.notes.length; i++) {
      final current = actual.notes[i];
      final old = context.notes[i];
      if (current.id != old.id ||
          current.npcId != old.npcId ||
          current.relationship != old.relationship ||
          current.note != old.note ||
          current.recordedAt != old.recordedAt) {
        throw const FormatException(
          'NPC-Kontext wurde zwischenzeitlich geändert.',
        );
      }
    }
  }
}

String _oneLine(String value) => value.replaceAll(RegExp(r'\s+'), ' ').trim();
