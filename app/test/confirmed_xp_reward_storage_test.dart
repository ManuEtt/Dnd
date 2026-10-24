import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

/// A controlled lost HTTP-like acknowledgement after a REAL SQLite commit.
class _LostAckRepository implements CampaignRepository {
  _LostAckRepository(this.db);
  final CampaignRepository db;
  bool loseResponse = false;
  Completer<void>? saveEntered;
  Completer<void>? saveBarrier;

  @override
  Future<void> saveCampaign(
    Campaign campaign, {
    List<GameEvent> events = const [],
    int? expectedRevision,
  }) async {
    if (saveEntered != null && !saveEntered!.isCompleted) {
      saveEntered!.complete();
    }
    await saveBarrier?.future;
    await db.saveCampaign(campaign, events: events, expectedRevision: expectedRevision);
    if (loseResponse) {
      loseResponse = false;
      throw const InvalidSaveException('Bestätigung verloren');
    }
  }

  @override
  Future<List<Campaign>> loadCampaigns() => db.loadCampaigns();
  @override
  Future<Campaign?> getCampaign(String id) => db.getCampaign(id);
  @override
  Future<void> deleteCampaign(String id) => db.deleteCampaign(id);
  @override
  Future<List<HeroCharacter>> loadCharacters() => db.loadCharacters();
  @override
  Future<void> saveCharacter(HeroCharacter hero) => db.saveCharacter(hero);
  @override
  Future<void> deleteCharacter(String id) => db.deleteCharacter(id);
  @override
  Future<Map<String, dynamic>> loadSettings() => db.loadSettings();
  @override
  Future<void> saveSettings(Map<String, dynamic> settings) => db.saveSettings(settings);
  @override
  Future<String> exportCampaign(String id) => db.exportCampaign(id);
  @override
  Future<Campaign> importCampaign(String source) => db.importCampaign(source);
  @override
  Future<Campaign?> reconstructCampaign(String id, {int? revision}) =>
      db.reconstructCampaign(id, revision: revision);
  @override
  Future<void> close() => db.close();
}

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String path;
  late SqliteCampaignRepository sqlite;
  late _LostAckRepository repository;
  late GameController controller;
  var disposed = false;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('xp-receipts-');
    path = paths.join(directory.path, 'state.sqlite');
    sqlite = await SqliteCampaignRepository.open(factory: databaseFactoryFfi, path: path);
    repository = _LostAckRepository(sqlite);
    controller = GameController(repository: repository);
    await controller.initialize();
    await controller.createDemo();
    disposed = false;
    expect(controller.error, isNull);
  });
  tearDown(() async {
    if (!disposed) controller.dispose();
    await sqlite.close();
    await directory.delete(recursive: true);
  });

  test('nur ausdrückliche Bestätigung, valide IDs und positive XP', () async {
    final initial = controller.currentCampaign!;
    Future<void> attempt({bool approved = true, int amount = 300, String id = 'xp-001'}) =>
        controller.confirmExperienceReward(
          campaignId: initial.id, expectedRevision: initial.revision,
          rewardId: 'quest-001', amount: amount, requestId: id,
          playerConfirmed: approved,
        );
    await attempt(approved: false);
    expect(controller.error, contains('bestätigt'));
    await attempt(amount: 0);
    expect(controller.error, contains('Ungültige'));
    await attempt(id: 'unzulässige id');
    expect(controller.error, contains('Ungültige'));
    expect(controller.currentCampaign!.toJson(), initial.toJson());
    expect((await sqlite.getCampaign(initial.id))!.toJson(), initial.toJson());
    expect(await sqlite.reconstructCampaign(initial.id, revision: 1), isNull);
  });

  test('ACK-Verlust und Neustart quittieren dieselbe XP-Belohnung nur einmal', () async {
    final initial = controller.currentCampaign!;
    Future<void> award({
      String id = 'xp-001',
      String rewardId = 'quest-001',
      int amount = 300,
      int? revision,
    }) => controller.confirmExperienceReward(
      campaignId: initial.id, expectedRevision: revision ?? initial.revision,
      rewardId: rewardId, amount: amount, requestId: id, playerConfirmed: true,
    );
    repository.loseResponse = true;
    await award();
    expect(controller.error, contains('Bestätigung verloren'));
    expect(controller.currentCampaign!.toJson(), initial.toJson());

    final persisted = (await sqlite.getCampaign(initial.id))!;
    expect(persisted.revision, 1);
    expect(persisted.hero.experience, 300);
    expect(persisted.facts['xp.reward.quest-001'], '300');
    expect(persisted.events, hasLength(1));
    expect(persisted.events.last.type, 'xp.reward.confirmed');
    expect(persisted.events.last.payload['actionRequestId'], 'xp-001');
    expect((await sqlite.loadCharacters()).single.experience, 300);
    expect(
      (await sqlite.reconstructCampaign(initial.id, revision: 1))!.toJson(),
      persisted.toJson(),
    );

    await award();
    expect(controller.error, isNull);
    expect(controller.currentCampaign!.toJson(), persisted.toJson());
    await award(amount: 301);
    expect(controller.error, contains('anderen Bestätigung'));
    await award(id: 'xp-002');
    expect(controller.error, contains('bereits bestätigt'));
    await controller.sendAction('Ich gehe zur Quelle', requestId: 'xp-001');
    expect(controller.error, contains('anderen Text'));
    expect((await sqlite.getCampaign(initial.id))!.toJson(), persisted.toJson());

    controller.dispose();
    disposed = true;
    await sqlite.close();
    sqlite = await SqliteCampaignRepository.open(factory: databaseFactoryFfi, path: path);
    repository = _LostAckRepository(sqlite);
    controller = GameController(repository: repository);
    disposed = false;
    await controller.initialize();
    expect(controller.currentCampaign!.toJson(), persisted.toJson());
    await award();
    expect(controller.error, isNull);
    await award(id: 'xp-003', rewardId: 'quest-003', revision: 0);
    expect(controller.error, contains('inzwischen geändert'));
    expect((await sqlite.getCampaign(initial.id))!.toJson(), persisted.toJson());
  });

  test('zwei Controller quittieren gleiche ID trotz parallelem SQLite-Commit', () async {
    final initial = controller.currentCampaign!;
    final second = GameController(repository: sqlite);
    try {
      await second.initialize();
      expect(second.currentCampaign!.id, initial.id);
      repository.saveEntered = Completer<void>();
      repository.saveBarrier = Completer<void>();
      final firstAttempt = controller.confirmExperienceReward(
        campaignId: initial.id, expectedRevision: initial.revision,
        rewardId: 'quest-parallel', amount: 300,
        requestId: 'xp-parallel-001', playerConfirmed: true,
      );
      await repository.saveEntered!.future.timeout(const Duration(seconds: 5));
      // Another controller commits the exact same request while the first
      // one has not reached its SQLite revision check.
      await second.confirmExperienceReward(
        campaignId: initial.id, expectedRevision: initial.revision,
        rewardId: 'quest-parallel', amount: 300,
        requestId: 'xp-parallel-001', playerConfirmed: true,
      );
      expect(second.error, isNull);
      final confirmed = second.currentCampaign!;
      repository.saveBarrier!.complete();
      await firstAttempt;
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(confirmed.hero.experience, 300);
      expect(
        confirmed.events.where(
          (event) => event.payload['actionRequestId'] == 'xp-parallel-001',
        ),
        hasLength(1),
      );
      expect((await sqlite.getCampaign(initial.id))!.toJson(), confirmed.toJson());
    } finally {
      if (repository.saveBarrier != null &&
          !repository.saveBarrier!.isCompleted) {
        repository.saveBarrier!.complete();
      }
      second.dispose();
    }
  });

  test('SQL-Fehler rollt XP, Journal, Revision und Heldenarchiv zurück', () async {
    final initial = controller.currentCampaign!;
    final db = await databaseFactoryFfi.openDatabase(
      path, options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      await db.execute('''
CREATE TRIGGER reject_xp
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"xp.reward.confirmed"') > 0
BEGIN
  SELECT RAISE(ABORT, 'test refused xp');
END
''');
      await controller.confirmExperienceReward(
        campaignId: initial.id, expectedRevision: initial.revision,
        rewardId: 'quest-rollback', amount: 300,
        requestId: 'xp-rollback', playerConfirmed: true,
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), initial.toJson());
      expect((await sqlite.getCampaign(initial.id))!.toJson(), initial.toJson());
      expect(await sqlite.reconstructCampaign(initial.id, revision: 1), isNull);
      expect(
        (await sqlite.loadCharacters()).single.experience,
        initial.hero.experience,
      );
    } finally {
      await db.close();
    }
  });

  test('Regelengine verweigert unbestätigte und doppelte XP', () {
    final engine = GameEngine();
    final initial = engine.createDemo();
    expect(
      () => engine.confirmExperienceReward(
        initial, rewardId: 'quest-001', amount: 300,
        requestId: 'xp-001', playerConfirmed: false,
      ), throwsFormatException,
    );
    final first = engine.confirmExperienceReward(
      initial, rewardId: 'quest-001', amount: 300,
      requestId: 'xp-001', playerConfirmed: true,
    );
    expect(first.campaign.hero.experience, 300);
    expect(first.campaign.hero.level, initial.hero.level);
    expect(
      () => engine.confirmExperienceReward(
        first.campaign, rewardId: 'quest-001', amount: 300,
        requestId: 'xp-002', playerConfirmed: true,
      ), throwsFormatException,
    );
  });
}
