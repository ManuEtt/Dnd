import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late SqliteCampaignRepository first;
  late SqliteCampaignRepository second;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atomic-preferences-');
    final path = paths.join(directory.path, 'campaign.sqlite');
    first = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    second = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
  });

  tearDown(() async {
    await second.close();
    await first.close();
    await directory.delete(recursive: true);
  });

  test('independent concurrent writers preserve unrelated settings', () async {
    await first.saveSettings({
      'backendUrl': 'https://example.invalid',
      'backendRequestLimit': 5,
    });
    await Future.wait([
      first.patchSettings({'lastCampaignId': 'campaign-a'}),
      second.patchSettings({'voiceLocale': 'de-DE', 'voiceRate': 0.9}),
    ]);

    final stored = await first.loadSettings();
    expect(stored['backendUrl'], 'https://example.invalid');
    expect(stored['backendRequestLimit'], 5);
    expect(stored['lastCampaignId'], 'campaign-a');
    expect(stored['voiceLocale'], 'de-DE');
    expect(stored['voiceRate'], 0.9);
    expect(await second.loadSettings(), stored);
  });

  test('many overlapping transactions retain all distinct keys', () async {
    final changes = [
      for (var index = 0; index < 24; index++)
        (index.isEven ? first : second).patchSettings({
          'setting-$index': index,
        }),
    ];
    await Future.wait(changes);
    final settings = await second.loadSettings();
    for (var index = 0; index < 24; index++) {
      expect(settings['setting-$index'], index);
    }
  });

  test('removal changes only named keys and preserves other writers', () async {
    await first.saveSettings({
      'legacyPreference': 'remove',
      'voiceLocale': 'de-DE',
      'backendUrl': 'https://example.invalid',
    });
    await Future.wait([
      first.patchSettings({}, removeKeys: {'legacyPreference'}),
      second.patchSettings({'lastCampaignId': 'campaign-b'}),
    ]);
    final settings = await first.loadSettings();
    expect(settings.containsKey('legacyPreference'), isFalse);
    expect(settings['voiceLocale'], 'de-DE');
    expect(settings['backendUrl'], 'https://example.invalid');
    expect(settings['lastCampaignId'], 'campaign-b');
  });

  test(
    'failed patch rolls back without altering durable preferences',
    () async {
      await first.patchSettings({'voiceLocale': 'de-DE'});
      await expectLater(
        second.patchSettings({'unsupported': Object()}),
        throwsA(isA<Object>()),
      );
      expect(await first.loadSettings(), {'voiceLocale': 'de-DE'});

      await expectLater(
        first.patchSettings(
          {'voiceLocale': 'de-AT'},
          removeKeys: {'voiceLocale'},
        ),
        throwsArgumentError,
      );
      expect(await second.loadSettings(), {'voiceLocale': 'de-DE'});
    },
  );

  test('concurrent settings updates cannot remove a pending action', () async {
    final outbox = PlayerActionOutbox(
      first,
      newRequestId: () => 'pending-settings-test',
    );
    final pending = await outbox.stage('campaign-a', 'Ich öffne die Tür.');
    await Future.wait([
      first.patchSettings({'lastCampaignId': 'campaign-a'}),
      second.patchSettings({'voiceLocale': 'de-DE'}),
    ]);
    expect((await outbox.pendingFor('campaign-a'))!.toJson(), pending.toJson());
    await outbox.remove(pending);
    expect(await outbox.pendingFor('campaign-a'), isNull);
    expect((await first.loadSettings())['voiceLocale'], 'de-DE');
  });

  test('campaign selection preserves concurrent voice preferences', () async {
    final controller = GameController(repository: first);
    try {
      await controller.initialize();
      expect(controller.error, isNull);
      await Future.wait([
        controller.createDemo(),
        second.patchSettings({'voiceLocale': 'de-DE', 'voiceRate': 1.0}),
      ]);
      expect(controller.error, isNull);
      final saved = controller.currentCampaign;
      expect(saved, isNotNull);
      final settings = await second.loadSettings();
      expect(settings['lastCampaignId'], saved!.id);
      expect(settings['voiceLocale'], 'de-DE');
      expect(settings['voiceRate'], 1.0);
      final restored = GameController(repository: second);
      try {
        await restored.initialize();
        expect(restored.error, isNull);
        expect(restored.currentCampaign?.id, saved.id);
      } finally {
        restored.dispose();
      }
    } finally {
      controller.dispose();
    }
  });
  test('deleting one campaign clears only its pending command', () async {
    var index = 0;
    final outbox = PlayerActionOutbox(
      first,
      newRequestId: () => 'deletion-${++index}',
    );
    await outbox.stage('campaign-one', 'Ich lausche.');
    final other = await outbox.stage('campaign-two', 'Ich warte.');
    await first.deleteCampaign('campaign-one');
    expect(await outbox.pendingFor('campaign-one'), isNull);
    expect(
      (await outbox.pendingFor('campaign-two'))!.requestId,
      other.requestId,
    );
  });

  test(
    'delete all data also removes orphaned durable pending actions',
    () async {
      final controller = GameController(repository: first);
      try {
        await controller.initialize();
        await controller.createDemo();
        expect(controller.error, isNull);
        final campaignId = controller.currentCampaign!.id;
        final outbox = PlayerActionOutbox(
          first,
          newRequestId: () => 'orphaned-intent',
        );
        await outbox.stage('orphan-id', 'Ich kehre zurück.');
        expect(await outbox.pendingFor('orphan-id'), isNotNull);
        await controller.deleteAllData();
        expect(controller.error, isNull);
        expect(await first.loadCampaigns(), isEmpty);
        expect(await outbox.pendingFor('orphan-id'), isNull);
        expect(await outbox.pendingFor(campaignId), isNull);
        expect(await second.loadSettings(), isEmpty);
      } finally {
        controller.dispose();
      }
    },
  );
}
