import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';

Campaign _campaign({
  String sessionId = 'session-one',
  String selectedDescription = 'Die Kartografin des Hafens.',
  String otherDescription = 'Die Waechterin am Tor.',
}) => Campaign(
  id: 'two-miras',
  name: 'Die zwei Miras',
  world: 'Valdorn',
  sessionId: sessionId,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 12),
  scene: 'Der Marktplatz',
  revision: 7,
  npcs: [
    WorldNpc(
      id: 'mira-one',
      name: 'Mira',
      description: selectedDescription,
      relationship: 'freundlich',
    ),
    WorldNpc(
      id: 'mira-two',
      name: 'MIRA',
      description: otherDescription,
      relationship: 'misstrauisch',
    ),
  ],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'note-one',
      npcId: 'mira-one',
      relationship: 'freundlich',
      note: 'Die erste Mira besitzt die Seekarte.',
      recordedAt: DateTime.utc(2026, 10, 25),
    ),
    NpcRelationshipNote(
      id: 'note-two',
      npcId: 'mira-two',
      relationship: 'misstrauisch',
      note: 'Die zweite Mira bewacht das Stadttor.',
      recordedAt: DateTime.utc(2026, 10, 26),
    ),
  ],
);

void _expectStaleSelection(Campaign original, Campaign changed) {
  final choice = NpcStorySelection.choose(original, 'mira-one');
  final unchanged = jsonEncode(changed.toJson());
  expect(() => choice.requireCurrent(changed), throwsFormatException);
  expect(
    () => NpcIdentityStoryPayload.prepare(
      changed,
      'Ich frage Mira nach dem Weg.',
      selectedNpc: choice,
    ),
    throwsFormatException,
  );
  expect(jsonEncode(changed.toJson()), unchanged);
  expect(changed.hero.toJson(), original.hero.toJson());
}

void main() {
  test('unchanged NPC selection survives campaign JSON roundtrip', () {
    final original = _campaign();
    final choice = NpcStorySelection.choose(original, 'mira-one');
    final recovered = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    choice.requireCurrent(recovered);
    final payload = NpcIdentityStoryPayload.prepare(
      recovered,
      'Ich frage Mira nach dem Weg.',
      selectedNpc: choice,
    )!;
    expect(payload.selectedNpcId, 'mira-one');
    expect(payload.npcContexts, hasLength(1));
    expect(payload.npcContexts.single['npcId'], 'mira-one');
    expect(payload.npcContexts.toString(), contains('Seekarte'));
    expect(payload.npcContexts.toString(), isNot(contains('Stadttor')));
    payload.requireCurrent(recovered);
    expect(recovered.toJson(), original.toJson());
  });

  test('session switch cannot reuse NPC choice with identical revision', () {
    final original = _campaign();
    final alteredJson = {
      ...original.toJson(),
      'sessionId': 'session-two',
    };
    final changed = Campaign.fromJson(alteredJson);
    expect(changed.id, original.id);
    expect(changed.revision, original.revision);
    expect(changed.npcs.first.toJson(), original.npcs.first.toJson());
    _expectStaleSelection(original, changed);
  });

  test('NPC profile change invalidates same-revision selection', () {
    final original = _campaign();
    final changed = _campaign(
      selectedDescription: 'Eine andere Person mit identischem Namen.',
    );
    expect(changed.sessionId, original.sessionId);
    expect(changed.npcs.first.name, original.npcs.first.name);
    expect(changed.npcs.first.id, original.npcs.first.id);
    expect(changed.npcs.first.relationship, original.npcs.first.relationship);
    expect(changed.npcs.first.alive, original.npcs.first.alive);
    _expectStaleSelection(original, changed);
  });

  test('unrelated NPC profile change does not invalidate chosen identity', () {
    final original = _campaign();
    final changed = _campaign(
      otherDescription: 'Die zweite Mira kennt das Nordtor.',
    );
    final choice = NpcStorySelection.choose(original, 'mira-one');
    final unchanged = jsonEncode(changed.toJson());
    choice.requireCurrent(changed);
    final payload = NpcIdentityStoryPayload.prepare(
      changed,
      'Ich spreche Mira an.',
      selectedNpc: choice,
    )!;
    expect(payload.selectedNpcId, 'mira-one');
    expect(payload.npcContexts, hasLength(1));
    expect(payload.npcContexts.toString(), contains('Seekarte'));
    expect(payload.npcContexts.toString(), isNot(contains('Stadttor')));
    expect(jsonEncode(changed.toJson()), unchanged);
  });
}
