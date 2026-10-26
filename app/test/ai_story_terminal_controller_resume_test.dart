import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

final _now = DateTime.utc(2026, 10, 26, 12);
const _corrected = 'Der Spieler hat den Hafenabschluss berichtigt.';

Map<String, dynamic> _plan() => {
  'title': 'Die Küstenentscheidung',
  'world': 'Valdorn',
  'opening': 'Ein Segel erscheint. Welchen Weg nimmst du?',
  'premise': 'Die Stadt erwartet eine Entscheidung.',
  'secret': 'Die Küste schützt einen alten Schwur.',
  'goal': 'Wähle selbst das Schicksal der Stadt.',
  'threads': [
    {
      'id': 'hafen',
      'title': 'Die Hafenspuren',
      'description': 'Finde die Ursache der seltsamen Segel.',
    },
    {
      'id': 'bund',
      'title': 'Der alte Bund',
      'description': 'Erkunde die Verbindungen der Bewohner.',
    },
  ],
  'npcs': [
    {
      'id': 'tela',
      'name': 'Tela',
      'description': 'Eine Kapitänin',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {
      'id': 'pier',
      'name': 'Der Pier',
      'description': 'Ein Anleger im Nebel.',
    },
  ],
};

class _EndingTransport implements BackendTransport {
  bool rewriteEnding = true;
  int advances = 0;
  final requests = <Map<String, Object?>>[];

  @override
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) async {
    if (method == 'GET' && uri.path == '/v1/session') {
      return BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'scope': 'narration:read-only',
          'expiresAt': _now.add(const Duration(minutes: 5)).toIso8601String(),
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/story/advance') {
      advances++;
      requests.add(Map<String, Object?>.from(body!));
      final threads = body['threads'] as List;
      final saved = threads.cast<Map>().singleWhere(
        (thread) => thread['id'] == 'hafen',
      );
      return BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': <Object>[],
          'turn': {
            'narration': 'Der Hafen bleibt unverändert. Wohin gehst du?',
            'threadUpdates': [
              {
                'id': 'hafen',
                'status': saved['status'],
                'description': rewriteEnding
                    ? 'Die KI behauptet einen anderen Abschluss.'
                    : saved['description'],
              },
            ],
            'newThreads': <Object>[],
            'npcUpdates': <Object>[],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unerwartete Backend-Anfrage: ${uri.path}');
  }
}

void main() {
  sqfliteFfiInit();

  for (final ending in ['resolved', 'abandoned']) {
    test('controller resumes $ending ending without AI rewriting history',
        () async {
      final folder = await Directory.systemTemp.createTemp('story-controller-');
      final path = paths.join(folder.path, 'campaign.sqlite');
      final seedEngine = GameEngine(clock: () => _now);
      final campaign = seedEngine.createAiCampaign(
        HeroCharacter(id: 'hero-$ending', name: 'Eila'),
        AiStoryPlan.fromJson(_plan()),
        provider: 'mock',
      );
      var repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      GameController? active;
      try {
        await repo.saveCampaign(campaign);
        active = GameController(repository: repo);
        await active.initialize();
        await active.openCampaign(campaign.id);
        expect(active.error, isNull);
        await active.saveStoryThread(
          threadId: 'hafen',
          title: 'Die Hafenspuren',
          description: 'Zuerst bestätigter Abschluss.',
          status: ending,
        );
        expect(active.error, isNull);
        await active.saveStoryThread(
          threadId: 'hafen',
          title: 'Die Hafenspuren',
          description: _corrected,
          status: ending,
        );
        expect(active.error, isNull);
        final beforeRestart = active.currentCampaign!;
        final heroSnapshot = jsonEncode(beforeRestart.hero.toJson());
        expect(beforeRestart.revision, campaign.revision + 2);
        active.dispose();
        active = null;
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );

        final transport = _EndingTransport();
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _now,
        );
        active = GameController(repository: repo, narrator: narrator);
        await active.initialize();
        expect(active.error, isNull);
        // Session credentials must not survive the app/controller restart.
        expect(narrator.enabled, isFalse);
        expect(active.currentCampaign!.id, campaign.id);
        expect(active.currentCampaign!.storyThreads.first.status, ending);
        expect(active.currentCampaign!.storyThreads.first.description,
            _corrected);

        await active.connectNarrator(
          url: 'https://story.example.test',
          sessionToken: 'story.session',
        );
        expect(active.error, isNull);
        expect(narrator.enabled, isTrue);

        final originalRevision = active.currentCampaign!.revision;
        await active.sendAction('Ich gehe zum Hafen.');
        expect(active.error, isNull);
        expect(transport.advances, 1);
        expect(transport.requests.single['campaignId'], campaign.id);
        expect(narrator.statusMessage, contains('nicht übernommen'));
        final afterRejected = active.currentCampaign!;
        expect(afterRejected.revision, originalRevision + 1);
        expect(afterRejected.storyBible['turnCount'], '0');
        expect(afterRejected.storyThreads.first.status, ending);
        expect(afterRejected.storyThreads.first.description, _corrected);
        expect(jsonEncode(afterRejected.hero.toJson()), heroSnapshot);
        expect(afterRejected.quests, isEmpty);
        expect(
          (await repo.reconstructCampaign(campaign.id))!.toJson(),
          afterRejected.toJson(),
        );

        transport.rewriteEnding = false;
        await active.sendAction('Ich untersuche die Anlegestelle.');
        expect(active.error, isNull);
        expect(transport.advances, 2);
        final afterAccepted = active.currentCampaign!;
        expect(afterAccepted.revision, originalRevision + 2);
        expect(afterAccepted.storyBible['turnCount'], '1');
        expect(afterAccepted.scene, contains('Hafen bleibt unverändert'));
        expect(afterAccepted.storyThreads.first.status, ending);
        expect(afterAccepted.storyThreads.first.description, _corrected);
        expect(jsonEncode(afterAccepted.hero.toJson()), heroSnapshot);
        expect(afterAccepted.quests, isEmpty);
        expect(afterAccepted.events.last.payload['storyProvider'], 'mock');
        expect(
          (await repo.reconstructCampaign(campaign.id))!.toJson(),
          afterAccepted.toJson(),
        );
      } finally {
        active?.dispose();
        await repo.close();
        await folder.delete(recursive: true);
      }
    });
  }
}
