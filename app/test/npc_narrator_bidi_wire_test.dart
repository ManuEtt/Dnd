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
import 'package:lebendiger_spielleiter/story/npc_narrator_memory.dart';

final _now = DateTime.utc(2026, 10, 30, 6);

NpcRelationshipNote _note(String id, String npcId, String text) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'freundlich\u200f',
      note: text,
      recordedAt: _now,
    );

Campaign _campaign(List<WorldNpc> npcs, List<NpcRelationshipNote> notes) =>
    Campaign(
      id: 'safe-npc-wire',
      name: 'Valdorn',
      world: 'Valdorn',
      sessionId: 'session-one',
      hero: HeroCharacter(id: 'aria', name: 'Aria'),
      scene: 'Der Hafen',
      npcs: npcs,
      npcRelationshipNotes: notes,
    );

Map<String, dynamic> _plan() => {
  'title': 'Der Hafen',
  'world': 'Valdorn',
  'opening': 'Mira wartet am Hafen. Was tust du?',
  'premise': 'Das alte Archiv ist geschlossen.',
  'secret': 'Der Schlüssel liegt unter dem Kai.',
  'goal': 'Finde einen eigenen Zugang zum Archiv.',
  'threads': [
    {
      'id': 'archiv',
      'title': 'Das Archiv',
      'description': 'Suche nach einem Weg hinein.',
    },
    {'id': 'kai', 'title': 'Der Kai', 'description': 'Erkunde den Hafen.'},
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
    {'id': 'hafen', 'name': 'Hafen', 'description': 'Ein ruhiger Kai.'},
  ],
};

class _Transport implements BackendTransport {
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
            'narration': 'Die Archivarin deutet auf den Kai. Was tust du?',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unexpected story request');
  }
}

void main() {
  sqfliteFfiInit();

  test('visually identical NPC names cannot be selected from prose', () {
    final campaign = _campaign(
      const [
        WorldNpc(id: 'mira-one', name: 'Mira'),
        WorldNpc(id: 'mira-two', name: 'Mira\u202e'),
      ],
      [
        _note('note-a', 'mira-one', 'Nur die erste Mira kennt den Ort.'),
        _note('note-b', 'mira-two', 'Nur die zweite Mira hat die Karte.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());

    for (final action in ['Ich frage Mira.', 'Ich frage Mira\u202e.']) {
      final memories = NpcNarratorMemory.merge(campaign, action, []);
      expect(memories, isEmpty);
    }
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('unique confirmed names, notes and general memory are wire-safe', () {
    final campaign = _campaign(
      const [
        WorldNpc(
          id: 'mira',
          name: 'Mira\u202e',
          relationship: 'vorsichtig\u200e',
        ),
      ],
      [_note('note', 'mira', 'Der\u2066 Schlüssel\u2069 liegt am Kai.\u0000')],
    );
    final before = campaign.toJson();
    final memories = NpcNarratorMemory.merge(
      campaign,
      'Ich frage Mira nach dem Schlüssel.',
      ['Fakt\u061c: Die Tür bleibt geschlossen.'],
      limit: 2,
      npcNoteLimit: 1,
    );

    expect(memories, hasLength(2));
    expect(
      memories.first,
      startsWith('Bestätigte NPC-Beziehungsnotiz zu Mira'),
    );
    expect(memories.first, contains('Schlüssel'));
    expect(memories.last, 'Fakt : Die Tür bleibt geschlossen.');
    expect(
      memories.any(
        (item) => RegExp(
          r'[\x00-\x1f\x7f-\x9f\u061c\u200e\u200f'
          r'\u2028-\u202e\u2066-\u2069]',
        ).hasMatch(item),
      ),
      isFalse,
    );
    expect(memories.every((item) => item.length <= 400), isTrue);
    expect(campaign.toJson(), before);
  });

  test('legacy saves without notes still pass bounded general context', () {
    final old = _campaign(const [
      WorldNpc(id: 'mira', name: 'Mira'),
    ], const []).toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(old);
    expect(
      NpcNarratorMemory.merge(restored, 'Ich frage Mira.', [
        'Fakt\u202e: Gespeichertes Wissen.',
      ]),
      ['Fakt : Gespeichertes Wissen.'],
    );
  });

  test('SQLite restart sends sanitized memory to legacy narrator', () async {
    final directory = await Directory.systemTemp.createTemp('bidi-wire-');
    final dbPath = paths.join(directory.path, 'campaign.sqlite');
    SqliteCampaignRepository? repository;
    GameController? controller;
    try {
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      final initial = GameEngine(clock: () => _now).createAiCampaign(
        HeroCharacter(id: 'aria', name: 'Aria'),
        AiStoryPlan.fromJson(_plan()),
        provider: 'mock',
      );
      final saved = initial.copyWith(
        npcs: const [
          WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich\u200e'),
        ],
        npcRelationshipNotes: [
          _note(
            'confirmed-one',
            'mira',
            'Die\u202e Chronik liegt unter dem Kai.\u2069',
          ),
        ],
        facts: const {'chronik': 'Bestätigter\u061c Hinweis am Hafen.'},
      );
      final originalNotes = saved.npcRelationshipNotes
          .map((entry) => entry.toJson())
          .toList();
      await repository.saveCampaign(saved);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );

      final transport = _Transport();
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      controller = GameController(
        repository: repository,
        narrator: narrator,
        engine: GameEngine(clock: () => _now),
      );
      await controller.openCampaign(saved.id);
      expect(controller.error, isNull);
      await controller.connectNarrator(
        url: 'https://story.example.test',
        sessionToken: 'test.safe-bidi',
      );
      expect(narrator.supportsNpcIdentityContexts, isFalse);
      await controller.sendAction('Ich frage Mira nach der Chronik.');
      expect(controller.error, isNull);
      expect(transport.requests, hasLength(1));

      final request = transport.requests.single;
      final memories = List<String>.from(request['memories'] as List);
      expect(memories, isNotEmpty);
      expect(memories.first, contains('Chronik liegt unter dem Kai'));
      expect(
        memories.first,
        startsWith('Bestätigte NPC-Beziehungsnotiz zu Mira'),
      );
      expect(memories.every((entry) => entry.length <= 400), isTrue);
      expect(
        memories.every(
          (entry) => !RegExp(
            r'[\x00-\x1f\x7f-\x9f\u061c\u200e\u200f'
            r'\u2028-\u202e\u2066-\u2069]',
          ).hasMatch(entry),
        ),
        isTrue,
      );
      expect(request.containsKey('npcContexts'), isFalse);
      final confirmed = controller.currentCampaign!;
      expect(confirmed.hero.toJson(), saved.hero.toJson());
      expect(
        confirmed.npcRelationshipNotes.map((note) => note.toJson()).toList(),
        originalNotes,
      );
      expect(confirmed.facts, saved.facts);
      expect(confirmed.revision, saved.revision + 1);
      expect(
        (await repository.reconstructCampaign(saved.id))!.toJson(),
        confirmed.toJson(),
      );
    } finally {
      controller?.dispose();
      await repository?.close();
      await directory.delete(recursive: true);
    }
  });
}
