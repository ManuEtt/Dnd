import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Campaign storageFixture({String id = 'journal-campaign'}) => Campaign(
  id: id,
  name: 'Revisionsjournal-Test',
  world: 'Aetheria',
  sessionId: 'journal-session',
  hero: HeroCharacter(
    id: 'journal-hero',
    name: 'Liora',
    abilities: {for (final ability in abilityNames) ability: 12},
    hitPoints: 12,
    maxHitPoints: 12,
    armorClass: 13,
    speed: 9,
    weaponDamage: '1d6',
  ),
  scene: 'Eine ruhige Lichtung',
);

GameEvent journalEvent(String campaignId, int number) => GameEvent(
  id: 'journal-event-$number',
  campaignId: campaignId,
  sessionId: 'journal-session',
  timestamp: DateTime.utc(2026, 11, 20),
  type: 'inventory.item_added',
  entities: const ['journal-hero'],
  payload: {'itemId': 'token-$number', 'quantity': 1},
);

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('journal-integrity-');
    databasePath = paths.join(directory.path, 'journal.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('genuine revision snapshot is restored unchanged', () async {
    final campaign = storageFixture();
    await repository.saveCampaign(campaign);
    final restored = await repository.reconstructCampaign(
      campaign.id,
      revision: 0,
    );
    expect(restored?.id, campaign.id);
    expect(restored?.revision, 0);
  });

  test('tampered journal rejects wrong ID or revision', () async {
    final campaign = storageFixture();
    await repository.saveCampaign(campaign);
    final database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      final malformedSnapshots = [
        storageFixture(id: 'other-campaign').toJson(),
        campaign.copyWith(revision: 7).toJson(),
      ];
      for (final snapshot in malformedSnapshots) {
        final updated = await database.update(
          'campaign_revisions',
          {'snapshot': jsonEncode(snapshot)},
          where: 'campaign_id = ? AND revision = ?',
          whereArgs: [campaign.id, 0],
        );
        expect(updated, 1);
        await expectLater(
          repository.reconstructCampaign(campaign.id, revision: 0),
          throwsA(isA<InvalidSaveException>()),
        );
        // A damaged historical row must not mutate the current snapshot.
        expect((await repository.getCampaign(campaign.id))?.id, campaign.id);
      }
    } finally {
      await database.close();
    }
  });

  test('combined event count permits exactly 10000 entries', () async {
    final campaign = storageFixture(id: 'at-event-limit');
    final events = List.generate(
      10000,
      (index) => journalEvent(campaign.id, index),
    );
    await repository.saveCampaign(campaign, events: events);
    final restored = await repository.getCampaign(campaign.id);
    expect(restored?.events.length, 10000);
  });

  test('10001 separately supplied events fail without partial save', () async {
    final campaign = storageFixture(id: 'over-event-limit');
    final events = List.generate(
      10001,
      (index) => journalEvent(campaign.id, index),
    );
    await expectLater(
      repository.saveCampaign(campaign, events: events),
      throwsA(isA<InvalidSaveException>()),
    );
    expect(await repository.getCampaign(campaign.id), isNull);
  });
}
