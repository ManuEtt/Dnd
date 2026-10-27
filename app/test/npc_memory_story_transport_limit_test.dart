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

final _now = DateTime.utc(2026, 10, 27, 12);

Map<String, dynamic> _plan() => {
  'title': 'Die Tore von Valdorn',
  'world': 'Valdorn',
  'opening': 'Die Archivarin wartet am Hafen. Was tust du?',
  'premise': 'Die Stadt sucht die verlorene Chronik.',
  'secret': 'Eine alte Truhe verbirgt das Siegel.',
  'goal': 'Finde die Chronik ohne jemanden zu verletzen.',
  'threads': [
    {
      'id': 'chronik',
      'title': 'Die Chronik',
      'description': 'Finde das verborgene Buch.',
    },
    {
      'id': 'tor',
      'title': 'Das Hafentor',
      'description': 'Warum ist das Tor geschlossen?',
    },
  ],
  'npcs': [
    {
      'id': 'mira',
      'name': 'Mira',
      'description': 'Archivarin am Hafen',
      'relationship': 'freundlich',
    },
  ],
  'places': [
    {
      'id': 'hafen',
      'name': 'Der Hafen',
      'description': 'Eine alte Anlegestelle.',
    },
  ],
};

class _CapturingStoryTransport implements BackendTransport {
  _CapturingStoryTransport({required this.identityContext});

  final bool identityContext;
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
          if (identityContext) 'capabilities': ['npc-identity-v1'],
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/story/advance') {
      requests.add(Map<String, Object?>.from(body!));
      return const BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': [],
          'turn': {
            'narration': 'Mira zeigt auf die Chronik. Was machst du als Nächstes?',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unerwartete Anfrage: ${uri.path}');
  }
}

void main() {
  sqfliteFfiInit();

  for (final supportsContext in [false, true]) {
    test(
      'full Story transport keeps exactly 12 memories (identity=$supportsContext)',
      () async {
        final folder = await Directory.systemTemp.createTemp(
          'story-twelve-memories-',
        );
        final path = paths.join(folder.path, 'campaign.sqlite');
        final repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final transport = _CapturingStoryTransport(
          identityContext: supportsContext,
        );
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _now,
        );
        final controller = GameController(
          repository: repository,
          narrator: narrator,
        );
        try {
          final original = GameEngine(clock: () => _now).createAiCampaign(
            HeroCharacter(id: 'aria', name: 'Aria'),
            AiStoryPlan.fromJson(_plan()),
            provider: 'mock',
          );
          final campaign = original.copyWith(
            facts: {
              for (var i = 0; i < 24; i++)
                'hinweis_${i.toString().padLeft(2, '0')}':
                    'Bestätigter Stadthinweis Nummer $i ist dokumentiert.',
            },
            npcRelationshipNotes: [
              for (var i = 0; i < 3; i++)
                NpcRelationshipNote(
                  id: 'mira-note-$i',
                  npcId: 'mira',
                  relationship: 'freundlich',
                  note: 'Mira bestätigte das Hafendetail Nummer $i.',
                  recordedAt: _now.subtract(Duration(days: i + 1)),
                ),
            ],
          );
          final initialJson = jsonEncode(campaign.toJson());
          await repository.saveCampaign(campaign);
          await controller.openCampaign(campaign.id);
          expect(controller.error, isNull);
          await controller.connectNarrator(
            url: 'https://story.example.test',
            sessionToken: 'story.memories',
          );
          expect(controller.error, isNull);
          expect(narrator.enabled, isTrue);
          expect(narrator.supportsNpcIdentityContexts, supportsContext);

          await controller.sendAction('Ich frage Mira nach der Chronik.');
          expect(controller.error, isNull);
          expect(transport.requests, hasLength(1));
          final request = transport.requests.single;
          final memories = List<String>.from(request['memories'] as List);

          // Three confirmed NPC notes outrank at least twenty confirmed
          // general facts, but neither kind can exceed the joint wire limit.
          expect(memories, hasLength(12));
          expect(
            memories.take(3).every(
              (value) => value.startsWith('Bestätigte NPC-Beziehungsnotiz'),
            ),
            isTrue,
          );
          expect(memories[0], contains('Hafendetail Nummer 0'));
          expect(memories[1], contains('Hafendetail Nummer 1'));
          expect(memories[2], contains('Hafendetail Nummer 2'));
          expect(memories.skip(3), hasLength(9));
          expect(memories.skip(3).any((entry) => entry.startsWith('Fakt ')),
              isTrue);
          expect(memories.every((entry) => entry.length <= 400), isTrue);
          expect(memories.toSet(), hasLength(12));

          if (supportsContext) {
            expect(request['campaignRevision'], campaign.revision + 1);
            final contexts = request['npcContexts'] as List;
            expect(contexts, hasLength(1));
            final context = contexts.single as Map;
            expect(context['npcId'], 'mira');
            expect(context['notes'], hasLength(3));
          } else {
            expect(request.containsKey('npcContexts'), isFalse);
            expect(request.containsKey('campaignRevision'), isFalse);
          }
          expect(request.containsKey('selectedNpcId'), isFalse);
          final confirmed = controller.currentCampaign!;
          expect(confirmed.revision, campaign.revision + 1);
          expect(confirmed.hero.toJson(), campaign.hero.toJson());
          expect(confirmed.scene, contains('Chronik'));
          expect(confirmed.quests, isEmpty);
          expect(
            (await repository.reconstructCampaign(campaign.id))!.toJson(),
            confirmed.toJson(),
          );
          // The source facts and NPC history were not overwritten by AI.
          expect(confirmed.facts, campaign.facts);
          expect(
            confirmed.npcRelationshipNotes.length,
            campaign.npcRelationshipNotes.length,
          );
          expect(jsonEncode(campaign.toJson()), initialJson);
        } finally {
          controller.dispose();
          await repository.close();
          await folder.delete(recursive: true);
        }
      },
    );
  }
}
