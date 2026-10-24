import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/death_save_decision_panel.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

class _Random implements Random {
  int calls = 0;
  final values = <int>[];
  @override
  int nextInt(int max) {
    calls++;
    return values.isEmpty ? 0 : values.removeAt(0) % max;
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
  id: 'death-fight',
  enemyName: 'Demo',
  enemyHitPoints: 30,
  enemyMaxHitPoints: 30,
);
Campaign down(
  GameEngine engine, {
  String className = 'Mönch',
  int level = 14,
  int failures = 2,
}) {
  final demo = engine.createDemo();
  return demo.copyWith(
    encounter: _fight,
    hero: demo.hero.copyWith(
      className: className,
      level: level,
      hitPoints: 0,
      maxHitPoints: 40,
      deathFailures: failures,
      conditions: ['bewusstlos'],
      savingThrowProficiencies: [],
      concentratingOn: '',
    ),
  );
}

Campaign request(GameEngine engine, Campaign campaign) =>
    engine.act(campaign, 'Todesrettungswurf').campaign;
Campaign provisional(GameEngine engine, Campaign campaign, {int natural = 1}) =>
    engine.resolveRoll(request(engine, campaign), natural: natural).campaign;

void main() {
  setUpAll(sqfliteFfiInit);
  late _Random random;
  late GameEngine engine;
  setUp(() {
    random = _Random();
    engine = GameEngine(dice: DiceEngine(random: random));
  });
  test(
    'new request shows Monk bonus; failed fatal outcome remains unconfirmed',
    () {
      final before = down(engine);
      final asked = request(engine, before);
      expect(asked.pendingRoll!.modifier, 5);
      expect(asked.pendingRoll!.deathSaveRulesVersion, 1);
      final waiting = engine.resolveRoll(asked, natural: 1);
      expect(waiting.events.single.type, 'deathSave.choicePending');
      expect(waiting.campaign.hero.toJson(), before.hero.toJson());
      expect(waiting.campaign.hero.isDead, isFalse);
      expect(waiting.campaign.pendingRoll, isNull);
      expect(waiting.campaign.pendingDeathSave!.originalNatural, 1);
      expect(
        Campaign.fromJson(waiting.campaign.toJson()).pendingDeathSave!.modifier,
        5,
      );
      expect(random.calls, 0);
    },
  );
  test(
    'accept applies original third failure once without resource or dice',
    () {
      final waiting = provisional(engine, down(engine));
      final result = engine.resolveDeathSaveDecision(waiting);
      expect(result.campaign.hero.isDead, isTrue);
      expect(result.campaign.hero.deathFailures, 3);
      expect(result.campaign.hero.spentClassResources, isEmpty);
      expect(result.campaign.pendingDeathSave, isNull);
      expect(result.campaign.encounter!.deathSaveResolvedThisTurn, isTrue);
      expect(
        () => engine.resolveDeathSaveDecision(result.campaign),
        throwsFormatException,
      );
      expect(random.calls, 0);
    },
  );
  test(
    'Focus reroll replaces fatal natural1 with20 and leaves hero able to act',
    () {
      final waiting = provisional(engine, down(engine));
      random.values.add(19);
      final result = engine.resolveDeathSaveDecision(
        waiting,
        feature: SavingThrowRerollFeature.disciplinedSurvivor,
      );
      expect(result.campaign.hero.hitPoints, 1);
      expect(result.campaign.hero.isDead, isFalse);
      expect(result.campaign.hero.deathFailures, 0);
      expect(result.campaign.hero.spentClassResources['focusPoints'], 1);
      expect(result.campaign.encounter!.round, 1);
      expect(result.campaign.encounter!.actionUsed, isFalse);
      expect(result.events.single.payload['originalRoll']['natural'], 1);
      expect(result.events.single.payload['roll']['natural'], 20);
      expect(random.calls, 1);
    },
  );
  test(
    'Fighter level bonus replaces original consequences, not a second roll',
    () {
      final waiting = provisional(
        engine,
        down(engine, className: 'Kämpfer', level: 9),
        natural: 2,
      );
      random.values.add(1);
      final result = engine.resolveDeathSaveDecision(
        waiting,
        feature: SavingThrowRerollFeature.indomitable,
      );
      expect(result.campaign.hero.isDead, isFalse);
      expect(result.campaign.hero.deathFailures, 2);
      expect(result.campaign.hero.deathSuccesses, 1);
      expect(result.events.single.payload['fighterLevelBonus'], 9);
      expect(result.events.single.payload['roll']['total'], 11);
      expect(result.campaign.hero.spentClassResources['indomitable'], 1);
    },
  );
  test(
    'lower natural1 replacement records two failures, not original plus two',
    () {
      final waiting = provisional(
        engine,
        down(engine, failures: 0),
        natural: 2,
      );
      final result = engine.resolveDeathSaveDecision(
        waiting,
        feature: SavingThrowRerollFeature.disciplinedSurvivor,
      );
      expect(result.campaign.hero.deathFailures, 2);
      expect(result.campaign.hero.spentClassResources['focusPoints'], 1);
    },
  );
  test('completed death save blocks another until actual next own turn', () {
    final asked = request(engine, down(engine));
    final resolved = engine
        .resolveRoll(asked, natural: 6)
        .campaign; //6+5 succeeds
    expect(resolved.hero.deathSuccesses, 1);
    expect(resolved.pendingDeathSave, isNull);
    expect(
      engine.act(resolved, 'Todesrettungswurf').events.single.type,
      'rules.blocked',
    );
    final next = engine.endHeroTurn(resolved).campaign; //enemy natural1 misses
    expect(next.encounter!.round, 2);
    expect(next.encounter!.deathSaveResolvedThisTurn, isFalse);
    expect(request(engine, next).pendingRoll!.type, 'death');
  });
  test(
    'legacy zero-bonus death request resolves with current authoritative bonus',
    () {
      final before = down(engine).copyWith(
        pendingRoll: const PendingRoll(
          id: 'legacy',
          type: 'death',
          modifier: 0,
          difficulty: 10,
        ),
      );
      final restored = Campaign.fromJson(before.toJson());
      final result = engine.resolveRoll(restored, natural: 6);
      expect(result.campaign.hero.deathSuccesses, 1);
      expect(result.events.single.payload['roll']['modifier'], 5);
    },
  );
  test('forged request and pending choice fields fail closed on import', () {
    final asked = request(engine, down(engine));
    expect(
      () => Campaign.fromJson({
        ...asked.toJson(),
        'pendingRoll': {...asked.pendingRoll!.toJson(), 'modifier': 6},
      }),
      throwsFormatException,
    );
    final waiting = engine.resolveRoll(asked, natural: 1).campaign;
    for (final forged in [
      {'originalNatural': 20, 'modifier': 5},
      {'originalNatural': 10, 'modifier': 5},
      {'originalNatural': 1, 'modifier': 6},
    ]) {
      expect(
        () => Campaign.fromJson({
          ...waiting.toJson(),
          'pendingDeathSave': forged,
        }),
        throwsFormatException,
      );
    }
    expect(
      () => Campaign.fromJson({
        ...waiting.toJson(),
        'pendingRoll': asked.pendingRoll!.toJson(),
      }),
      throwsFormatException,
    );
    expect(
      () => Campaign.fromJson({
        ...waiting.toJson(),
        'hero': waiting.hero
            .copyWith(spentClassResources: {'focusPoints': 14})
            .toJson(),
      }),
      throwsFormatException,
    );
    expect(
      () => Encounter.fromJson({
        ..._fight.toJson(),
        'deathSaveResolvedThisTurn': 1,
      }),
      throwsFormatException,
    );
  });
  test(
    'unavailable class choice, unrelated actions and end-turn cannot bypass decision',
    () {
      final waiting = provisional(engine, down(engine));
      expect(
        () => engine.resolveDeathSaveDecision(
          waiting,
          feature: SavingThrowRerollFeature.indomitable,
        ),
        throwsFormatException,
      );
      expect(
        engine.act(waiting, 'Ich greife an').events.single.type,
        'rules.blocked',
      );
      expect(() => engine.endHeroTurn(waiting), throwsFormatException);
      expect(
        () => engine.applyHealing(waiting, source: 'fremd', amount: 1),
        throwsFormatException,
      );
      expect(waiting.hero.spentClassResources, isEmpty);
      expect(random.calls, 0);
    },
  );
  test(
    'no-feature failures finalize directly and text choice cannot fabricate a roll',
    () {
      final result = engine.resolveRoll(
        request(
          engine,
          down(engine, className: 'Kämpfer', level: 1, failures: 0),
        ),
        natural: 2,
      );
      expect(result.campaign.pendingDeathSave, isNull);
      expect(result.campaign.hero.deathFailures, 1);
      expect(
        engine.act(result.campaign, 'Todesrettung annehmen').events.single.type,
        'rules.blocked',
      );
    },
  );
  test(
    'explicit text decision matches typed acceptance; sheet edit clears stale choice',
    () {
      final waiting = provisional(engine, down(engine));
      expect(
        engine.act(waiting, 'Todesrettung annehmen').campaign.hero.isDead,
        isTrue,
      );
      final edited = engine
          .updateHero(waiting, waiting.hero.copyWith(name: 'Mira'))
          .campaign;
      expect(edited.pendingDeathSave, isNull);
      expect(
        () => engine.resolveDeathSaveDecision(edited),
        throwsFormatException,
      );
    },
  );

  test('opponent turn cannot create a death request or consume dice', () {
    final before = down(
      engine,
    ).copyWith(encounter: _fight.copyWith(activeParticipant: 'enemy'));
    final blocked = engine.act(before, 'Todesrettungswurf');
    expect(blocked.events.single.type, 'rules.blocked');
    expect(blocked.campaign.pendingRoll, isNull);
    expect(blocked.campaign.pendingDeathSave, isNull);
    expect(random.calls, 0);
  });
  test(
    'provisional and accepted death events replay to exactly confirmed state',
    () {
      final before = down(engine);
      final waiting = provisional(engine, before);
      final accepted = engine.resolveDeathSaveDecision(waiting).campaign;
      expect(
        MemoryEngine.replay(before, accepted.events).toJson(),
        accepted.toJson(),
      );
    },
  );

  group('saved decision and atomic controller', () {
    late Directory dir;
    late String path;
    late SqliteCampaignRepository repo;
    late GameController controller;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('death-save-flow-');
      path = '${dir.path}/game.sqlite';
      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final initial = down(engine);
      await repo.saveCampaign(initial);
      controller = GameController(repository: repo, engine: engine);
      await controller.openCampaign(initial.id);
      await controller.sendAction('Todesrettungswurf');
      await controller.resolveRoll(natural: 1);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.pendingDeathSave, isNotNull);
    });
    tearDown(() async {
      controller.dispose();
      await repo.close();
      await dir.delete(recursive: true);
    });
    Future<void> choose(Campaign c) => controller.resolveDeathSaveDecision(
      campaignId: c.id,
      expectedRevision: c.revision,
      feature: SavingThrowRerollFeature.disciplinedSurvivor,
    );
    test(
      'pending choice survives restart and consumes one focus only on selected retry',
      () async {
        final saved = controller.currentCampaign!;
        controller.dispose();
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        controller = GameController(repository: repo, engine: engine);
        await controller.initialize();
        expect(controller.currentCampaign!.toJson(), saved.toJson());
        random.values.add(19);
        await choose(saved);
        expect(controller.error, isNull);
        final accepted = controller.currentCampaign!;
        expect(accepted.hero.hitPoints, 1);
        expect((await repo.getCampaign(saved.id))!.toJson(), accepted.toJson());
        await choose(saved);
        expect(controller.error, isNotNull);
        expect(
          controller.currentCampaign!.hero.spentClassResources['focusPoints'],
          1,
        );
      },
    );
    test(
      'late event failure preserves pre-save hero, pending choice and resource',
      () async {
        final before = controller.currentCampaign!;
        final db = await databaseFactoryFfi.openDatabase(path);
        await db.execute(
          "CREATE TRIGGER reject_death BEFORE INSERT ON game_events BEGIN SELECT RAISE(ABORT, 'late failure'); END",
        );
        random.values.add(19);
        await choose(before);
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect((await repo.getCampaign(before.id))!.toJson(), before.toJson());
        expect(
          await repo.reconstructCampaign(
            before.id,
            revision: before.revision + 1,
          ),
          isNull,
        );
      },
    );
    test(
      'stale UI revision cannot resolve a newer persisted decision state',
      () async {
        final before = controller.currentCampaign!;
        await controller.saveSessionRecap();
        final newer = controller.currentCampaign!;
        await choose(before);
        expect(controller.error, contains('erneut öffnen'));
        expect(controller.currentCampaign!.toJson(), newer.toJson());
        expect(random.calls, 0);
      },
    );
  });
  testWidgets('real adventure UI accepts persisted provisional fatal save', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repo, engine: engine);
    final voice = _Voice();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repo.close);
    });
    final initial = down(engine);
    await tester.runAsync(() => repo.saveCampaign(initial));
    await tester.runAsync(() => controller.openCampaign(initial.id));
    await tester.runAsync(() => controller.sendAction('Todesrettungswurf'));
    await tester.runAsync(() => controller.resolveRoll(natural: 1));
    final before = controller.currentCampaign!;
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
    final accept = find.byKey(const ValueKey('death-save-accept'));
    await tester.ensureVisible(accept);
    await tester.pumpAndSettle();
    expect(accept.hitTestable(), findsOneWidget);
    await tester.tap(accept);
    await tester.pump();
    await tester.runAsync(() async {
      for (var i = 0; i < 200 && controller.busy; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(controller.error, isNull);
    expect(controller.currentCampaign!.hero.isDead, isTrue);
    expect(controller.currentCampaign!.pendingDeathSave, isNull);
    final saved = await tester.runAsync(() => repo.getCampaign(before.id));
    expect(saved!.toJson(), controller.currentCampaign!.toJson());
    expect(tester.takeException(), isNull);
  });
  testWidgets('narrow scaled choice panel offers focus without changing hero', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final hero = down(engine).hero;
    final original = hero.toJson();
    var accepted = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
            child: SingleChildScrollView(
              child: DeathSaveDecisionPanel(
                hero: hero,
                pending: const PendingDeathSave(
                  originalNatural: 1,
                  modifier: 5,
                ),
                busy: false,
                onAccept: () => accepted++,
                onReroll: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('death-save-reroll-focus')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('death-save-reroll-focus')),
          )
          .style,
      FantasyButtonStyle.arcane,
    );
    expect(
      find.byKey(const ValueKey('death-save-reroll-indomitable')),
      findsNothing,
    );
    expect(hero.toJson(), original);
    expect(accepted, 0);
    expect(tester.takeException(), isNull);
  });
}
