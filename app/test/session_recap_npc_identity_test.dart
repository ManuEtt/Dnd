import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart' as story;

Campaign _campaign(List<WorldNpc> npcs) => Campaign(
  id: 'recap-identity',
  name: 'Zwei Hüterinnen',
  world: 'Valdorn',
  sessionId: 'recap-session',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 13),
  scene: 'Unbestätigt: Die beiden Miras sind dieselbe Person.',
  revision: 7,
  npcs: npcs,
);

void main() {
  test('same-name NPCs with equal relationships remain distinct in recap', () {
    final campaign = _campaign(const [
      WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
      WorldNpc(id: 'mira-b', name: 'MIRA', relationship: 'freundlich'),
    ]);
    final before = jsonEncode(campaign.toJson());
    final summary = story.MemoryEngine.buildSessionSummary(campaign);

    expect(summary, contains('Mira (NPC-ID: mira-a) (lebendig, freundlich)'));
    expect(summary, contains('MIRA (NPC-ID: mira-b) (lebendig, freundlich)'));
    expect(summary, isNot(contains('Unbestätigt:')));
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('unique and old JSON NPCs keep their human-readable name labels', () {
    final source = _campaign(const [
      WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
      WorldNpc(id: 'mara', name: 'Mara', relationship: 'neutral'),
    ]).toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(source);
    final summary = story.MemoryEngine.buildSessionSummary(restored);

    expect(
      summary,
      contains(
        'Bekannte NPCs: Mira (lebendig, freundlich); '
        'Mara (lebendig, neutral).',
      ),
    );
    expect(summary, isNot(contains('NPC-ID:')));
  });

  test('ambiguous stored IDs never become confirmed recap identities', () {
    final campaign = _campaign(const [
      WorldNpc(id: 'same-id', name: 'Mira', relationship: 'freundlich'),
      WorldNpc(id: 'same-id', name: 'Mira', relationship: 'feindlich'),
      WorldNpc(id: 'safe-id', name: 'Mara', relationship: 'neutral'),
    ]);
    final summary = story.MemoryEngine.buildSessionSummary(campaign);

    expect(summary, contains('Mara (lebendig, neutral)'));
    expect(summary, isNot(contains('Mira')));
    expect(summary, isNot(contains('same-id')));
  });

  test(
    'normalized German duplicates survive a saved recap and JSON roundtrip',
    () {
      final campaign = _campaign(const [
        WorldNpc(
          id: 'keeper-a',
          name: 'Große Hüterin',
          relationship: 'neutral',
        ),
        WorldNpc(
          id: 'keeper-b',
          name: 'GROSSE HUETERIN',
          relationship: 'neutral',
        ),
      ]);
      final beforeHero = campaign.hero.toJson();
      final result = GameEngine(
        clock: () => DateTime.utc(2026, 10, 27),
      ).saveSessionRecap(campaign);
      final recap = result.campaign.sessionRecaps.single.summary;

      expect(recap, contains('Große Hüterin (NPC-ID: keeper-a)'));
      expect(recap, contains('GROSSE HUETERIN (NPC-ID: keeper-b)'));
      expect(result.events.single.type, 'memory.sessionRecapSaved');
      expect(result.campaign.hero.toJson(), beforeHero);
      expect(result.campaign.revision, campaign.revision + 1);
      final restored = Campaign.fromJson(
        jsonDecode(jsonEncode(result.campaign.toJson()))
            as Map<String, dynamic>,
      );
      expect(restored.sessionRecaps.single.summary, recap);
      expect(restored.hero.toJson(), beforeHero);
    },
  );
}
