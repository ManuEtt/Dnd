import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

// Actual legacy item shape: catalog identity existed before typed stats.
// Canonical ordering mirrors the old repository writer.
Map<String, dynamic> legacyArchiveJson({int gold = 12}) => {
  'abilities': <String, int>{},
  'className': 'Waldläufer',
  'gold': gold,
  'id': 'legacy-raw',
  'inventory': [
    {
      'catalogId': 'weapon-longsword',
      'description': '',
      'id': 'legacy-sword',
      'name': 'Langschwert',
      'quantity': 1,
    },
  ],
  'level': 1,
  'name': 'Altbestand',
  'schemaVersion': 1,
  'species': 'Mensch',
};

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
    'unchanged legacy raw archive row remains editable without eager rewrite',
    () async {
      // A valid older writer stored only these fields; current readers supply
      // further defaults in memory. Keep canonical key ordering so this test
      // exercises absent legacy fields rather than JSON whitespace alone.
      final raw = jsonEncode(legacyArchiveJson());
      final database = await databaseFactoryFfi.openDatabase(
        paths.join(directory.path, 'save.sqlite'),
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.insert('characters', {
          'id': 'legacy-raw',
          'snapshot': raw,
          'updated_at': '2026-01-01T00:00:00.000Z',
        });
        final original = (await first.loadCharacters()).single;
        expect(original.name, 'Altbestand');
        expect(original.gold, 12);
        expect(original.inventory.single.stats, isNotNull);
        expect(
          (jsonDecode(raw) as Map)['inventory'].single.containsKey('stats'),
          isFalse,
        );
        expect(original.startingClassChoice, isNull);
        expect(
          original.toJson().length,
          greaterThan((jsonDecode(raw) as Map).length),
        );
        expect(
          (await database.query('characters')).single['snapshot'],
          raw,
          reason: 'Loading must not silently rewrite an older save.',
        );
        await controller.saveStandaloneHero(
          original,
          requireOriginalMatch: true,
          originalHero: original,
        );
        expect(controller.error, isNull);
        expect(
          (await second.loadCharacters()).single.toJson(),
          original.toJson(),
        );
        await controller.saveStandaloneHero(
          original.copyWith(backstory: 'Bewusst bearbeitet'),
          requireOriginalMatch: true,
          originalHero: original,
        );
        expect(controller.error, isNull);
        final stored = (await second.loadCharacters()).single;
        expect(stored.backstory, 'Bewusst bearbeitet');
        expect(stored.id, original.id);
        expect(stored.gold, 12);
        expect(
          stored.inventory.single.toJson(),
          original.inventory.single.toJson(),
        );
        expect(stored.startingClassChoice, isNull);
      } finally {
        await database.close();
      }
    },
  );

  test(
    'legacy normalization still rejects a concurrent real archive change',
    () async {
      final database = await databaseFactoryFfi.openDatabase(
        paths.join(directory.path, 'save.sqlite'),
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.insert('characters', {
          'id': 'legacy-raw',
          'snapshot': jsonEncode(legacyArchiveJson()),
          'updated_at': '2026-01-01T00:00:00.000Z',
        });
        final original = (await first.loadCharacters()).single;
        expect(original.gold, 12);
        // Independent connection keeps the historical JSON shape but changes
        // a real value after this editor opened. Normalization cannot hide it.
        final winningRaw = jsonEncode(legacyArchiveJson(gold: 3));
        await database.update(
          'characters',
          {'snapshot': winningRaw, 'updated_at': '2026-01-02T00:00:00.000Z'},
          where: 'id = ?',
          whereArgs: ['legacy-raw'],
        );
        final before = await database.query('characters');
        await controller.saveStandaloneHero(
          original.copyWith(backstory: 'Veralteter Entwurf'),
          requireOriginalMatch: true,
          originalHero: original,
        );
        expect(controller.error, contains('geändert'));
        expect(await database.query('characters'), before);
        final winner = (await second.loadCharacters()).single;
        expect(winner.gold, 3);
        expect(winner.backstory, isEmpty);
        expect(
          winner.inventory.single.toJson(),
          original.inventory.single.toJson(),
        );
        expect(
          (await database.query('characters')).single['snapshot'],
          winningRaw,
        );
      } finally {
        await database.close();
      }
    },
  );

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
