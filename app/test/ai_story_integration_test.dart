import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

final _now = DateTime.utc(2026, 10, 15, 11);

class _AiTransport implements BackendTransport {
  bool invalidStart = false;
  bool failAdvance = false;
  int starts = 0;
  int advances = 0;
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
    if (method == 'POST' && uri.path == '/v1/story/start') {
      starts++;
      return BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': [],
          'story': {
            'title': invalidStart ? '' : 'Das Rätsel von Seefall',
            'world': 'Veyr',
            'opening': 'Eila, ein Leuchtfeuer erlischt. Wie entscheidest du?',
            'premise': 'Die Küste ist in Gefahr.',
            'secret': 'Tela kennt die echte Ursache.',
            'goal': 'Rette die Küste auf eigene Weise.',
            'threads': [
              {
                'id': 'licht',
                'title': 'Das Leuchtfeuer',
                'description': 'Warum ist es erloschen?',
              },
              {
                'id': 'bund',
                'title': 'Alter Bund',
                'description': 'Finde einen Verbündeten.',
              },
            ],
            'npcs': [
              {
                'id': 'tela',
                'name': 'Tela',
                'description': 'Kapitänin',
                'relationship': 'neutral',
              },
            ],
            'places': [
              {
                'id': 'seefall',
                'name': 'Seefall',
                'description': 'Die Küstenstadt',
              },
            ],
          },
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/story/advance') {
      advances++;
      if (failAdvance) throw const SocketException('fake network error');
      return BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': [],
          'turn': {
            'narration':
                'Tela öffnet den verschlossenen Atlas. Willst du ihr vertrauen?',
            'threadUpdates': [
              {
                'id': 'licht',
                'status': 'resolved',
                'description': 'Die Karte weist einen neuen Weg.',
              },
            ],
            'newThreads': [
              {
                'id': 'atlas',
                'title': 'Der Atlas',
                'description': 'Erkunde die markierte Insel.',
              },
            ],
            'npcUpdates': [
              {
                'id': 'tela',
                'relationship': 'verbündet',
                'note': 'Eila rettete die Seekarte.',
              },
            ],
          },
        },
      );
    }
    throw StateError('Unexpected ${uri.path}');
  }
}

void main() {
  sqfliteFfiInit();
  test(
    'AI story is saved atomically, advances and restores across restarts',
    () async {
      final directory = await Directory.systemTemp.createTemp('ai-story-');
      final path = paths.join(directory.path, 'ai.sqlite');
      try {
        final repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final transport = _AiTransport();
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _now,
        );
        final controller = GameController(
          repository: repository,
          narrator: narrator,
        );
        await controller.connectNarrator(
          url: 'https://narrator.example.test',
          sessionToken: 'test.session',
          requestLimit: 12,
        );
        expect(controller.error, isNull);
        final hero = HeroCharacter(id: 'eila', name: 'Eila');
        transport.invalidStart = true;
        await controller.newAiCampaign(hero, theme: 'Spannende Geschichte');
        expect(controller.error, isNotNull);
        expect((await repository.loadCampaigns()), isEmpty);
        transport.invalidStart = false;
        await controller.newAiCampaign(hero, theme: 'Spannende Geschichte');
        expect(controller.error, isNull);
        final created = controller.currentCampaign!;
        expect(created.storyBible['secret'], isNotEmpty);
        expect(created.storyThreads, hasLength(2));
        expect(created.hero.hitPoints, isNull);
        await controller.sendAction('Ich bitte Tela um die Seekarte.');
        expect(controller.error, isNull);
        final advanced = controller.currentCampaign!;
        expect(advanced.revision, created.revision + 1);
        expect(advanced.hero.toJson(), created.hero.toJson());
        expect(advanced.storyThreads, hasLength(3));
        expect(advanced.storyThreads.first.status, 'resolved');
        expect(advanced.npcs.first.relationship, 'verbündet');
        expect(advanced.storyBible['turnCount'], '1');
        expect(
          (await repository.reconstructCampaign(created.id))!.toJson(),
          advanced.toJson(),
        );
        final exported = await repository.exportCampaign(created.id);
        expect(exported, contains('Tela kennt die echte Ursache.'));
        transport.failAdvance = true;
        await controller.sendAction('Ich erforsche die Insel.');
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.storyBible['turnCount'], '1');
        expect(controller.currentCampaign!.revision, advanced.revision + 1);
        controller.dispose();
        await repository.close();
        final reopened = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final recovered = await reopened.getCampaign(created.id);
        expect(recovered!.storyBible['secret'], created.storyBible['secret']);
        expect(recovered.storyThreads.length, 3);
        expect(recovered.npcRelationshipNotes, hasLength(1));
        await reopened.close();
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
