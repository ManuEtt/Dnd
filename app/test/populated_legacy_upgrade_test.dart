import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';

/// A populated schema-1 database, not just a settings-only mock.
///
/// Schema 2 differs from schema 1 only by pending_player_actions. First use
/// the real repository to write consistent snapshots, revisions and events,
/// then remove that table and restore SQLite user_version=1. This exercises
/// the actual onUpgrade path against existing game data.
void main() {
  sqfliteFfiInit();

  late Directory directory;
  late String path;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('legacy-full-upgrade-');
    path = paths.join(directory.path, 'game.sqlite');
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<Campaign> createPopulatedV1({
    required Map<String, dynamic> Function(String campaignId) pendingFor,
  }) async {
    final repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final controller = GameController(repository: repository);
      try {
        await controller.initialize();
        await controller.createDemo();
        expect(controller.error, isNull);
        await controller.sendAction('Ich untersuche den Brunnen');
        expect(controller.error, isNull);
        final snapshot = controller.currentCampaign!;
        expect(snapshot.revision, 1);
        expect(snapshot.events, isNotEmpty);
        await repository.saveSettings({
          'lastCampaignId': snapshot.id,
          'voiceLocale': 'de-DE',
          'backendRequestLimit': 7,
          'pendingPlayerActionsV1': pendingFor(snapshot.id),
        });
        return snapshot;
      } finally {
        controller.dispose();
      }
    } finally {
      await repository.close();
      final raw = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await raw.execute('DROP TABLE pending_player_actions');
        await raw.setVersion(1);
      } finally {
        await raw.close();
      }
    }
  }

  Future<void> assertVersion1AndNoOutboxTable() async {
    final raw = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      expect(await raw.getVersion(), 1);
      final tables = await raw.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'pending_player_actions'],
      );
      expect(tables, isEmpty);
    } finally {
      await raw.close();
    }
  }

  test('populated v1 game journal, hero and pending action survive upgrade',
      () async {
    final legacyId = 'legacy-resume-id';
    final expected = await createPopulatedV1(
      pendingFor: (campaignId) => {
        campaignId: {
          'campaignId': campaignId,
          'requestId': legacyId,
          'text': 'Ich betrachte die Runen.',
        },
      },
    );
    final campaignId = expected.id;
    await assertVersion1AndNoOutboxTable();

    var upgraded = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final restored = (await upgraded.getCampaign(campaignId))!;
      expect(restored.toJson(), expected.toJson());
      expect(restored.events.length, expected.events.length);
      expect(
        (await upgraded.reconstructCampaign(campaignId, revision: 0))!.revision,
        0,
      );
      expect(
        (await upgraded.reconstructCampaign(campaignId, revision: 1))!.toJson(),
        expected.toJson(),
      );
      final hero = (await upgraded.loadCharacters()).single;
      expect(hero.id, expected.hero.id);
      expect(hero.inventory.map((item) => item.id).toList(),
          expected.hero.inventory.map((item) => item.id).toList());

      final settings = await upgraded.loadSettings();
      expect(settings['lastCampaignId'], campaignId);
      expect(settings['voiceLocale'], 'de-DE');
      expect(settings['backendRequestLimit'], 7);
      expect(settings.containsKey('pendingPlayerActionsV1'), isFalse);
      final pending = await PlayerActionOutbox(upgraded).pendingFor(campaignId);
      expect(pending!.requestId, legacyId);
      expect(pending.text, 'Ich betrachte die Runen.');

      final exported = jsonDecode(await upgraded.exportCampaign(campaignId))
          as Map<String, dynamic>;
      expect(exported['schemaVersion'], 1);
      expect(exported['campaign'], expected.toJson());
    } finally {
      await upgraded.close();
    }

    // Reopening v2 must neither double-migrate nor lose the original ID.
    upgraded = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      expect(
        (await PlayerActionOutbox(upgraded).pendingFor(campaignId))!.requestId,
        legacyId,
      );
      expect((await upgraded.getCampaign(campaignId))!.toJson(),
          expected.toJson());
    } finally {
      await upgraded.close();
    }
  });

  test('invalid pending entry rolls back schema and retains the saved game',
      () async {
    final existing = await createPopulatedV1(pendingFor: (_) => {
      'other-campaign': {
        'campaignId': 'mismatched-id',
        'requestId': 'legacy-invalid',
        'text': 'Ich lausche.',
      },
    });
    await assertVersion1AndNoOutboxTable();

    await expectLater(
      SqliteCampaignRepository.open(factory: databaseFactoryFfi, path: path),
      throwsFormatException,
    );
    // This must still be a v1 database: the table creation and upgrade are
    // undone as a unit, including the original settings and game journal.
    await assertVersion1AndNoOutboxTable();
    final raw = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      final rows = await raw.query(
        'campaigns',
        columns: ['snapshot'],
        where: 'id = ?',
        whereArgs: [existing.id],
      );
      expect(jsonDecode(rows.single['snapshot'] as String),
          existing.toJson());
      final revisions = await raw.query(
        'campaign_revisions',
        where: 'campaign_id = ?',
        whereArgs: [existing.id],
      );
      expect(revisions, hasLength(2));
      final events = await raw.query(
        'game_events',
        where: 'campaign_id = ?',
        whereArgs: [existing.id],
      );
      expect(events.length, existing.events.length);
      final characters = await raw.query(
        'characters',
        where: 'id = ?',
        whereArgs: [existing.hero.id],
      );
      expect(characters, hasLength(1));
      final original = await raw.query('settings', where: 'id = 1');
      final settings = jsonDecode(original.single['snapshot'] as String)
          as Map<String, dynamic>;
      expect(settings['pendingPlayerActionsV1'], isNotNull);

      // Repair only the corrupt outbox map, then confirm upgrade/recovery.
      settings['pendingPlayerActionsV1'] = {
        existing.id: {
          'campaignId': existing.id,
          'requestId': 'legacy-repaired',
          'text': 'Ich lausche.',
        },
      };
      await raw.update('settings', {
        'snapshot': jsonEncode(settings),
      }, where: 'id = 1');
    } finally {
      await raw.close();
    }

    final upgraded = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      expect((await upgraded.getCampaign(existing.id))!.toJson(),
          existing.toJson());
      expect(
        (await PlayerActionOutbox(upgraded).pendingFor(existing.id))!.requestId,
        'legacy-repaired',
      );
    } finally {
      await upgraded.close();
    }
  });
}
