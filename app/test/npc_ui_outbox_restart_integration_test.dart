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
import 'package:lebendiger_spielleiter/services/npc_pending_action_recovery.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';

class _NpcTransport implements BackendTransport {
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
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 5))
              .toIso8601String(),
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
            'narration': 'Mira zeigt auf den alten Hafen.',
            'threadUpdates': [],
            'newThreads': [],
            'npcUpdates': [],
            'adventure': null,
          },
        },
      );
    }
    throw StateError('Unbekannte Backend-Anfrage: ${uri.path}');
  }
}

Map<String, dynamic> _plan() => {
  'title': 'Die zwei Hüterinnen',
  'world': 'Valdorn',
  'opening': 'Zwei Wächterinnen namens Mira erwarten dich.',
  'premise': 'Zwei Personen tragen denselben Namen.',
  'secret': 'Der geheime Schlüssel liegt in den Archiven.',
  'goal': 'Sprich mit der richtigen Mira.',
  'threads': [
    {
      'id': 'tor',
      'title': 'Das Stadttor',
      'description': 'Wer bewacht das Tor?',
    },
    {
      'id': 'brief',
      'title': 'Der geheime Brief',
      'description': 'Wer hat den Brief verfasst?',
    },
  ],
  'npcs': [
    {
      'id': 'mira-one',
      'name': 'Mira',
      'description': 'Eine Archivarin',
      'relationship': 'freundlich',
    },
  ],
  'places': [
    {
      'id': 'marktplatz',
      'name': 'Der Marktplatz',
      'description': 'Ein Ort voller Gerüchte.',
    },
  ],
};

class _Fixture {
  _Fixture(this.folder, this.path, this.repository, this.controller, this.transport);

  final Directory folder;
  final String path;
  SqliteCampaignRepository repository;
  GameController controller;
  final _NpcTransport transport;

  Future<void> connect() async {
    await controller.connectNarrator(
      url: 'https://spielleiter.example.test',
      sessionToken: 'npc-session.token',
    );
    expect(controller.error, isNull);
    expect(controller.narrator.supportsExplicitNpcSelection, isTrue);
  }

  Future<void> restart() async {
    controller.dispose();
    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    controller = GameController(
      repository: repository,
      narrator: BackendNarrator(transport: transport),
    );
    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.narrator.enabled, isFalse);
  }

  Future<void> close() async {
    controller.dispose();
    await repository.close();
    await folder.delete(recursive: true);
  }
}

Future<_Fixture> _start() async {
  final folder = await Directory.systemTemp.createTemp('npc-action-restart-');
  final path = paths.join(folder.path, 'campaign.sqlite');
  final repository = await SqliteCampaignRepository.open(
    factory: databaseFactoryFfi,
    path: path,
  );
  final transport = _NpcTransport();
  final controller = GameController(
    repository: repository,
    narrator: BackendNarrator(transport: transport),
  );
  final fixture = _Fixture(folder, path, repository, controller, transport);
  final initial = GameEngine().createAiCampaign(
    HeroCharacter(id: 'hero-npc-restart', name: 'Aria'),
    AiStoryPlan.fromJson(_plan()),
    provider: 'mock',
  );
  final campaign = initial.copyWith(
    npcs: const [
      WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
      WorldNpc(id: 'mira-two', name: 'Mira', relationship: 'misstrauisch'),
    ],
    npcRelationshipNotes: [
      NpcRelationshipNote(
        id: 'note-one',
        npcId: 'mira-one',
        relationship: 'freundlich',
        note: 'Mira aus dem Archiv kennt den Brief.',
        recordedAt: DateTime.utc(2026, 10, 25),
      ),
      NpcRelationshipNote(
        id: 'note-two',
        npcId: 'mira-two',
        relationship: 'misstrauisch',
        note: 'Mira am Tor bewacht die Schlüssel.',
        recordedAt: DateTime.utc(2026, 10, 26),
      ),
    ],
  );
  await repository.saveCampaign(campaign);
  await controller.openCampaign(campaign.id);
  expect(controller.error, isNull);
  return fixture;
}

void main() {
  sqfliteFfiInit();

  test('the selected Mira ID and only her memory reach the narrator', () async {
    final fixture = await _start();
    try {
      await fixture.connect();
      final before = fixture.controller.currentCampaign!;
      final outbox = PlayerActionOutbox(
        fixture.repository,
        newRequestId: () => 'chosen-mira-turn',
      );
      final action = await outbox.stage(
        before.id,
        'Ich frage Mira nach den Schlüsseln.',
        selectedNpcId: 'mira-two',
        selectedNpcRevision: before.revision,
      );
      final resolution = resolvePendingNpcAction(before, action);
      expect(resolution.state, PendingNpcActionState.ready);
      expect(resolution.choice?.npcId, 'mira-two');
      await fixture.controller.sendAction(
        action.text,
        requestId: action.requestId,
        selectedNpc: resolution.choice,
      );
      expect(fixture.controller.error, isNull);
      expect(fixture.transport.requests, hasLength(1));
      final sent = fixture.transport.requests.single;
      expect(sent['selectedNpcId'], 'mira-two');
      final contexts = sent['npcContexts'] as List;
      expect(contexts, hasLength(1));
      expect(contexts.toString(), contains('bewacht die Schlüssel'));
      expect(contexts.toString(), isNot(contains('kennt den Brief')));
      final confirmed = fixture.controller.currentCampaign!;
      expect(confirmed.revision, before.revision + 1);
      expect(confirmed.hero.toJson(), before.hero.toJson());
      await outbox.remove(action);
      expect(await outbox.pendingFor(before.id), isNull);
      expect(
        (await fixture.repository.reconstructCampaign(before.id))!.toJson(),
        confirmed.toJson(),
      );
    } finally {
      await fixture.close();
    }
  });

  test('lost NPC receipt reconciles after SQLite restart without replay',
      () async {
    final fixture = await _start();
    try {
      await fixture.connect();
      final before = fixture.controller.currentCampaign!;
      final outbox = PlayerActionOutbox(
        fixture.repository,
        newRequestId: () => 'lost-ack-npc',
      );
      final action = await outbox.stage(
        before.id,
        'Ich frage Mira nach den Schlüsseln.',
        selectedNpcId: 'mira-two',
        selectedNpcRevision: before.revision,
      );
      final selected = resolvePendingNpcAction(before, action);
      expect(selected.state, PendingNpcActionState.ready);
      await fixture.controller.sendAction(
        action.text,
        requestId: action.requestId,
        selectedNpc: selected.choice,
      );
      expect(fixture.controller.error, isNull);
      final confirmed = fixture.controller.currentCampaign!;
      expect(confirmed.events.last.payload['actionSelectedNpcId'], 'mira-two');
      expect(fixture.transport.requests, hasLength(1));

      // No acknowledgement: the outbox row intentionally remains on disk.
      await fixture.restart();
      final pending = (await PlayerActionOutbox(fixture.repository)
          .pendingFor(before.id))!;
      expect(pending.toJson(), action.toJson());
      final restored = fixture.controller.currentCampaign!;
      expect(restored.toJson(), confirmed.toJson());
      expect(fixture.controller.narrator.enabled, isFalse);
      final resolution = resolvePendingNpcAction(restored, pending);
      expect(resolution.state, PendingNpcActionState.alreadyConfirmed);
      expect(resolution.choice, isNull);

      // This is the same policy branch as the UI: remove the receipt, not
      // resend to a disconnected or paid provider after losing the ACK.
      await PlayerActionOutbox(fixture.repository).remove(pending);
      expect(
        await PlayerActionOutbox(fixture.repository).pendingFor(before.id),
        isNull,
      );
      expect(fixture.transport.requests, hasLength(1));
      expect(fixture.controller.currentCampaign!.toJson(), confirmed.toJson());
    } finally {
      await fixture.close();
    }
  });

  test('a stale selection stays queued after a competing SQLite revision',
      () async {
    final fixture = await _start();
    try {
      final before = fixture.controller.currentCampaign!;
      final outbox = PlayerActionOutbox(
        fixture.repository,
        newRequestId: () => 'stale-npc-choice',
      );
      final action = await outbox.stage(
        before.id,
        'Ich frage Mira nach den Schlüsseln.',
        selectedNpcId: 'mira-two',
        selectedNpcRevision: before.revision,
      );
      final changed = GameEngine().saveStoryThread(
        before,
        threadId: 'tor',
        title: 'Das Stadttor',
        description: 'Eine bestätigte neue Erinnerung.',
        status: 'open',
      );
      await fixture.repository.saveCampaign(
        changed.campaign,
        events: changed.events,
        expectedRevision: before.revision,
      );
      await fixture.restart();
      final current = fixture.controller.currentCampaign!;
      final snapshot = current.toJson();
      final pending = (await PlayerActionOutbox(fixture.repository)
          .pendingFor(before.id))!;
      final resolution = resolvePendingNpcAction(current, pending);
      expect(resolution.state, PendingNpcActionState.stale);
      expect(resolution.choice, isNull);
      expect(fixture.transport.requests, isEmpty);
      expect(fixture.controller.currentCampaign!.toJson(), snapshot);
      expect(pending.toJson(), action.toJson());
    } finally {
      await fixture.close();
    }
  });

  test('a matching text receipt for the other Mira cannot clear this choice',
      () async {
    final fixture = await _start();
    try {
      await fixture.connect();
      final before = fixture.controller.currentCampaign!;
      final outbox = PlayerActionOutbox(
        fixture.repository,
        newRequestId: () => 'npc-id-collision',
      );
      final action = await outbox.stage(
        before.id,
        'Ich frage Mira.',
        selectedNpcId: 'mira-one',
        selectedNpcRevision: before.revision,
      );
      await fixture.controller.sendAction(
        action.text,
        requestId: action.requestId,
        selectedNpc: NpcStorySelection.choose(before, 'mira-two'),
      );
      expect(fixture.controller.error, isNull);
      expect(fixture.transport.requests, hasLength(1));
      await fixture.restart();
      final current = fixture.controller.currentCampaign!;
      final pending = (await PlayerActionOutbox(fixture.repository)
          .pendingFor(before.id))!;
      expect(
        resolvePendingNpcAction(current, pending).state,
        PendingNpcActionState.stale,
      );
      expect(pending.toJson(), action.toJson());
      expect(fixture.transport.requests, hasLength(1));
    } finally {
      await fixture.close();
    }
  });
}
