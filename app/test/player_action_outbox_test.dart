import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('action-outbox-');
    path = paths.join(directory.path, 'campaign.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('staged text and ID survive real SQLite restart', () async {
    await repository.saveSettings({
      'backendUrl': 'https://example.invalid',
      'lastCampaignId': 'campaign-a',
    });
    final outbox = PlayerActionOutbox(
      repository,
      newRequestId: () => 'request-first',
    );
    final staged = await outbox.stage('campaign-a', '  Ich öffne die Tür. ');
    expect(staged.requestId, 'request-first');
    expect(staged.text, 'Ich öffne die Tür.');
    expect((await outbox.pendingFor('campaign-a'))!.toJson(), staged.toJson());
    expect((await repository.loadSettings())['backendUrl'],
        'https://example.invalid');

    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    final restored = PlayerActionOutbox(repository);
    expect((await restored.pendingFor('campaign-a'))!.toJson(),
        staged.toJson());
    await restored.remove(staged);
    expect(await restored.pendingFor('campaign-a'), isNull);
    expect((await repository.loadSettings())['lastCampaignId'], 'campaign-a');
  });

  test('unconfirmed intent never silently overwritten by a second action',
      () async {
    final outbox = PlayerActionOutbox(
      repository,
      newRequestId: () => 'same-request',
    );
    final first = await outbox.stage('one', 'Ich lausche.');
    await expectLater(
      outbox.stage('one', 'Ich greife an.'),
      throwsStateError,
    );
    await expectLater(
      outbox.stage('two', 'Ich untersuche die Truhe.'),
      throwsStateError,
    );
    expect((await outbox.pendingFor('one'))!.text, first.text);
    expect(await outbox.pendingFor('two'), isNull);

    await outbox.remove(first);
    expect(await outbox.pendingFor('one'), isNull);
  });

  test('pending intent in another campaign remains untouched', () async {
    var index = 0;
    final outbox = PlayerActionOutbox(
      repository,
      newRequestId: () => 'id-${++index}',
    );
    final first = await outbox.stage('one', 'Ich lausche.');
    final second = await outbox.stage('two', 'Ich untersuche die Truhe.');
    await outbox.remove(first);
    expect(await outbox.pendingFor('one'), isNull);
    expect((await outbox.pendingFor('two'))!.requestId, second.requestId);
    await outbox.remove(second);
  });

  test('invalid pending action is rejected before SQLite mutation', () async {
    final outbox = PlayerActionOutbox(
      repository,
      newRequestId: () => 'invalid identifier',
    );
    await expectLater(
      outbox.stage('one', 'Ich lausche.'),
      throwsFormatException,
    );
    expect(await outbox.pendingFor('one'), isNull);
  });

  test('stale settings writes cannot remove the durable outbox', () async {
    final staleSettings = await repository.loadSettings();
    final outbox = PlayerActionOutbox(
      repository,
      newRequestId: () => 'durable-req',
    );
    final staged = await outbox.stage('one', 'Ich lausche.');
    staleSettings['backendUrl'] = 'https://example.invalid';
    await repository.saveSettings(staleSettings);
    expect((await outbox.pendingFor('one'))!.requestId, staged.requestId);
    await outbox.remove(staged);
    expect((await repository.loadSettings())['backendUrl'],
        'https://example.invalid');
  });

  test('two SQLite connections cannot stage two actions for one campaign',
      () async {
    final secondRepository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final first = PlayerActionOutbox(
        repository,
        newRequestId: () => 'request-one',
      );
      final second = PlayerActionOutbox(
        secondRepository,
        newRequestId: () => 'request-two',
      );
      final outcomes = await Future.wait([
        first.stage('one', 'Ich lausche.').then((_) => true)
            .catchError((_) => false),
        second.stage('one', 'Ich greife an.').then((_) => true)
            .catchError((_) => false),
      ]);
      expect(outcomes.where((success) => success).length, 1);
      final saved = await first.pendingFor('one');
      expect(saved, isNotNull);
      expect(
        saved!.requestId,
        anyOf('request-one', 'request-two'),
      );
      final restored = await second.pendingFor('one');
      expect(restored!.toJson(), saved.toJson());
    } finally {
      await secondRepository.close();
    }
  });

  test('two different campaigns keep both concurrent requests', () async {
    final otherRepository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final first = PlayerActionOutbox(
        repository,
        newRequestId: () => 'id-one',
      );
      final second = PlayerActionOutbox(
        otherRepository,
        newRequestId: () => 'id-two',
      );
      await Future.wait([
        first.stage('one', 'Ich lausche.'),
        second.stage('two', 'Ich warte.'),
      ]);
      expect((await first.pendingFor('one'))!.requestId, 'id-one');
      expect((await second.pendingFor('two'))!.requestId, 'id-two');
    } finally {
      await otherRepository.close();
    }
  });

  test('stale removal never clears a different outstanding request', () async {
    final outbox = PlayerActionOutbox(
      repository,
      newRequestId: () => 'correct-req',
    );
    final saved = await outbox.stage('one', 'Ich lausche.');
    await expectLater(
      outbox.remove(PendingPlayerAction(
        campaignId: saved.campaignId,
        requestId: 'stale-req',
        text: saved.text,
      )),
      throwsStateError,
    );
    expect((await outbox.pendingFor('one'))!.requestId, saved.requestId);
  });
}
