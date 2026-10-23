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

  test('invalid/corrupt pending settings block new commands', () async {
    await repository.saveSettings({
      'pendingPlayerActionsV1': {
        'one': {'campaignId': 'other', 'requestId': 'ok', 'text': 'Ja'},
      },
    });
    final outbox = PlayerActionOutbox(repository);
    await expectLater(outbox.pendingFor('one'), throwsFormatException);
    await expectLater(outbox.stage('one', 'Ich lausche.'), throwsStateError);
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
