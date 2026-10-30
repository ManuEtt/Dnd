import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('outbox-validation-');
    databasePath = paths.join(directory.path, 'campaigns.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('direct SQLite outbox rejects intents that cannot be restored', () async {
    Future<void> reject({
      String campaignId = 'camp',
      String requestId = 'request-one',
      String text = 'Ich untersuche die Tür.',
    }) async {
      await expectLater(
        repository.stagePendingAction(
          campaignId: campaignId,
          requestId: requestId,
          text: text,
        ),
        throwsA(isA<FormatException>()),
      );
      expect(await repository.pendingActionFor(campaignId), isNull);
    }

    await reject(campaignId: '');
    await reject(campaignId: '   ');
    await reject(campaignId: 'bad\u0000id');
    await reject(campaignId: List<String>.filled(129, 'c').join());
    await reject(requestId: '');
    await reject(requestId: 'invalid id');
    await reject(requestId: 'bad/slash');
    await reject(requestId: List<String>.filled(129, 'r').join());
    await reject(text: '');
    await reject(text: '   ');
    await reject(text: List<String>.filled(4001, 'x').join());

    // A rejected direct store call must not leave a row that crashes restore.
    expect(await repository.pendingActionFor('camp'), isNull);
  });

  test('a valid direct intent survives restart and is decoded by the outbox', () async {
    await repository.stagePendingAction(
      campaignId: 'camp',
      requestId: 'request_01',
      text: 'Ich frage Mira nach dem Tor.',
      selectedNpcId: 'mira-two',
      selectedNpcRevision: 3,
    );
    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );

    final recovered = await PlayerActionOutbox(repository).pendingFor('camp');
    expect(recovered?.toJson(), {
      'campaignId': 'camp',
      'requestId': 'request_01',
      'text': 'Ich frage Mira nach dem Tor.',
      'selectedNpcId': 'mira-two',
      'selectedNpcRevision': 3,
    });

    await repository.removePendingAction(
      campaignId: 'camp',
      requestId: 'request_01',
      text: 'Ich frage Mira nach dem Tor.',
      selectedNpcId: 'mira-two',
      selectedNpcRevision: 3,
    );
    expect(await repository.pendingActionFor('camp'), isNull);
  });

  test('rejected writes leave an existing durable intent untouched', () async {
    await repository.stagePendingAction(
      campaignId: 'camp',
      requestId: 'request-old',
      text: 'Ich öffne die Tür.',
    );
    final before = await repository.pendingActionFor('camp');

    await expectLater(
      repository.stagePendingAction(
        campaignId: 'camp',
        requestId: 'request-new',
        text: '   ',
      ),
      throwsA(isA<FormatException>()),
    );
    await expectLater(
      repository.stagePendingAction(
        campaignId: 'other',
        requestId: 'request-old',
        text: 'Ich warte.',
      ),
      throwsA(isA<StateError>()),
    );
    expect(await repository.pendingActionFor('camp'), before);
    expect(await repository.pendingActionFor('other'), isNull);

    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    expect(
      (await PlayerActionOutbox(repository).pendingFor('camp'))?.toJson(),
      before,
    );
  });
}
