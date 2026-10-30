import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

final _now = DateTime.utc(2026, 10, 30, 12);

String _firstId(String prefix) => '$prefix-${_now.microsecondsSinceEpoch}-0';

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
  npcs: const [WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich')],
  sessionRecaps: recaps,
  npcRelationshipNotes: notes,
  storyThreads: threads,
);

GameEngine _engine() => GameEngine(clock: () => _now);

void main() {
  sqfliteFfiInit();

  test(
    'SQLite restart refuses duplicate journal IDs without rewriting history',
    () async {
      final dir = await Directory.systemTemp.createTemp('story-entry-ids-');
      final dbPath = paths.join(dir.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      try {
        final original = _campaign(
          notes: [
            NpcRelationshipNote(
              id: _firstId('npc-note'),
              npcId: 'mira',
              relationship: 'freundlich',
              note: 'Die alte Karte ist bestätigt.',
              recordedAt: _now,
            ),
          ],
          recaps: [
            SessionRecap(
              id: _firstId('recap'),
              title: 'Rückblick 1',
              summary: 'Der alte Brunnen.',
              createdAt: _now,
            ),
          ],
          threads: [
            StoryThread(
              id: _firstId('thread'),
              title: 'Der Brunnen',
              description: 'Ein bestätigter Hinweis.',
            ),
          ],
        );
        await repository.saveCampaign(original);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: dbPath,
        );
        final restored = (await repository.getCampaign(original.id))!;
        final before = jsonEncode(restored.toJson());
        // Each action represents a fresh engine after reopening the save.
        expect(
          () => _engine().recordNpcRelationship(
            restored,
            npcId: 'mira',
            relationship: 'neutral',
            note: 'Nicht neu bestätigen.',
          ),
          throwsFormatException,
        );
        expect(
          () => _engine().saveSessionRecap(restored),
          throwsFormatException,
        );
        expect(
          () => _engine().saveStoryThread(
            restored,
            title: 'Das Tor',
            description: 'Nicht neu bestätigen.',
            status: 'open',
          ),
          throwsFormatException,
        );
        expect(jsonEncode(restored.toJson()), before);
        expect(
          jsonEncode((await repository.getCampaign(original.id))!.toJson()),
          before,
        );
        expect(
          jsonEncode(
            (await repository.reconstructCampaign(original.id))!.toJson(),
          ),
          before,
        );

        // A genuinely new ID remains saveable without mutating old entries.
        final resumed =
            GameEngine(
              clock: () => _now.add(const Duration(milliseconds: 1)),
            ).recordNpcRelationship(
              restored,
              npcId: 'mira',
              relationship: 'freundlich',
              note: 'Mira hat eine weitere Karte bestätigt.',
            );
        await repository.saveCampaign(
          resumed.campaign,
          events: resumed.events,
          expectedRevision: restored.revision,
        );
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: dbPath,
        );
        final persisted = (await repository.getCampaign(original.id))!;
        expect(persisted.npcRelationshipNotes, hasLength(2));
        expect(persisted.npcRelationshipNotes.first.id, _firstId('npc-note'));
        expect(
          persisted.npcRelationshipNotes.first.note,
          'Die alte Karte ist bestätigt.',
        );
        expect(
          persisted.npcRelationshipNotes.map((note) => note.id).toSet(),
          hasLength(2),
        );
        expect(persisted.revision, restored.revision + 1);
        expect(persisted.hero.toJson(), original.hero.toJson());
        expect(persisted.sessionRecaps.single.id, _firstId('recap'));
        expect(persisted.storyThreads.single.id, _firstId('thread'));
        expect(
          (await repository.reconstructCampaign(original.id))!.toJson(),
          persisted.toJson(),
        );
      } finally {
        await repository.close();
        await dir.delete(recursive: true);
      }
    },
  );

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

    expect(() => _engine().saveSessionRecap(campaign), throwsFormatException);
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
    expect(saved.events.map((event) => event.type).toList(), [
      'memory.npcRelationshipRecorded',
      'memory.npcRelationshipRecorded',
      'memory.sessionRecapSaved',
      'memory.storyThreadSaved',
      'memory.storyThreadSaved',
    ]);
  });
}
