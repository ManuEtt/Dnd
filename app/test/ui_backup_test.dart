import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/backup_files.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'support/legacy_campaign_fixture.dart';

class _SilentVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
}

class _FakeFiles implements BackupFiles {
  Future<bool> Function()? save;
  Future<String?> Function()? open;
  int saveCalls = 0;
  int openCalls = 0;
  String? savedJson;
  String? savedName;

  @override
  Future<bool> saveJson({required String name, required String json}) {
    saveCalls++;
    savedName = name;
    savedJson = json;
    return save?.call() ?? Future.value(true);
  }

  @override
  Future<String?> openJson() {
    openCalls++;
    return open?.call() ?? Future.value(null);
  }
}

class _Fixture {
  _Fixture(this.repository, this.controller, this.voice, this.files);
  final SqliteCampaignRepository repository;
  final GameController controller;
  final _SilentVoice voice;
  final _FakeFiles files;
}

Future<_Fixture> _start(WidgetTester tester, _FakeFiles files) async {
  final repository = (await tester.runAsync(
    () => SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    ),
  ))!;
  final controller = GameController(repository: repository);
  final voice = _SilentVoice();
  await tester.runAsync(controller.createDemo);
  expect(controller.error, isNull);
  await tester.pumpWidget(
    LivingGameApp(controller: controller, voice: voice, backupFiles: files),
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
  });
  return _Fixture(repository, controller, voice, files);
}

Finder _button<T extends ButtonStyleButton>(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byWidgetPredicate((widget) => widget is T),
);

Future<void> _export(WidgetTester tester) async {
  await tester.tap(find.text('Abenteuer'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Spielstand exportieren'));
  await tester.pumpAndSettle();
}

Future<void> _import(WidgetTester tester) async {
  await tester.tap(find.text('Start'));
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
}

Future<void> _wait(WidgetTester tester, GameController controller) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 200 && controller.busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  expect(controller.busy, isFalse);
  await tester.pumpAndSettle();
}

Future<void> _unchanged(
  WidgetTester tester,
  _Fixture fixture,
  Map<String, Object?> previous,
) async {
  expect(fixture.controller.currentCampaign!.toJson(), previous);
  final campaigns = (await tester.runAsync(fixture.repository.loadCampaigns))!;
  expect(campaigns, hasLength(1));
  expect(campaigns.single.toJson(), previous);
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('360 px file export saves full JSON without changing SQLite', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = await _start(tester, _FakeFiles());
    final previous = fixture.controller.currentCampaign!.toJson();
    await _export(tester);
    await tester.tap(find.text('Als Datei speichern'));
    await tester.pumpAndSettle();
    expect(fixture.files.saveCalls, 1);
    expect(fixture.files.savedName, backupFileName(previous['name'] as String));
    expect(jsonDecode(fixture.files.savedJson!), previous);
    expect(find.text('JSON-Datei gespeichert.'), findsOneWidget);
    await _unchanged(tester, fixture, previous);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final result in ['cancel', 'friendly', 'unexpected']) {
    testWidgets('file export $result preserves confirmed state and fallback', (
      tester,
    ) async {
      final files = _FakeFiles()
        ..save = () async {
          if (result == 'friendly') {
            throw const BackupFileException(
              'Der Speicherort ist nicht verfügbar.',
            );
          }
          if (result == 'unexpected') throw StateError('/private/token-secret');
          return false;
        };
      final fixture = await _start(tester, files);
      final previous = fixture.controller.currentCampaign!.toJson();
      await _export(tester);
      await tester.tap(find.text('Als Datei speichern'));
      await tester.pumpAndSettle();
      expect(files.saveCalls, 1);
      expect(find.textContaining('token-secret'), findsNothing);
      expect(find.textContaining('/private'), findsNothing);
      expect(
        find.text(
          result == 'cancel'
              ? 'Speichern abgebrochen. Dein Spielstand bleibt unverändert.'
              : result == 'friendly'
              ? 'Der Speicherort ist nicht verfügbar.'
              : 'Die Datei konnte nicht verarbeitet werden. Versuche es erneut oder nutze den JSON-Text.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FilledButton>(_button<FilledButton>('Kopieren'))
            .onPressed,
        isNotNull,
      );
      await _unchanged(tester, fixture, previous);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('file import remains editable and saves only after confirmation', (
    tester,
  ) async {
    final files = _FakeFiles();
    final fixture = await _start(tester, files);
    final previous = fixture.controller.currentCampaign!.toJson();
    final source = jsonEncode(
      legacyArescanCampaign().toJson(),
    );
    files.open = () async => source;
    await _import(tester);
    await tester.tap(find.text('Datei wählen'));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextField, 'JSON-Spielstand');
    expect(tester.widget<TextField>(field).controller!.text, source);
    expect(tester.widget<TextField>(field).readOnly, isFalse);
    await _unchanged(tester, fixture, previous);
    // File content is still an explicit, correctable proposal until confirmation.
    await tester.enterText(field, source);
    await tester.tap(_button<FilledButton>('Importieren'));
    await tester.pump();
    await _wait(tester, fixture.controller);
    expect(fixture.controller.error, isNull);
    expect(fixture.controller.currentCampaign!.name, 'Das Herz der Ewigkeit');
    expect(fixture.controller.currentCampaign!.hero.hitPoints, isNull);
    expect(fixture.controller.campaigns, hasLength(2));
    final campaigns = (await tester.runAsync(
      fixture.repository.loadCampaigns,
    ))!;
    expect(campaigns, hasLength(2));
    expect(
      campaigns.firstWhere((c) => c.id == previous['id']).toJson(),
      previous,
    );
    expect(files.openCalls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled file import keeps pasted text and changes no data', (
    tester,
  ) async {
    final fixture = await _start(tester, _FakeFiles());
    final previous = fixture.controller.currentCampaign!.toJson();
    await _import(tester);
    final field = find.widgetWithText(TextField, 'JSON-Spielstand');
    await tester.enterText(field, 'mein Entwurf');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datei wählen'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, 'mein Entwurf');
    expect(find.textContaining('Dateiauswahl abgebrochen'), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await _unchanged(tester, fixture, previous);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid file is rejected without a partial campaign import', (
    tester,
  ) async {
    final fixture = await _start(
      tester,
      _FakeFiles()..open = () async => '{"formatVersion":999}',
    );
    final previous = fixture.controller.currentCampaign!.toJson();
    await _import(tester);
    await tester.tap(find.text('Datei wählen'));
    await tester.pumpAndSettle();
    await tester.tap(_button<FilledButton>('Importieren'));
    await tester.pump();
    await _wait(tester, fixture.controller);
    expect(fixture.controller.error, isNotNull);
    expect(find.byType(MaterialBanner), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    await _unchanged(tester, fixture, previous);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file read failures show safe feedback and preserve text', (
    tester,
  ) async {
    final fixture = await _start(
      tester,
      _FakeFiles()
        ..open = () async => throw StateError('/private/secret-token'),
    );
    final previous = fixture.controller.currentCampaign!.toJson();
    await _import(tester);
    final field = find.widgetWithText(TextField, 'JSON-Spielstand');
    await tester.enterText(field, 'bleibt erhalten');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datei wählen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-token'), findsNothing);
    expect(tester.widget<TextField>(field).controller!.text, 'bleibt erhalten');
    await _unchanged(tester, fixture, previous);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pending export disables duplicates, copy and dialog dismissal', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final fixture = await _start(
      tester,
      _FakeFiles()..save = () => pending.future,
    );
    final previous = fixture.controller.currentCampaign!.toJson();
    await _export(tester);
    await tester.tap(find.text('Als Datei speichern'));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(
            _button<OutlinedButton>('Als Datei speichern'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(_button<FilledButton>('Kopieren')).onPressed,
      isNull,
    );
    expect(
      tester.widget<TextButton>(_button<TextButton>('Schließen')).onPressed,
      isNull,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Als Datei speichern'));
    expect(fixture.files.saveCalls, 1);
    pending.complete(false);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await _unchanged(tester, fixture, previous);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending import prevents confirmation and closes after cancellation',
    (tester) async {
      final pending = Completer<String?>();
      final fixture = await _start(
        tester,
        _FakeFiles()..open = () => pending.future,
      );
      final previous = fixture.controller.currentCampaign!.toJson();
      await _import(tester);
      await tester.tap(find.text('Datei wählen'));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'JSON-Spielstand'),
            )
            .readOnly,
        isTrue,
      );
      expect(
        tester
            .widget<OutlinedButton>(_button<OutlinedButton>('Datei wählen'))
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FilledButton>(_button<FilledButton>('Importieren'))
            .onPressed,
        isNull,
      );
      expect(
        tester.widget<TextButton>(_button<TextButton>('Abbrechen')).onPressed,
        isNull,
      );
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      pending.complete(null);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(fixture.files.openCalls, 1);
      await _unchanged(tester, fixture, previous);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unmount during pending file read ignores a late result', (
    tester,
  ) async {
    final pending = Completer<String?>();
    final fixture = await _start(
      tester,
      _FakeFiles()..open = () => pending.future,
    );
    final previous = fixture.controller.currentCampaign!.toJson();
    await _import(tester);
    await tester.tap(find.text('Datei wählen'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete('{}');
    await tester.pumpAndSettle();
    await _unchanged(tester, fixture, previous);
    expect(tester.takeException(), isNull);
  });

  testWidgets('clipboard export stays available without a file operation', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });
    final fixture = await _start(tester, _FakeFiles());
    final previous = fixture.controller.currentCampaign!.toJson();
    await _export(tester);
    await tester.tap(find.text('Kopieren'));
    await tester.pumpAndSettle();
    expect(jsonDecode(copied!), previous);
    expect(find.text('JSON in die Zwischenablage kopiert.'), findsOneWidget);
    expect(fixture.files.saveCalls, 0);
    await _unchanged(tester, fixture, previous);
    expect(tester.takeException(), isNull);
  });

  testWidgets('character and settings export use the injected file service', (
    tester,
  ) async {
    final fixture = await _start(tester, _FakeFiles());
    await tester.runAsync(
      () => fixture.controller.saveStandaloneHero(
        fixture.controller.currentCampaign!.hero,
      ),
    );
    await tester.tap(find.text('Helden'));
    await tester.pumpAndSettle();
    final button = find.text('Exportieren');
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Als Datei speichern'));
    await tester.pumpAndSettle();
    expect(fixture.files.savedName, startsWith('charakter-'));
    expect(
      jsonDecode(fixture.files.savedJson!),
      fixture.controller.characters.single.toJson(),
    );
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Optionen'));
    await tester.pumpAndSettle();
    final settingsExport = find.text('Aktuelle Kampagne exportieren');
    await tester.scrollUntilVisible(
      settingsExport,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(settingsExport);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Als Datei speichern'));
    await tester.pumpAndSettle();
    expect(fixture.files.savedName, startsWith('kampagne-'));
    expect(
      jsonDecode(fixture.files.savedJson!),
      fixture.controller.currentCampaign!.toJson(),
    );
    expect(fixture.files.saveCalls, 2);
    expect(tester.takeException(), isNull);
  });
}
