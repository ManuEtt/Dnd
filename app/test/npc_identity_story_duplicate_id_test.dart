import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';

Campaign _campaign(List<WorldNpc> npcs, List<NpcRelationshipNote> notes) =>
    Campaign(
      id: 'duplicate-npc-id',
      name: 'Die zwei Hüter',
      world: 'Valdorn',
      sessionId: 'session-1',
      hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 12),
      scene: 'Vor dem Tor',
      revision: 3,
      npcs: npcs,
      npcRelationshipNotes: notes,
    );

NpcRelationshipNote _note(String npcId, String text) => NpcRelationshipNote(
  id: 'note-$npcId',
  npcId: npcId,
  relationship: 'freundlich',
  note: text,
  recordedAt: DateTime.utc(2026, 10, 29),
);

void main() {
  test('duplicate saved ID never selects either uniquely named NPC', () {
    final campaign = _campaign(
      const [
        WorldNpc(id: 'shared', name: 'Mira'),
        WorldNpc(id: 'shared', name: 'Tarek'),
      ],
      [_note('shared', 'Nur eine gespeicherte Notiz.')],
    );
    final before = jsonEncode(campaign.toJson());
    expect(
      NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira.'),
      isNull,
    );
    expect(
      NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Tarek.'),
      isNull,
    );
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('duplicate ID cannot suppress another confirmed unique NPC', () {
    final campaign = _campaign(
      const [
        WorldNpc(id: 'shared', name: 'Mira'),
        WorldNpc(id: 'shared', name: 'Tarek'),
        WorldNpc(id: 'unique', name: 'Lina'),
      ],
      [
        _note('shared', 'Mehrdeutig.'),
        _note('unique', 'Lina kennt den Brunnen.'),
      ],
    );
    final payload = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich frage Mira, Tarek und Lina.',
    );
    expect(payload, isNotNull);
    expect(payload!.npcContexts, hasLength(1));
    expect(payload.npcContexts.single['npcId'], 'unique');
    expect(payload.npcContexts.toString(), contains('Brunnen'));
    expect(payload.npcContexts.toString(), isNot(contains('Mehrdeutig')));
    payload.requireCurrent(campaign);
    expect(campaign.hero.hitPoints, 12);
  });

  test('unique saved IDs remain available after campaign JSON restore', () {
    final campaign = _campaign(
      const [WorldNpc(id: 'mira', name: 'Mira')],
      [_note('mira', 'Mira bewacht den Turm.')],
    );
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(campaign.toJson())) as Map<String, dynamic>,
    );
    final payload = NpcIdentityStoryPayload.prepare(
      restored,
      'Ich frage Mira.',
    );
    expect(payload!.npcContexts.single['npcId'], 'mira');
    payload.requireCurrent(restored);
    expect(restored.hero.hitPoints, 12);
  });
}
