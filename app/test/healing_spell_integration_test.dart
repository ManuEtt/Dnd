import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/healing_spell_dialog.dart';

class _Random implements Random {
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return 0;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

class _Voice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
}

const _fight = Encounter(
  id: 'fight',
  enemyName: 'Demo',
  enemyHitPoints: 100,
  enemyMaxHitPoints: 100,
  enemyAttackBonus: 0,
);
Campaign _campaign(GameEngine engine, {Encounter? fight = _fight}) {
  final demo = engine.createDemo();
  return demo.copyWith(
    encounter: fight,
    hero: demo.hero.copyWith(
      className: 'Kleriker',
      level: 5,
      hitPoints: 5,
      maxHitPoints: 40,
      spells: ['Wunden heilen', 'Heilendes Wort'],
      abilities: const {
        'strength': 14,
        'dexterity': 14,
        'constitution': 14,
        'intelligence': 14,
        'wisdom': 16,
        'charisma': 18,
      },
    ),
  );
}

GameUpdate _cast(
  GameEngine engine,
  Campaign before, {
  String spell = 'Wunden heilen',
  bool pact = false,
}) => engine.castHealingSpell(
  before,
  spellName: spell,
  castingClass: 'Kleriker',
  pactMagic: pact,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
);
Future<void> _controllerCast(GameController controller, Campaign before) =>
    controller.castHealingSpell(
      campaignId: before.id,
      expectedRevision: before.revision,
      spellName: 'Wunden heilen',
      castingClass: 'Kleriker',
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
    );

void main() {
  setUpAll(sqfliteFfiInit);
  late _Random random;
  late GameEngine engine;
  setUp(() {
    random = _Random();
    engine = GameEngine(dice: DiceEngine(random: random));
  });

  test('Magic action and bonus action consume independent turn budgets', () {
    final before = _campaign(engine);
    final main = _cast(engine, before);
    expect(main.campaign.hero.hitPoints, 10);
    expect(main.campaign.hero.spentSpellSlots, {'1': 1});
    expect(main.campaign.encounter!.actionUsed, isTrue);
    expect(main.campaign.encounter!.bonusActionUsed, isFalse);
    expect(main.campaign.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(main.events.single.payload['targetId'], before.hero.id);
    expect(main.events.single.payload['healingRoll'], isNotNull);
    expect(main.events.single.payload['hitPointsRestored'], 5);
    expect(main.campaign.encounter!.round, 1); // no involuntary enemy turn
    final bonus = _cast(engine, before, spell: 'Heilendes Wort');
    expect(bonus.campaign.encounter!.actionUsed, isFalse);
    expect(bonus.campaign.encounter!.bonusActionUsed, isTrue);
  });
  test('one slot per turn survives JSON and resets exactly at next turn', () {
    final first = _cast(engine, _campaign(engine)).campaign;
    final restored = Campaign.fromJson(first.toJson());
    final calls = random.calls;
    expect(
      () => _cast(engine, restored, spell: 'Heilendes Wort'),
      throwsFormatException,
    );
    expect(random.calls, calls);
    expect(restored.hero.spentSpellSlots, {'1': 1});
    final next = engine.act(restored, 'Zug beenden').campaign;
    expect(next.encounter!.round, 2);
    expect(next.encounter!.spellSlotExpendedThisTurn, isFalse);
    expect(_cast(engine, next).campaign.hero.spentSpellSlots, {'1': 2});
  });
  test(
    'Pact and normal slots share turn restriction without sharing pools',
    () {
      final base = _campaign(engine);
      final mix = base.copyWith(
        hero: base.hero.copyWith(
          level: 3,
          secondaryClassName: 'Hexenmeister',
          secondaryClassLevel: 2,
        ),
      );
      final pact = _cast(engine, mix, pact: true).campaign;
      expect(pact.hero.spentPactSlots, 1);
      expect(pact.hero.spentSpellSlots, isEmpty);
      expect(
        () => _cast(engine, pact, spell: 'Heilendes Wort'),
        throwsFormatException,
      );
    },
  );
  test(
    'used actions, wrong turn, Rage, pending and Action Surge fail before dice',
    () {
      final before = _campaign(engine);
      final invalid = [
        before.copyWith(encounter: _fight.copyWith(actionUsed: true)),
        before.copyWith(encounter: _fight.copyWith(activeParticipant: 'enemy')),
        before.copyWith(
          encounter: _fight.copyWith(rageStartedRound: 1, rageUntilRound: 2),
        ),
        before.copyWith(
          pendingRoll: const PendingRoll(
            id: 'p',
            type: 'perception',
            modifier: 3,
            difficulty: 10,
          ),
        ),
        before.copyWith(
          encounter: _fight.copyWith(
            surgeUsedThisTurn: true,
            surgeReserved: true,
          ),
        ),
      ];
      random.calls = 0;
      for (final c in invalid) {
        expect(() => _cast(engine, c), throwsFormatException);
      }
      final usedBonus = before.copyWith(
        encounter: _fight.copyWith(bonusActionUsed: true),
      );
      expect(
        () => _cast(engine, usedBonus, spell: 'Heilendes Wort'),
        throwsFormatException,
      );
      expect(random.calls, 0);
      expect(before.hero.spentSpellSlots, isEmpty);
    },
  );
  test(
    'legacy encounters default to no slot spent; wrong JSON type is rejected',
    () {
      final old = _fight.toJson();
      expect(old.containsKey('spellSlotExpendedThisTurn'), isFalse);
      expect(Encounter.fromJson(old).spellSlotExpendedThisTurn, isFalse);
      expect(
        () => Encounter.fromJson({...old, 'spellSlotExpendedThisTurn': 1}),
        throwsFormatException,
      );
    },
  );

  group('real SQLite and controller', () {
    late Directory dir;
    late String path;
    late SqliteCampaignRepository repository;
    late GameController controller;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('healing-spells-');
      path = '${dir.path}/campaign.sqlite';
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(repository: repository, engine: engine);
      await repository.saveCampaign(_campaign(engine));
      final campaign = (await repository.loadCampaigns()).single;
      await controller.openCampaign(campaign.id);
    });
    tearDown(() async {
      controller.dispose();
      await repository.close();
      await dir.delete(recursive: true);
    });
    test(
      'slot, action and event survive restart; repeat cannot spend again',
      () async {
        await _controllerCast(controller, controller.currentCampaign!);
        expect(controller.error, isNull);
        final saved = controller.currentCampaign!;
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        controller.dispose();
        controller = GameController(repository: repository, engine: engine);
        await controller.initialize();
        expect(controller.currentCampaign!.toJson(), saved.toJson());
        await _controllerCast(controller, saved);
        expect(controller.error, contains('bereits einen Zauberplatz'));
        expect(
          (await repository.getCampaign(saved.id))!.toJson(),
          saved.toJson(),
        );
      },
    );
    test(
      'late event failure rolls back slot, HP, turn flag and display',
      () async {
        final before = controller.currentCampaign!;
        final db = await databaseFactoryFfi.openDatabase(path);
        await db.execute(
          '''CREATE TRIGGER reject_healing BEFORE INSERT ON game_events
        BEGIN SELECT RAISE(ABORT, 'test late healing failure'); END''',
        );
        await _controllerCast(controller, before);
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect(
          (await repository.getCampaign(before.id))!.toJson(),
          before.toJson(),
        );
        expect(
          await repository.reconstructCampaign(
            before.id,
            revision: before.revision + 1,
          ),
          isNull,
        );
      },
    );
    test(
      'stale revision cannot apply a second dialog to a newer sheet',
      () async {
        final before = controller.currentCampaign!;
        await controller.saveHero(before.hero.copyWith(hitPoints: 6));
        final newer = controller.currentCampaign!;
        await _controllerCast(controller, before);
        expect(controller.error, contains('erneut öffnen'));
        expect(controller.currentCampaign!.toJson(), newer.toJson());
      },
    );
  });

  testWidgets(
    'adventure button casts a real healing spell and persists its event',
    (tester) async {
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository, engine: engine);
      final voice = _Voice();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        voice.dispose();
        await tester.runAsync(repository.close);
      });
      final campaign = _campaign(engine, fight: null);
      await tester.runAsync(() => repository.saveCampaign(campaign));
      await tester.runAsync(() => controller.openCampaign(campaign.id));
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('adventure-cast-healing-spell'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(HealingSpellDialog), findsOneWidget);
      for (final key in ['verbal', 'somatic', 'confirm']) {
        final control = find.byKey(ValueKey('healing-spell-$key'));
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        await tester.tap(control);
        await tester.pump();
      }
      await tester.runAsync(() async {
        for (var i = 0; i < 200 && controller.busy; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.hero.hitPoints, 10);
      expect(controller.currentCampaign!.hero.spentSpellSlots, {'1': 1});
      expect(controller.currentCampaign!.events.last.type, 'spell.healing');
      final stored = await tester.runAsync(
        () => repository.getCampaign(campaign.id),
      );
      expect(stored!.toJson(), controller.currentCampaign!.toJson());
      expect(tester.takeException(), isNull);
    },
  );
}
