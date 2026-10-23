import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

const _backendUrl = 'https://narrator.example.test';
const _testToken = 'integration_session.signature';
const _action = 'Ich betrachte den Himmel.';
const _remoteText =
    'Liora, zwischen den Wolken glimmt ein silberner Stern. '
    'Mira wartet aufmerksam auf deine nächste Entscheidung. Was tust du?';

class _Request {
  _Request(this.method, this.uri, this.bearerToken, this.body);
  final String method;
  final Uri uri;
  final String bearerToken;
  final Map<String, Object?>? body;
}

/// Only the network boundary is simulated; all persistence uses real SQLite.
class _Transport implements BackendTransport {
  _Transport(this.now);
  final DateTime Function() now;
  final requests = <_Request>[];
  String sessionProvider = 'mock';
  bool failNarration = false;
  BackendResponse? narrationResponse;

  List<_Request> get narrationRequests =>
      requests.where((request) => request.method == 'POST').toList();

  @override
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) async {
    requests.add(
      _Request(
        method,
        uri,
        bearerToken,
        body == null
            ? null
            : Map<String, Object?>.from(jsonDecode(jsonEncode(body)) as Map),
      ),
    );
    if (method == 'GET' && uri.path == '/v1/session') {
      return BackendResponse(
        statusCode: 200,
        body: {
          'provider': sessionProvider,
          'scope': 'narration:read-only',
          'expiresAt': now().add(const Duration(minutes: 5)).toIso8601String(),
        },
      );
    }
    if (method == 'POST' && uri.path == '/v1/narrate') {
      if (failNarration) throw const SocketException('simulated disconnect');
      return narrationResponse ??
          BackendResponse(
            statusCode: 200,
            body: {
              'provider': sessionProvider,
              'text': _remoteText,
              'stateChanges': <Object?>[],
            },
          );
    }
    throw StateError('Unexpected test endpoint: $method ${uri.path}');
  }
}

/// Rejects a commit before SQLite confirms it, with all reads delegated.
class _ControlledRepository implements CampaignRepository {
  _ControlledRepository(this.delegate);
  final CampaignRepository delegate;
  bool failNextSave = false;

  @override
  Future<void> saveCampaign(
    Campaign campaign, {
    List<GameEvent> events = const [],
    int? expectedRevision,
  }) async {
    if (failNextSave) {
      failNextSave = false;
      throw const InvalidSaveException('Test: Speicherung abgelehnt.');
    }
    await delegate.saveCampaign(
      campaign,
      events: events,
      expectedRevision: expectedRevision,
    );
  }

  @override
  Future<List<Campaign>> loadCampaigns() => delegate.loadCampaigns();
  @override
  Future<Campaign?> getCampaign(String id) => delegate.getCampaign(id);
  @override
  Future<void> deleteCampaign(String id) => delegate.deleteCampaign(id);
  @override
  Future<List<HeroCharacter>> loadCharacters() => delegate.loadCharacters();
  @override
  Future<void> saveCharacter(HeroCharacter character) =>
      delegate.saveCharacter(character);
  @override
  Future<void> deleteCharacter(String id) => delegate.deleteCharacter(id);
  @override
  Future<Map<String, dynamic>> loadSettings() => delegate.loadSettings();
  @override
  Future<void> saveSettings(Map<String, dynamic> settings) =>
      delegate.saveSettings(settings);
  @override
  Future<String> exportCampaign(String id) => delegate.exportCampaign(id);
  @override
  Future<Campaign> importCampaign(String source) =>
      delegate.importCampaign(source);
  @override
  Future<Campaign?> reconstructCampaign(String id, {int? revision}) =>
      delegate.reconstructCampaign(id, revision: revision);
  @override
  Future<void> close() => delegate.close();
}

/// The provider may replace messages and audit metadata, never domain fields.
Map<String, dynamic> _domainState(Campaign campaign) =>
    Map<String, dynamic>.from(campaign.toJson())
      ..remove('messages')
      ..remove('events')
      ..remove('revision');

String _localText(Campaign campaign) =>
    GameEngine().act(campaign, _action).narration;

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository sqlite;
  late _ControlledRepository repository;
  late _Transport transport;
  late BackendNarrator narrator;
  late GameController controller;
  late DateTime now;

  BackendNarrator createNarrator() =>
      BackendNarrator(transport: transport, clock: () => now);

  GameController createController() => GameController(
    repository: repository,
    narrator: narrator,
    engine: GameEngine(
      dice: DiceEngine(random: Random(117)),
      clock: () => now,
    ),
  );

  Future<void> connect({int limit = 20, bool allowPaidProvider = false}) async {
    await controller.connectNarrator(
      url: _backendUrl,
      sessionToken: _testToken,
      requestLimit: limit,
      allowPaidProvider: allowPaidProvider,
    );
    expect(controller.error, isNull);
    expect(narrator.enabled, true);
  }

  Future<void> expectConfirmed(Campaign campaign) async {
    expect(controller.currentCampaign!.toJson(), campaign.toJson());
    expect(
      (await sqlite.getCampaign(campaign.id))!.toJson(),
      campaign.toJson(),
    );
    expect(
      (await sqlite.reconstructCampaign(campaign.id))!.toJson(),
      campaign.toJson(),
    );
  }

  setUp(() async {
    now = DateTime.utc(2026, 10, 13, 12);
    directory = await Directory.systemTemp.createTemp('living-gm-backend-');
    databasePath = paths.join(directory.path, 'campaign.sqlite');
    sqlite = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    repository = _ControlledRepository(sqlite);
    transport = _Transport(() => now);
    narrator = createNarrator();
    controller = createController();
    await controller.initialize();
    await controller.createDemo();
    expect(controller.error, isNull);
  });

  tearDown(() async {
    controller.dispose();
    await sqlite.close();
    await directory.delete(recursive: true);
  });

  test('duplicate request ID never calls external narrator twice', () async {
    await connect();
    await controller.sendAction(_action, requestId: 'narrator-retry-1');
    expect(controller.error, isNull);
    final confirmed = controller.currentCampaign!;
    expect(transport.narrationRequests, hasLength(1));
    await controller.sendAction(_action, requestId: 'narrator-retry-1');
    expect(controller.error, isNull);
    expect(transport.narrationRequests, hasLength(1));
    await expectConfirmed(confirmed);
  });
  test('default offline play makes no network request', () async {
    final before = controller.currentCampaign!;
    await controller.sendAction(_action);
    expect(controller.error, isNull);
    expect(transport.requests, isEmpty);
    expect(narrator.enabled, false);
    final confirmed = controller.currentCampaign!;
    expect(confirmed.messages.last.text, _localText(before));
    expect(_domainState(confirmed), _domainState(before));
    await expectConfirmed(confirmed);
  });

  test(
    'explicit connection transmits confirmed context and persists only narration',
    () async {
      final seed = controller.currentCampaign!;
      await controller.sendAction('Ich untersuche den Brunnen');
      final before = controller.currentCampaign!;
      final localOutcome = _localText(before);
      await connect();
      expect(transport.requests.single.method, 'GET');
      expect(transport.requests.single.body, isNull);
      await controller.sendAction(_action);
      expect(controller.error, isNull);

      final request = transport.narrationRequests.single;
      expect(request.uri.toString(), '$_backendUrl/v1/narrate');
      expect(request.bearerToken, _testToken);
      expect(request.body!['campaignId'], before.id);
      expect(request.body!['playerName'], before.hero.name);
      expect(request.body!['action'], _action);
      expect(request.body!['scene'], before.scene);
      expect(request.body!['outcome'], localOutcome);
      expect(
        request.body!['memories'],
        anyElement(allOf(contains('keyFound:'), contains('true'))),
      );
      expect(
        request.body!['memories'],
        anyElement(allOf(contains('Anzahl 1'), contains('Messingschlüssel'))),
      );
      expect(
        request.body!.keys,
        unorderedEquals([
          'campaignId',
          'playerName',
          'action',
          'scene',
          'outcome',
          'memories',
        ]),
      );

      final confirmed = controller.currentCampaign!;
      expect(confirmed.messages.last.text, _remoteText);
      expect(confirmed.revision, before.revision + 1);
      expect(confirmed.events.last.payload['narrationProvider'], 'mock');
      expect(_domainState(confirmed), _domainState(before));
      expect(
        confirmed.events.last.payload['stateAfter'],
        confirmed.copyWith(events: const []).toJson(),
      );
      expect(
        MemoryEngine.replay(seed, confirmed.events).toJson(),
        confirmed.toJson(),
      );
      await expectConfirmed(confirmed);
    },
  );

  test(
    'relevant confirmed NPC state reaches the backend beyond the first twenty facts',
    () async {
      final base = controller.currentCampaign!;
      final crowded = base.copyWith(
        revision: base.revision + 1,
        facts: {
          for (var index = 0; index < 120; index++)
            'distant-$index': 'Ein fernes Land trägt die Nummer $index.',
          ...base.facts,
          'lyra-secret': 'Lyra bewachte den vergessenen Wasserweg.',
        },
        npcs: [
          ...base.npcs,
          const WorldNpc(
            id: 'lyra',
            name: 'Lyra',
            alive: false,
            description: 'Die Wächterin des Wasserwegs.',
          ),
        ],
      );
      await sqlite.saveCampaign(crowded);
      await controller.openCampaign(crowded.id);
      await connect();
      await controller.sendAction('Was weiß ich über Lyra?');
      expect(controller.error, isNull);
      final memories =
          transport.narrationRequests.single.body!['memories'] as List;
      expect(memories.length, lessThanOrEqualTo(20));
      expect(memories.first, allOf(contains('NPC tot'), contains('Lyra')));
      expect(memories, anyElement(contains('vergessenen Wasserweg')));
      expect(controller.currentCampaign!.npcs.last.alive, false);
      expect(controller.currentCampaign!.facts, crowded.facts);
      await expectConfirmed(controller.currentCampaign!);
    },
  );

  test('inventory, rolls, combat and character edits remain local', () async {
    await connect();
    await controller.sendAction('Ich untersuche den Brunnen');
    expect(controller.currentCampaign!.events.last.type, 'inventory.itemAdded');
    await controller.sendAction('Ich untersuche meine Umgebung');
    expect(controller.currentCampaign!.events.last.type, 'roll.requested');
    await controller.resolveRoll(natural: 16);
    expect(controller.currentCampaign!.events.last.type, 'roll.resolved');
    await controller.rollDice('1W20+2');
    expect(controller.currentCampaign!.events.last.type, 'dice.freeRoll');
    await controller.saveHero(
      controller.currentCampaign!.hero.copyWith(
        backstory: 'Eine neue Herkunft',
      ),
    );
    expect(controller.currentCampaign!.events.last.type, 'character.updated');
    await controller.sendAction('Ich gehe zum Waldschrein');
    expect(controller.currentCampaign!.encounter, isNotNull);
    expect(controller.currentCampaign!.events.last.type, 'combat.started');
    expect(controller.error, isNull);
    expect(transport.narrationRequests, isEmpty);
    expect(narrator.requestsUsed, 0);
    await expectConfirmed(controller.currentCampaign!);
  });

  for (final stateChanges in <Object?>[
    null,
    {'hitPoints': 0},
    [
      {'type': 'character.damage', 'amount': 99},
    ],
  ]) {
    test(
      'invalid stateChanges $stateChanges falls back without mutation',
      () async {
        await connect();
        transport.narrationResponse = BackendResponse(
          statusCode: 200,
          body: {
            'provider': 'mock',
            'text':
                'Diese unzulässige Erzählung darf nicht gespeichert werden.',
            'stateChanges': stateChanges,
          },
        );
        final before = controller.currentCampaign!;
        await controller.sendAction(_action);
        expect(controller.error, isNull);
        final confirmed = controller.currentCampaign!;
        expect(confirmed.messages.last.text, _localText(before));
        expect(
          confirmed.events.last.payload.containsKey('narrationProvider'),
          false,
        );
        expect(_domainState(confirmed), _domainState(before));
        expect(narrator.statusMessage, contains('verworfen'));
        await expectConfirmed(confirmed);
      },
    );
  }

  test('network failure commits the current local turn once', () async {
    await connect();
    transport.failNarration = true;
    final before = controller.currentCampaign!;
    await controller.sendAction(_action);
    expect(controller.error, isNull);
    final confirmed = controller.currentCampaign!;
    expect(confirmed.messages.last.text, _localText(before));
    expect(confirmed.revision, before.revision + 1);
    expect(confirmed.events, hasLength(before.events.length + 1));
    expect(transport.narrationRequests, hasLength(1));
    expect(narrator.requestsUsed, 1);
    expect(narrator.statusMessage, contains('ausgefallen'));
    await expectConfirmed(confirmed);
  });

  test('401 clears the session while preserving the local turn', () async {
    await connect();
    transport.narrationResponse = const BackendResponse(
      statusCode: 401,
      body: null,
    );
    final before = controller.currentCampaign!;
    await controller.sendAction(_action);
    expect(controller.error, isNull);
    expect(narrator.enabled, false);
    expect(narrator.provider, isNull);
    expect(narrator.expiresAt, isNull);
    expect(narrator.allowPaidProvider, false);
    expect(narrator.statusMessage, contains('abgelaufen'));
    expect(controller.currentCampaign!.messages.last.text, _localText(before));
    await controller.sendAction(_action);
    expect(transport.narrationRequests, hasLength(1));
    expect(controller.currentCampaign!.revision, before.revision + 2);
    await expectConfirmed(controller.currentCampaign!);
  });

  test('expired session is cleared before transmitting a new turn', () async {
    await connect();
    now = now.add(const Duration(minutes: 6));
    final before = controller.currentCampaign!;
    await controller.sendAction(_action);
    expect(controller.error, isNull);
    expect(transport.narrationRequests, isEmpty);
    expect(narrator.enabled, false);
    expect(narrator.expiresAt, isNull);
    expect(controller.currentCampaign!.messages.last.text, _localText(before));
    await expectConfirmed(controller.currentCampaign!);
  });

  test(
    'failed save after remote narration cannot change confirmed state',
    () async {
      await connect();
      final before = controller.currentCampaign!;
      repository.failNextSave = true;
      await controller.sendAction(_action);
      expect(transport.narrationRequests, hasLength(1));
      expect(controller.error, contains('Speicherung abgelehnt'));
      expect(controller.busy, false);
      await expectConfirmed(before);
      expect(
        await sqlite.reconstructCampaign(
          before.id,
          revision: before.revision + 1,
        ),
        isNull,
      );

      await controller.sendAction(_action);
      expect(controller.error, isNull);
      final confirmed = controller.currentCampaign!;
      expect(confirmed.revision, before.revision + 1);
      expect(confirmed.events, hasLength(before.events.length + 1));
      expect(confirmed.messages.last.text, _remoteText);
      await expectConfirmed(confirmed);
    },
  );

  test(
    'tokens and paid consent never survive persistence or restart',
    () async {
      transport.sessionProvider = 'openai';
      await connect(limit: 3, allowPaidProvider: true);
      await controller.sendAction(_action);
      expect(narrator.allowPaidProvider, true);
      final confirmed = controller.currentCampaign!;
      final settings = await sqlite.loadSettings();
      expect(settings, {
        'lastCampaignId': confirmed.id,
        'backendUrl': _backendUrl,
        'backendRequestLimit': 3,
      });
      for (final source in [
        jsonEncode(settings),
        controller.exportCampaign(),
        controller.exportHero(confirmed.hero),
        await sqlite.exportCampaign(confirmed.id),
      ]) {
        expect(source, isNot(contains(_testToken)));
        expect(source, isNot(contains('allowPaidProvider')));
        expect(source, isNot(contains('sessionToken')));
      }
      controller.dispose();
      await sqlite.close();
      await for (final entry in directory.list(recursive: true)) {
        if (entry is File) {
          expect(
            latin1.decode(await entry.readAsBytes()),
            isNot(contains(_testToken)),
            reason:
                'A session credential must never enter SQLite or its journals.',
          );
        }
      }
      sqlite = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
      );
      repository = _ControlledRepository(sqlite);
      narrator = createNarrator();
      controller = createController();
      final requestCount = transport.requests.length;
      await controller.initialize();
      expect(controller.error, isNull);
      expect(narrator.backendUrl, _backendUrl);
      expect(narrator.requestLimit, 3);
      expect(narrator.enabled, false);
      expect(narrator.allowPaidProvider, false);
      expect(narrator.provider, isNull);
      expect(narrator.expiresAt, isNull);
      await expectConfirmed(confirmed);
      await controller.sendAction(_action);
      expect(transport.requests, hasLength(requestCount));
      expect(
        controller.currentCampaign!.messages.last.text,
        _localText(confirmed),
      );
    },
  );

  test(
    'local request cap prevents further transmissions but play continues',
    () async {
      await connect(limit: 1);
      await controller.sendAction(_action);
      expect(controller.currentCampaign!.messages.last.text, _remoteText);
      final before = controller.currentCampaign!;
      await controller.sendAction(_action);
      expect(controller.error, isNull);
      expect(transport.narrationRequests, hasLength(1));
      expect(narrator.requestsUsed, 1);
      expect(narrator.statusMessage, contains('Anfragelimit'));
      expect(
        controller.currentCampaign!.messages.last.text,
        _localText(before),
      );
      expect(controller.currentCampaign!.revision, before.revision + 1);
      await expectConfirmed(controller.currentCampaign!);
    },
  );
}
