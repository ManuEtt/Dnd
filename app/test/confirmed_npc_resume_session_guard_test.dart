import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_resume_selection.dart';

Campaign _campaign(String sessionId) => Campaign(
  id: 'npc-session-guard',
  name: 'Erinnerungen am Brunnen',
  world: 'Rabenwacht',
  sessionId: sessionId,
  revision: 3,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
  ],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'note-1',
      npcId: 'mira',
      relationship: 'freundlich',
      note: 'Mira kennt den Weg zum Brunnen.',
      recordedAt: DateTime.utc(2026, 11, 6),
    ),
  ],
);

void main() {
  test('NPC resume rejects empty and whitespace-only session identities', () {
    for (final sessionId in ['', ' ', '\t\n', '\u2003']) {
      final campaign = _campaign(sessionId);
      final original = jsonEncode(campaign.toJson());

      expect(
        () => ConfirmedNpcResumeSelector.read(
          campaign,
          expectedRevision: 3,
        ),
        throwsFormatException,
        reason: 'A session identity is required for ${sessionId.codeUnits}.',
      );
      expect(jsonEncode(campaign.toJson()), original);
    }
  });

  test('NPC resume accepts a valid session and preserves confirmed data', () {
    final campaign = _campaign('session-3');
    final original = jsonEncode(campaign.toJson());

    final selection = ConfirmedNpcResumeSelector.read(
      campaign,
      expectedRevision: 3,
    );

    expect(selection.sessionId, 'session-3');
    expect(selection.entries, hasLength(1));
    expect(selection.entries.single.npcId, 'mira');
    expect(selection.playerOverview, contains('Mira kennt den Weg'));
    selection.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('NPC resume rejects stale session even with matching revision', () {
    final selection = ConfirmedNpcResumeSelector.read(
      _campaign('session-3'),
      expectedRevision: 3,
    );

    expect(
      () => selection.requireCurrent(_campaign('session-4')),
      throwsFormatException,
    );
    expect(
      () => selection.requireCurrent(_campaign('')),
      throwsFormatException,
    );
  });
}
