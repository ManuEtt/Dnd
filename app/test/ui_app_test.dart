import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_experience.dart';
import 'support/legacy_campaign_fixture.dart';

class _SilentVoice extends VoiceController {
  final spoken = <String>[];
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {
    spoken.add(text);
  }

  @override
  Future<void> startListening(void Function(String) onText) async {
    onText('Ich untersuche den Wald.');
  }
}

class _ActivityVoice extends _SilentVoice {
  bool microphoneActive = false;
  bool playbackActive = false;

  @override
  Future<void> startListening(void Function(String) onText) async {
    microphoneActive = true;
    await super.startListening(onText);
  }

  @override
  Future<void> stopListening() async {
    microphoneActive = false;
    await super.stopListening();
  }

  @override
  Future<void> speak(String text) async {
    await stopListening();
    playbackActive = true;
    await super.speak(text);
  }

  @override
  Future<void> stopSpeaking() async {
    playbackActive = false;
    await super.stopSpeaking();
  }
}

Future<void> waitForController(
  WidgetTester tester,
  GameController controller, {
  bool hasError = false,
}) async {
  await tester.runAsync(() async {
    // Let filesystem/isolate work finish in real time before settling animations.
    for (var attempt = 0; attempt < 200 && controller.busy; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  expect(controller.busy, isFalse);
  expect(controller.error, hasError ? isNotNull : isNull);
}

Future<void> importCampaignText(WidgetTester tester, String source) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final button = find.text('Kampagne aus JSON importieren');
  await tester.scrollUntilVisible(
    button,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.enterText(
    find.widgetWithText(TextField, 'JSON-Spielstand'),
    source,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Importieren'));
  // The real SQLite import needs real async time before a busy indicator can
  // settle; callers wait for the controller before settling the route.
  await tester.pump();
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('home does not ship a fixed Arescan campaign', (tester) async {
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repository);
    final voice = _SilentVoice();
    await tester.runAsync(controller.initialize);
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    expect(controller.campaigns, isEmpty);
    expect(find.text('Arescan-Spielstand laden'), findsNothing);
    expect(find.text('Das Herz der Ewigkeit'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Kampagne aus JSON importieren'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Kampagne aus JSON importieren'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
  });

  testWidgets(
    '360 px Android navigation opens demo, correctable voice text and journal',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentVoice();
      await tester.runAsync(controller.initialize);
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byType(FantasyRuneEmblem),
        ),
        findsNWidgets(5),
      );
      // The illustrated home header increases the content height on 360 dp.
      // Scroll the *visible* home list to the real demo action before tapping.
      // Disabling hit-test warnings would hide a genuine navigation failure.
      final demoStart = find.text('Kostenlose Demo starten');
      await tester.scrollUntilVisible(
        demoStart,
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(demoStart);
      await tester.pumpAndSettle();
      expect(demoStart.hitTestable(), findsOneWidget);
      await tester.tap(demoStart);
      await waitForController(tester, controller);
      await tester.pumpAndSettle();
      expect(controller.currentCampaign, isNotNull);
      expect(find.text('Was möchtest du tun?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The text command in the persistent composer is independent of the
      // new illustrated action cards further up in the scene list.
      await tester.tap(find.byKey(const ValueKey('adventure-shortcut-speech')));
      await tester.pumpAndSettle();
      expect(find.text('Ich untersuche den Wald.'), findsOneWidget);
      await tester.tap(find.byTooltip('Handlung senden'));
      await waitForController(tester, controller);
      await tester.pumpAndSettle();
      expect(controller.currentCampaign!.messages.length, greaterThan(1));
      await tester.tap(find.text('Tagebuch'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Dauerhafte Erinnerungen'),
        280,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Dauerhafte Erinnerungen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Helden'));
      await tester.pumpAndSettle();
      expect(find.text('Charakter erstellen'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    },
  );

  testWidgets(
    'Schnellaktionen bleiben unter der Erzählung auch nach Scrollen fixiert',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentVoice();
      await tester.runAsync(controller.createDemo);
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();

      final shortcuts = find.byKey(const ValueKey('adventure-fixed-shortcuts'));
      expect(shortcuts, findsOneWidget);
      // The dock must be a real, non-scrolling Scaffold.bottomNavigationBar.
      final dockScaffolds = tester
          .widgetList<Scaffold>(find.byType(Scaffold))
          .where(
            (scaffold) =>
                scaffold.bottomNavigationBar is FantasyPinnedActionBar,
          );
      expect(dockScaffolds, hasLength(1));
      // Only the dock offers microphone and the generic W20 shortcut.
      expect(
        find.byKey(const ValueKey('adventure-shortcut-speech')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('adventure-shortcut-roll')),
        findsOneWidget,
      );
      expect(find.text('Sprechen'), findsNothing);
      final before = tester.getTopLeft(shortcuts);
      final navigationTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
      expect(tester.getBottomLeft(shortcuts).dy, closeTo(navigationTop, 1));
      await tester.drag(find.byType(ListView).first, const Offset(0, -360));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(shortcuts).dy, closeTo(before.dy, 1));
      expect(
        find.byKey(const ValueKey('adventure-shortcut-inspect')).hitTestable(),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('adventure-shortcut-inspect')),
      );
      await waitForController(tester, controller);
      await tester.pumpAndSettle();
      expect(controller.currentCampaign!.messages.last.text, isNotEmpty);
      expect(
        find.byKey(const ValueKey('adventure-fixed-shortcuts')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    },
  );

  testWidgets('Schnellaktionen nur in der Abenteueransicht', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repository);
    final voice = _SilentVoice();
    await tester.runAsync(controller.createDemo);
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    expect(
      find.byKey(const ValueKey('adventure-fixed-shortcuts')),
      findsNothing,
    );
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('adventure-fixed-shortcuts')),
      findsOneWidget,
    );
    for (final page in ['Start', 'Helden', 'Tagebuch', 'Optionen']) {
      await tester.tap(find.text(page).last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('adventure-fixed-shortcuts')),
        findsNothing,
        reason: 'Die Schnellaktionen sind in $page unzulässig.',
      );
      expect(
        tester
            .widgetList<Scaffold>(find.byType(Scaffold))
            .where(
              (scaffold) =>
                  scaffold.bottomNavigationBar is FantasyPinnedActionBar,
            ),
        isEmpty,
      );
    }
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('adventure-fixed-shortcuts')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
  });

  testWidgets(
    'adventure recap preserves an unfinished action and confirmed state',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentVoice();
      await tester.runAsync(controller.createDemo);
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextField, 'Was möchtest du tun?');
      await tester.enterText(input, 'Ich möchte später den Brunnen erkunden.');
      final heroBefore = jsonEncode(controller.currentCampaign!.hero.toJson());
      await tester.tap(find.byKey(const ValueKey('adventure-memory-recap')));
      await waitForController(tester, controller);
      await tester.pumpAndSettle();
      expect(
        find.text('Ich möchte später den Brunnen erkunden.'),
        findsOneWidget,
      );
      expect(controller.currentCampaign!.events.last.type, 'memory.recalled');
      expect(
        controller.currentCampaign!.messages.last.text,
        contains('Waldlicht'),
      );
      expect(jsonEncode(controller.currentCampaign!.hero.toJson()), heroBefore);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    },
  );

  testWidgets(
    'Arescan notice guides unconfirmed sheet completion without invented HP',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentVoice();
      await tester.runAsync(() => importLegacyArescan(controller));
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Charakterbogen unvollständig'),
        findsOneWidget,
      );
      expect(find.textContaining('TP ?/?'), findsOneWidget);
      expect(controller.currentCampaign!.hero.hitPoints, isNull);
      expect(tester.takeException(), isNull);
      final completeButton = find.text('Vervollständigen');
      // The persistent composer can otherwise obscure the notice on 360 px.
      await tester.scrollUntilVisible(
        completeButton,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(completeButton);
      await tester.pumpAndSettle();
      expect(completeButton.hitTestable(), findsOneWidget);
      await tester.tap(completeButton);
      await tester.pumpAndSettle();
      expect(find.text('Charakter bearbeiten'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    },
  );

  testWidgets(
    'Arescan on a 360 px screen keeps text submission usable with a 300 px keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentVoice();
      await tester.runAsync(() => importLegacyArescan(controller));
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Charakterbogen unvollständig'),
        findsOneWidget,
      );
      final input = find.widgetWithText(TextField, 'Was möchtest du tun?');
      await tester.tap(input);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(input, 'Ich untersuche das Amulett.');
      await tester.pumpAndSettle();
      final send = find.byTooltip('Handlung senden');
      expect(send.hitTestable(), findsOneWidget);
      expect(tester.getBottomRight(send).dy, lessThanOrEqualTo(500));
      await tester.tap(send);
      await waitForController(tester, controller);
      await tester.pumpAndSettle();
      expect(controller.currentCampaign!.revision, 1);
      expect(controller.currentCampaign!.hero.hitPoints, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    },
  );

  testWidgets(
    'failed import stays on campaign selection and successful import opens the new campaign',
    (tester) async {
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentVoice();
      await tester.runAsync(controller.createDemo);
      final previous = controller.currentCampaign!;
      final source = jsonEncode(controller.engine.createDemo().toJson());
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await importCampaignText(tester, 'invalid JSON');
      await waitForController(tester, controller, hasError: true);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      expect(find.text('Was möchtest du tun?'), findsNothing);
      expect(controller.currentCampaign!.toJson(), previous.toJson());
      expect(tester.takeException(), isNull);
      await importCampaignText(tester, source);
      await waitForController(tester, controller);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect(find.text('Was möchtest du tun?'), findsOneWidget);
      expect(controller.currentCampaign!.id, isNot(previous.id));
      expect(controller.campaigns, hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    },
  );

  testWidgets(
    'a storage failure preserves the input and does not replay the last spoken reply',
    (tester) async {
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentVoice()..autoSpeak = true;
      await tester.runAsync(controller.createDemo);
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      final input = find.widgetWithText(TextField, 'Was möchtest du tun?');
      await tester.enterText(input, 'Ich untersuche den Brunnen.');
      await tester.tap(find.byTooltip('Handlung senden'));
      await waitForController(tester, controller);
      await tester.pumpAndSettle();
      expect(voice.spoken, [controller.currentCampaign!.messages.last.text]);
      final confirmed = controller.currentCampaign!.toJson();
      // Closing the real database exercises the same error boundary as a failed
      // device write, without replacing the game rules or controller with mocks.
      await tester.runAsync(repository.close);
      await tester.enterText(input, 'Ich gehe zum Waldschrein.');
      await tester.tap(find.byTooltip('Handlung senden'));
      await waitForController(tester, controller, hasError: true);
      await tester.pumpAndSettle();
      expect(voice.spoken, hasLength(1));
      expect(controller.currentCampaign!.toJson(), confirmed);
      expect(find.text('Ich gehe zum Waldschrein.'), findsOneWidget);
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
    },
  );

  testWidgets('leaving the adventure stops microphone and narration', (
    tester,
  ) async {
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repository);
    final voice = _ActivityVoice();
    await tester.runAsync(controller.createDemo);
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('adventure-shortcut-speech')));
    await tester.pumpAndSettle();
    expect(voice.microphoneActive, isTrue);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(voice.microphoneActive, isFalse);
    expect(voice.playbackActive, isFalse);
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
    await voice.speak(controller.currentCampaign!.messages.last.text);
    expect(voice.playbackActive, isTrue);
    await tester.tap(find.text('Helden'));
    await tester.pumpAndSettle();
    expect(voice.playbackActive, isFalse);
    expect(voice.microphoneActive, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
  });

  testWidgets('settings expose full SRD attribution and software licenses', (
    tester,
  ) async {
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repository);
    final voice = _SilentVoice();
    await tester.runAsync(controller.initialize);
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Optionen'));
    await tester.pumpAndSettle();
    final button = find.text('Softwarelizenzen anzeigen');
    await tester.scrollUntilVisible(
      button,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(
      find.textContaining(
        'This work includes material from the System Reference Document 5.2.1',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('by Wizards of the Coast LLC'), findsOneWidget);
    expect(
      find.textContaining('https://www.dndbeyond.com/srd'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'https://creativecommons.org/licenses/by/4.0/legalcode',
      ),
      findsOneWidget,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
  });
  testWidgets('deutscher Fantasy-Charakterbogen öffnet aus dem Abenteuer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repository);
    final voice = _SilentVoice();
    await tester.runAsync(controller.createDemo);
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('adventure-open-character-sheet')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Charakterbogen'), findsOneWidget);
    expect(find.text('RÜSTUNGSKLASSE'), findsOneWidget);
    // The passive-Perception row can move the tab bar just below a small
    // screen's initial viewport. Prove it is reachable by actual scrolling.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sheet-tab-0')),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Attribute'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Was möchtest du tun?'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
  });
}
