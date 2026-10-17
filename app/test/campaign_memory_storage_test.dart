import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

void main() {
  sqfliteFfiInit();
  late Directory folder;
  late SqliteCampaignRepository repository;
  late GameController controller;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('campaign-memory-');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: paths.join(folder.path, 'game.sqlite'),
    );
    controller = GameController(repository: repository);
    await controller.initialize();
    await controller.createDemo();
  });
  tearDown(() async {
    controller.dispose();
    await repository.close();
    await folder.delete(recursive: true);
  });

  test(
    'three memory features survive repository restart and JSON export',
    () async {
      await controller.saveStoryThread(
        title: 'Das letzte Siegel',
        description: 'Noch nicht untersucht',
        status: 'open',
      );
      expect(controller.error, isNull);
      await controller.recordNpcRelationship(
        npcId: 'mira',
        relationship: 'verbündet',
        note: 'Mira hat dem Helden einen Hinweis gegeben.',
      );
      expect(controller.error, isNull);
      await controller.saveSessionRecap();
      expect(controller.error, isNull);
      final current = controller.currentCampaign!;
      expect(current.storyThreads.single.status, 'open');
      expect(current.npcRelationshipNotes.single.note, contains('Hinweis'));
      expect(
        current.sessionRecaps.single.summary,
        contains('Das letzte Siegel'),
      );
      final backup = controller.exportCampaign();
      expect(backup, contains('sessionRecaps'));
      expect(backup, contains('npcRelationshipNotes'));
      expect(backup, contains('storyThreads'));
      final persisted = (await repository.getCampaign(current.id))!;
      expect(persisted.toJson(), current.toJson());
      expect(
        (await repository.reconstructCampaign(current.id))!.toJson(),
        current.toJson(),
      );

      controller.dispose();
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: paths.join(folder.path, 'game.sqlite'),
      );
      controller = GameController(repository: repository);
      await controller.initialize();
      expect(controller.currentCampaign!.toJson(), current.toJson());
    },
  );

  test(
    'failed update never overwrites confirmed memory in controller',
    () async {
      await controller.saveStoryThread(
        title: 'Das letzte Siegel',
        description: 'Untersuchung offen',
        status: 'open',
      );
      final saved = controller.currentCampaign!;
      await controller.saveStoryThread(
        threadId: 'does-not-exist',
        title: 'Falscher Faden',
        description: '',
        status: 'resolved',
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), saved.toJson());
      expect(
        (await repository.getCampaign(saved.id))!.toJson(),
        saved.toJson(),
      );
    },
  );
}
