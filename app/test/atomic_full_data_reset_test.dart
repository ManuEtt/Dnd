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
  late SqliteCampaignRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('atomic-data-reset-');
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

  Future<(GameController, PlayerActionOutbox, String)> seededGame() async {
    final controller = GameController(repository: repository);
    await controller.initialize();
    expect(controller.error, isNull);
    await controller.createDemo();
    expect(controller.error, isNull);
    final id = controller.currentCampaign!.id;
    await controller.sendAction('Ich untersuche den Brunnen.');
    expect(controller.error, isNull);

    await repository.patchSettings({'voiceLocale': 'de-DE'});
    final outbox = PlayerActionOutbox(
      repository,
      newRequestId: () => 'pending-atomic-reset',
    );
    await outbox.stage('orphaned-command', 'Ich werde zurückkehren.');
    expect((await repository.loadCharacters()), isNotEmpty);
    expect((await repository.getCampaign(id))!.events, isNotEmpty);
    return (controller, outbox, id);
  }

  Future<int> rowCount(String table) async {
    // Fixed test-only table names; never interpolate user input.
    final database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      final rows = await database.rawQuery(
        'SELECT COUNT(*) AS total FROM $table',
      );
      return rows.single['total'] as int;
    } finally {
      await database.close();
    }
  }

  test(
    'confirmed full reset clears all tables and stays empty after restart',
    () async {
      final (controller, outbox, id) = await seededGame();
      try {
        await controller.deleteAllData();
        expect(controller.error, isNull);
        expect(controller.currentCampaign, isNull);
        expect(await repository.getCampaign(id), isNull);
        expect(await repository.loadCharacters(), isEmpty);
        expect(await repository.loadSettings(), isEmpty);
        expect(await outbox.pendingFor('orphaned-command'), isNull);

        for (final table in [
          'campaigns',
          'campaign_revisions',
          'game_events',
          'characters',
          'settings',
          'pending_player_actions',
        ]) {
          expect(await rowCount(table), 0, reason: table);
        }
        // Repeat is intentionally harmless and must not recreate old data.
        await controller.deleteAllData();
        expect(controller.error, isNull);
      } finally {
        controller.dispose();
      }

      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      expect(await repository.loadCampaigns(), isEmpty);
      expect(await repository.loadCharacters(), isEmpty);
      expect(await repository.loadSettings(), isEmpty);
      expect(
        await PlayerActionOutbox(repository).pendingFor('orphaned-command'),
        isNull,
      );
    },
  );

  test(
    'late SQLite failure rolls back campaigns journal settings and outbox',
    () async {
      final (controller, outbox, id) = await seededGame();
      final saved = (await repository.getCampaign(id))!;
      final settings = await repository.loadSettings();
      final character = (await repository.loadCharacters()).single;
      final before = <String, int>{};
      for (final table in [
        'campaigns',
        'campaign_revisions',
        'game_events',
        'characters',
        'settings',
        'pending_player_actions',
      ]) {
        before[table] = await rowCount(table);
      }

      final database = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.execute('''
CREATE TRIGGER reject_character_deletion
BEFORE DELETE ON characters
BEGIN
  SELECT RAISE(ABORT, 'test rollback of all local data');
END''');

        await controller.deleteAllData();
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign?.id, id);
        expect((await repository.getCampaign(id))!.toJson(), saved.toJson());
        expect(
          (await repository.loadCharacters()).single.toJson(),
          character.toJson(),
        );
        expect(await repository.loadSettings(), settings);
        expect(
          (await outbox.pendingFor('orphaned-command'))!.requestId,
          'pending-atomic-reset',
        );
        for (final entry in before.entries) {
          expect(
            await rowCount(entry.key),
            entry.value,
            reason: 'rollback of ${entry.key}',
          );
        }
        await database.execute('DROP TRIGGER reject_character_deletion');
        await controller.deleteAllData();
        expect(controller.error, isNull);
        expect(await repository.loadCampaigns(), isEmpty);
        expect(await outbox.pendingFor('orphaned-command'), isNull);
      } finally {
        controller.dispose();
        await database.close();
      }
    },
  );
}
