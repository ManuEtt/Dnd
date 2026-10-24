import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_sending_cast_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sending_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

HeroCharacter _caster() => HeroCharacter(
  id: 'sending-record-caster',
  name: 'Nora',
  className: 'Magier',
  level: 5,
  spells: const ['Sending'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 14,
    'charisma': 12,
  },
  maxHitPoints: 28,
  hitPoints: 28,
);

SrdSendingCastPreview _preview(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  String recipient = 'npc-1',
  String message = 'Bitte antworte.',
  SendingBlockStatus block = SendingBlockStatus.notBlockedConfirmed,
  SendingPlaneRelation plane = SendingPlaneRelation.samePlaneConfirmed,
  int? roll,
}) => SrdSendingCastPreflightRules.preview(
  hero,
  spell: spell,
  castingClass: 'Magier',
  slotLevel: 3,
  recipientId: recipient,
  message: message,
  recipientKnowledge: SendingRecipientKnowledge.personallyMet,
  recipientIsCreatureConfirmed: true,
  blockStatus: block,
  planeRelation: plane,
  percentileRoll: roll,
  actionAvailableConfirmed: true,
  slotTurnLimitConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late SrdSpellDefinition sending;

  setUpAll(() async {
    sending = (await SrdSpellCatalogLoader.load()).find('Sending')!;
  });

  test('domain records one slot without pretending to deliver a message', () {
    final hero = _caster();
    final preview = _preview(
      hero,
      sending,
      block: SendingBlockStatus.blockedConfirmed,
    );
    final before = hero.toJson();
    expect(
      () => SrdSendingCastPreflightRules.confirmAttemptResourceUse(
        hero,
        preview,
        playerConfirmed: false,
      ),
      throwsFormatException,
    );
    final recorded = SrdSendingCastPreflightRules.confirmAttemptResourceUse(
      hero,
      preview,
      playerConfirmed: true,
    );
    expect(recorded.hero.spentSpellSlots, {'3': 1});
    expect(hero.toJson(), before);
    expect(preview.assessment.outcome, SendingDeliveryOutcome.blocked);
    expect(
      () => SrdSendingCastPreflightRules.confirmAttemptResourceUse(
        recorded.hero,
        preview,
        playerConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSendingCastPreflightRules.confirmAttemptResourceUse(
        hero.copyWith(hitPoints: 27),
        preview,
        playerConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  test('game engine rejects reused action IDs without applying resources', () {
    final engine = GameEngine();
    final campaign = engine.createDemo(hero: _caster());
    final preview = _preview(campaign.hero, sending);
    expect(
      () => engine.confirmSendingAttempt(
        campaign,
        preview: preview,
        requestId: 'bad id',
        playerConfirmed: true,
      ),
      throwsFormatException,
    );
    final recorded = engine.confirmSendingAttempt(
      campaign,
      preview: preview,
      requestId: 'sending-1',
      playerConfirmed: true,
    );
    expect(recorded.campaign.hero.spentSpellSlots['3'], 1);
    expect(recorded.events.single.type, 'spell.sending.attemptConfirmed');
    expect(recorded.events.single.payload['deliveryNotPerformed'], true);
    expect(
      () => engine.confirmSendingAttempt(
        recorded.campaign,
        preview: preview,
        requestId: 'sending-1',
        playerConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  group('SQLite/Controller sending receipts', () {
    late Directory directory;
    late String dbPath;
    late SqliteCampaignRepository sqlite;
    late GameController controller;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('sending-cast-');
      dbPath = paths.join(directory.path, 'game.sqlite');
      sqlite = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      controller = GameController(repository: sqlite);
      await controller.initialize();
      await controller.newCampaign(_caster());
      expect(controller.error, isNull);
    });

    tearDown(() async {
      controller.dispose();
      await sqlite.close();
      await directory.delete(recursive: true);
    });

    test('confirmed cast is persisted once; retry and restart are safe', () async {
      final start = controller.currentCampaign!;
      final preview = _preview(start.hero, sending);
      Future<void> cast() => controller.confirmSendingAttempt(
        campaignId: start.id,
        expectedRevision: start.revision,
        preview: preview,
        requestId: 'sending-once',
        playerConfirmed: true,
      );
      await cast();
      expect(controller.error, isNull);
      final saved = (await sqlite.getCampaign(start.id))!;
      expect(saved.hero.spentSpellSlots, {'3': 1});
      expect(saved.events, hasLength(1));
      expect(saved.events.single.payload['message'], 'Bitte antworte.');
      expect(saved.events.single.payload['deliveryNotPerformed'], true);
      expect(
        (await sqlite.reconstructCampaign(start.id, revision: 1))!.toJson(),
        saved.toJson(),
      );
      await cast();
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), saved.toJson());

      controller.dispose();
      await sqlite.close();
      sqlite = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      controller = GameController(repository: sqlite);
      await controller.initialize();
      expect(controller.currentCampaign!.toJson(), saved.toJson());
      await cast();
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), saved.toJson());
      final different = _preview(start.hero, sending, message: 'Anderer Text');
      await controller.confirmSendingAttempt(
        campaignId: start.id,
        expectedRevision: start.revision,
        preview: different,
        requestId: 'sending-once',
        playerConfirmed: true,
      );
      expect(controller.error, contains('anderen Bestätigung'));
      expect((await sqlite.getCampaign(start.id))!.toJson(), saved.toJson());
    });

    test('unconfirmed, stale and invalid requests cannot spend a slot', () async {
      final start = controller.currentCampaign!;
      final preview = _preview(start.hero, sending);
      await controller.confirmSendingAttempt(
        campaignId: start.id,
        expectedRevision: start.revision,
        preview: preview,
        requestId: 'sending-not-approved',
        playerConfirmed: false,
      );
      expect(controller.error, contains('ausdrücklich'));
      expect(controller.currentCampaign!.toJson(), start.toJson());
      await controller.confirmSendingAttempt(
        campaignId: start.id,
        expectedRevision: start.revision + 1,
        preview: preview,
        requestId: 'sending-stale',
        playerConfirmed: true,
      );
      expect(controller.error, contains('inzwischen geändert'));
      await controller.confirmSendingAttempt(
        campaignId: start.id,
        expectedRevision: start.revision,
        preview: preview,
        requestId: 'has spaces',
        playerConfirmed: true,
      );
      expect(controller.error, contains('Ungültige'));
      expect((await sqlite.getCampaign(start.id))!.toJson(), start.toJson());
    });

    test('SQLite journal failure rolls back slot and campaign revision', () async {
      final start = controller.currentCampaign!;
      final preview = _preview(start.hero, sending);
      final db = await databaseFactoryFfi.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await db.execute("""
CREATE TRIGGER reject_sending
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"spell.sending.attemptConfirmed"') > 0
BEGIN
  SELECT RAISE(ABORT, 'test rejected sending');
END
""");
        await controller.confirmSendingAttempt(
          campaignId: start.id,
          expectedRevision: start.revision,
          preview: preview,
          requestId: 'sending-rollback',
          playerConfirmed: true,
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), start.toJson());
        expect((await sqlite.getCampaign(start.id))!.toJson(), start.toJson());
        expect(await sqlite.reconstructCampaign(start.id, revision: 1), isNull);
      } finally {
        await db.close();
      }
    });
  });
}
