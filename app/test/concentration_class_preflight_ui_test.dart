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
import 'package:lebendiger_spielleiter/ui/character_effect_dialog.dart';

class _CountingRandom implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return max - 1;
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
  final _CountingRandom random;
  final voice = _SilentVoice();

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
  }

  Future<void> restart(WidgetTester tester) async {
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
    expect(controller.error, isNull);
    await mount(tester);
  }

  Future<Map<String, List<Map<String, Object?>>>> tables(
    WidgetTester tester,
  ) async => (await tester.runAsync(() async {
    final database = await databaseFactoryFfi.openDatabase(
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
          table: await database.query(table, orderBy: 'rowid'),
      };
    } finally {
      await database.close();
    }
  }))!;

  Future<void> expectStored(WidgetTester tester, Campaign expected) async {
    final stored = await tester.runAsync(
      () => repository.getCampaign(expected.id),
    );
    expect(stored!.toJson(), expected.toJson());
  }
}

Future<_Fixture> _start(
  WidgetTester tester, {
  required String primary,
  String secondary = 'Mönch',
}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final directory = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('concentration-class-ui-'),
  ))!;
  final databasePath = paths.join(directory.path, 'game.sqlite');
  final repository = (await tester.runAsync(
    () => SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    ),
  ))!;
  final random = _CountingRandom();
  final engine = GameEngine(
    dice: DiceEngine(random: random),
    clock: () => DateTime.utc(2026, 11, 1),
  );
  final demo = engine.createDemo();
  final original = Campaign.fromJson(
    demo
        .copyWith(
          hero: demo.hero.copyWith(
            className: primary,
            secondaryClassName: secondary,
            secondaryClassLevel: 14,
            level: 20,
            hitPoints: 80,
            maxHitPoints: 80,
            temporaryHitPoints: 0,
            abilities: {for (final ability in abilityNames) ability: 14},
            savingThrowProficiencies: const [],
            concentratingOn: 'Segen',
            spentClassResources: const {'focusPoints': 3},
          ),
        )
        .toJson(),
  );
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

Finder _control(String name) => find.byKey(ValueKey('character-effect-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _openDamage(WidgetTester tester) async {
  await _tap(
    tester,
    find.byKey(const ValueKey('adventure-confirm-character-effect')),
  );
  expect(find.byType(CharacterEffectDialog), findsOneWidget);
  for (final entry in {
    'source': 'Bestätigter Energieschaden',
    'amount': '5',
  }.entries) {
    await tester.ensureVisible(_control(entry.key));
    await tester.enterText(_control(entry.key), entry.value);
    await tester.pump();
  }
}

Future<void> _confirm(WidgetTester tester, GameController controller) async {
  await tester.ensureVisible(_control('confirm'));
  await tester.pumpAndSettle();
  expect(_control('confirm').hitTestable(), findsOneWidget);
  await tester.tap(_control('confirm'));
  await tester.pump();
  await tester.runAsync(() async {
    for (var i = 0; i < 200 && controller.busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  expect(controller.busy, isFalse);
  await tester.pumpAndSettle();
}

void _expectDamage(Campaign before, Campaign after) {
  expect(after.hero.hitPoints, 75);
  expect(after.hero.concentratingOn, 'Segen');
  expect(after.hero.spentClassResources, before.hero.spentClassResources);
  expect(after.revision, before.revision + 1);
  expect(after.events, hasLength(before.events.length + 1));
  final event = after.events.last;
  expect(event.type, 'effect.damage');
  expect(event.payload['source'], 'Bestätigter Energieschaden');
  expect(event.payload['damage'], 5);
  expect(event.payload['concentrationDc'], 10);
  expect(event.payload['concentrationMaintained'], isTrue);
  final save = event.payload['concentrationSave'] as Map;
  expect(save['natural'], 20);
  expect(save['modifier'], 8);
  expect(save['total'], 28);
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Legacy-Klasse bleibt lesbar; UI-Schaden erst nach Klassenbestätigung',
    (tester) async {
      final fixture = await _start(tester, primary: 'Unbestätigt');
      final before = fixture.controller.currentCampaign!;
      final rows = await fixture.tables(tester);

      // A readable historical profile is not an authorization to calculate
      // new class-derived saving throw bonuses. Cancelling stays read-only.
      await _openDamage(tester);
      await _tap(tester, _control('cancel'));
      expect(fixture.random.calls, 0);
      expect(fixture.controller.currentCampaign!.toJson(), before.toJson());
      expect(await fixture.tables(tester), rows);

      await _openDamage(tester);
      await _confirm(tester, fixture.controller);
      expect(find.byType(CharacterEffectDialog), findsNothing);
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(
        find.text('Die bestätigten Klassen und Stufen sind nicht konsistent.'),
        findsOneWidget,
      );
      expect(fixture.random.calls, 0);
      expect(fixture.controller.currentCampaign!.toJson(), before.toJson());
      expect(
        fixture.controller.characters.single.toJson(),
        before.hero.toJson(),
      );
      await fixture.expectStored(tester, before);
      expect(await fixture.tables(tester), rows);

      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), before.toJson());
      expect(fixture.controller.currentCampaign!.hero.className, 'Unbestätigt');
      expect(fixture.random.calls, 0);

      // Explicit existing character confirmation corrects only the chosen
      // class; it is not inferred by opening the campaign or damage dialog.
      await tester.runAsync(
        () => fixture.controller.saveHero(
          before.hero.copyWith(className: 'Kämpfer'),
          expectedCampaignId: before.id,
          expectedRevision: before.revision,
        ),
      );
      expect(fixture.controller.error, isNull);
      final corrected = fixture.controller.currentCampaign!;
      expect(corrected.hero.hitPoints, before.hero.hitPoints);
      expect(corrected.hero.concentratingOn, before.hero.concentratingOn);
      expect(
        corrected.hero.spentClassResources,
        before.hero.spentClassResources,
      );
      expect(fixture.random.calls, 0);
      await tester.pumpAndSettle();

      await _openDamage(tester);
      await _confirm(tester, fixture.controller);
      expect(fixture.controller.error, isNull);
      expect(fixture.random.calls, 1);
      final confirmed = fixture.controller.currentCampaign!;
      _expectDamage(corrected, confirmed);
      await fixture.expectStored(tester, confirmed);
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(fixture.random.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bestätigte Klassenaliase speichern UI-Konzentrationsrettung bis Neustart',
    (tester) async {
      final fixture = await _start(
        tester,
        primary: 'Fighter',
        secondary: 'Monk',
      );
      final before = fixture.controller.currentCampaign!;
      await _openDamage(tester);
      await _confirm(tester, fixture.controller);
      expect(fixture.controller.error, isNull);
      expect(fixture.random.calls, 1);
      final confirmed = fixture.controller.currentCampaign!;
      _expectDamage(before, confirmed);
      expect(confirmed.hero.className, 'Fighter');
      expect(confirmed.hero.secondaryClassName, 'Monk');
      await fixture.expectStored(tester, confirmed);
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(fixture.random.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
