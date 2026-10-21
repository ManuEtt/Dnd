import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Campaign fixture({
  String id = 'campaign-a',
  List<GameEvent> events = const [],
}) => Campaign(
  id: id,
  name: 'Der vergessene Hain',
  world: 'Aetheria',
  sessionId: 'session-one',
  hero: HeroCharacter(
    id: 'hero-one',
    name: 'Liora',
    abilities: {for (final key in abilityNames) key: 12},
    hitPoints: 12,
    maxHitPoints: 12,
    armorClass: 13,
    speed: 9,
    weaponDamage: '1d6',
  ),
  scene: 'Am Rand des Silberwaldes.',
  facts: const {'Ort': 'Silberwald'},
  events: events,
);

GameEvent reward(String campaignId, {String id = 'event-reward'}) => GameEvent(
  id: id,
  campaignId: campaignId,
  sessionId: 'session-one',
  timestamp: DateTime.utc(2026, 10, 13),
  type: 'inventory.item_added',
  entities: const ['hero-one'],
  payload: const {'itemId': 'golden-key', 'quantity': 1},
);

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('living-gm-storage-');
    databasePath = paths.join(directory.path, 'test.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
  });
  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('Getrennte Inventarwerte überleben SQLite und JSON-Export', () async {
    final base = fixture();
    final character = base.hero.copyWith(
      inventory: const [
        InventoryItem(
          id: 'spear-custom',
          name: 'Eigener Speer',
          quantity: 2,
          description: 'Von einer Meisterschmiedin gefertigt.',
          stats: InventoryItemStats(
            kind: InventoryItemKind.weapon,
            damage: '1d6',
            damageType: 'Stich',
            weightLb: 3.0,
            priceCp: 120,
            rangeNormalFt: 20,
            rangeLongFt: 60,
          ),
        ),
      ],
    );
    final campaign = base.copyWith(hero: character);
    await repository.saveCampaign(campaign);
    final restored = (await repository.getCampaign(campaign.id))!;
    final item = restored.hero.inventory.single;
    expect(item.stats!.damage, '1d6');
    expect(item.stats!.weightLb, 3.0);
    expect(item.stats!.rangeLongFt, 60);
    expect(item.description, 'Von einer Meisterschmiedin gefertigt.');
    final encoded = await repository.exportCampaign(campaign.id);
    final envelope = jsonDecode(encoded) as Map<String, dynamic>;
    final decoded = Campaign.fromJson(
      Map<String, dynamic>.from(envelope['campaign'] as Map),
    );
    expect(decoded.hero.inventory.single.stats!.priceCp, 120);
    expect(decoded.hero.inventory.single.stats!.damageType, 'Stich');
  });

  test(
    'confirmed scene, character, facts, settings and journal survive reopen',
    () async {
      final initial = fixture();
      await repository.saveCampaign(initial);
      await repository.saveCharacter(initial.hero);
      await repository.saveSettings({'autoSpeak': false, 'locale': 'de-DE'});
      final event = reward(initial.id);
      final updated = initial.copyWith(
        revision: 1,
        scene: 'Der goldene Schlüssel öffnet den Tempel.',
        facts: const {'Ort': 'Tempel', 'Schlüssel': 'golden'},
        hero: initial.hero.copyWith(
          inventory: const [
            InventoryItem(id: 'golden-key', name: 'Goldener Schlüssel'),
          ],
        ),
        events: [event],
      );
      await repository.saveCampaign(updated, events: [event]);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
      );
      final restored = (await repository.getCampaign(initial.id))!;
      expect(restored.scene, updated.scene);
      expect(restored.hero.inventory.single.id, 'golden-key');
      expect(restored.facts['Schlüssel'], 'golden');
      expect(restored.events.single.id, event.id);
      expect(
        (await repository.loadCharacters()).single.name,
        initial.hero.name,
      );
      expect(await repository.loadSettings(), {
        'autoSpeak': false,
        'locale': 'de-DE',
      });
      expect(
        (await repository.reconstructCampaign(initial.id))!.toJson(),
        restored.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(initial.id, revision: 0))!.scene,
        initial.scene,
      );
    },
  );

  test(
    'late event collision rolls back snapshot and revision journal atomically',
    () async {
      final first = fixture(events: [reward('campaign-a')]);
      final second = fixture(id: 'campaign-b');
      await repository.saveCampaign(first);
      await repository.saveCampaign(second);
      final failed = second.copyWith(
        revision: 1,
        scene: 'Diese Szene darf nie bestätigt werden.',
        events: [reward(second.id)],
      );
      await expectLater(
        repository.saveCampaign(failed),
        throwsA(isA<InvalidSaveException>()),
      );
      expect(
        (await repository.getCampaign(second.id))!.toJson(),
        second.toJson(),
      );
      expect(
        await repository.reconstructCampaign(second.id, revision: 1),
        isNull,
      );
    },
  );

  test(
    'retry of confirmed revision never duplicates inventory rewards or events',
    () async {
      final initial = fixture();
      await repository.saveCampaign(initial);
      final event = reward(initial.id);
      final confirmed = initial.copyWith(
        revision: 1,
        events: [event],
        hero: initial.hero.copyWith(
          inventory: const [
            InventoryItem(id: 'golden-key', name: 'Goldener Schlüssel'),
          ],
        ),
      );
      await repository.saveCampaign(confirmed, events: [event]);
      await repository.saveCampaign(confirmed, events: [event]);
      final restored = (await repository.getCampaign(initial.id))!;
      expect(restored.events, hasLength(1));
      expect(restored.hero.inventory.single.quantity, 1);
      expect(restored.revision, 1);
    },
  );

  test('stale writer cannot replace a newer confirmed revision', () async {
    final initial = fixture();
    await repository.saveCampaign(initial);
    await repository.saveCampaign(
      initial.copyWith(revision: 1, scene: 'Neuere Szene'),
    );
    await expectLater(
      repository.saveCampaign(
        initial.copyWith(revision: 1, scene: 'Veraltete Szene'),
      ),
      throwsA(isA<CampaignConflictException>()),
    );
    expect((await repository.getCampaign(initial.id))!.scene, 'Neuere Szene');
  });

  test(
    'confirmed events cannot be removed or rewritten by a later revision',
    () async {
      final original = fixture(events: [reward('campaign-a')]);
      await repository.saveCampaign(original);
      await expectLater(
        repository.saveCampaign(original.copyWith(revision: 1, events: [])),
        throwsA(isA<InvalidSaveException>()),
      );
      expect((await repository.getCampaign(original.id))!.events, hasLength(1));
    },
  );

  test(
    'corrupt, newer and conflicting imports leave existing campaigns unchanged',
    () async {
      final original = fixture();
      await repository.saveCampaign(original);
      final invalid = original.toJson();
      invalid['hero'] = {'id': 'bad-hero'};
      for (final source in [
        '{broken',
        jsonEncode(invalid),
        jsonEncode({
          'format': 'living-gm-campaign',
          'schemaVersion': 99,
          'campaign': original.toJson(),
        }),
        await repository.exportCampaign(original.id),
      ]) {
        await expectLater(
          repository.importCampaign(source),
          throwsA(isA<Exception>()),
        );
        expect(
          (await repository.getCampaign(original.id))!.toJson(),
          original.toJson(),
        );
        expect(await repository.loadCampaigns(), hasLength(1));
      }
    },
  );

  test(
    'export/import preserves an incomplete historical character without invented values',
    () async {
      final historical = fixture().copyWith(
        hero: HeroCharacter(
          id: 'arescan',
          name: 'Arescan',
          className: 'Waldläufer',
          unverifiedNotes: const [
            'Historischer Angriffsgesamtwert 19; natürlicher Wurf unbekannt.',
          ],
        ),
      );
      await repository.saveCampaign(historical);
      final exported = await repository.exportCampaign(historical.id);
      await repository.deleteCampaign(historical.id);
      final imported = await repository.importCampaign(exported);
      expect(imported.toJson(), historical.toJson());
      expect(imported.hero.hitPoints, isNull);
      expect(imported.hero.abilities['dexterity'], isNull);
      expect(imported.hero.isComplete, isFalse);
    },
  );

  test(
    'newer database schema is refused without destructive downgrade',
    () async {
      await repository.close();
      final newer = await databaseFactoryFfi.openDatabase(databasePath);
      await newer.setVersion(99);
      await newer.close();
      await expectLater(
        SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: databasePath,
        ),
        throwsA(isA<UnsupportedDatabaseVersion>()),
      );
      final unchanged = await databaseFactoryFfi.openDatabase(databasePath);
      expect(await unchanged.getVersion(), 99);
      await unchanged.setVersion(1);
      await unchanged.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
      );
    },
  );
  test('Kampagnenfortschritt und Heldenarchiv sind atomar gespeichert', () async {
    final initial = fixture().copyWith(
      hero: fixture().hero.copyWith(experience: 0),
    );
    await repository.saveCampaign(initial);
    expect((await repository.loadCharacters()).single.experience, 0);
    final updated = initial.copyWith(
      revision: 1,
      hero: initial.hero.copyWith(experience: 300, gold: 37),
    );
    await repository.saveCampaign(updated, expectedRevision: 0);
    expect((await repository.loadCharacters()).single.experience, 300);
    expect((await repository.loadCharacters()).single.gold, 37);

    final stale = initial.copyWith(
      revision: 1,
      hero: initial.hero.copyWith(experience: 100),
    );
    await expectLater(
      repository.saveCampaign(stale, expectedRevision: 0),
      throwsA(isA<CampaignConflictException>()),
    );
    expect((await repository.loadCharacters()).single.experience, 300);
    expect((await repository.getCampaign(initial.id))!.hero.experience, 300);

    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    expect((await repository.loadCharacters()).single.experience, 300);
  });

  test('Altes getrenntes Heldenarchiv übernimmt neueren Kampagnenstand', () async {
    final campaign = fixture().copyWith(
      hero: fixture().hero.copyWith(experience: 650),
    );
    await repository.saveCampaign(campaign);
    // Simulate a pre-fix archive entry with old XP and an older update time.
    await repository.saveCharacter(campaign.hero.copyWith(experience: 0));
    await repository.close();
    final database = await databaseFactoryFfi.openDatabase(databasePath);
    await database.update(
      'characters',
      {'updated_at': '2020-01-01T00:00:00.000Z'},
      where: 'id = ?',
      whereArgs: [campaign.hero.id],
    );
    await database.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    final merged = (await repository.loadCharacters()).single;
    expect(merged.id, campaign.hero.id);
    expect(merged.experience, 650);

    // Repair is durable, not just a one-time in-memory projection.
    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    expect((await repository.loadCharacters()).single.experience, 650);
  });

  test('Ältere Kampagnen dürfen verdiente EP nicht zurücksetzen', () async {
    final hero = fixture().hero.copyWith(experience: 700);
    await repository.saveCharacter(hero);
    final oldCampaign = fixture(id: 'old-adventure').copyWith(
      hero: hero.copyWith(experience: 0),
    );
    await repository.saveCampaign(oldCampaign);
    expect((await repository.loadCharacters()).single.experience, 700);
    expect((await repository.getCampaign(oldCampaign.id))!.hero.experience, 0);
  });

}
