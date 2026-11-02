import '../domain/models.dart';
import 'npc_continuity_reader.dart';

/// Bounded, read-only player-facing excerpt of confirmed NPC history.
///
/// All identity and note selection comes from the saved campaign and the
/// existing [NpcContinuityReader], never from the scene or AI messages.
/// This is not a provider request and cannot update rules or campaign state.
class ConfirmedNpcContinuityExcerpt {
  const ConfirmedNpcContinuityExcerpt._();

  static final RegExp _validId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _whiteSpace = RegExp(r'\s');

  /// At most 1,800 UTF-16 units, including labels and newlines.
  /// The exact saved ID is always shown, even for a unique displayed name.
  static String read(
    Campaign campaign, {
    required String npcId,
    int maxNotes = 3,
  }) {
    if (!_validId.hasMatch(npcId) || maxNotes < 1 || maxNotes > 3) {
      throw const FormatException('Ungültige NPC-Kurzfassung.');
    }
    final snapshot = NpcContinuityReader.read(
      campaign,
      npcId: npcId,
      limit: maxNotes,
    );

    final name = _clean(snapshot.name, 100, joinName: true);
    if (name.isEmpty) {
      throw const FormatException('NPC hat keinen sicheren Anzeigenamen.');
    }
    final relationship = _clean(snapshot.currentRelationship, 100);
    final lines = <String>[
      'Bestätigter NPC (ID: $npcId): $name',
      'Status: ${snapshot.alive ? 'lebendig' : 'tot'}',
      'Aktuelle Beziehung: ${relationship.isEmpty ? 'unbekannt' : relationship}',
    ];
    var added = 0;
    for (final note in snapshot.recentNotes) {
      final text = _clean(note.note, 280);
      if (text.isEmpty) continue;
      final relation = _clean(note.relationship, 80);
      lines.add(
        'Bestätigte Notiz ${note.recordedAt.toUtc().toIso8601String()} '
        '(${relation.isEmpty ? 'unbekannt' : relation}): $text',
      );
      added++;
    }
    if (added == 0) lines.add('Keine bestätigten Beziehungsnotizen.');

    final result = lines.join('\n');
    if (result.length > 1800) {
      throw const FormatException('NPC-Kurzfassung überschreitet das Limit.');
    }
    return result;
  }

  // Legacy control/format marks are untrusted in presentation. A format
  // character inside an NPC name does not create a distinct identity.
  static bool _format(int value) =>
      value == 0x061c ||
      (value >= 0x200b && value <= 0x200f) ||
      (value >= 0x202a && value <= 0x202e) ||
      (value >= 0x2060 && value <= 0x2069) ||
      value == 0xfeff;

  static bool _separator(int value) =>
      value < 0x20 ||
      (value >= 0x7f && value <= 0x9f) ||
      value == 0x2028 ||
      value == 0x2029 ||
      _whiteSpace.hasMatch(String.fromCharCode(value));

  // Process only enough text to build the bounded output. Truncate on rune
  // boundaries so an emoji's UTF-16 surrogate pair cannot be split.
  static String _clean(String raw, int limit, {bool joinName = false}) {
    final buffer = StringBuffer();
    var used = 0;
    var pendingSpace = false;
    for (final rune in raw.runes) {
      if (_format(rune)) {
        if (!joinName) pendingSpace = true;
        continue;
      }
      if (_separator(rune)) {
        pendingSpace = true;
        continue;
      }
      final space = pendingSpace && used > 0 ? 1 : 0;
      final size = rune > 0xffff ? 2 : 1;
      if (used + space + size > limit - 1) {
        return '${buffer.toString().trimRight()}…';
      }
      if (space > 0) {
        buffer.write(' ');
        used++;
      }
      buffer.writeCharCode(rune);
      used += size;
      pendingSpace = false;
    }
    return buffer.toString();
  }
}
