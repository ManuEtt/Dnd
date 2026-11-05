import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';

class _SequenceRandom implements Random {
  _SequenceRandom(this.naturals);

  final List<int> naturals;
  int calls = 0;

  @override
  int nextInt(int max) {
    final index = calls++;
    if (index >= naturals.length) {
      throw StateError('Unerwarteter zusätzlicher Würfelwurf im UI-Test.');
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
    required this.directory,
    required this.databasePath,
    required this.repository,
    required this.controller,
    required this.engine,
    required this.random,
  });

  final Directory directory;
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

Future<_Fixture> _start(WidgetTester tester, {required bool legacy}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final directory = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('manual-saving-throw-ui-'),
  ))!;
  final databasePath = paths.join(directory.path, 'game.sqlite');
  final repository = (await tester.runAsync(
    () => SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    ),
  ))!;
  final random = _SequenceRandom(legacy ? [3] : [1, 3]);
  final engine = GameEngine(
    dice: DiceEngine(random: random),
    clock: () => DateTime.utc(2026, 11, 5),
  );
  final demo = engine.createDemo();
  var original = demo.copyWith(
    hero: demo.hero.copyWith(
      className: legacy ? 'Hausregelhauptklasse' : 'Fighter',
      secondaryClassName: legacy ? 'Monk' : 'Cleric',
      secondaryClassLevel: legacy ? 14 : 1,
      level: legacy ? 15 : 10,
      hitPoints: 80,
      maxHitPoints: 80,
      temporaryHitPoints: 0,
      abilities: {for (final ability in abilityNames) ability: 14},
      savingThrowProficiencies: const ['strength'],
      spentClassResources: legacy ? const {'focusPoints': 3} : const {},
    ),
    revision: 0,
  );
  original = Campaign.fromJson(original.toJson());
  await tester.runAsync(
    () => repository.saveCampaign(original, events: original.events),
  );
  final controller = GameController(repository: repository, engine: engine);
  final fixture = _Fixture(
    directory: directory,
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
  await tester.runAsync(() => controller.openCampaign(original.id));
  expect(controller.error, isNull);
  expect(controller.currentCampaign!.toJson(), original.toJson());
  expect(random.calls, 0);
  await fixture.mount(tester);
  return fixture;
}

Future<Campaign> _send(
  WidgetTester tester,
  _Fixture fixture,
  String text,
) async {
  final before = fixture.controller.currentCampaign!;
  final input = find.widgetWithText(TextField, 'Was möchtest du tun?');
  await tester.enterText(input, text);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final send = find.byTooltip('Handlung senden');
  expect(send.hitTestable(), findsOneWidget);
  await tester.tap(send);
  await tester.pump();
  // Real SQLite outbox staging begins before controller.busy is set. Wait
  // for the committed revision and the completed actual UI dispatch.
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (fixture.controller.currentCampaign!.revision > before.revision &&
        !fixture.controller.busy &&
        find
            .byKey(const ValueKey('adventure-action-submitting'))
            .evaluate()
            .isEmpty) {
      break;
    }
  }
  expect(fixture.controller.busy, isFalse);
  expect(fixture.controller.error, isNull);
  await tester.pumpAndSettle();
  expect(
    find.byKey(const ValueKey('adventure-action-submitting')),
    findsNothing,
  );
  final after = fixture.controller.currentCampaign!;
  expect(
    await tester.runAsync(() => fixture.repository.pendingActionFor(after.id)),
    isNull,
    reason: 'Die bestätigte Handlung muss vollständig quittiert sein.',
  );
  expect(after.revision, before.revision + 1);
  expect(after.events, hasLength(before.events.length + 1));
  expect(
    after.messages.any(
      (message) => message.role == 'player' && message.text == text,
    ),
    isTrue,
  );
  expect(find.byKey(const ValueKey('adventure-retry-action')), findsNothing);
  expect(tester.takeException(), isNull);
  return after;
}

Future<void> _readResponse(WidgetTester tester, String text) async {
  final storyScroll = find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;
  final position = tester.state<ScrollableState>(storyScroll).position;
  // The existing automatic story scroll can retain an older lazy-list extent
  // after the composer/layout changes. Use actual backward gestures to bring
  // that viewport into its settled bounds before scrolling to the response.
  for (var attempt = 0; attempt < 30 && position.outOfRange; attempt++) {
    await tester.drag(
      storyScroll,
      Offset(0, position.pixels > position.maxScrollExtent ? 300 : -300),
    );
    await tester.pumpAndSettle();
  }
  expect(position.outOfRange, isFalse);
  await tester.scrollUntilVisible(
    find.text(text),
    180,
    scrollable: storyScroll,
  );
  await tester.pumpAndSettle();
  expect(find.text(text), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Initiale UI-Rettung blockiert Altprofil; bestätigte Korrektur erlaubt neuen W20',
    (tester) async {
      final fixture = await _start(tester, legacy: true);
      final original = fixture.controller.currentCampaign!;
      final blocked = await _send(
        tester,
        fixture,
        'Rettungswurf: Weisheit SG 10',
      );
      expect(blocked.events.last.type, 'rules.blocked');
      expect(
        blocked.messages.last.text,
        'Die bestätigten Klassen und Stufen sind nicht konsistent.',
      );
      expect(blocked.hero.toJson(), original.hero.toJson());
      expect(fixture.random.calls, 0);
      await _readResponse(tester, blocked.messages.last.text);
      await fixture.expectStored(tester, blocked);
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), blocked.toJson());
      expect(fixture.random.calls, 0);

      // An explicit existing controller save changes the class, never the old
      // rejection event or silently recomputed training/resources.
      await tester.runAsync(
        () => fixture.controller.saveHero(
          blocked.hero.copyWith(className: 'Wizard'),
        ),
      );
      expect(fixture.controller.error, isNull);
      await tester.pumpAndSettle();
      final corrected = fixture.controller.currentCampaign!;
      expect(corrected.hero.className, 'Wizard');
      expect(corrected.hero.secondaryClassName, 'Monk');
      expect(
        corrected.hero.spentClassResources,
        blocked.hero.spentClassResources,
      );
      final rolled = await _send(
        tester,
        fixture,
        'Rettungswurf: Weisheit SG 10',
      );
      expect(rolled.events.last.type, 'saving.roll');
      final roll = rolled.events.last.payload['roll'] as Map;
      expect(roll['natural'], 3);
      expect(roll['modifier'], 7); // +2 Wisdom +5 Monk proficiency, once.
      expect(roll['total'], 10);
      expect(rolled.events.last.payload['failed'], isFalse);
      expect(rolled.hero.toJson(), corrected.hero.toJson());
      expect(fixture.random.calls, 1);
      expect(
        rolled.events
            .take(blocked.events.length)
            .map((event) => event.toJson())
            .toList(),
        blocked.events.map((event) => event.toJson()).toList(),
      );
      await _readResponse(tester, rolled.messages.last.text);
      await fixture.expectStored(tester, rolled);
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), rolled.toJson());
      expect(fixture.random.calls, 1);
    },
  );

  testWidgets(
    'Gültiger Fighter-Cleric-Alias würfelt und speichert die bestätigte Rettung',
    (tester) async {
      final fixture = await _start(tester, legacy: false);
      final original = fixture.controller.currentCampaign!;
      final result = await _send(tester, fixture, 'Rettungswurf: Stärke SG 18');
      expect(result.events.last.type, 'saving.roll');
      expect(result.events.last.payload['total'], 7);
      final roll = result.events.last.payload['roll'] as Map;
      expect(roll['natural'], 1);
      expect(roll['modifier'], 6);
      expect(result.hero.toJson(), original.hero.toJson());
      expect(fixture.random.calls, 1);
      await _readResponse(tester, result.messages.last.text);
      await fixture.expectStored(tester, result);
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), result.toJson());
      expect(fixture.random.calls, 1);
    },
  );
}
