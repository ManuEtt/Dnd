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
  late String path;
  late SqliteCampaignRepository first;
  late SqliteCampaignRepository second;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('campaign-delete-');
    path = paths.join(directory.path, 'game.sqlite');
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

  Future<(GameController, String)> seedSelectedCampaign() async {
    final controller = GameController(repository: first);
    await controller.initialize();
    expect(controller.error, isNull);
    await controller.createDemo();
    expect(controller.error, isNull);
    final id = controller.currentCampaign!.id;
    await first.patchSettings({
      'voiceLocale': 'de-DE',
      'backendRequestLimit': 8,
    });
    return (controller, id);
  }

  test('deleting selected game atomically clears its saved selection', () async {
    final (controller, id) = await seedSelectedCampaign();
    final outbox = PlayerActionOutbox(
      first,
      newRequestId: () => 'pending-delete-01',
    );
    await outbox.stage(id, 'Ich öffne das Tor.');
    try {
      await controller.deleteCampaign(id);
      expect(controller.error, isNull);
      expect(controller.currentCampaign, isNull);
      expect(await second.getCampaign(id), isNull);
      expect(await outbox.pendingFor(id), isNull);
      final settings = await second.loadSettings();
      expect(settings['lastCampaignId'], isNull);
      expect(settings['voiceLocale'], 'de-DE');
      expect(settings['backendRequestLimit'], 8);

      final restored = GameController(repository: second);
      try {
        await restored.initialize();
        expect(restored.error, isNull);
        expect(restored.currentCampaign, isNull);
      } finally {
        restored.dispose();
      }
    } finally {
      controller.dispose();
    }
  });

  test('unselected campaign deletion preserves selected game and settings',
      () async {
    final (controller, selectedId) = await seedSelectedCampaign();
    try {
      await controller.createDemo();
      expect(controller.error, isNull);
      final secondId = controller.currentCampaign!.id;
      expect(secondId, isNot(selectedId));
      await controller.openCampaign(selectedId);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.id, selectedId);
      await second.deleteCampaign(secondId);
      final settings = await first.loadSettings();
      expect(settings['lastCampaignId'], selectedId);
      expect(settings['voiceLocale'], 'de-DE');
      expect(await second.getCampaign(selectedId), isNotNull);
      expect(await second.getCampaign(secondId), isNull);
    } finally {
      controller.dispose();
    }
  });

  test('concurrent selection change survives deletion of the old game',
      () async {
    final (controller, deletedId) = await seedSelectedCampaign();
    try {
      await controller.createDemo();
      final otherId = controller.currentCampaign!.id;
      expect(otherId, isNot(deletedId));
      await first.patchSettings({'lastCampaignId': deletedId});

      await Future.wait([
        first.deleteCampaign(deletedId),
        second.patchSettings({'lastCampaignId': otherId}),
      ]);

      final settings = await first.loadSettings();
      expect(settings['lastCampaignId'], otherId);
      expect(settings['voiceLocale'], 'de-DE');
      expect(await first.getCampaign(deletedId), isNull);
      expect(await first.getCampaign(otherId), isNotNull);
      final restored = GameController(repository: second);
      try {
        await restored.initialize();
        expect(restored.error, isNull);
        expect(restored.currentCampaign?.id, otherId);
      } finally {
        restored.dispose();
      }
    } finally {
      controller.dispose();
    }
  });

  test('late settings failure rolls back deleted game and pending command',
      () async {
    final (controller, id) = await seedSelectedCampaign();
    final action = await PlayerActionOutbox(
      first,
      newRequestId: () => 'rollback-pending-01',
    ).stage(id, 'Ich lausche.');
    final raw = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      await raw.execute('''
CREATE TRIGGER block_selected_campaign_update
BEFORE UPDATE ON settings
BEGIN
  SELECT RAISE(ABORT, 'test selection rollback');
END''');
      await controller.deleteCampaign(id);
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign?.id, id);
      expect(await second.getCampaign(id), isNotNull);
      expect((await PlayerActionOutbox(second).pendingFor(id))!.toJson(),
          action.toJson());
      final settings = await second.loadSettings();
      expect(settings['lastCampaignId'], id);
      expect(settings['voiceLocale'], 'de-DE');

      await raw.execute('DROP TRIGGER block_selected_campaign_update');
      await controller.deleteCampaign(id);
      expect(controller.error, isNull);
      expect(await second.getCampaign(id), isNull);
      expect(await PlayerActionOutbox(second).pendingFor(id), isNull);
      expect((await second.loadSettings())['lastCampaignId'], isNull);
    } finally {
      controller.dispose();
      await raw.close();
    }
  });
}
