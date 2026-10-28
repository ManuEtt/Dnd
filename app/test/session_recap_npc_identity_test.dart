import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart' as story;

Campaign _campaign(List<WorldNpc> npcs, {String name = 'Zwei Hüterinnen'}) {
  return Campaign(
    id: 'recap-identity',
    name: name,
    world: 'Valdorn',
    sessionId: 'recap-session',
    hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 13),
    scene: 'Unbestätigt: Die beiden Miras sind dieselbe Person.',
    revision: 7,
    npcs: npcs,
  );
}

String _longRecapNameFor(List<WorldNpc> npcs, {int extra = 0}) {
  final baseline = story.MemoryEngine.buildSessionSummary(_campaign(npcs));
  final npcStart = baseline.indexOf('Bekannte NPCs: ');
  if (npcStart < 0) throw StateError('NPC-Bereich fehlt im Testaufbau.');
  const firstEntry =
      'Bekannte NPCs: Mira (NPC-ID: mira-a) (lebendig, freundlich).';
  final padding = 2400 - npcStart - firstEntry.length + extra;
  if (padding < 0) throw StateError('Ungültiger Testgrenzwert.');
  return 'Zwei Hüterinnen${List.filled(padding, 'X').join()}';
}

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

  test('long recap preserves a complete first same-name NPC identity', () {
    const npcs = [
      WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
      WorldNpc(id: 'mira-b', name: 'MIRA', relationship: 'feindlich'),
    ];
    final campaign = _campaign(npcs, name: _longRecapNameFor(npcs));
    final before = jsonEncode(campaign.toJson());
    final summary = story.MemoryEngine.buildSessionSummary(campaign);

    expect(summary.length, 2400);
    expect(
      summary,
      endsWith('Bekannte NPCs: Mira (NPC-ID: mira-a) (lebendig, freundlich).'),
    );
    expect(summary, isNot(contains('mira-b')));
    expect(jsonEncode(campaign.toJson()), before);

    final saved = GameEngine(
      clock: () => DateTime.utc(2026, 10, 28),
    ).saveSessionRecap(campaign);
    expect(saved.campaign.sessionRecaps.single.summary, summary);
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(saved.campaign.toJson())) as Map<String, dynamic>,
    );
    expect(restored.sessionRecaps.single.summary, summary);
    expect(restored.hero.toJson(), campaign.hero.toJson());
  });

  test('long recap drops NPC header when no complete identity fits', () {
    const npcs = [
      WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
      WorldNpc(id: 'mira-b', name: 'MIRA', relationship: 'feindlich'),
    ];
    final campaign = _campaign(npcs, name: _longRecapNameFor(npcs, extra: 1));
    final summary = story.MemoryEngine.buildSessionSummary(campaign);

    expect(summary.length, lessThanOrEqualTo(2400));
    expect(summary, endsWith('Held: Aria.'));
    expect(summary, isNot(contains('Bekannte NPCs:')));
    expect(summary, isNot(contains('NPC-ID:')));
    expect(campaign.npcs, hasLength(2));
  });
}
