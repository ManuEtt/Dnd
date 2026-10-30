import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

final _now = DateTime.utc(2026, 10, 30, 12);

String _firstId(String prefix) =>
    '$prefix-${_now.microsecondsSinceEpoch}-0';

Campaign _campaign({
  List<SessionRecap> recaps = const [],
  List<NpcRelationshipNote> notes = const [],
  List<StoryThread> threads = const [],
}) => Campaign(
  id: 'entry-id-collision',
  name: 'Das Archiv',
  world: 'Valdorn',
  sessionId: 'session-7',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 13),
  scene: 'Vor dem alten Archiv.',
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
  ],
  sessionRecaps: recaps,
  npcRelationshipNotes: notes,
  storyThreads: threads,
);

GameEngine _engine() => GameEngine(clock: () => _now);

void main() {
  test('restarted engine refuses to reuse a confirmed NPC note ID', () {
    final original = _campaign(
      notes: [
        NpcRelationshipNote(
          id: _firstId('npc-note'),
          npcId: 'mira',
          relationship: 'freundlich',
          note: 'Mira hat den Schlüssel bereits bestätigt.',
          recordedAt: _now,
        ),
      ],
    );
    final saved = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(saved.toJson());

    expect(
      () => _engine().recordNpcRelationship(
        saved,
        npcId: 'mira',
        relationship: 'neutral',
        note: 'Ein zweiter bestätigter Hinweis.',
      ),
      throwsFormatException,
    );
    expect(jsonEncode(saved.toJson()), before);
    expect(saved.npcRelationshipNotes, hasLength(1));
    expect(saved.npcs.single.relationship, 'freundlich');
    expect(saved.revision, 0);
  });

  test('restarted engine refuses to reuse a saved session recap ID', () {
    final campaign = _campaign(
      recaps: [
        SessionRecap(
          id: _firstId('recap'),
          title: 'Rückblick 1',
          summary: 'Das Tor wurde untersucht.',
          createdAt: _now,
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());

    expect(
      () => _engine().saveSessionRecap(campaign),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.sessionRecaps.single.summary, 'Das Tor wurde untersucht.');
  });

  test('new story thread refuses a generated ID already in use', () {
    final campaign = _campaign(
      threads: [
        StoryThread(
          id: _firstId('thread'),
          title: 'Das Tor',
          description: 'Mira kennt das Tor.',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());

    expect(
      () => _engine().saveStoryThread(
        campaign,
        title: 'Der Brunnen',
        description: 'Ein zweiter Hinweis.',
        status: 'open',
      ),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.storyThreads.single.title, 'Das Tor');
  });

  test('editing a confirmed story thread preserves its existing ID', () {
    final original = StoryThread(
      id: _firstId('thread'),
      title: 'Das Tor',
      description: 'Alter Hinweis.',
    );
    final campaign = _campaign(threads: [original]);
    final beforeHero = jsonEncode(campaign.hero.toJson());
    final result = _engine().saveStoryThread(
      campaign,
      threadId: original.id,
      title: 'Das Tor',
      description: 'Neuer bestätigter Hinweis.',
      status: 'resolved',
    );

    expect(result.campaign.storyThreads, hasLength(1));
    expect(result.campaign.storyThreads.single.id, original.id);
    expect(result.campaign.storyThreads.single.status, 'resolved');
    expect(result.campaign.revision, campaign.revision + 1);
    expect(result.events.single.type, 'memory.storyThreadSaved');
    expect(jsonEncode(result.campaign.hero.toJson()), beforeHero);
    expect(
      Campaign.fromJson(
        jsonDecode(jsonEncode(result.campaign.toJson()))
            as Map<String, dynamic>,
      ).storyThreads.single.id,
      original.id,
    );
  });

  test('new confirmed records retain distinct IDs, history and rules', () {
    final engine = _engine();
    final initial = _campaign();
    final initialHero = jsonEncode(initial.hero.toJson());

    final firstNote = engine.recordNpcRelationship(
      initial,
      npcId: 'mira',
      relationship: 'freundlich',
      note: 'Die Karte liegt im Turm.',
    );
    final secondNote = engine.recordNpcRelationship(
      firstNote.campaign,
      npcId: 'mira',
      relationship: 'freundlich',
      note: 'Mira kennt auch den Brunnen.',
    );
    final recap = engine.saveSessionRecap(secondNote.campaign);
    final thread = engine.saveStoryThread(
      recap.campaign,
      title: 'Der Brunnen',
      description: 'Finde das Archiv.',
      status: 'open',
    );
    final addedAgain = engine.saveStoryThread(
      thread.campaign,
      title: 'Das Stadttor',
      description: 'Sprich mit Mira.',
      status: 'open',
    );
    final saved = Campaign.fromJson(
      jsonDecode(jsonEncode(addedAgain.campaign.toJson()))
          as Map<String, dynamic>,
    );

    expect(saved.npcRelationshipNotes, hasLength(2));
    expect(
      saved.npcRelationshipNotes.map((entry) => entry.id).toSet(),
      hasLength(2),
    );
    expect(saved.sessionRecaps, hasLength(1));
    expect(saved.storyThreads.map((item) => item.id).toSet(), hasLength(2));
    expect(saved.revision, initial.revision + 5);
    expect(jsonEncode(saved.hero.toJson()), initialHero);
    expect(
      saved.events.map((event) => event.type).toList(),
      [
        'memory.npcRelationshipRecorded',
        'memory.npcRelationshipRecorded',
        'memory.sessionRecapSaved',
        'memory.storyThreadSaved',
        'memory.storyThreadSaved',
      ],
    );
  });
}
