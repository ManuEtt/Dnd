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

bool _validUtf16(String text) {
  for (var index = 0; index < text.length; index++) {
    final unit = text.codeUnitAt(index);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      index++;
      if (index >= text.length) return false;
      final trailing = text.codeUnitAt(index);
      if (trailing < 0xdc00 || trailing > 0xdfff) return false;
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      return false;
    }
  }
  return true;
}

class _UnicodeTransport implements BackendTransport {
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
      requests.add(Map<String, Object?>.from(body!));
      return const BackendResponse(
        statusCode: 200,
        body: {
          'provider': 'mock',
          'stateChanges': [],
          'turn': {
            'narration': 'Mira zeigt auf den Hafen. Was tust du?',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unexpected transport request');
  }
}

void main() {
  sqfliteFfiInit();

  test('story memory wire safely truncates multibyte NPC notes', () async {
    final folder = await Directory.systemTemp.createTemp('npc-unicode-wire-');
    final repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: paths.join(folder.path, 'campaign.sqlite'),
    );
    final transport = _UnicodeTransport();
    final narrator = BackendNarrator(transport: transport, clock: () => _now);
    final controller = GameController(
      repository: repository,
      narrator: narrator,
    );

    try {
      final plan = AiStoryPlan.fromJson({
        'title': 'Die Hafenchronik',
        'world': 'Valdorn',
        'opening': 'Die Archivarin wartet am Hafen. Was tust du?',
        'premise': 'In der Stadt fehlt eine Chronik.',
        'secret': 'Die Chronik liegt hinter dem alten Tor.',
        'goal': 'Finde die Chronik.',
        'threads': [
          {
            'id': 'chronik',
            'title': 'Die Chronik',
            'description': 'Wo liegt das Buch?',
          },
          {
            'id': 'tor',
            'title': 'Das Hafentor',
            'description': 'Wie lässt sich das Tor öffnen?',
          },
        ],
        'npcs': [
          {
            'id': 'mira',
            'name': 'Mira',
            'description': 'Archivarin',
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
      });
      final dragons = List.filled(190, '🐉').join();
      final longNote = 'Der verborgene Hafen:\n$dragons';
      final original = GameEngine(clock: () => _now).createAiCampaign(
        HeroCharacter(id: 'aria', name: 'Aria'),
        plan,
        provider: 'mock',
      );
      final campaign = original.copyWith(
        facts: {
          for (var i = 0; i < 20; i++)
            'stadt_$i': 'Bestätigter Ort $i',
        },
        npcRelationshipNotes: [
          NpcRelationshipNote(
            id: 'unicode-long',
            npcId: 'mira',
            relationship: 'freundlich',
            note: longNote,
            recordedAt: _now.subtract(const Duration(days: 1)),
          ),
          NpcRelationshipNote(
            id: 'unicode-breaks',
            npcId: 'mira',
            relationship: 'freundlich',
            note: 'Brücke\tam\nHafen und die Hüterin.',
            recordedAt: _now.subtract(const Duration(days: 2)),
          ),
        ],
      );
      final originalNotes = campaign.npcRelationshipNotes
          .map((entry) => entry.toJson())
          .toList();
      await repository.saveCampaign(campaign);
      await controller.openCampaign(campaign.id);
      expect(controller.error, isNull);
      await controller.connectNarrator(
        url: 'https://story.example.test',
        sessionToken: 'test.unicode',
      );
      expect(controller.error, isNull);

      await controller.sendAction('Ich frage Mira nach dem Hafen.');
      expect(controller.error, isNull);
      expect(transport.requests, hasLength(1));
      final memories = List<String>.from(
        transport.requests.single['memories'] as List,
      );

      expect(memories, isNotEmpty);
      expect(memories.length, lessThanOrEqualTo(12));
      final npcMemories = memories
          .where((entry) => entry.startsWith('Bestätigte NPC-Beziehungsnotiz'))
          .toList();
      expect(npcMemories, hasLength(2));
      expect(memories.first, contains('Der verborgene Hafen:'));
      expect(memories.first, contains('🐉'));
      expect(memories.first.endsWith('…'), isTrue);
      expect(memories[1], contains('Brücke am Hafen'));
      expect(memories.every((entry) => entry.length <= 400), isTrue);
      expect(memories.every(_validUtf16), isTrue);
      expect(
        memories.every((entry) => !RegExp(r'[\r\n\t]').hasMatch(entry)),
        isTrue,
      );

      final confirmed = controller.currentCampaign!;
      expect(
        confirmed.npcRelationshipNotes.map((entry) => entry.toJson()).toList(),
        originalNotes,
      );
      expect(confirmed.hero.toJson(), campaign.hero.toJson());
    } finally {
      controller.dispose();
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
