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
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';

final _clock = DateTime.utc(2026, 10, 30, 7);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String content, {
  String relationship = 'freundlich',
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: relationship,
  note: content,
  recordedAt: _clock,
);

Campaign _campaign({
  List<WorldNpc>? npcs,
  List<NpcRelationshipNote>? notes,
  int revision = 7,
}) => Campaign(
  id: 'bidi-identity',
  name: 'Valdorn',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'aria', name: 'Aria'),
  scene: 'Das Archiv',
  revision: revision,
  npcs:
      npcs ??
      const [WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich')],
  npcRelationshipNotes:
      notes ?? [_note('note-mira', 'mira', 'Mira kennt den Weg zum Archiv.')],
);

Map<String, dynamic> _plan() => {
  'title': 'Das alte Archiv',
  'world': 'Valdorn',
  'opening': 'Vor dem Archiv wartet eine Wächterin. Was tust du?',
  'premise': 'Ein lange vergessener Schwur bindet die Stadt.',
  'secret': 'Der Schlüssel liegt hinter dem Brunnen.',
  'goal': 'Finde den Weg ins Archiv.',
  'threads': [
    {'id': 'archiv', 'title': 'Das Archiv', 'description': 'Suche den Zugang.'},
    {'id': 'tor', 'title': 'Das Tor', 'description': 'Erkunde das Tor.'},
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
    {'id': 'markt', 'name': 'Marktplatz', 'description': 'Ein alter Brunnen.'},
  ],
};

class _Transport implements BackendTransport {
  _Transport(this.supportsIdentity);

  final bool supportsIdentity;
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
          'scope': 'narration:read-only',
          'provider': 'mock',
          'expiresAt': _clock.add(const Duration(minutes: 5)).toIso8601String(),
          if (supportsIdentity) 'capabilities': ['npc-identity-v1'],
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
            'narration': 'Tarek zeigt zum Archiv. Was tust du?',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unexpected story endpoint');
  }
}

void main() {
  sqfliteFfiInit();

  test('invisible directional controls never disambiguate NPC names', () {
    for (final marker in ['\u061c', '\u200e', '\u200f', '\u202e', '\u2066']) {
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira', name: 'Mira'),
          WorldNpc(id: 'other', name: 'Mi' + marker + 'ra'),
        ],
        notes: [
          _note('a', 'mira', 'Nur Mira A kennt den Weg.'),
          _note('b', 'other', 'Nur Mira B besitzt den Schlüssel.'),
        ],
      );
      final before = jsonEncode(campaign.toJson());
      expect(
        NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira.'),
        isNull,
      );
      expect(
        NpcIdentityStoryPayload.prepare(
          campaign,
          'Ich frage Mi' + marker + 'ra.',
        ),
        isNull,
      );
      final choice = NpcStorySelection.choose(campaign, 'mira');
      final selected = NpcIdentityStoryPayload.prepare(
        campaign,
        'Ich frage Mira.',
        selectedNpc: choice,
      );
      expect(selected!.selectedNpcId, 'mira');
      expect(selected.npcContexts.single['npcId'], 'mira');
      selected.requireCurrent(campaign);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('unsafe name, relationship and note fields omit structured context', () {
    final cases = [
      _campaign(
        npcs: const [WorldNpc(id: 'mira', name: 'Mira\u202e')],
      ),
      _campaign(
        npcs: const [
          WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich\u200f'),
        ],
      ),
      _campaign(
        notes: [_note('unsafe', 'mira', 'Die\u2066 Karte\u2069 liegt am Kai.')],
      ),
      _campaign(
        notes: [
          _note(
            'unsafe',
            'mira',
            'Die Karte liegt am Kai.',
            relationship: 'neutral\u061c',
          ),
        ],
      ),
    ];
    for (final campaign in cases) {
      final before = jsonEncode(campaign.toJson());
      expect(
        NpcIdentityStoryPayload.prepare(campaign, 'Ich spreche Mira an.'),
        isNull,
      );
      final choice = NpcStorySelection.choose(campaign, 'mira');
      expect(
        NpcIdentityStoryPayload.prepare(
          campaign,
          'Ich spreche Mira an.',
          selectedNpc: choice,
        ),
        isNull,
      );
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('valid German names and revision-bound selected IDs still work', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'keeper', name: 'Große Hüterin', relationship: 'neutral'),
      ],
      notes: [_note('hue', 'keeper', 'Die Hüterin kennt das Südtor.')],
    );
    final payload = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich frage die GROSSE HUETERIN nach dem Tor.',
    )!;
    expect(payload.npcContexts.single['npcName'], 'Große Hüterin');
    expect(payload.npcContexts.single['npcId'], 'keeper');
    final notes = payload.npcContexts.single['notes'] as List;
    expect((notes.single as Map)['note'], 'Die Hüterin kennt das Südtor.');
    payload.requireCurrent(campaign);
    expect(
      () => payload.requireCurrent(campaign.copyWith(revision: 8)),
      throwsFormatException,
    );
  });

  test('legacy campaigns without NPC notes never invent identity facts', () {
    final old = _campaign().toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(old);
    expect(
      NpcIdentityStoryPayload.prepare(restored, 'Ich frage Mira.'),
      isNull,
    );
    expect(restored.npcRelationshipNotes, isEmpty);
  });

  for (final capability in [false, true]) {
    test(
      'SQLite restart negotiates safe identity contexts ($capability)',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'bidi-context-',
        );
        final dbPath = paths.join(directory.path, 'campaign.sqlite');
        SqliteCampaignRepository? repository;
        GameController? controller;
        try {
          repository = await SqliteCampaignRepository.open(
            factory: databaseFactoryFfi,
            path: dbPath,
          );
          final original = GameEngine(clock: () => _clock).createAiCampaign(
            HeroCharacter(id: 'aria', name: 'Aria'),
            AiStoryPlan.fromJson(_plan()),
            provider: 'mock',
          );
          final campaign = original.copyWith(
            npcs: const [
              WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
              WorldNpc(
                id: 'other',
                name: 'Mi\u202era',
                relationship: 'neutral',
              ),
              WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
            ],
            npcRelationshipNotes: [
              _note('mira-note', 'mira', 'Mira kennt den Turm.'),
              _note('other-note', 'other', 'Andere Mira kennt das Tor.'),
              _note('tarek-note', 'tarek', 'Tarek kennt das Archiv.'),
            ],
          );
          await repository.saveCampaign(campaign);
          await repository.close();
          repository = await SqliteCampaignRepository.open(
            factory: databaseFactoryFfi,
            path: dbPath,
          );
          final transport = _Transport(capability);
          final narrator = BackendNarrator(
            transport: transport,
            clock: () => _clock,
          );
          controller = GameController(
            repository: repository,
            narrator: narrator,
            engine: GameEngine(clock: () => _clock),
          );
          await controller.openCampaign(campaign.id);
          expect(controller.error, isNull);
          await controller.connectNarrator(
            url: 'https://story.example.test',
            sessionToken: 'bidi.context',
          );
          expect(controller.error, isNull);
          expect(narrator.supportsNpcIdentityContexts, capability);
          await controller.sendAction(
            'Ich frage Mira und Tarek nach dem Archiv.',
          );
          expect(controller.error, isNull);
          expect(transport.sent, hasLength(1));

          final wire = transport.sent.single;
          if (capability) {
            final contexts = wire['npcContexts'] as List;
            expect(contexts, hasLength(1));
            final context = contexts.single as Map;
            expect(context['npcId'], 'tarek');
            expect(context['npcName'], 'Tarek');
            expect(
              (context['notes'] as List).single,
              containsPair('npcId', 'tarek'),
            );
            expect(wire['campaignRevision'], campaign.revision + 1);
          } else {
            expect(wire.containsKey('npcContexts'), isFalse);
            expect(wire.containsKey('campaignRevision'), isFalse);
          }
          expect(wire.containsKey('selectedNpcId'), isFalse);
          final current = controller.currentCampaign!;
          expect(current.hero.toJson(), campaign.hero.toJson());
          expect(
            current.npcRelationshipNotes.map((item) => item.toJson()).toList(),
            campaign.npcRelationshipNotes.map((item) => item.toJson()).toList(),
          );
          expect(
            (await repository.reconstructCampaign(campaign.id))!.toJson(),
            current.toJson(),
          );
        } finally {
          controller?.dispose();
          await repository?.close();
          await directory.delete(recursive: true);
        }
      },
    );
  }
}
