import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Map<String, dynamic> _plan() => {
  'title': 'Die Stimmen des Hafens',
  'world': 'Valdorn',
  'opening': 'Eila, ein Segel erscheint am Horizont. Was tust du?',
  'premise': 'Die Küste wartet auf eine Entscheidung.',
  'secret': 'Der alte Schwur wurde im Hafen verborgen.',
  'goal': 'Entscheide selbst über das Schicksal der Küste.',
  'threads': [
    {
      'id': 'hafen',
      'title': 'Die Hafenspuren',
      'description': 'Untersuche die seltsamen Segel.',
    },
    {
      'id': 'bund',
      'title': 'Ein alter Bund',
      'description': 'Sprich mit den Küstenbewohnern.',
    },
  ],
  'npcs': [
    {
      'id': 'tela',
      'name': 'Tela',
      'description': 'Die Kapitänin',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {
      'id': 'anleger',
      'name': 'Der Anleger',
      'description': 'Ein alter Steg an der Küste.',
    },
  ],
};

Map<String, dynamic> _storyReply(String status, String description) => {
  'narration': 'Die Reise führt am Hafen weiter. Was unternimmst du?',
  'threadUpdates': [
    {'id': 'hafen', 'status': status, 'description': description},
  ],
  'newThreads': [],
  'npcUpdates': [],
  'adventure': null,
};

void main() {
  sqfliteFfiInit();

  for (final ending in ['resolved', 'abandoned']) {
    test('SQLite preserves corrected $ending ending after restart', () async {
      final directory = await Directory.systemTemp.createTemp('thread-end-');
      final path = paths.join(directory.path, 'story.sqlite');
      final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 26, 12));
      final original = engine.createAiCampaign(
        HeroCharacter(id: 'hero-$ending', name: 'Eila'),
        AiStoryPlan.fromJson(_plan()),
        provider: 'mock',
      );
      final heroJson = jsonEncode(original.hero.toJson());
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );

      try {
        await repository.saveCampaign(original);
        final finished = engine.saveStoryThread(
          original,
          threadId: 'hafen',
          title: 'Die Hafenspuren',
          description: 'Das erste bestätigte Ende.',
          status: ending,
        );
        await repository.saveCampaign(
          finished.campaign,
          events: finished.events,
          expectedRevision: original.revision,
        );
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );

        final loaded = (await repository.getCampaign(original.id))!;
        expect(loaded.storyThreads.first.status, ending);
        expect(
          loaded.storyThreads.first.description,
          'Das erste bestätigte Ende.',
        );

        // Only an explicit local journal edit may correct confirmed history.
        final corrected = engine.saveStoryThread(
          loaded,
          threadId: 'hafen',
          title: 'Die Hafenspuren',
          description: 'Der Spieler hat das Ende ausdrücklich berichtigt.',
          status: ending,
        );
        expect(corrected.events.single.type, 'memory.storyThreadSaved');
        await repository.saveCampaign(
          corrected.campaign,
          events: corrected.events,
          expectedRevision: loaded.revision,
        );
        final afterCorrection = (await repository.reconstructCampaign(
          original.id,
        ))!;
        expect(afterCorrection.toJson(), corrected.campaign.toJson());
        expect(
          afterCorrection.storyThreads.first.description,
          'Der Spieler hat das Ende ausdrücklich berichtigt.',
        );

        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final resumed = (await repository.getCampaign(original.id))!;
        final baseline = jsonEncode(resumed.toJson());
        expect(resumed.revision, original.revision + 2);
        expect(resumed.storyThreads.first.status, ending);
        expect(resumed.hero.toJson(), original.hero.toJson());
        expect(resumed.events.last.type, 'memory.storyThreadSaved');

        final decision = 'Ich gehe zum Hafen und sehe nach dem Schiff.';
        final pending = engine.act(resumed, decision);
        expect(pending.events.single.type, 'narrative.turn');

        // The narrator may not silently replace the player's saved ending.
        expect(
          () => AiStoryStep.fromJson(
            _storyReply(ending, 'Die KI erfindet einen anderen Abschluss.'),
            pending.campaign,
          ),
          throwsFormatException,
        );
        expect(jsonEncode(resumed.toJson()), baseline);
        expect(
          jsonEncode((await repository.getCampaign(original.id))!.toJson()),
          baseline,
        );

        // An unchanged terminal thread may accompany a normal new scene.
        final accepted = AiStoryStep.fromJson(
          _storyReply(
            ending,
            'Der Spieler hat das Ende ausdrücklich berichtigt.',
          ),
          pending.campaign,
        );
        final applied = engine.applyAiStoryStep(
          pending,
          accepted,
          provider: 'mock',
          decision: decision,
        );
        expect(
          applied.campaign.storyThreads.first.description,
          'Der Spieler hat das Ende ausdrücklich berichtigt.',
        );
        expect(jsonEncode(applied.campaign.hero.toJson()), heroJson);
        expect(applied.campaign.quests, isEmpty);
        await repository.saveCampaign(
          applied.campaign,
          events: applied.events,
          expectedRevision: resumed.revision,
        );

        final confirmed = (await repository.getCampaign(original.id))!;
        expect(confirmed.storyThreads.first.status, ending);
        expect(
          confirmed.storyThreads.first.description,
          'Der Spieler hat das Ende ausdrücklich berichtigt.',
        );
        expect(jsonEncode(confirmed.hero.toJson()), heroJson);
        expect(
          (await repository.reconstructCampaign(original.id))!.toJson(),
          confirmed.toJson(),
        );
      } finally {
        await repository.close();
        await directory.delete(recursive: true);
      }
    });
  }
}
