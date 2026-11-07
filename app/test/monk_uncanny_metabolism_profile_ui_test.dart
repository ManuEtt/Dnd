import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';

class _SequenceRandom implements Random {
  _SequenceRandom(this.naturals);

  final List<int> naturals;
  final List<int> sides = [];
  int get calls => sides.length;

  @override
  int nextInt(int max) {
    final index = calls;
    sides.add(max);
    if (index >= naturals.length) {
      throw StateError(
        'Unerwarteter zusätzlicher Wurf im Stoffwechsel-UI-Test.',
      );
    }
    return (naturals[index] - 1) % max;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

class _SilentVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> speak(String text) async {}
}

class _Fixture {
  _Fixture({
    required this.databasePath,
    required this.repository,
    required this.controller,
    required this.engine,
    required this.random,
  });

  final String databasePath;
  SqliteCampaignRepository repository;
  GameController controller;
  final GameEngine engine;
  final _SequenceRandom random;
  final voice = _SilentVoice();

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
  }

  Future<Map<String, List<Map<String, Object?>>>> tables(
    WidgetTester tester,
  ) async {
    return (await tester.runAsync(() async {
      final db = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        return {
          for (final table in [
            'campaigns',
            'campaign_revisions',
            'game_events',
            'characters',
            'settings',
            'pending_player_actions',
          ])
            table: await db.query(table, orderBy: 'rowid'),
        };
      } finally {
        await db.close();
      }
    }))!;
  }

  Future<void> expectStored(WidgetTester tester, Campaign expected) async {
    final stored = await tester.runAsync(
      () => repository.getCampaign(expected.id),
    );
    expect(stored!.toJson(), expected.toJson());
    final characters = (await tester.runAsync(repository.loadCharacters))!;
    expect(characters.single.toJson(), expected.hero.toJson());
    expect(
      await tester.runAsync(() => repository.pendingActionFor(expected.id)),
      isNull,
    );
  }

  Future<void> restart(WidgetTester tester) async {
    final campaignId = controller.currentCampaign!.id;
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.runAsync(repository.close);
    repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
      ),
    ))!;
    controller = GameController(repository: repository, engine: engine);
    await tester.runAsync(controller.initialize);
    await tester.runAsync(() => controller.openCampaign(campaignId));
    expect(controller.error, isNull);
    await mount(tester);
  }
}

Campaign _campaign(GameEngine engine, {required bool legacy}) {
  final demo = engine.createDemo();
  final hero = demo.hero.copyWith(
    id: '${demo.id}-hero',
    name: 'Mira',
    className: legacy ? 'Historische Klasse' : 'Fighter',
    secondaryClassName: 'Monk',
    secondaryClassLevel: 2,
    level: 4,
    subclass: '',
    secondarySubclass: '',
    hitPoints: 10,
    maxHitPoints: 30,
    temporaryHitPoints: 0,
    abilities: {
      for (final ability in abilityNames)
        ability: ability == 'dexterity' || ability == 'wisdom' ? 16 : 14,
    },
    savingThrowProficiencies: const ['strength'],
    conditions: const [],
    exhaustionLevel: 0,
    inventory: const [],
    equippedArmorId: '',
    equippedShieldId: '',
    equippedWeaponId: '',
    equippedArmorTrained: false,
    equippedShieldTrained: false,
    spentClassResources: const {'focusPoints': 2},
  );
  final plan = AiStoryPlan.fromJson({
    'title': 'Nebelland',
    'world': 'Veyr',
    'opening': 'Ein dunkler Wald wartet.',
    'premise': 'Die Straße ist versperrt.',
    'secret': 'Ein alter Verrat.',
    'goal': 'Finde den Pfad.',
    'threads': [
      {'id': 'weg', 'title': 'Der Weg', 'description': 'Suche den Pfad.'},
      {'id': 'bund', 'title': 'Der Bund', 'description': 'Finde Freunde.'},
    ],
    'npcs': [
      {
        'id': 'mara',
        'name': 'Mara',
        'description': 'Pfadfinderin',
        'relationship': 'neutral',
      },
    ],
    'places': [
      {'id': 'wald', 'name': 'Wald', 'description': 'Nebliger Pfad'},
    ],
  });
  final campaign = engine
      .createAiCampaign(hero, plan, provider: 'mock')
      .copyWith(
        adventureOffer: AdventureOffer.fromJson({
          'id': 'offer',
          'title': 'Die Brücke',
          'description': 'Ein Schatten wartet.',
          'archetype': 'bandit',
          'questTitle': 'Der Weg',
          'questDescription': 'Überwinde die Brücke.',
        }),
      );
  return Campaign.fromJson(campaign.toJson());
}

Future<_Fixture> _start(WidgetTester tester, {required bool legacy}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final directory = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('monk-metabolism-profile-ui-'),
  ))!;
  final databasePath = '${directory.path}/game.sqlite';
  final repository = (await tester.runAsync(
    () => SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    ),
  ))!;
  final random = _SequenceRandom(legacy ? [20, 1] : [20, 1, 4]);
  final engine = GameEngine(
    dice: DiceEngine(random: random),
    clock: () => DateTime.utc(2026, 11, 6),
  );
  final controller = GameController(repository: repository, engine: engine);
  final fixture = _Fixture(
    databasePath: databasePath,
    repository: repository,
    controller: controller,
    engine: engine,
    random: random,
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.controller.dispose();
    fixture.voice.dispose();
    await tester.runAsync(fixture.repository.close);
    await tester.runAsync(() => directory.delete(recursive: true));
  });
  await tester.runAsync(controller.initialize);
  final original = _campaign(engine, legacy: legacy);
  // Import the historical JSON through the actual SQL-backed controller.
  await tester.runAsync(
    () => controller.importCampaign(jsonEncode(original.toJson())),
  );
  expect(controller.error, isNull);
  expect(controller.currentCampaign!.toJson(), original.toJson());
  expect(random.calls, 0);
  await fixture.mount(tester);
  return fixture;
}

Future<void> _tapOfferButton(
  WidgetTester tester,
  _Fixture fixture,
  String key,
) async {
  final storyScroll = find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;
  final position = tester.state<ScrollableState>(storyScroll).position;
  for (
    var attempt = 0;
    attempt < 30 && position.pixels > position.minScrollExtent;
    attempt++
  ) {
    await tester.drag(storyScroll, const Offset(0, 600));
    await tester.pumpAndSettle();
  }
  final button = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(button, 180, scrollable: storyScroll);
  await tester.pumpAndSettle();
  expect(button.hitTestable(), findsOneWidget);
  expect(
    find.descendant(
      of: button,
      matching: find.text(
        key == 'adventure-accept-uncanny-metabolism'
            ? 'Annehmen + Unheimlicher Stoffwechsel'
            : 'Begegnung annehmen',
      ),
    ),
    findsOneWidget,
  );
  final oldRevision = fixture.controller.currentCampaign!.revision;
  await tester.tap(button);
  await tester.pump();
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (!fixture.controller.busy &&
        (fixture.controller.error != null ||
            fixture.controller.currentCampaign!.revision > oldRevision)) {
      break;
    }
  }
  expect(fixture.controller.busy, isFalse);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Stoffwechsel-Schaltfläche weist lesbares Altprofil vor jedem Wurf ab; normale Annahme bleibt möglich',
    (tester) async {
      final fixture = await _start(tester, legacy: true);
      final original = fixture.controller.currentCampaign!;
      final rows = await fixture.tables(tester);
      await _tapOfferButton(
        tester,
        fixture,
        'adventure-accept-uncanny-metabolism',
      );
      final error = fixture.controller.error;
      expect(
        error,
        'Die bestätigten Klassen und Stufen sind nicht konsistent.',
      );
      expect(find.widgetWithText(MaterialBanner, error!), findsOneWidget);
      expect(fixture.random.calls, 0);
      expect(fixture.controller.currentCampaign!.toJson(), original.toJson());
      expect(fixture.controller.currentCampaign!.adventureOffer, isNotNull);
      expect(await fixture.tables(tester), rows);
      await fixture.expectStored(tester, original);

      await _tapOfferButton(tester, fixture, 'adventure-accept');
      expect(fixture.controller.error, isNull);
      final started = fixture.controller.currentCampaign!;
      expect(started.revision, original.revision + 1);
      expect(started.events, hasLength(original.events.length + 1));
      expect(started.events.last.type, 'adventure.accepted');
      expect(started.encounter, isNotNull);
      expect(started.adventureOffer, isNull);
      expect(started.hero.toJson(), original.hero.toJson());
      expect(started.hero.hitPoints, 10);
      expect(started.hero.spentClassResources, {'focusPoints': 2});
      expect(started.events.last.payload['uncannyMetabolismUsed'], isNull);
      expect(fixture.random.sides, [20, 20]);
      await fixture.expectStored(tester, started);
    },
  );

  testWidgets(
    'Stoffwechsel-Schaltfläche bestätigt Heilung und vollen Fokus genau einmal in SQLite und nach Neustart',
    (tester) async {
      final fixture = await _start(tester, legacy: false);
      final original = fixture.controller.currentCampaign!;
      await _tapOfferButton(
        tester,
        fixture,
        'adventure-accept-uncanny-metabolism',
      );
      expect(fixture.controller.error, isNull);
      final started = fixture.controller.currentCampaign!;
      expect(started.revision, original.revision + 1);
      expect(started.events, hasLength(original.events.length + 1));
      expect(started.events.last.type, 'adventure.accepted');
      expect(started.events.last.payload['uncannyMetabolismUsed'], isTrue);
      expect(started.events.last.payload['uncannyMetabolismHealing'], 6);
      expect(started.events.last.payload['uncannyMetabolismDieRoll'], 4);
      expect(started.events.last.payload['focusRecoveredAtInitiative'], 2);
      expect(started.hero.hitPoints, 16);
      expect(started.hero.maxHitPoints, 30);
      expect(started.hero.spentClassResources, {'uncannyMetabolism': 1});
      expect(ClassResourceRules.remaining(started.hero, 'focusPoints'), 2);
      expect(started.hero.toJson(), {
        ...original.hero.toJson(),
        'hitPoints': 16,
        'spentClassResources': {'uncannyMetabolism': 1},
      });
      expect(started.adventureOffer, isNull);
      expect(started.encounter, isNotNull);
      expect(fixture.random.sides, [20, 20, 6]);
      await fixture.expectStored(tester, started);
      final rows = await fixture.tables(tester);
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), started.toJson());
      expect(await fixture.tables(tester), rows);
      await fixture.expectStored(tester, started);
      expect(fixture.random.calls, 3);
      expect(
        find.byKey(const ValueKey('adventure-accept-uncanny-metabolism')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
