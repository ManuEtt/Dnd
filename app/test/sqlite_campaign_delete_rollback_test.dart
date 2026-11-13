import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('failed selection cleanup rolls back campaign deletion', () async {
    final folder = await Directory.systemTemp.createTemp('delete-rollback-');
    final path = p.join(folder.path, 'campaign.sqlite');
    final repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = GameEngine().createDemo();
      await repository.saveCampaign(campaign, events: campaign.events);
      await repository.saveSettings({
        'lastCampaignId': campaign.id,
        'theme': 'dark',
      });
      final observer = await databaseFactoryFfi.openDatabase(path);
      try {
        await observer.execute('''
CREATE TRIGGER reject_selected_campaign_cleanup
BEFORE UPDATE ON settings
BEGIN
  SELECT RAISE(ABORT, 'forced settings write failure');
END
''');
        await expectLater(
          repository.deleteCampaignAndReconcileSelection(campaign.id),
          throwsA(isA<Exception>()),
        );
        expect((await repository.getCampaign(campaign.id))!.toJson(),
            campaign.toJson());
        expect(await repository.loadSettings(), {
          'lastCampaignId': campaign.id,
          'theme': 'dark',
        });
        final revisions = await observer.query(
          'campaign_revisions',
          where: 'campaign_id = ?',
          whereArgs: [campaign.id],
        );
        expect(revisions, isNotEmpty);
      } finally {
        await observer.close();
      }
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });

  test('deleting an unselected campaign preserves current selection', () async {
    final folder = await Directory.systemTemp.createTemp('delete-selection-');
    final path = p.join(folder.path, 'campaign.sqlite');
    final repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = GameEngine().createDemo();
      await repository.saveCampaign(campaign, events: campaign.events);
      await repository.saveSettings({
        'lastCampaignId': 'another-campaign',
        'theme': 'dark',
      });
      await repository.deleteCampaignAndReconcileSelection(campaign.id);
      expect(await repository.getCampaign(campaign.id), isNull);
      expect(await repository.loadSettings(), {
        'lastCampaignId': 'another-campaign',
        'theme': 'dark',
      });
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
