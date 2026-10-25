import '../domain/models.dart';

/// Selects bounded, confirmed NPC history for the optional AI narrator.
///
/// This prepares untrusted narrative context only. It cannot modify campaign
/// state or grant any mechanical authority to a text provider.
class NpcNarratorMemory {
  const NpcNarratorMemory._();

  /// Keep NPC history relevant to the player's current action ahead of
  /// unrelated general memories, without exceeding the existing wire limits.
  static List<String> merge(
    Campaign campaign,
    String action,
    List<String> general, {
    int limit = 12,
    int npcNoteLimit = 3,
  }) {
    if (limit < 1 || limit > 20 || npcNoteLimit < 0 || npcNoteLimit > limit) {
      throw const FormatException('Ungültige Erzähler-Erinnerungsgrenzen.');
    }

    final mentioned = <String, WorldNpc>{};
    for (final npc in campaign.npcs) {
      if (npc.id.isNotEmpty && _mentions(action, npc.name)) {
        // Ambiguous repeated IDs cannot authorize NPC-specific memories.
        if (campaign.npcs.where((other) => other.id == npc.id).length == 1) {
          mentioned[npc.id] = npc;
        }
      }
    }
    final relevant = <({NpcRelationshipNote note, WorldNpc npc, int order})>[];
    for (var index = 0; index < campaign.npcRelationshipNotes.length; index++) {
      final note = campaign.npcRelationshipNotes[index];
      final npc = mentioned[note.npcId];
      if (npc == null || note.note.trim().isEmpty) continue;
      relevant.add((note: note, npc: npc, order: index));
    }
    relevant.sort((a, b) {
      final time = b.note.recordedAt.compareTo(a.note.recordedAt);
      return time != 0 ? time : b.order.compareTo(a.order);
    });

    final result = <String>[];
    final selectedNotes = <String>[];
    for (final entry in relevant.take(npcNoteLimit)) {
      final note = entry.note;
      final normalizedNote = _oneLine(note.note);
      final text = _truncate(
        'Bestätigte NPC-Beziehungsnotiz zu ${_oneLine(entry.npc.name)} '
        '(${_oneLine(note.relationship)}): ${normalizedNote}',
        400,
      );
      if (result.contains(text)) continue;
      result.add(text);
      selectedNotes.add(normalizedNote);
    }
    for (final raw in general) {
      final value = _oneLine(raw);
      if (value.isEmpty ||
          selectedNotes.any(
            (note) => note.isNotEmpty && value.contains(note),
          )) {
        continue;
      }
      final text = _truncate(value, 400);
      if (!result.contains(text)) result.add(text);
      if (result.length == limit) break;
    }
    return List.unmodifiable(result);
  }

  static bool _mentions(String action, String npcName) {
    final normalized = _normalize(npcName);
    if (normalized.isEmpty) return false;
    final playerText = _normalize(action);
    return RegExp(
      '(^|[^a-z0-9])${RegExp.escape(normalized)}(?=[^a-z0-9]|'
      r'$)',
    ).hasMatch(playerText);
  }

  static String _normalize(String text) => _oneLine(text)
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss');

  static String _oneLine(String text) => text
      .replaceAll(RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static String _truncate(String text, int length) {
    if (text.length <= length) return text;
    var end = length - 1;
    if (end > 0) {
      final unit = text.codeUnitAt(end - 1);
      if (unit >= 0xd800 && unit <= 0xdbff) end--;
    }
    return '${text.substring(0, end).trimRight()}…';
  }
}
