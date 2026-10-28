import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late SqliteCampaignRepository first;
  late SqliteCampaignRepository second;
  late GameController controller;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('stale-hero-editor-');
    final path = paths.join(directory.path, 'save.sqlite');
    first = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      singleInstance: false,
    );
    second = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
      singleInstance: false,
    );
    controller = GameController(repository: first);
    await controller.initialize();
  });

  tearDown(() async {
    controller.dispose();
    await second.close();
    await first.close();
    await directory.delete(recursive: true);
  });

  test(
    'another connection advancing a campaign rejects an old open hero editor',
    () async {
      await controller.createDemo();
      expect(controller.error, isNull);
      final opened = controller.currentCampaign!;
      final winner = opened.copyWith(
        revision: opened.revision + 1,
        hero: opened.hero.copyWith(name: 'Neuer bestätigter Held'),
      );
      await second.saveCampaign(winner, expectedRevision: opened.revision);

      await controller.saveHero(
        opened.hero.copyWith(name: 'Veralteter Entwurf'),
        expectedCampaignId: opened.id,
        expectedRevision: opened.revision,
      );
      expect(controller.error, contains('geändert'));
      expect(controller.currentCampaign!.revision, opened.revision);
      expect((await first.getCampaign(opened.id))!.hero.name, winner.hero.name);
      expect((await first.getCampaign(opened.id))!.revision, winner.revision);
      expect(
        (await first.loadCharacters())
            .singleWhere((h) => h.id == opened.hero.id)
            .name,
        winner.hero.name,
      );
      expect(
        await first.reconstructCampaign(
          opened.id,
          revision: winner.revision + 1,
        ),
        isNull,
      );
    },
  );

  test(
    'an old editor cannot save after the selected campaign has changed',
    () async {
      await controller.createDemo();
      final opened = controller.currentCampaign!;
      await controller.saveHero(
        opened.hero.copyWith(name: 'Unzulässiger Wechsel'),
        expectedCampaignId: 'another-campaign',
        expectedRevision: opened.revision,
      );
      expect(controller.error, contains('geändert'));
      expect((await first.getCampaign(opened.id))!.hero.name, opened.hero.name);
    },
  );

  test(
    'archive compare-and-swap rejects another editor and survives restart',
    () async {
      final original = HeroCharacter(id: 'hero-stale', name: 'Erste Fassung');
      await first.saveCharacter(original);
      final confirmed = original.copyWith(name: 'Zweite Fassung');
      await second.saveCharacterIfUnchanged(
        confirmed,
        expectedOriginal: original,
      );
      await controller.saveStandaloneHero(
        original.copyWith(name: 'Veraltete Fassung'),
        requireOriginalMatch: true,
        originalHero: original,
      );
      expect(controller.error, contains('geändert'));
      expect((await first.loadCharacters()).single.name, 'Zweite Fassung');
      await second.close();
      final path = paths.join(directory.path, 'save.sqlite');
      second = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
        singleInstance: false,
      );
      expect((await second.loadCharacters()).single.name, 'Zweite Fassung');

      await controller.saveStandaloneHero(
        confirmed.copyWith(name: 'Dritte Fassung'),
        requireOriginalMatch: true,
        originalHero: confirmed,
      );
      expect(controller.error, isNull);
      expect((await second.loadCharacters()).single.name, 'Dritte Fassung');
    },
  );

  test('new archive character cannot overwrite an existing ID', () async {
    final existing = HeroCharacter(id: 'hero-duplicate', name: 'Vorhanden');
    await second.saveCharacter(existing);
    await controller.saveStandaloneHero(
      existing.copyWith(name: 'Doppelte Anlage'),
      requireOriginalMatch: true,
    );
    expect(controller.error, contains('geändert'));
    expect((await first.loadCharacters()).single.name, 'Vorhanden');
  });

  test(
    'a deleted archive character is not silently recreated by old editor',
    () async {
      final original = HeroCharacter(id: 'hero-deleted', name: 'Gelöscht');
      await first.saveCharacter(original);
      await second.deleteCharacter(original.id);
      await controller.saveStandaloneHero(
        original.copyWith(name: 'Rückkehr'),
        requireOriginalMatch: true,
        originalHero: original,
      );
      expect(controller.error, contains('geändert'));
      expect(await first.loadCharacters(), isEmpty);
    },
  );

  test(
    'atomic archive check rejects a stale original without writing',
    () async {
      final original = HeroCharacter(id: 'hero-atom', name: 'Anfang');
      await first.saveCharacter(original);
      await second.saveCharacterIfUnchanged(
        original.copyWith(name: 'Aktuell'),
        expectedOriginal: original,
      );
      await expectLater(
        first.saveCharacterIfUnchanged(
          original.copyWith(name: 'Alt'),
          expectedOriginal: original,
        ),
        throwsA(isA<CampaignConflictException>()),
      );
      expect((await second.loadCharacters()).single.name, 'Aktuell');
    },
  );
}
