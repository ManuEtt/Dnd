import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart';

Campaign _campaign({
  List<WorldNpc>? npcs,
  List<NpcRelationshipNote>? notes,
}) => Campaign(
  id: 'npc-recall-campaign',
  name: 'Zwei Miras',
  world: 'Eiren',
  sessionId: 'session-2',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 13),
  scene: 'Ungesicherte Erzählung: Zwei Miras sind eine Person.',
  revision: 7,
  npcs:
      npcs ??
      const [
        WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-b', name: 'MIRA', relationship: 'feindlich'),
      ],
  npcRelationshipNotes:
      notes ??
      [
        NpcRelationshipNote(
          id: 'note-a',
          npcId: 'mira-a',
          relationship: 'freundlich',
          note: 'Die erste Mira übergab die Karte.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
        NpcRelationshipNote(
          id: 'note-b',
          npcId: 'mira-b',
          relationship: 'feindlich',
          note: 'Die zweite Mira bewacht das Tor.',
          recordedAt: DateTime.utc(2026, 10, 26),
        ),
      ],
);

void main() {
  test('same-name relationship notes identify each saved NPC in recall', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    final recalled = MemoryEngine.retrieve(
      campaign,
      'Was weißt du über Mira?',
      matchingOnly: true,
    );
    expect(
      recalled,
      contains('Beziehung zu Mira (NPC-ID: mira-a): freundlich. '
          'Die erste Mira übergab die Karte.'),
    );
    expect(
      recalled,
      contains('Beziehung zu MIRA (NPC-ID: mira-b): feindlich. '
          'Die zweite Mira bewacht das Tor.'),
    );
    expect(recalled, contains(startsWith('NPC lebendig: Mira (NPC-ID: mira-a)')));
    expect(recalled, contains(startsWith('NPC lebendig: MIRA (NPC-ID: mira-b)')));
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('identical confirmed notes for different IDs are not collapsed', () {
    final time = DateTime.utc(2026, 10, 26);
    final campaign = _campaign(
      notes: [
        NpcRelationshipNote(
          id: 'note-a',
          npcId: 'mira-a',
          relationship: 'neutral',
          note: 'Eine gemeinsame Beobachtung.',
          recordedAt: time,
        ),
        NpcRelationshipNote(
          id: 'note-b',
          npcId: 'mira-b',
          relationship: 'neutral',
          note: 'Eine gemeinsame Beobachtung.',
          recordedAt: time,
        ),
      ],
    );
    final recalled = MemoryEngine.retrieve(campaign, '', limit: 20);
    expect(
      recalled.where((item) => item.contains('Eine gemeinsame Beobachtung.')),
      hasLength(2),
    );
    expect(recalled.join(' '), contains('NPC-ID: mira-a'));
    expect(recalled.join(' '), contains('NPC-ID: mira-b'));
  });

  test('unique names and restored old saves keep the existing labels', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
      ],
      notes: [
        NpcRelationshipNote(
          id: 'note-a',
          npcId: 'mira-a',
          relationship: 'freundlich',
          note: 'Mira zeigte die Karte.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(campaign.toJson())) as Map<String, dynamic>,
    );
    final recalled = MemoryEngine.retrieve(restored, '', limit: 20);
    expect(
      recalled,
      contains('Beziehung zu Mira: freundlich. Mira zeigte die Karte.'),
    );
    expect(recalled, contains(startsWith('NPC lebendig: Mira. Beziehung:')));
    expect(recalled.join(' '), isNot(contains('NPC-ID:')));
    expect(restored.hero.hitPoints, 13);
  });

  test('duplicate stored IDs never authorize a relationship note', () {
    final invalid = _campaign(
      npcs: const [
        WorldNpc(id: 'same-id', name: 'Mira'),
        WorldNpc(id: 'same-id', name: 'Andere Mira'),
      ],
      notes: [
        NpcRelationshipNote(
          id: 'note-1',
          npcId: 'same-id',
          relationship: 'freundlich',
          note: 'Dieser Eintrag ist nicht zuordenbar.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    expect(MemoryEngine.retrieve(invalid, ''), isEmpty);
  });

  test('short recall skips ambiguous notes rather than hiding their ID', () {
    final campaign = _campaign();
    final recalled = MemoryEngine.retrieve(
      campaign,
      'Was weißt du über Mira?',
      matchingOnly: true,
      maxCharacters: 40,
    );
    expect(recalled, isEmpty);
    expect(campaign.revision, 7);
    expect(campaign.hero.hitPoints, 13);
  });

  test('distinct names, regular memories and empty legacy notes still work', () {
    final campaign = _campaign(
      npcs: const [WorldNpc(id: 'tarek', name: 'Tarek')],
      notes: const [],
    ).copyWith(facts: const {'Schlüssel': 'Der Schlüssel wurde gefunden.'});
    final memories = MemoryEngine.retrieve(
      campaign,
      'Was weißt du über den Schlüssel?',
      matchingOnly: true,
    );
    expect(memories, contains('Fakt Schlüssel:. Der Schlüssel wurde gefunden.'));
    expect(memories.join(' '), isNot(contains('NPC-ID:')));
  });
}
