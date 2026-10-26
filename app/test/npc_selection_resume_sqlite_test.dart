import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';

final _now = DateTime.utc(2026, 10, 26, 12);

Campaign _campaign() => Campaign(
  id: 'npc-resume',
  name: 'Die zwei Miras',
  world: 'Valdorn',
  sessionId: 'erste-sitzung',
  hero: HeroCharacter(id: 'held-npc-resume', name: 'Aria', hitPoints: 12),
  scene: 'Vor dem Stadttor',
  npcs: const [
    WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
    WorldNpc(id: 'mira-two', name: 'MIRA', relationship: 'misstrauisch'),
  ],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'note-one',
      npcId: 'mira-one',
      relationship: 'freundlich',
      note: 'Die erste Mira verwahrt die Karte.',
      recordedAt: DateTime.utc(2026, 10, 23),
    ),
    NpcRelationshipNote(
      id: 'note-two',
      npcId: 'mira-two',
      relationship: 'misstrauisch',
      note: 'Die zweite Mira bewacht das Tor.',
      recordedAt: DateTime.utc(2026, 10, 25),
    ),
  ],
);

class _RecordedNpcTransport implements BackendTransport {
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
          'capabilities': ['npc-identity-v1', 'npc-selection-v1'],
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
            'narration': 'Die ausgewählte Mira blickt auf.',
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

Future<void> _send(
  BackendNarrator narrator,
  Campaign campaign,
  NpcIdentityStoryPayload payload,
) async {
  final result = await narrator.advanceStory(
    campaignId: campaign.id,
    heroName: campaign.hero.name,
    action: 'Ich frage Mira nach der Karte.',
    scene: campaign.scene,
    premise: 'Die Stadt braucht Hilfe.',
    goal: 'Finde den Eingang.',
    secret: 'Das Siegel ist verborgen.',
    threads: const [],
    npcs: [
      for (final npc in campaign.npcs)
        {'id': npc.id, 'name': npc.name, 'relationship': npc.relationship},
    ],
    memories: const [],
    recentActions: const [],
    campaignRevision: payload.campaignRevision,
    npcContexts: payload.npcContexts,
    selectedNpcId: payload.selectedNpcId,
  );
  expect(result?['narration'], contains('ausgewählte Mira'));
}

void main() {
  sqfliteFfiInit();

  test('NPC identity survives SQLite restart without cross-talk', () async {
    final directory = await Directory.systemTemp.createTemp('npc-resume-');
    final path = paths.join(directory.path, 'campaign.sqlite');
    final saved = _campaign();
    final baseline = jsonEncode(saved.toJson());
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      await repository.saveCampaign(saved);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final recovered = (await repository.getCampaign(saved.id))!;
      expect(jsonEncode(recovered.toJson()), baseline);
      expect(recovered.sessionId, 'erste-sitzung');

      // Free text cannot choose one of two equal display names.
      expect(
        NpcIdentityStoryPayload.prepare(recovered, 'Ich frage Mira.'),
        isNull,
      );
      final chosen = NpcStorySelection.choose(recovered, 'mira-two');
      final payload = NpcIdentityStoryPayload.prepare(
        recovered,
        'Ich frage Mira.',
        selectedNpc: chosen,
      )!;
      payload.requireCurrent(recovered);
      expect(payload.selectedNpcId, 'mira-two');
      expect(payload.npcContexts, hasLength(1));
      expect(payload.npcContexts.single['npcId'], 'mira-two');
      expect(payload.npcContexts.toString(), contains('bewacht das Tor'));
      expect(
        payload.npcContexts.toString(),
        isNot(contains('verwahrt die Karte')),
      );

      final transport = _RecordedNpcTransport();
      final narrator = BackendNarrator(transport: transport, clock: () => _now);
      try {
        await narrator.connect(
          url: 'https://story.example.test',
          sessionToken: 'local.resume',
        );
        expect(narrator.supportsExplicitNpcSelection, isTrue);
        await _send(narrator, recovered, payload);
        expect(transport.requests, hasLength(1));
        final request = transport.requests.single;
        expect(request['selectedNpcId'], 'mira-two');
        expect(request['campaignRevision'], recovered.revision);
        final contexts = request['npcContexts'] as List;
        expect(contexts, hasLength(1));
        expect((contexts.single as Map)['npcId'], 'mira-two');
        expect(jsonEncode(recovered.toJson()), baseline);
        expect(
          (await repository.getCampaign(saved.id))!.hero.toJson(),
          saved.hero.toJson(),
        );
      } finally {
        narrator.dispose();
      }

      // A later confirmed session invalidates both the old choice and payload.
      final later = recovered.copyWith(
        revision: recovered.revision + 1,
        sessionId: 'zweite-sitzung',
      );
      await repository.saveCampaign(
        later,
        expectedRevision: recovered.revision,
      );
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final resumed = (await repository.getCampaign(saved.id))!;
      expect(resumed.sessionId, 'zweite-sitzung');
      expect(() => chosen.requireCurrent(resumed), throwsFormatException);
      expect(() => payload.requireCurrent(resumed), throwsFormatException);
      expect(
        () => NpcIdentityStoryPayload.prepare(
          resumed,
          'Ich frage Mira.',
          selectedNpc: chosen,
        ),
        throwsFormatException,
      );

      // A new player choice uses the latest saved revision, not the old ID
      // context or another same-name NPC's relationship notes.
      final fresh = NpcStorySelection.choose(resumed, 'mira-two');
      final renewed = NpcIdentityStoryPayload.prepare(
        resumed,
        'Ich frage Mira.',
        selectedNpc: fresh,
      )!;
      renewed.requireCurrent(resumed);
      expect(renewed.campaignRevision, resumed.revision);
      expect(renewed.npcContexts.single['npcId'], 'mira-two');
      expect(
        renewed.npcContexts.toString(),
        isNot(contains('verwahrt die Karte')),
      );
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });

  test('legacy JSON without NPC notes cannot invent saved NPC history', () {
    final old = _campaign().toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(old);
    final chosen = NpcStorySelection.choose(restored, 'mira-two');
    expect(
      NpcIdentityStoryPayload.prepare(
        restored,
        'Ich frage Mira.',
        selectedNpc: chosen,
      ),
      isNull,
    );
    expect(restored.hero.toJson(), _campaign().hero.toJson());
  });
}
