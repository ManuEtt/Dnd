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
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';

final _clock = DateTime.utc(2026, 10, 27, 10);

Map<String, dynamic> _plan() => {
  'title': 'Zwei Stimmen von Mira',
  'world': 'Valdorn',
  'opening': 'Zwei Wächterinnen erwarten eine Antwort.',
  'premise': 'Zwei gleichnamige Figuren besitzen verschiedene Hinweise.',
  'secret': 'Ein versteckter Schwur verbindet die Tore.',
  'goal': 'Finde die richtige Ansprechpartnerin.',
  'threads': [
    {
      'id': 'tor',
      'title': 'Das Stadttor',
      'description': 'Wer besitzt den Schlüssel?',
    },
  ],
  'npcs': [
    {
      'id': 'mira-one',
      'name': 'Mira',
      'description': 'Eine Archivarin.',
      'relationship': 'freundlich',
    },
  ],
  'places': [
    {
      'id': 'markt',
      'name': 'Marktplatz',
      'description': 'Ein belebter Platz.',
    },
  ],
};

class _IdentityTransport implements BackendTransport {
  _IdentityTransport({this.supportsSelection = true});
  final bool supportsSelection;
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
          'capabilities': [
            'npc-identity-v1',
            if (supportsSelection) 'npc-selection-v1',
          ],
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
            'narration': 'Die ausgewählte Wächterin antwortet.',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
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
  late Directory directory;
  late SqliteCampaignRepository repository;
  late _IdentityTransport transport;
  late BackendNarrator narrator;
  late GameController controller;

  Future<void> openCampaign({bool supportsSelection = true}) async {
    directory = await Directory.systemTemp.createTemp('npc-controller-choice-');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: paths.join(directory.path, 'campaign.sqlite'),
    );
    final original = GameEngine(clock: () => _clock).createAiCampaign(
      HeroCharacter(id: 'aria-npc-select', name: 'Aria'),
      AiStoryPlan.fromJson(_plan()),
      provider: 'mock',
    );
    final saved = original.copyWith(
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
    await repository.saveCampaign(saved);
    transport = _IdentityTransport(supportsSelection: supportsSelection);
    narrator = BackendNarrator(transport: transport, clock: () => _clock);
    controller = GameController(repository: repository, narrator: narrator);
    await controller.initialize();
    await controller.openCampaign(saved.id);
    await controller.connectNarrator(
      url: 'https://story.example.test',
      sessionToken: 'npc-choice.session',
    );
    expect(controller.error, isNull);
  }

  tearDown(() async {
    controller.dispose();
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('explicit NPC selection reaches narrator without mixing same names',
      () async {
    await openCampaign();
    final before = controller.currentCampaign!;
    final choice = NpcStorySelection.choose(before, 'mira-two');
    await controller.sendAction('Ich frage Mira nach dem Tor.', selectedNpc: choice);

    expect(controller.error, isNull);
    expect(transport.requests, hasLength(1));
    final request = transport.requests.single;
    expect(request['selectedNpcId'], 'mira-two');
    expect(request['campaignRevision'], before.revision + 1);
    final contexts = request['npcContexts'] as List;
    expect(contexts, hasLength(1));
    expect((contexts.single as Map)['npcId'], 'mira-two');
    expect(contexts.toString(), contains('bewacht das Tor'));
    expect(contexts.toString(), isNot(contains('verwahrt die Karte')));
    expect(controller.currentCampaign!.revision, before.revision + 1);
    expect(controller.currentCampaign!.hero.toJson(), before.hero.toJson());
    expect(
      (await repository.getCampaign(before.id))!.storyThreads.toString(),
      controller.currentCampaign!.storyThreads.toString(),
    );
  });

  test('unsupported backend rejects explicit selection without committing',
      () async {
    await openCampaign(supportsSelection: false);
    final before = controller.currentCampaign!.toJson();
    final choice = NpcStorySelection.choose(controller.currentCampaign!, 'mira-two');
    await controller.sendAction('Ich rede mit Mira.', selectedNpc: choice);
    expect(controller.error, contains('NPC-Auswahlunterstützung'));
    expect(transport.requests, isEmpty);
    expect(controller.currentCampaign!.toJson(), before);
    expect((await repository.getCampaign(controller.currentCampaign!.id))!.toJson(), before);
  });

  test('stale NPC selection is rejected before any provider call', () async {
    await openCampaign();
    final choice = NpcStorySelection.choose(controller.currentCampaign!, 'mira-two');
    await controller.saveStoryThread(
      threadId: 'tor',
      title: 'Das Stadttor',
      description: 'Ein bestätigter Hinweis.',
      status: 'open',
    );
    expect(controller.error, isNull);
    final before = controller.currentCampaign!.toJson();
    await controller.sendAction('Ich rede mit Mira.', selectedNpc: choice);
    expect(controller.error, contains('nicht mehr aktuell'));
    expect(transport.requests, isEmpty);
    expect(controller.currentCampaign!.toJson(), before);
  });

  test('a request ID cannot be replayed with a different chosen NPC',
      () async {
    await openCampaign();
    final choice = NpcStorySelection.choose(controller.currentCampaign!, 'mira-two');
    const action = 'Ich befrage Mira nach dem Tor.';
    await controller.sendAction(
      action,
      requestId: 'npc-choice-once',
      selectedNpc: choice,
    );
    expect(controller.error, isNull);
    final confirmed = controller.currentCampaign!;
    expect(transport.requests, hasLength(1));
    await controller.sendAction(
      action,
      requestId: 'npc-choice-once',
      selectedNpc: choice,
    );
    expect(controller.error, isNull);
    expect(transport.requests, hasLength(1));
    expect(controller.currentCampaign!.revision, confirmed.revision);
    final different = NpcStorySelection.choose(
      controller.currentCampaign!,
      'mira-one',
    );
    await controller.sendAction(
      action,
      requestId: 'npc-choice-once',
      selectedNpc: different,
    );
    expect(controller.error, contains('anderen Text'));
    expect(transport.requests, hasLength(1));
    expect(controller.currentCampaign!.revision, confirmed.revision);
    expect(
      (await repository.getCampaign(confirmed.id))!.hero.toJson(),
      confirmed.hero.toJson(),
    );
  });
}
