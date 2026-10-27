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

final _clock = DateTime.utc(2026, 10, 27, 10);

Map<String, dynamic> _plan() => {
  'title': 'Die Chroniken des Hafens',
  'world': 'Valdorn',
  'opening': 'Mira steht vor dem Hafen. Was tust du?',
  'premise': 'Ein alter Schwur liegt über der Stadt.',
  'secret': 'Die Wache kennt den verborgenen Schlüssel.',
  'goal': 'Klär die Geschichte des Hafens.',
  'threads': [
    {
      'id': 'hafen',
      'title': 'Die Hafenspuren',
      'description': 'Finde den Ursprung des alten Schwurs.',
    },
    {
      'id': 'brief',
      'title': 'Ein verschlossener Brief',
      'description': 'Erkunde den zweiten Handlungsstrang.',
    },
  ],
  'npcs': [
    {
      'id': 'mira',
      'name': 'Mira',
      'description': 'Die Archivarin am Hafen.',
      'relationship': 'freundlich',
    },
  ],
  'places': [
    {
      'id': 'pier',
      'name': 'Der Pier',
      'description': 'Hier landen die Schiffe.',
    },
  ],
};

class _RecordingTransport implements BackendTransport {
  _RecordingTransport(this.npcCapability);

  final bool npcCapability;
  final sent = <Map<String, Object?>>[];

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
          'expiresAt': _clock.add(const Duration(minutes: 5)).toIso8601String(),
          if (npcCapability) 'capabilities': ['npc-identity-v1'],
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/story/advance') {
      sent.add(Map<String, Object?>.from(body!));
      return const BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': [],
          'turn': {
            'narration': 'Mira deutet auf den Leuchtturm. Was tust du?',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unerwarteter Story-Endpunkt: ${uri.path}');
  }
}

void main() {
  sqfliteFfiInit();

  for (final supportsContext in [false, true]) {
    test(
      'Story transport keeps exactly 12 total memories (npc identity: $supportsContext)',
      () async {
        final folder = await Directory.systemTemp.createTemp('npc-wire-cap-');
        final dbPath = paths.join(folder.path, 'campaign.sqlite');
        final repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: dbPath,
        );
        final transport = _RecordingTransport(supportsContext);
        final narrator = BackendNarrator(
          transport: transport,
          clock: () => _clock,
        );
        final controller = GameController(
          repository: repository,
          narrator: narrator,
          engine: GameEngine(clock: () => _clock),
        );

        try {
          final initial = GameEngine(clock: () => _clock).createAiCampaign(
            HeroCharacter(id: 'hero-wire', name: 'Aria'),
            AiStoryPlan.fromJson(_plan()),
            provider: 'mock',
          );
          final populated = initial.copyWith(
            facts: {
              for (var i = 0; i < 18; i++)
                'archiv-$i': 'Bestätigter Fakt Nummer $i über Valdorn.',
            },
            npcRelationshipNotes: [
              for (var i = 0; i < 3; i++)
                NpcRelationshipNote(
                  id: 'mira-note-$i',
                  npcId: 'mira',
                  relationship: 'freundlich',
                  note: 'Mira hat die bestätigte Notiz Nummer $i hinterlegt.',
                  recordedAt: _clock.subtract(Duration(days: i + 1)),
                ),
            ],
          );
          await repository.saveCampaign(populated);
          await controller.initialize();
          await controller.openCampaign(populated.id);
          expect(controller.error, isNull);
          await controller.connectNarrator(
            url: 'https://story.example.test',
            sessionToken: 'memory-limit.session',
          );
          expect(controller.error, isNull);
          expect(narrator.supportsNpcIdentityContexts, supportsContext);

          final baseline = controller.currentCampaign!;
          final heroBefore = jsonEncode(baseline.hero.toJson());
          await controller.sendAction('Ich frage Mira nach dem Hafen.');
          expect(controller.error, isNull);
          expect(transport.sent, hasLength(1));
          final request = transport.sent.single;
          final memories = List<String>.from(request['memories'] as List);
          expect(memories, hasLength(12));
          expect(memories.every((entry) => entry.length <= 400), isTrue);
          expect(memories[0], contains('Notiz Nummer 0'));
          expect(memories[1], contains('Notiz Nummer 1'));
          expect(memories[2], contains('Notiz Nummer 2'));
          expect(
            memories.take(3).every(
              (entry) => entry.startsWith('Bestätigte NPC-Beziehungsnotiz'),
            ),
            isTrue,
          );
          expect(
            memories.skip(3).any((entry) => entry.contains('Bestätigter Fakt')),
            isTrue,
          );
          expect(memories.toSet(), hasLength(memories.length));

          if (supportsContext) {
            expect(request['campaignRevision'], baseline.revision + 1);
            final contexts = request['npcContexts'] as List;
            expect(contexts, hasLength(1));
            final context = contexts.single as Map;
            expect(context['npcId'], 'mira');
            expect((context['notes'] as List), hasLength(3));
          } else {
            expect(request.containsKey('campaignRevision'), isFalse);
            expect(request.containsKey('npcContexts'), isFalse);
          }
          final confirmed = controller.currentCampaign!;
          expect(confirmed.revision, baseline.revision + 1);
          expect(jsonEncode(confirmed.hero.toJson()), heroBefore);
          expect(
            (await repository.reconstructCampaign(populated.id))!.toJson(),
            confirmed.toJson(),
          );
        } finally {
          controller.dispose();
          await repository.close();
          await folder.delete(recursive: true);
        }
      },
    );
  }
}
