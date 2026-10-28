import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

final _time = DateTime.utc(2026, 10, 25, 12);

class _CapturedTransport implements BackendTransport {
  _CapturedTransport(this.supportsContext);

  final bool supportsContext;
  final sentMemories = <List<String>>[];
  final sentPayloads = <Map<String, Object?>>[];

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
          'expiresAt': _time.add(const Duration(minutes: 5)).toIso8601String(),
          if (supportsContext) 'capabilities': ['npc-identity-v1'],
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/story/start') {
      return BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': [],
          'story': {
            'title': 'Die Stimmen von Valdorn',
            'world': 'Valdorn',
            'opening': 'Ein neuer Weg wartet auf dich. Was tust du?',
            'premise': 'Die Stadt braucht Hilfe.',
            'secret': 'Der Turm hat ein verborgenes Siegel.',
            'goal': 'Finde eine friedliche Lösung.',
            'threads': [
              {
                'id': 'turm',
                'title': 'Der versiegelte Turm',
                'description': 'Wie wird der Turm geöffnet?',
              },
              {
                'id': 'brief',
                'title': 'Der alte Brief',
                'description': 'Wer schrieb den Brief?',
              },
            ],
            'npcs': [
              {
                'id': 'mira',
                'name': 'Mira',
                'description': 'Archivarin',
                'relationship': 'neutral',
              },
            ],
            'places': [
              {
                'id': 'tor',
                'name': 'Stadttor',
                'description': 'Das westliche Stadttor',
              },
            ],
          },
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/story/advance') {
      sentMemories.add(List<String>.from(body!['memories'] as List));
      sentPayloads.add(Map<String, Object?>.from(body));
      return BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': [],
          'turn': {
            'narration': 'Mira wartet auf deine Frage. Wie antwortest du?',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unexpected request to ${uri.path}');
  }
}

void main() {
  sqfliteFfiInit();

  test(
    'twelve NPC notes fill the actual story transport memory budget',
    () async {
      final dir = await Directory.systemTemp.createTemp('npc-memory-budget-');
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: paths.join(dir.path, 'npc.sqlite'),
      );
      final transport = _CapturedTransport(true);
      final narrator = BackendNarrator(
        transport: transport,
        clock: () => _time,
      );
      final controller = GameController(
        repository: repository,
        narrator: narrator,
      );
      try {
        await controller.connectNarrator(
          url: 'https://narrator.example.test',
          sessionToken: 'test.session',
        );
        await controller.newAiCampaign(
          HeroCharacter(id: 'aria', name: 'Aria'),
          theme: 'Die alte Stadt',
        );
        expect(controller.error, isNull);
        for (var i = 0; i < 12; i++) {
          await controller.recordNpcRelationship(
            npcId: 'mira',
            relationship: 'freundlich',
            note: 'Bestätigter Hinweis Nummer $i.',
          );
          expect(controller.error, isNull);
        }
        await controller.sendAction('Ich frage Mira nach allen Hinweisen.');
        expect(controller.error, isNull);
        expect(transport.sentPayloads, hasLength(1));
        final memories = transport.sentPayloads.single['memories'] as List;
        expect(memories.length, lessThanOrEqualTo(12));
        expect(
          memories.every((item) => item is String && item.length <= 400),
          isTrue,
        );
        expect(
          memories.any((item) => item.toString().contains('Hinweis Nummer')),
          isTrue,
        );
      } finally {
        controller.dispose();
        await repository.close();
        await dir.delete(recursive: true);
      }
    },
  );

  for (final supportsContext in [false, true]) {
    test(
      'NPC identity transport negotiated=$supportsContext preserves SQLite and mechanics',
      () async {
        final dir = await Directory.systemTemp.createTemp('npc-context-');
        final dbPath = paths.join(dir.path, 'npc.sqlite');
        final repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: dbPath,
        );
        final transport = _CapturedTransport(supportsContext);
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _time,
        );
        final controller = GameController(
          repository: repository,
          narrator: narrator,
        );

        try {
          await controller.connectNarrator(
            url: 'https://narrator.example.test',
            sessionToken: 'test.session',
          );
          expect(controller.error, isNull);
          expect(narrator.supportsNpcIdentityContexts, supportsContext);
          await controller.newAiCampaign(
            HeroCharacter(id: 'aria', name: 'Aria'),
            theme: 'Die alte Stadt',
          );
          expect(controller.error, isNull);
          final originalHero = controller.currentCampaign!.hero.toJson();

          await controller.recordNpcRelationship(
            npcId: 'mira',
            relationship: 'freundlich',
            note: 'Mira verriet Aria den verborgenen Bibliotheksweg.',
          );
          expect(controller.error, isNull);
          final confirmed = controller.currentCampaign!;
          expect(confirmed.npcRelationshipNotes, hasLength(1));

          await controller.sendAction(
            'Ich frage Mira nach dem Bibliotheksweg.',
          );
          expect(controller.error, isNull);
          expect(transport.sentMemories, hasLength(1));
          final memories = transport.sentMemories.single;
          expect(memories, isNotEmpty);
          expect(memories.first, startsWith('Bestätigte NPC-Beziehungsnotiz'));
          expect(memories.first, contains('Bibliotheksweg'));
          expect(memories.every((entry) => entry.length <= 400), isTrue);
          expect(memories.length, lessThanOrEqualTo(12));
          final payload = transport.sentPayloads.single;
          if (supportsContext) {
            expect(payload['campaignRevision'], confirmed.revision + 1);
            final contexts = payload['npcContexts'] as List;
            expect(contexts, hasLength(1));
            final context = contexts.single as Map;
            expect(context['campaignId'], confirmed.id);
            expect(context['npcId'], 'mira');
            expect(context['npcName'], 'Mira');
            expect(context['relationship'], 'freundlich');
            final notes = context['notes'] as List;
            expect(notes, hasLength(1));
            expect((notes.single as Map)['npcId'], 'mira');
            expect((notes.single as Map)['note'], contains('Bibliotheksweg'));
          } else {
            expect(payload.containsKey('campaignRevision'), isFalse);
            expect(payload.containsKey('npcContexts'), isFalse);
          }
          expect(controller.currentCampaign!.hero.toJson(), originalHero);
          expect(
            (await repository.getCampaign(confirmed.id))!.hero.toJson(),
            originalHero,
          );
        } finally {
          controller.dispose();
          await repository.close();
          await dir.delete(recursive: true);
        }
      },
    );
  }
}
