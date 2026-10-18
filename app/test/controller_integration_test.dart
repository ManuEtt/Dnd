import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'support/legacy_campaign_fixture.dart';

/// Injects a real storage failure at the persistence boundary, while reads still
/// use SQLite. This tests UI state against confirmed data, not a mirrored mock.
class ControlledRepository implements CampaignRepository {
  ControlledRepository(this.delegate);
  final CampaignRepository delegate;
  bool failNextSave = false;
  Completer<void>? saveBarrier;

  @override
  Future<void> saveCampaign(
    Campaign campaign, {
    List<GameEvent> events = const [],
    int? expectedRevision,
  }) async {
    await saveBarrier?.future;
    if (failNextSave) {
      failNextSave = false;
      throw const InvalidSaveException('Test: Speicherung abgelehnt.');
    }
    await delegate.saveCampaign(
      campaign,
      events: events,
      expectedRevision: expectedRevision,
    );
  }

  @override
  Future<List<Campaign>> loadCampaigns() => delegate.loadCampaigns();
  @override
  Future<Campaign?> getCampaign(String id) => delegate.getCampaign(id);
  @override
  Future<void> deleteCampaign(String id) => delegate.deleteCampaign(id);
  @override
  Future<List<HeroCharacter>> loadCharacters() => delegate.loadCharacters();
  @override
  Future<void> saveCharacter(HeroCharacter character) =>
      delegate.saveCharacter(character);
  @override
  Future<void> deleteCharacter(String id) => delegate.deleteCharacter(id);
  @override
  Future<Map<String, dynamic>> loadSettings() => delegate.loadSettings();
  @override
  Future<void> saveSettings(Map<String, dynamic> settings) =>
      delegate.saveSettings(settings);
  @override
  Future<String> exportCampaign(String id) => delegate.exportCampaign(id);
  @override
  Future<Campaign> importCampaign(String source) =>
      delegate.importCampaign(source);
  @override
  Future<Campaign?> reconstructCampaign(String id, {int? revision}) =>
      delegate.reconstructCampaign(id, revision: revision);
  @override
  Future<void> close() => delegate.close();
}

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository sqlite;
  late ControlledRepository repository;
  late GameController controller;
  var controllerDisposed = false;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('living-gm-controller-');
    databasePath = paths.join(directory.path, 'campaign.sqlite');
    sqlite = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    repository = ControlledRepository(sqlite);
    controller = GameController(repository: repository);
    controllerDisposed = false;
    await controller.initialize();
  });
  tearDown(() async {
    if (!controllerDisposed) controller.dispose();
    await sqlite.close();
    await directory.delete(recursive: true);
  });

  test(
    'rejected save leaves displayed and durable game state unchanged',
    () async {
      await controller.createDemo();
      final confirmed = controller.currentCampaign!;
      repository.failNextSave = true;
      await controller.sendAction('Ich untersuche den Brunnen');
      expect(controller.error, contains('Speicherung abgelehnt'));
      expect(controller.busy, false);
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(
        (await sqlite.getCampaign(confirmed.id))!.toJson(),
        confirmed.toJson(),
      );
      expect(
        await sqlite.reconstructCampaign(confirmed.id, revision: 1),
        isNull,
      );

      await controller.sendAction('Ich untersuche den Brunnen');
      expect(controller.error, isNull);
      expect(
        controller.currentCampaign!.hero.inventory.where(
          (e) => e.id == 'brass-key',
        ),
        hasLength(1),
      );
      expect(controller.currentCampaign!.revision, 1);
    },
  );

  test(
    'last campaign, inventory and memory restore after repository restart',
    () async {
      await controller.createDemo();
      await controller.sendAction('Ich untersuche den Brunnen');
      final confirmed = controller.currentCampaign!;
      controller.dispose();
      await sqlite.close();
      sqlite = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
      );
      repository = ControlledRepository(sqlite);
      controller = GameController(repository: repository);
      await controller.initialize();
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(controller.currentCampaign!.facts['keyFound'], 'true');
      expect(
        controller.currentCampaign!.hero.inventory.where(
          (e) => e.id == 'brass-key',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'stale UI cannot overwrite a newer SQLite revision and can reload',
    () async {
      await controller.createDemo();
      final original = controller.currentCampaign!;
      await sqlite.saveCampaign(
        original.copyWith(
          revision: 1,
          scene: 'Von einem neueren Schreiber bestätigte Szene',
        ),
      );
      await controller.sendAction('Ich untersuche den Brunnen');
      expect(controller.error, contains('inzwischen geändert'));
      expect(controller.currentCampaign!.revision, 0);
      expect((await sqlite.getCampaign(original.id))!.revision, 1);
      await controller.openCampaign(original.id);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.revision, 1);
      await controller.sendAction('Ich untersuche den Brunnen');
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.revision, 2);
    },
  );

  test(
    'historical Arescan loads with unknown stats and blocks combat',
    () async {
      await importLegacyArescan(controller);
      expect(controller.error, isNull);
      final history = controller.currentCampaign!;
      expect(
        history.hero.abilities.values.every((value) => value == null),
        true,
      );
      expect(history.hero.hitPoints, isNull);
      expect(history.events.single.payload['attackTotal'], 19);
      expect(history.events.single.payload['narratedDamage'], 14);
      await controller.sendAction('Ich greife den Schattenritter an');
      final current = controller.currentCampaign!;
      expect(controller.error, isNull);
      expect(current.pendingRoll, isNull);
      expect(current.hero.hitPoints, isNull);
      expect(current.hero.abilities['dexterity'], isNull);
      expect(current.events.last.type, 'rules.blocked');
      expect(
        (await sqlite.getCampaign(current.id))!.toJson(),
        current.toJson(),
      );
    },
  );

  test(
    'editing stats cancels a pending roll with cached old modifiers',
    () async {
      await controller.createDemo();
      await controller.sendAction('Ich untersuche meine Umgebung');
      final before = controller.currentCampaign!;
      expect(before.pendingRoll, isNotNull);
      await controller.saveHero(
        before.hero.copyWith(
          abilities: {...before.hero.abilities, 'wisdom': 20},
        ),
      );
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.pendingRoll, isNull);
      expect(controller.currentCampaign!.hero.abilities['wisdom'], 20);
    },
  );

  test(
    'finishing an in-flight commit after disposal does not notify disposed UI',
    () async {
      await controller.createDemo();
      repository.saveBarrier = Completer<void>();
      final pending = controller.sendAction('Ich untersuche den Brunnen');
      await Future<void>.delayed(Duration.zero);
      expect(controller.busy, true);
      controller.dispose();
      controllerDisposed = true;
      repository.saveBarrier!.complete();
      await pending;
      expect(controller.error, isNull);
      final stored = (await sqlite.loadCampaigns()).single;
      expect(stored.revision, 1);
      expect(stored.facts['keyFound'], 'true');
    },
  );
}
