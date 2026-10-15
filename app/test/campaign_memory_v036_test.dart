import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

GameEngine _engine() => GameEngine(clock: () => DateTime.utc(2026, 10, 15));

Campaign _seed() => Campaign(
  id: 'test-campaign',
  name: 'Das Licht von Mooswacht',
  world: 'Aetheria',
  sessionId: 'test-session',
  hero: HeroCharacter(id: 'hero', name: 'Arescan'),
  scene: 'Ein unbestätigter Drache fliegt in den Wolken.',
  facts: const {'keyFound': 'true', 'Ort': 'Alter Brunnen'},
  quests: const [Quest(id: 'key', title: 'Den Schlüssel finden')],
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'neutral'),
  ],
  messages: [
    NarrativeMessage(
      id: 'narrative', role: 'gm',
      text: 'Die KI erfindet einen Drachen und einen goldenen Thron.',
      timestamp: DateTime.utc(2026, 10, 15),
    ),
  ],
);

void main() {
  test('legacy saves without new optional fields remain importable', () {
    final data = _seed().toJson();
    data.remove('sessionRecaps');
    data.remove('storyThreads');
    data.remove('npcRelationshipNotes');
    final loaded = Campaign.fromJson(data);
    expect(loaded.sessionRecaps, isEmpty);
    expect(loaded.storyThreads, isEmpty);
    expect(loaded.npcRelationshipNotes, isEmpty);
    expect(loaded.hero.toJson(), _seed().hero.toJson());
  });

  test('recorded recap uses structured facts and never free narrator text', () {
    final engine = _engine();
    final original = _seed();
    final update = engine.saveSessionRecap(original);
    expect(update.events.single.type, 'memory.sessionRecapSaved');
    final recap = update.campaign.sessionRecaps.single;
    expect(recap.summary, contains('Den Schlüssel finden'));
    expect(recap.summary, contains('Mira'));
    expect(recap.summary, contains('Alter Brunnen'));
    expect(recap.summary, isNot(contains('Drachen')));
    expect(recap.summary, isNot(contains('goldenen Thron')));
    expect(original.sessionRecaps, isEmpty);
    expect(update.campaign.hero.toJson(), original.hero.toJson());
    expect(Campaign.fromJson(update.campaign.toJson()).toJson(),
        update.campaign.toJson());
    expect(update.events.single.payload['stateAfter'],
        update.campaign.copyWith(events: const []).toJson());
  });

  test('relationship history remains searchable and records every change', () {
    final engine = _engine();
    final first = engine.recordNpcRelationship(
      _seed(), npcId: 'mira', relationship: 'freundlich',
      note: 'Mira vertraut Arescan den Lageplan an.',
    );
    final next = engine.recordNpcRelationship(
      first.campaign, npcId: 'mira', relationship: 'misstrauisch',
      note: 'Arescan hat den Brunnen ohne Rückfrage geöffnet.',
    );
    expect(next.campaign.npcs.single.relationship, 'misstrauisch');
    expect(next.campaign.npcRelationshipNotes.length, 2);
    expect(next.campaign.npcRelationshipNotes.first.relationship, 'freundlich');
    expect(MemoryEngine.retrieve(next.campaign, 'Was weißt du über Mira?',
        matchingOnly: true).join(' '), contains('misstrauisch'));
    expect(next.campaign.quests, first.campaign.quests);
    expect(Campaign.fromJson(next.campaign.toJson()).toJson(),
        next.campaign.toJson());
  });

  test('open, resolved and abandoned threads persist without quest rewards', () {
    final engine = _engine();
    final first = engine.saveStoryThread(
      _seed(), title: 'Das alte Siegel',
      description: 'Wem gehört das Siegel?', status: 'open',
    );
    final id = first.campaign.storyThreads.single.id;
    final second = engine.saveStoryThread(
      first.campaign, threadId: id, title: 'Das alte Siegel',
      description: 'Der Ursprung wurde geklärt.', status: 'resolved',
    );
    expect(second.campaign.storyThreads.single.status, 'resolved');
    expect(second.campaign.storyThreads.length, 1);
    expect(second.campaign.quests.single.status, 'active');
    expect(second.campaign.hero.toJson(), first.campaign.hero.toJson());
    expect(Campaign.fromJson(second.campaign.toJson()).toJson(),
        second.campaign.toJson());
  });

  test('unknown targets and oversized input never modify a campaign', () {
    final engine = _engine();
    final campaign = _seed();
    final old = jsonEncode(campaign.toJson());
    expect(() => engine.recordNpcRelationship(campaign,
        npcId: 'unknown', relationship: 'neutral', note: 'Test'),
        throwsFormatException);
    expect(() => engine.saveStoryThread(campaign,
        threadId: 'ghost', title: 'Titel',
        description: 'Notiz', status: 'open'), throwsFormatException);
    expect(() => engine.saveStoryThread(campaign,
        title: 'Titel', description: 'Notiz', status: 'completed'),
        throwsFormatException);
    expect(() => engine.recordNpcRelationship(campaign,
        npcId: 'mira', relationship: 'neutral', note: ' '),
        throwsFormatException);
    expect(jsonEncode(campaign.toJson()), old);
  });

  test('invalid imports reject duplicates and notes for unknown NPCs', () {
    final campaign = _engine().saveSessionRecap(_seed()).campaign;
    final data = campaign.toJson();
    data['sessionRecaps'] = [
      ...campaign.sessionRecaps.map((r) => r.toJson()),
      ...campaign.sessionRecaps.map((r) => r.toJson()),
    ];
    expect(() => Campaign.fromJson(data), throwsFormatException);

    final second = _seed().toJson();
    second['npcRelationshipNotes'] = [
      NpcRelationshipNote(
        id: 'note', npcId: 'intruder', relationship: 'feindlich',
        note: 'Notiz', recordedAt: DateTime.utc(2026, 10, 15),
      ).toJson(),
    ];
    expect(() => Campaign.fromJson(second), throwsFormatException);
  });

  test('recall and event replay include saved structured records', () {
    final engine = _engine();
    final initial = _seed();
    final thread = engine.saveStoryThread(initial,
        title: 'Bogen des Mondes', description: 'Suche am Waldschrein',
        status: 'open');
    final recap = engine.saveSessionRecap(thread.campaign);
    final recall = engine.act(recap.campaign, 'Was weißt du über Mondes?');
    expect(recall.events.single.type, 'memory.recalled');
    expect(recall.narration, contains('Bogen des Mondes'));
    expect(recall.narration, isNot(contains('Drachen')));
    final reconstructed = MemoryEngine.replay(initial, [
      ...thread.events, ...recap.events, ...recall.events,
    ]);
    expect(reconstructed.toJson(), recall.campaign.toJson());
  });
}
