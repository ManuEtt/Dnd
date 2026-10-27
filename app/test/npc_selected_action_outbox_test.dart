import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';

void main() {
  sqfliteFfiInit();

  test(
    'selected NPC ID and revision remain intact after SQLite restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('npc-intent-');
      final path = paths.join(directory.path, 'campaign.sqlite');
      var repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final outbox = PlayerActionOutbox(
          repo,
          newRequestId: () => 'select-mira',
        );
        final staged = await outbox.stage(
          'campaign-one',
          'Ich frage Mira nach der Karte.',
          selectedNpcId: 'mira-two',
          selectedNpcRevision: 5,
        );
        expect(staged.selectedNpcId, 'mira-two');
        expect(staged.selectedNpcRevision, 5);
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = PlayerActionOutbox(repo);
        final pending = (await restored.pendingFor('campaign-one'))!;
        expect(pending.toJson(), staged.toJson());
        await restored.remove(pending);
        expect(await restored.pendingFor('campaign-one'), isNull);
        final plain = await restored.stage('campaign-two', 'Ich warte.');
        expect(plain.selectedNpcId, isNull);
        expect(plain.toJson().containsKey('selectedNpcId'), isFalse);
      } finally {
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'outbox rejects incomplete or invalid NPC identity before writing',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'npc-bad-intent-',
      );
      final path = paths.join(directory.path, 'campaign.sqlite');
      final repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final outbox = PlayerActionOutbox(repo);
        for (final invalid in [
          {'selectedNpcId': 'mira-two'},
          {'selectedNpcRevision': 0},
          {'selectedNpcId': '../mira', 'selectedNpcRevision': 0},
          {'selectedNpcId': 'mira-two', 'selectedNpcRevision': -1},
        ]) {
          await expectLater(
            outbox.stage(
              'campaign-one',
              'Ich frage Mira.',
              selectedNpcId: invalid['selectedNpcId'] as String?,
              selectedNpcRevision: invalid['selectedNpcRevision'] as int?,
            ),
            throwsFormatException,
          );
        }
        expect(await outbox.pendingFor('campaign-one'), isNull);
      } finally {
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'SQLite 2 pending text-only actions migrate to SQLite 3 safely',
    () async {
      final directory = await Directory.systemTemp.createTemp('npc-upgrade-');
      final path = paths.join(directory.path, 'campaign.sqlite');
      final old = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
CREATE TABLE pending_player_actions (
  campaign_id TEXT PRIMARY KEY NOT NULL,
  request_id TEXT NOT NULL UNIQUE,
  action_text TEXT NOT NULL
)''');
          },
        ),
      );
      try {
        await old.insert('pending_player_actions', {
          'campaign_id': 'previous',
          'request_id': 'old-request',
          'action_text': 'Ich öffne die Tür.',
        });
      } finally {
        await old.close();
      }
      final repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final outbox = PlayerActionOutbox(repo);
        final legacy = (await outbox.pendingFor('previous'))!;
        expect(legacy.requestId, 'old-request');
        expect(legacy.text, 'Ich öffne die Tür.');
        expect(legacy.selectedNpcId, isNull);
        final chosen = await outbox.stage(
          'new-campaign',
          'Ich frage die zweite Mira.',
          selectedNpcId: 'mira-two',
          selectedNpcRevision: 12,
        );
        expect(
          (await outbox.pendingFor('new-campaign'))!.toJson(),
          chosen.toJson(),
        );
        expect((await outbox.pendingFor('previous'))!.text, legacy.text);
      } finally {
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'stale same-text acknowledgement cannot clear a different NPC or revision',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'npc-stale-clear-',
      );
      final path = paths.join(directory.path, 'campaign.sqlite');
      var repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final outbox = PlayerActionOutbox(
          repo,
          newRequestId: () => 'same-request-id',
        );
        final saved = await outbox.stage(
          'campaign-one',
          'Ich frage Mira.',
          selectedNpcId: 'mira-two',
          selectedNpcRevision: 12,
        );

        // Equal request ID and text are insufficient: both identity fields
        // are part of the player's original, persisted decision.
        for (final wrong in [
          const PendingPlayerAction(
            campaignId: 'campaign-one',
            requestId: 'same-request-id',
            text: 'Ich frage Mira.',
            selectedNpcId: 'mira-one',
            selectedNpcRevision: 12,
          ),
          const PendingPlayerAction(
            campaignId: 'campaign-one',
            requestId: 'same-request-id',
            text: 'Ich frage Mira.',
            selectedNpcId: 'mira-two',
            selectedNpcRevision: 11,
          ),
          const PendingPlayerAction(
            campaignId: 'campaign-one',
            requestId: 'same-request-id',
            text: 'Ich frage Mira.',
          ),
        ]) {
          await expectLater(outbox.remove(wrong), throwsStateError);
          expect(
            (await outbox.pendingFor(saved.campaignId))!.toJson(),
            saved.toJson(),
          );
        }

        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final recovered = PlayerActionOutbox(repo);
        expect(
          (await recovered.pendingFor(saved.campaignId))!.toJson(),
          saved.toJson(),
        );
        await recovered.remove(saved);
        expect(await recovered.pendingFor(saved.campaignId), isNull);
      } finally {
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'a stale NPC acknowledgement cannot remove a newly selected same-text action',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'npc-replaced-clear-',
      );
      final path = paths.join(directory.path, 'campaign.sqlite');
      final repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final outbox = PlayerActionOutbox(
          repo,
          newRequestId: () => 'reused-request-id',
        );
        final original = await outbox.stage(
          'campaign-one',
          'Ich frage Mira.',
          selectedNpcId: 'mira-one',
          selectedNpcRevision: 7,
        );
        await outbox.remove(original);

        // The same deterministic ID is only used to reproduce a stale
        // completion from an earlier request. Production IDs are random.
        final replacement = await outbox.stage(
          'campaign-one',
          'Ich frage Mira.',
          selectedNpcId: 'mira-two',
          selectedNpcRevision: 8,
        );
        await expectLater(outbox.remove(original), throwsStateError);
        expect(
          (await outbox.pendingFor(replacement.campaignId))!.toJson(),
          replacement.toJson(),
        );
        await outbox.remove(replacement);
        expect(await outbox.pendingFor(replacement.campaignId), isNull);
      } finally {
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
