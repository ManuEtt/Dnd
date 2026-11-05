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
    () => Directory.systemTemp.createTemp('saving-throw-class-ui-'),
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
    clock: () => DateTime.utc(2026, 11, 2),
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
  if (legacy) {
    // Follow the actual optimistic-revision contract: create the campaign
    // first, then append the historically confirmed failed saving throw.
    await tester.runAsync(
      () => repository.saveCampaign(original, events: original.events),
    );
    original = original.copyWith(revision: 1);
    // Explicit historical confirmation, not a new roll calculated from an
    // unknown class. Opening or retrying this save must never rewrite it.
    final previousSave = GameEvent(
      id: 'historical-confirmed-failed-save',
      campaignId: original.id,
      sessionId: original.sessionId,
      timestamp: DateTime.utc(2026, 11, 1),
      type: 'saving.roll',
      entities: [original.hero.id],
      payload: {
        'ability': 'wisdom',
        'difficulty': 18,
        'total': 8,
        'failed': true,
        'manualDifficulty': true,
        'roll': DiceResult(
          expression: '1d20+7',
          rolls: const [1],
          modifier: 7,
          total: 8,
          natural: 1,
        ).toJson(),
        'revision': original.revision,
        'stateAfter': original.copyWith(events: const []).toJson(),
      },
    );
    original = original.copyWith(events: [...original.events, previousSave]);
  }
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
    'Legacy-Klasse bleibt lesbar; UI-Fokuswiederholung verbraucht keinen W20',
    (tester) async {
      final fixture = await _start(tester, legacy: true);
      final before = fixture.controller.currentCampaign!;
      final previous = before.events.last;
      expect(previous.type, 'saving.roll');
      expect(previous.payload['failed'], isTrue);
      await fixture.expectStored(tester, before);

      final blocked = await _send(
        tester,
        fixture,
        'Rettungswurf wiederholen: Fokus',
      );
      expect(blocked.events.last.type, 'rules.blocked');
      expect(
        blocked.messages.last.text,
        'Die bestätigten Klassen und Stufen sind nicht konsistent.',
      );
      await _readResponse(tester, blocked.messages.last.text);
      expect(blocked.hero.toJson(), before.hero.toJson());
      expect(
        blocked.events[before.events.length - 1].toJson(),
        previous.toJson(),
      );
      expect(blocked.hero.spentClassResources['focusPoints'], 3);
      expect(fixture.random.calls, 0);
      await fixture.expectStored(tester, blocked);

      // Rejection is itself documented. Only the rule-dependent hero/resource
      // change is blocked; the narration/event revision is intentionally saved.
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), blocked.toJson());
      expect(
        fixture.controller.currentCampaign!.hero.className,
        'Hausregelhauptklasse',
      );
      expect(fixture.random.calls, 0);
      await fixture.expectStored(tester, blocked);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Fighter-Alias wiederholt UI-Rettungswurf einmal und speichert bis Neustart',
    (tester) async {
      final fixture = await _start(tester, legacy: false);
      final original = fixture.controller.currentCampaign!;
      final failed = await _send(tester, fixture, 'Rettungswurf: Stärke SG 18');
      expect(failed.events.last.type, 'saving.roll');
      expect(failed.events.last.payload['failed'], isTrue);
      expect(failed.events.last.payload['total'], 7); // 1 + STR2 + PB4.
      expect(failed.hero.toJson(), original.hero.toJson());
      expect(
        failed.messages.last.text,
        contains('Rettungswurf wiederholen: Unbeugsam'),
      );
      expect(fixture.random.calls, 1);

      final rerolled = await _send(
        tester,
        fixture,
        'Rettungswurf wiederholen: Unbeugsam',
      );
      final event = rerolled.events.last;
      expect(event.type, 'saving.rerolled');
      expect(event.payload['previousTotal'], 7);
      expect(event.payload['fighterLevelBonus'], 9);
      expect(event.payload['resource'], 'indomitable');
      expect(event.payload['passed'], isTrue);
      final roll = event.payload['roll'] as Map;
      expect(roll['natural'], 3);
      expect(roll['modifier'], 15); // STR2 + PB4 + Fighter9, once each.
      expect(roll['total'], 18);
      expect(rerolled.hero.spentClassResources, const {'indomitable': 1});
      expect(rerolled.hero.className, 'Fighter');
      expect(rerolled.hero.secondaryClassName, 'Cleric');
      expect(
        rerolled.messages.last.text,
        contains('Wiederholter Rettungswurf: 18 – gelungen.'),
      );
      await _readResponse(tester, rerolled.messages.last.text);
      expect(fixture.random.calls, 2);
      await fixture.expectStored(tester, rerolled);

      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), rerolled.toJson());
      expect(fixture.random.calls, 2);
      final duplicate = await _send(
        tester,
        fixture,
        'Rettungswurf wiederholen: Unbeugsam',
      );
      expect(duplicate.events.last.type, 'rules.blocked');
      expect(duplicate.hero.toJson(), rerolled.hero.toJson());
      expect(
        duplicate.messages.last.text,
        'Es liegt kein unmittelbar vorheriger fehlgeschlagener Rettungswurf vor.',
      );
      expect(fixture.random.calls, 2);
      await fixture.expectStored(tester, duplicate);
      expect(tester.takeException(), isNull);
    },
  );
}
