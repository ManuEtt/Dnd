import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';

class _SilentVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
}

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
  _Fixture(
    this.folder,
    this.path,
    this.repository,
    this.controller,
    this.transport,
  );

  final Directory folder;
  final String path;
  SqliteCampaignRepository repository;
  GameController controller;
  final _NpcTransport transport;
  final voice = _SilentVoice();
  final campaignId = 'unused';

  Future<void> connect() async {
    await controller.connectNarrator(
      url: 'https://spielleiter.example.test',
      sessionToken: 'npc-session.token',
    );
    expect(controller.error, isNull);
    expect(controller.narrator.supportsExplicitNpcSelection, isTrue);
  }

  Future<void> restart(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.runAsync(repository.close);
    repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      ),
    ))!;
    controller = GameController(
      repository: repository,
      narrator: BackendNarrator(transport: transport),
    );
    await tester.runAsync(controller.initialize);
    expect(controller.error, isNull);
    expect(controller.narrator.enabled, isFalse);
  }

  Future<void> adventure(WidgetTester tester) async {
    // The production screen restores SQLite-backed pending actions during
    // its initial frame. Let real SQLite futures complete outside FakeAsync.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
    });
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Abenteuer'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
    await tester.runAsync(() => folder.delete(recursive: true));
  }
}

Future<_Fixture> _start(WidgetTester tester) async {
  final folder = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('npc-ui-restart-'),
  ))!;
  final path = paths.join(folder.path, 'campaign.sqlite');
  final repo = (await tester.runAsync(
    () =>
        SqliteCampaignRepository.open(factory: databaseFactoryFfi, path: path),
  ))!;
  final transport = _NpcTransport();
  final controller = GameController(
    repository: repo,
    narrator: BackendNarrator(transport: transport),
  );
  final fixture = _Fixture(folder, path, repo, controller, transport);
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
  await tester.runAsync(() => repo.saveCampaign(campaign));
  await tester.runAsync(() => controller.openCampaign(campaign.id));
  expect(controller.error, isNull);
  return fixture;
}

Future<void> _pendingVisible(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('adventure-retry-action')), findsOneWidget);
}

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets('UI chooses second Mira explicitly and transports only her ID', (
    tester,
  ) async {
    final f = await _start(tester);
    addTearDown(() => f.close(tester));
    await f.connect();
    await f.adventure(tester);
    final campaign = f.controller.currentCampaign!;
    final actionField = find.widgetWithText(TextField, 'Was möchtest du tun?');
    await tester.enterText(actionField, 'Ich frage Mira nach den Schlüsseln.');
    await tester.pumpAndSettle();
    final picker = find.byKey(const ValueKey('adventure-choose-npc'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('npc-picker-mira-one')), findsOneWidget);
    expect(find.byKey(const ValueKey('npc-picker-mira-two')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('npc-picker-mira-two')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 140)),
    );
    await tester.pumpAndSettle();
    expect(f.controller.error, isNull);
    expect(f.transport.requests, hasLength(1));
    expect(f.transport.requests.single['selectedNpcId'], 'mira-two');
    final contexts = f.transport.requests.single['npcContexts'] as List;
    expect(contexts, hasLength(1));
    expect(contexts.toString(), contains('bewacht die Schlüssel'));
    expect(contexts.toString(), isNot(contains('kennt den Brief')));
    expect(f.controller.currentCampaign!.revision, campaign.revision + 1);
    final outbox = PlayerActionOutbox(f.repository);
    expect(await tester.runAsync(() => outbox.pendingFor(campaign.id)), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lost ACK after restart is reconciled without provider replay', (
    tester,
  ) async {
    final f = await _start(tester);
    addTearDown(() => f.close(tester));
    await f.connect();
    final before = f.controller.currentCampaign!;
    const text = 'Ich frage Mira nach den Schlüsseln.';
    final outbox = PlayerActionOutbox(
      f.repository,
      newRequestId: () => 'lost-ack-npc',
    );
    final pending = (await tester.runAsync(
      () => outbox.stage(
        before.id,
        text,
        selectedNpcId: 'mira-two',
        selectedNpcRevision: before.revision,
      ),
    ))!;
    await tester.runAsync(
      () => f.controller.sendAction(
        text,
        requestId: pending.requestId,
        selectedNpc: NpcStorySelection.choose(before, 'mira-two'),
      ),
    );
    expect(f.controller.error, isNull);
    final confirmed = f.controller.currentCampaign!;
    expect(confirmed.revision, before.revision + 1);
    expect(f.transport.requests, hasLength(1));
    expect(confirmed.events.last.payload['actionSelectedNpcId'], 'mira-two');

    await f.restart(tester);
    await f.adventure(tester);
    await _pendingVisible(tester);
    expect(f.controller.currentCampaign!.revision, confirmed.revision);
    expect(f.controller.narrator.enabled, isFalse);
    final retry = find.byKey(const ValueKey('adventure-retry-action'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 140)),
    );
    await tester.pumpAndSettle();
    expect(f.controller.error, isNull);
    expect(f.transport.requests, hasLength(1));
    expect(f.controller.currentCampaign!.revision, confirmed.revision);
    expect(
      await tester.runAsync(
        () => PlayerActionOutbox(f.repository).pendingFor(before.id),
      ),
      isNull,
    );
    expect(retry, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new revision leaves stale NPC intent pending without replay', (
    tester,
  ) async {
    final f = await _start(tester);
    addTearDown(() => f.close(tester));
    final before = f.controller.currentCampaign!;
    final outbox = PlayerActionOutbox(
      f.repository,
      newRequestId: () => 'stale-npc-selection',
    );
    final pending = (await tester.runAsync(
      () => outbox.stage(
        before.id,
        'Ich frage Mira nach den Schlüsseln.',
        selectedNpcId: 'mira-two',
        selectedNpcRevision: before.revision,
      ),
    ))!;
    final changed = GameEngine().saveStoryThread(
      before,
      threadId: 'tor',
      title: 'Das Stadttor',
      description: 'Eine bereits bestätigte neue Erinnerung.',
      status: 'open',
    );
    await tester.runAsync(
      () => f.repository.saveCampaign(
        changed.campaign,
        events: changed.events,
        expectedRevision: before.revision,
      ),
    );
    await f.restart(tester);
    await f.adventure(tester);
    await _pendingVisible(tester);
    final snapshot = f.controller.currentCampaign!.toJson();
    final retry = find.byKey(const ValueKey('adventure-retry-action'));
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 140)),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('NPC-Auswahl ist nicht mehr aktuell'),
      findsWidgets,
    );
    expect(f.transport.requests, isEmpty);
    expect(f.controller.currentCampaign!.toJson(), snapshot);
    expect(
      (await tester.runAsync(
        () => PlayerActionOutbox(f.repository).pendingFor(before.id),
      ))!.toJson(),
      pending.toJson(),
    );
    expect(retry, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
