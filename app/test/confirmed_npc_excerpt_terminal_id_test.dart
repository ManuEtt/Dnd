import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_continuity_excerpt.dart';

Campaign _campaign(String npcId) => Campaign(
  id: 'npc-excerpt-strict-id',
  name: 'Erinnerungen am Tor',
  world: 'Valdorn',
  sessionId: 'session-excerpt',
  revision: 2,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Der Drachenhort wurde gefunden.',
  npcs: [WorldNpc(id: npcId, name: 'Mira')],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'note-1',
      npcId: npcId,
      relationship: 'freundlich',
      note: 'Mira kennt den Weg zum Turm.',
      recordedAt: DateTime.utc(2026, 11, 13),
    ),
  ],
);

void main() {
  test('trailing newlines cannot be accepted as confirmed NPC identities', () {
    for (final invalidId in [
      'mira\n',
      'mira\r',
      'mira\r\n',
      'mira\u2028',
      'mira\u2029',
      'mira\u200b',
      'mira ',
    ]) {
      final campaign = _campaign(invalidId);
      final before = jsonEncode(campaign.toJson());

      expect(
        () => ConfirmedNpcContinuityExcerpt.read(campaign, npcId: invalidId),
        throwsFormatException,
        reason: 'Unsafe saved NPC ID must fail closed',
      );
      expect(jsonEncode(campaign.toJson()), before);
      expect(campaign.hero.hitPoints, 17);
    }
  });

  test('safe complete ID and notes survive a JSON restart unchanged', () {
    final canonicalId = List.filled(64, 'a').join();
    final campaign = _campaign(canonicalId);
    final before = jsonEncode(campaign.toJson());
    final restored = Campaign.fromJson(
      jsonDecode(before) as Map<String, dynamic>,
    );

    final excerpt = ConfirmedNpcContinuityExcerpt.read(
      restored,
      npcId: canonicalId,
      maxNotes: 1,
    );

    expect(excerpt, contains('ID: $canonicalId'));
    expect(excerpt, contains('Mira kennt den Weg zum Turm.'));
    expect(excerpt.split('\n'), hasLength(4));
    expect(excerpt, isNot(contains('Drachenhort')));
    expect(restored.hero.toJson(), campaign.hero.toJson());
    expect(jsonEncode(restored.toJson()), before);
  });

  test('nearby safe ID is not silently matched to a malformed saved ID', () {
    final campaign = _campaign('mira\n');
    final before = jsonEncode(campaign.toJson());

    expect(
      () => ConfirmedNpcContinuityExcerpt.read(campaign, npcId: 'mira'),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
  });
}
