import '../domain/models.dart';
import 'npc_identity_memory.dart';

/// A bounded, read-only NPC snapshot prepared for a negotiated Story API.
///
/// Mentioning a displayed name can select a saved identity only when that
/// displayed name is unique across the campaign. Equal names must be selected
/// by explicit NPC ID in a future UI, never guessed from player prose.
class NpcIdentityStoryPayload {
  NpcIdentityStoryPayload._(this.campaignRevision, this.npcContexts);

  final int campaignRevision;
  final List<Map<String, Object>> npcContexts;

  static NpcIdentityStoryPayload? prepare(
    Campaign campaign,
    String playerAction, {
    int maxNpcs = 3,
    int maxNotes = 3,
  }) {
    if (campaign.revision < 0 ||
        campaign.revision > 2147483647 ||
        maxNpcs < 1 ||
        maxNpcs > 3 ||
        maxNotes < 1 ||
        maxNotes > 5) {
      throw const FormatException('Ungültige NPC-Kontextgrenzen.');
    }
    final counts = <String, int>{};
    for (final npc in campaign.npcs) {
      final name = _fold(npc.name);
      if (name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
    }

    final selected = <Map<String, Object>>[];
    for (final npc in campaign.npcs) {
      final name = _fold(npc.name);
      if (name.isEmpty ||
          counts[name] != 1 ||
          !_mentions(playerAction, name) ||
          !_validId(npc.id) ||
          !_validText(npc.name, 80) ||
          !_validText(npc.relationship, 80)) {
        continue;
      }
      final snapshot = NpcIdentityMemory.read(
        campaign,
        npcId: npc.id,
        expectedRevision: campaign.revision,
        maxNotes: maxNotes,
      );
      if (snapshot.notes.isEmpty ||
          snapshot.notes.any(
            (note) =>
                !_validId(note.id) ||
                !_validText(note.relationship, 80) ||
                !_validText(note.note, 500) ||
                note.npcId != npc.id,
          )) {
        continue;
      }
      NpcIdentityMemory.requireCurrent(campaign, snapshot);
      selected.add(snapshot.toContextMap());
      if (selected.length == maxNpcs) break;
    }
    if (selected.isEmpty) return null;
    return NpcIdentityStoryPayload._(
      campaign.revision,
      List.unmodifiable(selected),
    );
  }

  static bool _validId(String value) =>
      RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(value);

  static bool _validText(String text, int max) =>
      text.trim().isNotEmpty &&
      text.length <= max &&
      !RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]').hasMatch(text);

  static bool _mentions(String action, String name) {
    final playerText = _fold(action);
    return RegExp(
      '(^|[^a-z0-9])${RegExp.escape(name)}(?=[^a-z0-9]|'
      r'$)',
    ).hasMatch(playerText);
  }

  static String _fold(String value) => value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
