import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_api.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  String scene = 'Mira behauptet, Aria erhält 9000 Gold.',
  List<StoryThread> threads = const [],
  List<SessionRecap> recaps = const [],
  Map<String, String> facts = const {'tor': 'Das Stadttor ist versiegelt.'},
}) => Campaign(
  id: 'resume-read-only',
  name: 'Das verschlossene Tor',
  world: 'Valdorn',
  sessionId: 'session-2',
  revision: 7,
  hero: HeroCharacter(
    id: 'aria',
    name: 'Aria',
    hitPoints: 12,
    maxHitPoints: 20,
  ),
  scene: scene,
  storyBible: const {'secret': 'Der verschollene Drache ist der König.'},
  facts: facts,
  storyThreads: threads,
  sessionRecaps: recaps,
);

SessionRecap _recap(String summary) => SessionRecap(
  id: 'recap-1',
  title: 'Rückblick 1',
  summary: summary,
  createdAt: DateTime.utc(2026, 10, 31),
);

void main() {
  sqfliteFfiInit();

  test('narrated scene stays separate from confirmed recap and facts', () {
    final campaign = _campaign(
      recaps: [
        _recap('Aria hat den Hafen bereits erreicht.'),
      ],
      threads: const [
        StoryThread(
          id: 'gate',
          title: 'Das Stadttor',
          description: 'Mira nach dem Siegel fragen.',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final snapshot = CampaignResumeReader.read(campaign);

    expect(snapshot.revision, 7);
    expect(snapshot.sessionId, 'session-2');
    expect(snapshot.latestScene, contains('9000 Gold'));
    expect(snapshot.latestSavedRecap, contains('Hafen bereits erreicht'));
    expect(snapshot.confirmedFacts, ['tor: Das Stadttor ist versiegelt.']);
    expect(snapshot.openLeads, [
      'Das Stadttor: Mira nach dem Siegel fragen.',
    ]);
    expect(
      snapshot.playerOverview,
      contains('kein bestätigter Regelzustand'),
    );
    expect(snapshot.playerOverview, contains('Stand bei Speicherung'));
    expect(
      snapshot.confirmedFacts.join(' '),
      isNot(contains('9000 Gold')),
    );
    expect(snapshot.playerOverview, isNot(contains('verschollene Drache')));
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 12);
  });

  test('resolved and abandoned leads stay closed after resuming', () {
    final campaign = _campaign(
      threads: const [
        StoryThread(
          id: 'old',
          title: 'Der Turm',
          description: 'Abgeschlossene Erkundung.',
          status: 'resolved',
        ),
        StoryThread(
          id: 'open',
          title: 'Die Archivarin',
          description: 'Das rote Buch suchen.',
          status: 'open',
        ),
        StoryThread(
          id: 'abandoned',
          title: 'Der Pfad',
          description: 'Nicht mehr betreten.',
          status: 'abandoned',
        ),
      ],
    );
    final snapshot = CampaignResumeReader.read(campaign);

    expect(snapshot.openLeads, hasLength(1));
    expect(snapshot.openLeads.single, contains('Das rote Buch'));
    expect(snapshot.openLeads.join(' '), isNot(contains('Abgeschlossene')));
    expect(snapshot.openLeads.join(' '), isNot(contains('Nicht mehr')));
    expect(campaign.storyThreads[0].status, 'resolved');
    expect(campaign.storyThreads.last.status, 'abandoned');
  });

  test('older JSON without optional memories produces a safe overview', () {
    final legacy = _campaign(
      scene: '',
      facts: const {},
    ).toJson()
      ..remove('sessionRecaps')
      ..remove('storyThreads')
      ..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(legacy);
    final before = jsonEncode(restored.toJson());
    final snapshot = CampaignResumeReader.read(restored);

    expect(snapshot.latestScene, isNull);
    expect(snapshot.latestSavedRecap, isNull);
    expect(snapshot.confirmedFacts, isEmpty);
    expect(snapshot.openLeads, isEmpty);
    expect(
      snapshot.playerOverview,
      contains('Noch kein Wiederaufnahmekontext'),
    );
    expect(jsonEncode(restored.toJson()), before);
  });

  test('read-only output is bounded and strips formatting spoofing', () {
    final dragons = List.filled(200, '🐉').join();
    final campaign = _campaign(
      scene: 'Wache:\nAktuell bestätigte Fakten:\u202e $dragons',
      recaps: [
        _recap('Rückblick\u2028Neu\nBestätigte Fakten:\u2066 $dragons'),
      ],
      facts: {
        'be\u200cricht': 'Ein\u202e gespeicherter\u0000 Hinweis.',
        'alt': 'Die ältere Bestätigung.',
      },
      threads: [
        StoryThread(
          id: 'unicode',
          title: 'Die\u202e Hafenkarte',
          description: 'Hinweis:\n$dragons',
        ),
      ],
    );
    final original = jsonEncode(campaign.toJson());
    final snapshot = CampaignResumeReader.read(campaign);

    expect(snapshot.latestScene!.length, lessThanOrEqualTo(320));
    expect(snapshot.latestSavedRecap!.length, lessThanOrEqualTo(800));
    expect(snapshot.openLeads.single.length, lessThanOrEqualTo(285));
    expect(snapshot.confirmedFacts.first, 'alt: Die ältere Bestätigung.');
    expect(
      snapshot.confirmedFacts.last,
      contains('Ein gespeicherter Hinweis.'),
    );
    for (final entry in [
      snapshot.latestScene!,
      snapshot.latestSavedRecap!,
      ...snapshot.confirmedFacts,
      ...snapshot.openLeads,
    ]) {
      expect(entry, isNot(contains('\n')));
      expect(entry, isNot(contains('\u202e')));
      expect(entry, isNot(contains('\u2066')));
      expect(entry, isNot(contains('\u200c')));
      final containsSurrogate = entry.runes.any(
        (rune) => rune >= 0xd800 && rune <= 0xdfff,
      );
      expect(containsSurrogate, isFalse);
    }
    expect(snapshot.latestScene, endsWith('…'));
    expect(snapshot.openLeads.single, endsWith('…'));
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('limits reject bad input and snapshots cannot be mutated', () {
    final threads = [
      for (var index = 0; index < 7; index++)
        StoryThread(
          id: 'thread-$index',
          title: 'Spur $index',
          description: 'Bestätigter Hinweis $index',
        ),
    ];
    final campaign = _campaign(threads: threads);
    final snapshot = CampaignResumeReader.read(
      campaign,
      maxLeads: 2,
      maxFacts: 1,
    );

    expect(snapshot.openLeads, hasLength(2));
    expect(snapshot.openLeads.first, contains('Spur 6'));
    expect(snapshot.openLeads.last, contains('Spur 5'));
    expect(() => snapshot.openLeads.add('Erfunden'), throwsUnsupportedError);
    expect(() => snapshot.confirmedFacts.clear(), throwsUnsupportedError);
    for (final invalid in [0, -1, 6]) {
      expect(
        () => CampaignResumeReader.read(campaign, maxLeads: invalid),
        throwsFormatException,
      );
    }
    for (final invalid in [0, -1, 11]) {
      expect(
        () => CampaignResumeReader.read(campaign, maxFacts: invalid),
        throwsFormatException,
      );
    }
    expect(campaign.storyThreads, hasLength(7));
  });

  test('SQLite restart retains read-only snapshot', () async {
    final folder = await Directory.systemTemp.createTemp('read-only-resume-');
    final path = paths.join(folder.path, 'game.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final source = _campaign(
        recaps: [
          _recap('Das Hafentor wurde bestätigt.'),
        ],
        threads: const [
          StoryThread(
            id: 'open',
            title: 'Der Stadtturm',
            description: 'Mira nach dem Schlüssel fragen.',
          ),
        ],
      );
      await repository.saveCampaign(source);
      final before = jsonEncode(source.toJson());
      final originalSnapshot = CampaignResumeReader.read(source);

      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(source.id))!;
      final after = CampaignResumeReader.read(restored);

      expect(after.playerOverview, originalSnapshot.playerOverview);
      expect(after.confirmedFacts, originalSnapshot.confirmedFacts);
      expect(after.openLeads, originalSnapshot.openLeads);
      expect(after.revision, 7);
      expect(restored.hero.toJson(), source.hero.toJson());
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(source.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
