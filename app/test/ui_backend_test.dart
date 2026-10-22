import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'support/legacy_campaign_fixture.dart';

class _SilentVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}

  @override
  Future<void> stopSpeaking() async {}
}

class _FakeBackend extends BackendTransport {
  String provider = 'mock';
  int calls = 0;

  @override
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) async {
    ++calls;
    if (method == 'GET') {
      return BackendResponse(
        statusCode: 200,
        body: {
          'scope': 'narration:read-only',
          'provider': provider,
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 5))
              .toIso8601String(),
        },
      );
    }
    return BackendResponse(
      statusCode: 200,
      body: {
        'text':
            'Der Wind trägt den Duft des Waldes zu dir. Was möchtest du tun?',
        'provider': provider,
        'stateChanges': <Object?>[],
      },
    );
  }
}

class _PendingBackend extends _FakeBackend {
  final response = Completer<BackendResponse>();
  bool narrationRequested = false;

  @override
  Future<BackendResponse> request({
    required String method,
    required Uri uri,
    required String bearerToken,
    Map<String, Object?>? body,
  }) {
    if (method == 'POST') {
      narrationRequested = true;
      ++calls;
      return response.future;
    }
    return super.request(
      method: method,
      uri: uri,
      bearerToken: bearerToken,
      body: body,
    );
  }
}

Future<SqliteCampaignRepository> _repository(WidgetTester tester) async =>
    (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;

Future<void> _finishAction(
  WidgetTester tester,
  GameController controller,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 200 && controller.busy; ++attempt) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  expect(controller.busy, isFalse);
  await tester.pumpAndSettle();
}

Future<void> _settings(WidgetTester tester) async {
  await tester.tap(find.text('Optionen'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Backend verbinden'),
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _dialog(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Backend verbinden'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Backend verbinden'));
  await tester.pumpAndSettle();
}

Future<void> _enterConnection(
  WidgetTester tester, {
  String limit = '20',
}) async {
  await tester.enterText(
    find.byKey(const Key('backend-url')),
    'https://spielleiter.example.org',
  );
  await tester.enterText(
    find.byKey(const Key('backend-token')),
    'short_session.signature',
  );
  await tester.enterText(find.byKey(const Key('backend-limit')), limit);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

Future<void> _close(
  WidgetTester tester,
  GameController controller,
  VoiceController voice,
  SqliteCampaignRepository repository,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
  voice.dispose();
  await tester.runAsync(repository.close);
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'settings default to a free local narrator without network access',
    (tester) async {
      final repository = await _repository(tester);
      final transport = _FakeBackend();
      final controller = GameController(
        repository: repository,
        narrator: BackendNarrator(transport: transport),
      );
      final voice = _SilentVoice();
      await tester.runAsync(controller.initialize);
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await _settings(tester);
      expect(find.text('Aktiver Spielleiter: lokale Demo'), findsOneWidget);
      expect(find.textContaining('ohne API-Kosten'), findsOneWidget);
      expect(transport.calls, 0);
      expect(controller.narrator.enabled, isFalse);
      expect(tester.takeException(), isNull);
      await _close(tester, controller, voice, repository);
    },
  );

  testWidgets(
    'a 360 px connect dialog keeps credentials private and works with a keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = await _repository(tester);
      final transport = _FakeBackend();
      final controller = GameController(
        repository: repository,
        narrator: BackendNarrator(transport: transport),
      );
      final voice = _SilentVoice();
      await tester.runAsync(controller.initialize);
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await _settings(tester);
      await _dialog(tester);
      final token = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('backend-token')),
          matching: find.byType(TextField),
        ),
      );
      expect(token.obscureText, isTrue);
      expect(token.autocorrect, isFalse);
      expect(token.enableSuggestions, isFalse);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const Key('backend-allow-paid')),
            )
            .value,
        isFalse,
      );
      await tester.ensureVisible(find.byKey(const Key('backend-token')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('backend-token')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.widgetWithText(FilledButton, 'Verbinden').hitTestable(),
        findsOneWidget,
      );
      await _enterConnection(tester, limit: '7');
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Verbinden'));
      await _finishAction(tester, controller);
      expect(controller.narrator.enabled, isTrue);
      expect(controller.narrator.allowPaidProvider, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Aktiver Spielleiter: Server-Demo'), findsOneWidget);
      expect(transport.calls, 1);
      final settings = await tester.runAsync(repository.loadSettings);
      expect(settings, {
        'backendUrl': 'https://spielleiter.example.org',
        'backendRequestLimit': 7,
      });
      expect(settings.toString(), isNot(contains('short_session.signature')));
      expect(tester.takeException(), isNull);
      await _close(tester, controller, voice, repository);
    },
  );

  testWidgets('paid narration requires a separate opt-in on every connection', (
    tester,
  ) async {
    final repository = await _repository(tester);
    final transport = _FakeBackend()..provider = 'openai';
    final controller = GameController(
      repository: repository,
      narrator: BackendNarrator(transport: transport),
    );
    final voice = _SilentVoice();
    await tester.runAsync(controller.initialize);
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await _settings(tester);
    await _dialog(tester);
    await _enterConnection(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Verbinden'));
    await _finishAction(tester, controller);
    expect(controller.narrator.enabled, isFalse);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('ausdrückliche Kostenfreigabe'), findsWidgets);
    final paid = find.byKey(const Key('backend-allow-paid'));
    await tester.ensureVisible(paid);
    await tester.pumpAndSettle();
    await tester.tap(paid);
    await tester.tap(find.widgetWithText(FilledButton, 'Verbinden'));
    await _finishAction(tester, controller);
    expect(controller.narrator.enabled, isTrue);
    expect(controller.narrator.allowPaidProvider, isTrue);
    expect(find.text('Aktiver Spielleiter: OpenAI'), findsOneWidget);
    await tester.ensureVisible(find.text('Neu verbinden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neu verbinden'));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(paid).value, isFalse);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const Key('backend-token')))
          .controller!
          .text,
      isEmpty,
    );
    expect(transport.calls, 2);
    expect(tester.takeException(), isNull);
    await _close(tester, controller, voice, repository);
  });

  testWidgets('invalid address and request limit do not send a session token', (
    tester,
  ) async {
    final repository = await _repository(tester);
    final transport = _FakeBackend();
    final controller = GameController(
      repository: repository,
      narrator: BackendNarrator(transport: transport),
    );
    final voice = _SilentVoice();
    await tester.runAsync(controller.initialize);
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await _settings(tester);
    await _dialog(tester);
    await _enterConnection(tester, limit: '101');
    await tester.enterText(
      find.byKey(const Key('backend-url')),
      'http://example.org',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Verbinden'));
    await tester.pumpAndSettle();
    expect(
      find.text('HTTPS-Adresse ohne Zugangsdaten eingeben.'),
      findsOneWidget,
    );
    expect(
      find.text('Eine ganze Zahl zwischen 1 und 100 eingeben.'),
      findsOneWidget,
    );
    expect(transport.calls, 0);
    expect(controller.narrator.enabled, isFalse);
    expect(tester.takeException(), isNull);
    await _close(tester, controller, voice, repository);
  });

  testWidgets(
    'adventure observes narrator disconnect without a controller update',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = await _repository(tester);
      final narrator = BackendNarrator(transport: _FakeBackend());
      final controller = GameController(
        repository: repository,
        narrator: narrator,
      );
      final voice = _SilentVoice();
      await tester.runAsync(() => importLegacyArescan(controller));
      await narrator.connect(
        url: 'https://spielleiter.example.org',
        sessionToken: 'short_session.signature',
      );
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Server-Demo · 0/20'), findsOneWidget);
      narrator.disconnect();
      await tester.pumpAndSettle();
      expect(find.textContaining('Backend getrennt.'), findsOneWidget);
      final input = find.widgetWithText(TextField, 'Was möchtest du tun?');
      await tester.tap(input);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Handlung senden').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _close(tester, controller, voice, repository);
    },
  );

  testWidgets('deleting all local data also disconnects and clears settings', (
    tester,
  ) async {
    final repository = await _repository(tester);
    final controller = GameController(
      repository: repository,
      narrator: BackendNarrator(transport: _FakeBackend()),
    );
    final voice = _SilentVoice();
    await tester.runAsync(controller.createDemo);
    await tester.runAsync(
      () => controller.connectNarrator(
        url: 'https://spielleiter.example.org',
        sessionToken: 'short_session.signature',
      ),
    );
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Optionen'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Alle lokalen Spieldaten löschen'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alle lokalen Spieldaten löschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Endgültig löschen'));
    await _finishAction(tester, controller);
    expect(controller.narrator.enabled, isFalse);
    expect(controller.currentCampaign, isNull);
    expect(controller.campaigns, isEmpty);
    expect(controller.characters, isEmpty);
    expect(await tester.runAsync(repository.loadSettings), isEmpty);
    expect(tester.takeException(), isNull);
    await _close(tester, controller, voice, repository);
  });

  testWidgets('a pending narrator request can be disconnected in settings', (
    tester,
  ) async {
    final repository = await _repository(tester);
    final transport = _PendingBackend();
    final controller = GameController(
      repository: repository,
      narrator: BackendNarrator(transport: transport),
    );
    final voice = _SilentVoice();
    await tester.runAsync(controller.createDemo);
    await tester.runAsync(
      () => controller.connectNarrator(
        url: 'https://spielleiter.example.org',
        sessionToken: 'short_session.signature',
      ),
    );
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.tap(find.text('Abenteuer'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Was möchtest du tun?'),
      'Ich lausche dem Wind.',
    );
    await tester.tap(find.byTooltip('Handlung senden'));
    await tester.pump();
    expect(transport.narrationRequested, isTrue);
    expect(controller.busy, isTrue);
    // The indeterminate progress indicator intentionally keeps animating while
    // the fake POST is pending; use bounded pumps to navigate during that wait.
    await tester.tap(find.text('Optionen'));
    await tester.pump(const Duration(milliseconds: 400));
    final disconnect = find.text('Lokale Demo verwenden');
    await tester.scrollUntilVisible(
      disconnect,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 400));
    final disconnectButton = find.ancestor(
      of: disconnect,
      matching: find.byWidgetPredicate((widget) => widget is FantasyTextButton),
    );
    expect(tester.widget<FantasyTextButton>(disconnectButton).onPressed, isNotNull);
    await tester.tap(disconnect);
    await tester.pump();
    expect(controller.narrator.enabled, isFalse);
    await _finishAction(tester, controller);
    expect(transport.response.isCompleted, isFalse);
    final confirmed = controller.currentCampaign!.toJson();
    // A late provider reply cannot replace the local fallback after disconnect.
    transport.response.complete(
      const BackendResponse(
        statusCode: 200,
        body: {
          'text': 'Diese verspätete Erzählung darf nicht übernommen werden.',
          'provider': 'mock',
          'stateChanges': <Object?>[],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.currentCampaign!.toJson(), confirmed);
    expect(controller.currentCampaign!.revision, 1);
    expect(
      controller.currentCampaign!.messages.last.text,
      isNot(contains('verspätete Erzählung')),
    );
    expect(controller.currentCampaign!.events.last.type, 'narrative.turn');
    expect(transport.calls, 2);
    expect(find.text('Aktiver Spielleiter: lokale Demo'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _close(tester, controller, voice, repository);
  });
}
