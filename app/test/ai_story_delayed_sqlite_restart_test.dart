import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _clock = DateTime.utc(2026, 10, 31, 8, 0);
const _decision = 'Ich frage Mira nach dem verschwundenen Schiff.';
const _confirmedEnding = 'Die Spielerin hat den Fall im Hafen abgeschlossen.';

Map<String, dynamic> _plan() => {
  'title': 'Das Echo des Hafens',
  'world': 'Valdorn',
  'opening': 'Mira wartet am Pier. Was tust du?',
  'premise': 'Ein Schiff verschwand im Nebel.',
  'secret': 'Die Seekarte zeigt einen verborgenen Pfad.',
  'goal': 'Finde den Weg des Schiffes.',
  'threads': [
    {
      'id': 'hafen',
      'title': 'Die Hafenspur',
      'description': 'Suche das verschwundene Schiff.',
    },
    {
      'id': 'bund',
      'title': 'Ein alter Bund',
      'description': 'Sprich mit den Bewohnern.',
    },
  ],
  'npcs': [
    {
      'id': 'mira',
      'name': 'Mira',
      'description': 'Kartografin',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {'id': 'pier', 'name': 'Der Pier', 'description': 'Ein Steg im Nebel.'},
  ],
};

class _DelayedStoryTransport implements BackendTransport {
  final started = Completer<void>();
  final reply = Completer<BackendResponse>();
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
          'expiresAt': _clock.add(const Duration(minutes: 5)).toIso8601String(),
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/story/advance') {
      requests.add(Map<String, Object?>.from(body!));
      started.complete();
      return reply.future;
    }
    throw StateError('Unerwartete Backend-Anfrage: ' + uri.path);
  }

  void release() {
    if (reply.isCompleted) return;
    reply.complete(
      const BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': <Object>[],
          'turn': {
            'narration': 'Mira entdeckt eine neue Spur im Nebel.',
            'threadUpdates': <Object>[],
            'newThreads': [
              {
                'id': 'echo',
                'title': 'Das neue Echo',
                'description': 'Suche nach weiteren Hinweisen.',
              },
            ],
            'npcUpdates': [
              {
                'id': 'mira',
                'relationship': 'freundlich',
                'note': 'Mira vertraut der Spielerin die Karte an.',
              },
            ],
            'adventure': null,
          },
        },
      ),
    );
  }
}

void main() {
  sqfliteFfiInit();

  for (final interveningSave in [false, true]) {
    test(
      interveningSave
          ? 'late AI story answer cannot overwrite a newer SQLite checkpoint'
          : 'delayed AI story answer confirms one turn after SQLite restart',
      () async {
        final folder = await Directory.systemTemp.createTemp('story-race-');
        final path = paths.join(folder.path, 'campaign.sqlite');
        final engine = GameEngine(clock: () => _clock);
        final original = engine.createAiCampaign(
          HeroCharacter(id: 'hero', name: 'Eila', hitPoints: 15),
          AiStoryPlan.fromJson(_plan()),
          provider: 'mock',
        );
        var repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
          singleInstance: false,
        );
        SqliteCampaignRepository? concurrent;
        GameController? controller;
        final transport = _DelayedStoryTransport();

        try {
          await repository.saveCampaign(original);
          await repository.close();
          repository = await SqliteCampaignRepository.open(
            factory: databaseFactoryFfi,
            path: path,
            singleInstance: false,
          );
          concurrent = await SqliteCampaignRepository.open(
            factory: databaseFactoryFfi,
            path: path,
            singleInstance: false,
          );

          final narrator = BackendNarrator(
            transport: transport,
            clock: () => _clock,
          );
          controller = GameController(
            repository: repository,
            engine: GameEngine(clock: () => _clock),
            narrator: narrator,
          );
          await controller.initialize();
          expect(controller.error, isNull);
          expect(narrator.enabled, isFalse);
          await controller.openCampaign(original.id);
          expect(controller.currentCampaign!.revision, original.revision);
          await controller.connectNarrator(
            url: 'https://story.example.test',
            sessionToken: 'test.delayed-story',
          );
          expect(controller.error, isNull);

          final pending = controller.sendAction(_decision);
          await transport.started.future.timeout(const Duration(seconds: 30));
          expect(transport.requests, hasLength(1));
          expect(transport.requests.single['campaignId'], original.id);
          expect(controller.busy, isTrue);

          if (interveningSave) {
            final latest = (await concurrent.getCampaign(original.id))!;
            final changed = engine.saveStoryThread(
              latest,
              threadId: 'hafen',
              title: 'Die Hafenspur',
              description: _confirmedEnding,
              status: 'resolved',
            );
            await concurrent.saveCampaign(
              changed.campaign,
              events: changed.events,
              expectedRevision: latest.revision,
            );
            final savedBeforeReply = (await concurrent.getCampaign(
              original.id,
            ))!;
            final confirmedJson = jsonEncode(savedBeforeReply.toJson());
            final savedEventCount = savedBeforeReply.events.length;

            transport.release();
            await pending;
            expect(controller.error, contains('inzwischen'));
            final persisted = (await concurrent.getCampaign(original.id))!;
            expect(jsonEncode(persisted.toJson()), confirmedJson);
            expect(persisted.revision, original.revision + 1);
            expect(persisted.events, hasLength(savedEventCount));
            expect(persisted.events.last.type, 'memory.storyThreadSaved');
            expect(persisted.storyThreads.first.status, 'resolved');
            expect(persisted.storyThreads.first.description, _confirmedEnding);
            expect(persisted.storyThreads.any((t) => t.id == 'echo'), isFalse);
            expect(persisted.npcRelationshipNotes, isEmpty);
            expect(persisted.hero.toJson(), original.hero.toJson());
            expect(
              (await concurrent.reconstructCampaign(original.id))!.toJson(),
              persisted.toJson(),
            );
            await controller.openCampaign(original.id);
            expect(controller.error, isNull);
            expect(controller.currentCampaign!.toJson(), persisted.toJson());
          } else {
            transport.release();
            await pending;
            expect(controller.error, isNull);
            final persisted = (await concurrent.getCampaign(original.id))!;
            expect(persisted.revision, original.revision + 1);
            expect(persisted.events, hasLength(1));
            expect(persisted.events.single.type, 'narrative.turn');
            expect(persisted.events.single.payload['storyProvider'], 'mock');
            expect(persisted.storyThreads.any((t) => t.id == 'echo'), isTrue);
            expect(persisted.npcRelationshipNotes, hasLength(1));
            expect(persisted.npcRelationshipNotes.single.npcId, 'mira');
            expect(persisted.storyBible['turnCount'], '1');
            expect(persisted.hero.toJson(), original.hero.toJson());
            expect(
              (await concurrent.reconstructCampaign(original.id))!.toJson(),
              persisted.toJson(),
            );
          }
        } finally {
          transport.release();
          controller?.dispose();
          await concurrent?.close();
          await repository.close();
          await folder.delete(recursive: true);
        }
      },
    );
  }
}
