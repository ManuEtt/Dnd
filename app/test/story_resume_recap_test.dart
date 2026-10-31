import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _now = DateTime.utc(2026, 10, 31, 12);

Campaign _campaign({
  List<StoryThread> threads = const [],
  Map<String, String> facts = const {'archiv': 'Das Tor ist versiegelt.'},
}) => Campaign(
  id: 'resume-confirmed',
  name: 'Das vergessene Archiv',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 17,
    maxHitPoints: 20,
  ),
  scene: 'Ein unbestätigter Drache schenkt dir 9000 Gold.',
  messages: [
    NarrativeMessage(
      id: 'unconfirmed',
      role: 'gm',
      text: 'Du bekommst ein Schwert und 9000 Gold.',
      timestamp: _now,
    ),
  ],
  storyBible: const {'secret': 'Der verborgene Schatz liegt im Turm.'},
  facts: facts,
  storyThreads: threads,
);

const _threads = [
  StoryThread(
    id: 'old',
    title: 'Die alte Mühle',
    description: 'Den verschlossenen Keller untersuchen.',
  ),
  StoryThread(
    id: 'closed',
    title: 'Die Brücke',
    description: 'Dieser Weg ist bereits abgeschlossen.',
    status: 'resolved',
  ),
  StoryThread(
    id: 'recent',
    title: 'Die Archivarin',
    description: 'Mira nach dem verschwundenen Buch befragen.',
  ),
  StoryThread(
    id: 'abandoned',
    title: 'Der Turm',
    description: 'Diesen Pfad nicht mehr verfolgen.',
    status: 'abandoned',
  ),
  StoryThread(
    id: 'latest',
    title: 'Die Hafenkarte',
    description: 'Den sicheren Anlegeplatz bei Tarek erfragen.',
  ),
];

void main() {
  sqfliteFfiInit();

  test('recap retains up to three confirmed open leads in stable order', () {
    final campaign = _campaign(threads: _threads);
    final original = jsonEncode(campaign.toJson());
    final result = GameEngine(clock: () => _now).saveSessionRecap(campaign);
    final summary = result.campaign.sessionRecaps.single.summary;
    final leads = summary.split('Offene Anknüpfungspunkte').last;

    expect(leads, contains('Die Hafenkarte: Den sicheren Anlegeplatz'));
    expect(leads, contains('Die Archivarin: Mira nach dem'));
    expect(leads, contains('Die alte Mühle: Den verschlossenen Keller'));
    expect(leads.indexOf('Die Hafenkarte'), lessThan(leads.indexOf('Die Archivarin')));
    expect(leads.indexOf('Die Archivarin'), lessThan(leads.indexOf('Die alte Mühle')));
    expect(leads, isNot(contains('Dieser Weg ist bereits abgeschlossen')));
    expect(leads, isNot(contains('Diesen Pfad nicht mehr verfolgen')));
    expect(summary, contains('Das Tor ist versiegelt.'));
    expect(summary, isNot(contains('9000 Gold')));
    expect(summary, isNot(contains('Der verborgene Schatz')));
    expect(result.events.single.type, 'memory.sessionRecapSaved');
    expect(result.campaign.hero.toJson(), campaign.hero.toJson());
    expect(result.campaign.storyThreads.map((e) => e.toJson()).toList(),
        campaign.storyThreads.map((e) => e.toJson()).toList());
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('closed or empty leads cannot be invented as resume prompts', () {
    final campaign = _campaign(
      threads: const [
        StoryThread(
          id: 'done',
          title: 'Das letzte Siegel',
          description: 'Die Prüfung ist beendet.',
          status: 'resolved',
        ),
        StoryThread(
          id: 'empty',
          title: 'Noch ohne Hinweis',
          description: '   ',
        ),
      ],
    );
    final result = GameEngine(clock: () => _now).saveSessionRecap(campaign);
    final text = result.campaign.sessionRecaps.single.summary;

    expect(text, isNot(contains('Offene Anknüpfungspunkte')));
    expect(text, isNot(contains('Die Prüfung ist beendet.')));
    expect(text, contains('Das letzte Siegel'));
  });

  test('resume lead truncation is Unicode-safe and text is single-line', () {
    final dragons = List.filled(100, '🐉').join();
    final campaign = _campaign(
      threads: [
        StoryThread(
          id: 'unicode',
          title: 'Mira\u202e',
          description: 'Die\nKarte \u2066liegt am Kai. $dragons',
        ),
      ],
    );
    final original = jsonEncode(campaign.toJson());
    final summary = GameEngine(clock: () => _now)
        .saveSessionRecap(campaign)
        .campaign
        .sessionRecaps
        .single
        .summary;
    final leads = summary.split('Offene Anknüpfungspunkte').last;

    expect(leads, contains('Mira: Die Karte  liegt am Kai.'));
    expect(leads, isNot(contains('\u202e')));
    expect(leads, isNot(contains('\u2066')));
    expect(leads.trimRight().endsWith('…'), isTrue);
    expect(
      leads.runes.any((rune) => rune >= 0xd800 && rune <= 0xdfff),
      isFalse,
    );
    expect(summary.length, lessThanOrEqualTo(2400));
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('full recap never drops confirmed facts to add another open lead', () {
    final campaign = _campaign(
      threads: const [
        StoryThread(
          id: 'open',
          title: 'Der Hafen',
          description: 'Den nächsten Hinweis suchen.',
        ),
      ],
      facts: {
        for (var index = 0; index < 150; index++)
          'bestätigt_index_$index': List.filled(40, 'x').join(),
      },
    );
    final update = GameEngine(clock: () => _now).saveSessionRecap(campaign);
    final summary = update.campaign.sessionRecaps.single.summary;

    expect(summary.length, lessThanOrEqualTo(2400));
    expect(summary, isNot(contains('Offene Anknüpfungspunkte')));
    expect(summary, contains('bestätigt_index_0'));
    expect(Campaign.fromJson(update.campaign.toJson()).toJson(),
        update.campaign.toJson());
  });

  test('saved continuation survives SQLite restart and replay', () async {
    final folder = await Directory.systemTemp.createTemp('resume-recap-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final original = _campaign(threads: _threads);
      await repository.saveCampaign(original);
      final update = GameEngine(clock: () => _now).saveSessionRecap(original);
      await repository.saveCampaign(
        update.campaign,
        events: update.events,
        expectedRevision: original.revision,
      );
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final resumed = (await repository.getCampaign(original.id))!;
      final recap = resumed.sessionRecaps.single.summary;

      expect(recap, contains('Die Hafenkarte: Den sicheren Anlegeplatz'));
      expect(recap, isNot(contains('9000 Gold')));
      expect(resumed.revision, original.revision + 1);
      expect(resumed.events, hasLength(1));
      expect(resumed.hero.toJson(), original.hero.toJson());
      expect(resumed.quests, isEmpty);
      expect(
        (await repository.reconstructCampaign(original.id))!.toJson(),
        resumed.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
