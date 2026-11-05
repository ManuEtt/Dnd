import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/campaign_resume_context.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _recapTime = DateTime.utc(2026, 11, 5);

Campaign _campaign({
  String id = 'campaign-resume-stamp',
  String sessionId = 'session-two',
  int revision = 7,
  String scene = 'Mira erzählt eine unbestätigte Geschichte.',
  Map<String, String>? facts,
  List<StoryThread>? threads,
  List<SessionRecap>? recaps,
}) => Campaign(
  id: id,
  name: 'Die verschwundene Karte',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 12),
  scene: scene,
  facts: facts ?? const {'tor': 'Das Tor ist verschlossen.'},
  storyThreads:
      threads ??
      const [
        StoryThread(
          id: 'tower',
          title: 'Der Turm',
          description: 'Das Siegel prüfen.',
        ),
      ],
  sessionRecaps:
      recaps ??
      [
        SessionRecap(
          id: 'recap-one',
          title: 'Früherer Rückblick',
          summary: 'Die Gruppe fand einen Hinweis.',
          createdAt: _recapTime,
        ),
      ],
);

void main() {
  sqfliteFfiInit();

  test('reader snapshot validates JSON and rejects foreign IDs', () {
    final campaign = _campaign();
    final snapshot = CampaignResumeReader.read(campaign);
    final before = jsonEncode(campaign.toJson());
    final jsonClone = Campaign.fromJson(
      jsonDecode(before) as Map<String, dynamic>,
    );

    snapshot.requireCurrent(campaign);
    snapshot.requireCurrent(jsonClone);
    expect(jsonEncode(campaign.toJson()), before);
    expect(
      () => snapshot.requireCurrent(_campaign(id: 'another-campaign')),
      throwsFormatException,
    );
    expect(
      () => snapshot.requireCurrent(_campaign(sessionId: 'session-three')),
      throwsFormatException,
    );
    expect(
      () => snapshot.requireCurrent(campaign.copyWith(revision: 8)),
      throwsFormatException,
    );
  });

  test('even hidden changes beyond the visible scene are stale', () {
    final dragons = List.filled(210, '🐉').join();
    final campaign = _campaign(scene: '$dragons first ending');
    final snapshot = CampaignResumeReader.read(campaign);
    final changed = campaign.copyWith(scene: '$dragons second ending');
    final before = jsonEncode(campaign.toJson());

    expect(
      CampaignResumeReader.read(changed).latestScene,
      snapshot.latestScene,
    );
    expect(snapshot.latestScene, endsWith('…'));
    expect(() => snapshot.requireCurrent(changed), throwsFormatException);
    snapshot.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('unselected facts, old recaps and earlier leads remain provenance', () {
    final campaign = _campaign(
      facts: const {
        'hidden': 'Die ursprüngliche ältere Entdeckung.',
        'visible': 'Das Stadttor wurde verschlossen.',
      },
      threads: const [
        StoryThread(
          id: 'old-lead',
          title: 'Der Keller',
          description: 'Den Keller durchsuchen.',
        ),
        StoryThread(
          id: 'new-lead',
          title: 'Die Brücke',
          description: 'Die Brücke beobachten.',
        ),
      ],
      recaps: [
        SessionRecap(
          id: 'old-recap',
          title: 'Früher',
          summary: 'Das erste Geheimnis.',
          createdAt: _recapTime,
        ),
        SessionRecap(
          id: 'new-recap',
          title: 'Zuletzt',
          summary: 'Die Ankunft in der Stadt.',
          createdAt: _recapTime,
        ),
      ],
    );
    final snapshot = CampaignResumeReader.read(
      campaign,
      maxFacts: 1,
      maxLeads: 1,
    );
    final changes = [
      campaign.copyWith(
        facts: const {
          'hidden': 'Eine andere ältere Entdeckung.',
          'visible': 'Das Stadttor wurde verschlossen.',
        },
      ),
      campaign.copyWith(
        storyThreads: const [
          StoryThread(
            id: 'old-lead',
            title: 'Der Keller',
            description: 'Ein anderer Hinweis.',
          ),
          StoryThread(
            id: 'new-lead',
            title: 'Die Brücke',
            description: 'Die Brücke beobachten.',
          ),
        ],
      ),
      campaign.copyWith(
        sessionRecaps: [
          SessionRecap(
            id: 'old-recap',
            title: 'Früher',
            summary: 'Ein veränderter Rückblick.',
            createdAt: _recapTime,
          ),
          campaign.sessionRecaps.last,
        ],
      ),
    ];

    expect(snapshot.confirmedFacts, [
      'visible: Das Stadttor wurde verschlossen.',
    ]);
    expect(snapshot.openLeads, ['Die Brücke: Die Brücke beobachten.']);
    for (final changed in changes) {
      expect(
        CampaignResumeReader.read(
          changed,
          maxFacts: 1,
          maxLeads: 1,
        ).playerOverview,
        snapshot.playerOverview,
      );
      expect(() => snapshot.requireCurrent(changed), throwsFormatException);
    }
    snapshot.requireCurrent(campaign);
  });

  test('rule-only edits cannot turn an unchanged recap into a stale fact', () {
    final campaign = _campaign();
    final snapshot = CampaignResumeReader.read(campaign);
    final combatOnly = campaign.copyWith(
      hero: campaign.hero.copyWith(hitPoints: 4),
    );
    final before = jsonEncode(campaign.toJson());

    snapshot.requireCurrent(combatOnly);
    expect(snapshot.confirmedFacts, contains('tor: Das Tor ist verschlossen.'));
    expect(snapshot.latestScene, contains('unbestätigte Geschichte'));
    expect(snapshot.confirmedFacts.join(' '), isNot(contains('Geschichte')));
    expect(jsonEncode(campaign.toJson()), before);
    expect(combatOnly.hero.hitPoints, 4);
  });

  test('unbound snapshots fail closed without saved source identity', () {
    final forged = CampaignResumeSnapshot(
      revision: 7,
      sessionId: 'session-two',
      confirmedFacts: const ['tor: Angeblich offen.'],
      openLeads: const ['Neuer Schatz: 999 Gold.'],
    );
    expect(() => forged.requireCurrent(_campaign()), throwsFormatException);
  });

  test('SQLite restart checks source without rewriting saves', () async {
    final folder = await Directory.systemTemp.createTemp('resume-stamp-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    final campaign = _campaign(revision: 0);
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      await repository.saveCampaign(campaign);
      final snapshot = CampaignResumeReader.read(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(campaign.id))!;
      final before = jsonEncode(restored.toJson());

      snapshot.requireCurrent(restored);
      final changed = restored.copyWith(
        facts: const {'tor': 'Das Tor wurde wieder geöffnet.'},
      );
      expect(() => snapshot.requireCurrent(changed), throwsFormatException);
      expect(restored.hero.hitPoints, 12);
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(restored.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
