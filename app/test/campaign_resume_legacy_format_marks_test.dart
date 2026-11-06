import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/campaign_resume_context.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  String scene = 'Die Karte liegt am Tor.',
  Map<String, String> facts = const {'ort': 'Das Tor ist verschlossen.'},
  List<StoryThread> threads = const [],
  List<SessionRecap> recaps = const [],
}) => Campaign(
  id: 'resume-legacy-format',
  name: 'Das Stadttor',
  world: 'Valdorn',
  sessionId: 'session-two',
  revision: 0,
  hero: HeroCharacter(
    id: 'aria',
    name: 'Aria',
    hitPoints: 12,
    maxHitPoints: 20,
  ),
  scene: scene,
  facts: facts,
  storyThreads: threads,
  sessionRecaps: recaps,
  storyBible: const {'secret': 'Der alte Turm ist verflucht.'},
);

void main() {
  sqfliteFfiInit();

  test('legacy Unicode format marks cannot spoof resume text', () {
    const legacyMarks = [
      '\u00ad', // Soft hyphen
      '\u034f', // Combining grapheme joiner
      '\u180e', // Mongolian vowel separator
      '\u206a', // Deprecated directional formatting controls
      '\u206b',
      '\u206c',
      '\u206d',
      '\u206e',
      '\u206f',
    ];
    final marks = legacyMarks.join();
    final campaign = _campaign(
      scene: 'Die Szene: Vor$marks der Tür.',
      recaps: [
        SessionRecap(
          id: 'recap-one',
          title: 'Rückblick',
          summary: 'Früherer Rückblick: Sicher$marks notiert.',
          createdAt: DateTime.utc(2026, 11, 5),
        ),
      ],
      facts: {'Karte$marks': 'Belegt$marks im Archiv.'},
      threads: [
        StoryThread(
          id: 'lead-one',
          title: 'Stadt$marks Tor',
          description: 'Suche$marks den Schlüssel.',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());

    final snapshot = CampaignResumeReader.read(campaign);

    expect(snapshot.latestScene, 'Die Szene: Vor der Tür.');
    expect(snapshot.latestSavedRecap, 'Früherer Rückblick: Sicher notiert.');
    expect(snapshot.confirmedFacts, ['Karte: Belegt im Archiv.']);
    expect(snapshot.openLeads, ['Stadt Tor: Suche den Schlüssel.']);
    for (final mark in legacyMarks) {
      expect(snapshot.playerOverview, isNot(contains(mark)));
    }
    expect(snapshot.playerOverview, isNot(contains('verflucht')));
    snapshot.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 12);
    expect(campaign.revision, 0);
  });

  test('Unicode is retained while hidden edits remain stale', () {
    final campaign = _campaign(
      scene: 'Ärger am Tor – שלום مرحبا 🐉',
      threads: const [
        StoryThread(
          id: 'quest_1',
          title: 'Die Älteste',
          description: 'Den Hinweis im Außenhof suchen. 🐉',
        ),
      ],
    );
    final saved = CampaignResumeReader.read(campaign);
    final altered = campaign.copyWith(
      scene: 'Ärger am Tor – שלום مرحبا \u00ad🐉',
    );

    expect(saved.latestScene, 'Ärger am Tor – שלום مرحبا 🐉');
    expect(saved.openLeads.single, contains('Außenhof suchen. 🐉'));
    expect(CampaignResumeReader.read(altered).latestScene, saved.latestScene);
    expect(() => saved.requireCurrent(altered), throwsFormatException);
    saved.requireCurrent(campaign);
    expect(campaign.hero.hitPoints, 12);
  });

  test('canonical continuation survives SQLite restart', () async {
    final folder = await Directory.systemTemp.createTemp('resume-legacy-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = _campaign(
        recaps: [
          SessionRecap(
            id: 'recap-one',
            title: 'Rückblick',
            summary: 'Die Älteste hat die Karte bestätigt.',
            createdAt: DateTime.utc(2026, 11, 5),
          ),
        ],
        threads: const [
          StoryThread(
            id: 'lead-one',
            title: 'Der Brunnen',
            description: 'Den Schlüssel suchen.',
          ),
        ],
      );
      final originalJson = jsonEncode(campaign.toJson());
      final expected = CampaignResumeReader.read(campaign);

      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(campaign.id))!;
      final actual = CampaignResumeReader.read(restored);

      expect(actual.playerOverview, expected.playerOverview);
      expect(actual.openLeads, expected.openLeads);
      expect(actual.confirmedFacts, expected.confirmedFacts);
      actual.requireCurrent(restored);
      expect(jsonEncode(restored.toJson()), originalJson);
      expect(restored.hero.toJson(), campaign.hero.toJson());
      expect(
        (await repository.reconstructCampaign(campaign.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
