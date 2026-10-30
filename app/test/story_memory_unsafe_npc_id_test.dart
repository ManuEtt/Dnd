import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart';

Campaign _campaign(
  List<WorldNpc> npcs, {
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'unsafe-npc-memory',
  name: 'Stadt der Spiegel',
  world: 'Valdorn',
  sessionId: 'saved-session',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigte Erzählung',
  revision: 4,
  npcs: npcs,
  npcRelationshipNotes: notes,
);

NpcRelationshipNote _note(String id, String npcId, String text) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'freundlich',
      note: text,
      recordedAt: DateTime.utc(2026, 10, 30),
    );

void main() {
  test('unsafe same-name IDs and notes cannot enter story context', () {
    final source = _campaign(
      const [
        WorldNpc(id: 'bad\nid', name: 'Mira', relationship: 'misstrauisch'),
        WorldNpc(id: 'safe-id', name: 'MIRA', relationship: 'freundlich'),
      ],
      notes: [
        _note('unsafe', 'bad\nid', 'Geheime unzuordenbare Notiz.'),
        _note('safe', 'safe-id', 'Die bestätigte Hafenkarte.'),
      ],
    );
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    final recalled = MemoryEngine.retrieve(
      restored,
      'Was weißt du über Mira?',
      matchingOnly: true,
    ).join('\n');
    final recap = MemoryEngine.buildSessionSummary(restored);

    expect(recalled, contains('NPC-ID: safe-id'));
    expect(recalled, contains('Die bestätigte Hafenkarte.'));
    expect(recalled, isNot(contains('bad\nid')));
    expect(recalled, isNot(contains('Geheime unzuordenbare Notiz.')));
    expect(recap, contains('MIRA (NPC-ID: safe-id)'));
    expect(recap, isNot(contains('bad\nid')));
    expect(recap, isNot(contains('misstrauisch')));
    expect(jsonEncode(restored.toJson()), before);
    expect(restored.hero.hitPoints, 17);
  });

  test('spaces, punctuation and overlong ambiguous IDs are omitted', () {
    final tooLong = List.filled(65, 'x').join();
    final unsafeIds = ['two words', 'with.dot', 'bad\nid', 'trailing\n', tooLong];
    for (final unsafeId in unsafeIds) {
      final campaign = _campaign([
        WorldNpc(id: unsafeId, name: 'Mira'),
        const WorldNpc(id: 'safe', name: 'MIRA'),
      ]);
      final recall = MemoryEngine.retrieve(
        campaign,
        'Mira',
        matchingOnly: true,
      ).join('\n');
      final recap = MemoryEngine.buildSessionSummary(campaign);

      expect(recall, contains('NPC-ID: safe'), reason: unsafeId);
      expect(recall, isNot(contains('NPC-ID: $unsafeId')), reason: unsafeId);
      expect(recap, contains('NPC-ID: safe'), reason: unsafeId);
      expect(recap, isNot(contains('NPC-ID: $unsafeId')), reason: unsafeId);
      expect(campaign.npcs, hasLength(2));
    }
  });

  test('64-character canonical ID remains attributable after saved recap', () {
    final safeId = List.filled(64, 'x').join();
    final campaign = _campaign([
      WorldNpc(id: safeId, name: 'Mira'),
      const WorldNpc(id: 'other', name: 'MIRA'),
    ]);
    final recall = MemoryEngine.retrieve(
      campaign,
      'Mira',
      matchingOnly: true,
    ).join('\n');
    expect(recall, contains('NPC-ID: $safeId'));

    final saved = GameEngine(
      clock: () => DateTime.utc(2026, 10, 30),
    ).saveSessionRecap(campaign);
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(saved.campaign.toJson())) as Map<String, dynamic>,
    );
    expect(restored.sessionRecaps.single.summary, contains('NPC-ID: $safeId'));
    expect(restored.hero.toJson(), campaign.hero.toJson());
    expect(saved.events.single.type, 'memory.sessionRecapSaved');
  });

  test('unique legacy NPC with unsafe ID keeps its visible name', () {
    final legacy = _campaign(
      const [WorldNpc(id: 'legacy\nid', name: 'Liora')],
      notes: [_note('old', 'legacy\nid', 'Liora bewacht den Nordturm.')],
    ).toJson()..remove('sessionRecaps');
    final restored = Campaign.fromJson(legacy);
    final before = jsonEncode(restored.toJson());
    final recalled = MemoryEngine.retrieve(
      restored,
      'Liora',
      matchingOnly: true,
    ).join('\n');
    final recap = MemoryEngine.buildSessionSummary(restored);

    expect(recalled, contains('Beziehung zu Liora'));
    expect(recalled, contains('Nordturm'));
    expect(recalled, isNot(contains('NPC-ID:')));
    expect(recap, contains('Liora (lebendig, neutral)'));
    expect(recap, isNot(contains('NPC-ID:')));
    expect(jsonEncode(restored.toJson()), before);
    expect(restored.hero.hitPoints, 17);
  });
}
