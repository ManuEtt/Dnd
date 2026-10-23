import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';

void main() {
  sqfliteFfiInit();

  Future<void> createLegacyDatabase(
    String path,
    Map<String, dynamic> settings,
  ) async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (database, _) async {
          await database.execute('''
CREATE TABLE settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  snapshot TEXT NOT NULL
)''');
        },
      ),
    );
    await db.insert('settings', {
      'id': 1,
      'snapshot': jsonEncode(settings),
    });
    await db.close();
  }

  test('version 1 outbox migrates with IDs and unrelated settings intact',
      () async {
    final dir = await Directory.systemTemp.createTemp('outbox-migration-');
    final path = paths.join(dir.path, 'legacy.sqlite');
    try {
      await createLegacyDatabase(path, {
        'backendUrl': 'https://example.invalid',
        'pendingPlayerActionsV1': {
          'one': {
            'campaignId': 'one',
            'requestId': 'original-one',
            'text': 'Ich öffne die Tür.',
          },
          'two': {
            'campaignId': 'two',
            'requestId': 'original-two',
            'text': 'Ich warte.',
          },
        },
      });
      var db = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final outbox = PlayerActionOutbox(db);
        expect((await outbox.pendingFor('one'))!.requestId, 'original-one');
        expect((await outbox.pendingFor('two'))!.text, 'Ich warte.');
        final settings = await db.loadSettings();
        expect(settings['backendUrl'], 'https://example.invalid');
        expect(settings.containsKey('pendingPlayerActionsV1'), isFalse);
      } finally {
        await db.close();
      }
      db = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final outbox = PlayerActionOutbox(db);
        expect((await outbox.pendingFor('one'))!.requestId, 'original-one');
        final action = (await outbox.pendingFor('two'))!;
        await outbox.remove(action);
        expect(await outbox.pendingFor('two'), isNull);
      } finally {
        await db.close();
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('invalid legacy action aborts upgrade without deleting settings',
      () async {
    final dir = await Directory.systemTemp.createTemp('outbox-bad-legacy-');
    final path = paths.join(dir.path, 'legacy.sqlite');
    try {
      final settings = {
        'backendUrl': 'https://example.invalid',
        'pendingPlayerActionsV1': {
          'one': {
            'campaignId': 'different',
            'requestId': 'original-one',
            'text': 'Ich warte.',
          },
        },
      };
      await createLegacyDatabase(path, settings);
      await expectLater(
        SqliteCampaignRepository.open(factory: databaseFactoryFfi, path: path),
        throwsFormatException,
      );
      final legacy = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(version: 1),
      );
      try {
        final rows = await legacy.query('settings', where: 'id = 1');
        expect(jsonDecode(rows.single['snapshot'] as String), settings);
      } finally {
        await legacy.close();
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
