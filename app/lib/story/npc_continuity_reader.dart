import '../domain/models.dart';

/// Read-only, confirmed continuity for a single NPC in one saved campaign.
///
/// This is story context, never permission to change rules or quest state.
class NpcContinuitySnapshot {
  NpcContinuitySnapshot({
    required this.npcId,
    required this.name,
    required this.alive,
    required this.currentRelationship,
    this.disambiguateName = false,
    required List<NpcRelationshipNote> recentNotes,
  }) : recentNotes = List.unmodifiable(recentNotes);

  final String npcId;
  final String name;
  final bool alive;
  final String currentRelationship;

  /// Only add the stored NPC ID when another NPC shares the displayed name.
  final bool disambiguateName;

  /// Most recent confirmed notes first, with deterministic timestamp ties.
  final List<NpcRelationshipNote> recentNotes;

  /// Line-safe context only from persisted NPC state and notes.
  ///
  /// Free narration, session summaries and model output are not consulted.
  String get confirmedContext {
    final heading = disambiguateName
        ? 'NPC: ${_singleLine(name)} (NPC-ID: $npcId)'
        : 'NPC: ${_singleLine(name)}';
    final lines = <String>[
      heading,
      'Status: ${alive ? 'lebendig' : 'tot'}',
      'Aktuelle Beziehung: ${_singleLine(currentRelationship)}',
      if (recentNotes.isEmpty) 'Keine bestätigten Beziehungsnotizen.',
      for (final note in recentNotes)
        'Beziehungsnotiz ${note.recordedAt.toUtc().toIso8601String()} '
            '(${_singleLine(note.relationship)}): ${_singleLine(note.note)}',
    ];
    return lines.join('\n');
  }
}

/// Projection of stored NPC history for later narrative continuity.
///
/// It does not persist, replay, infer missing facts or contact an AI provider.
class NpcContinuityReader {
  const NpcContinuityReader._();

  static NpcContinuitySnapshot read(
    Campaign campaign, {
    required String npcId,
    int limit = 5,
  }) {
    if (npcId.trim().isEmpty || limit < 1 || limit > 20) {
      throw const FormatException('Ungültige NPC-Erinnerungsanfrage.');
    }

    final matches = campaign.npcs.where((npc) => npc.id == npcId).toList();
    if (matches.length != 1) {
      throw const FormatException('NPC nicht eindeutig bestätigt.');
    }
    final npc = matches.single;
    // A saved NPC ID is the identity; a display name is not. Any other NPC
    // with the same normalized name makes text-only continuity ambiguous.
    final nameKey = _npcNameKey(npc.name);
    final disambiguate = campaign.npcs.any(
      (other) => other.id != npc.id && _npcNameKey(other.name) == nameKey,
    );
    if (disambiguate && !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(npc.id)) {
      throw const FormatException(
        'NPC-ID kann nicht sicher dargestellt werden.',
      );
    }

    final notes = <({int position, NpcRelationshipNote value})>[
      for (var i = 0; i < campaign.npcRelationshipNotes.length; i++)
        if (campaign.npcRelationshipNotes[i].npcId == npcId)
          (position: i, value: campaign.npcRelationshipNotes[i]),
    ];
    notes.sort((a, b) {
      final byTime = b.value.recordedAt.compareTo(a.value.recordedAt);
      return byTime != 0 ? byTime : b.position.compareTo(a.position);
    });

    return NpcContinuitySnapshot(
      npcId: npc.id,
      name: npc.name,
      alive: npc.alive,
      currentRelationship: npc.relationship,
      disambiguateName: disambiguate,
      recentNotes: notes.take(limit).map((entry) => entry.value).toList(),
    );
  }
}

// Stored notes may originate from legacy imports. Treat formatting controls as
// untrusted presentation data: they must not rewrite or hide context labels.
// Keep ordinary Unicode letters and punctuation unchanged.
String _singleLine(String value) => value
    .replaceAll(
      RegExp(
        r'[\x00-\x1f\x7f-\x9f\u061c\u200e\u200f'
        r'\u2028-\u202e\u2066-\u2069]',
      ),
      ' ',
    )
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

// Invisible direction marks do not introduce a space into a displayed name.
// Match the structured identity transport's ambiguity check, while retaining
// real spaces as meaningful characters and sanitizing rendered context above.
String _npcNameKey(String value) =>
    _singleLine(
          value.replaceAll(
            RegExp(r'[\u061c\u200e\u200f\u202a-\u202e\u2066-\u2069]'),
            '',
          ),
        )
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
