import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/backup_files.dart';
import 'package:lebendiger_spielleiter/ui/backup_dialogs.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

class _FakeBackupFiles implements BackupFiles {
  Future<bool> Function()? save;
  int saveCalls = 0;
  String? savedJson;
  String? savedName;

  @override
  Future<bool> saveJson({required String name, required String json}) {
    saveCalls++;
    savedName = name;
    savedJson = json;
    return save?.call() ?? Future<bool>.value(true);
  }

  @override
  Future<String?> openJson() async => null;
}

Finder _button(String label) => find.widgetWithText(FantasyTextButton, label);

String _longJson() => jsonEncode({
  'name': 'Würfelraunen',
  'journal': List<String>.filled(80, 'Im Wald erklingt ein leiser Ruf.'),
});

Future<void> _openExport(
  WidgetTester tester, {
  required double width,
  required String json,
  required _FakeBackupFiles files,
  required List<bool> closed,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              await showExportBackupDialog(
                context,
                title: 'Spielstand exportieren',
                json: json,
                name: 'kampagne.json',
                files: files,
              );
              closed.add(true);
            },
            child: const Text('Exportdialog öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Exportdialog öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final width in [320.0, 360.0]) {
    testWidgets('Export $width dp: 200 % Schrift/IME, volles JSON kopieren', (
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

      final files = _FakeBackupFiles();
      final closed = <bool>[];
      final json = _longJson();
      await _openExport(
        tester,
        width: width,
        json: json,
        files: files,
        closed: closed,
      );
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      expect(tester.widget<SelectableText>(find.byType(SelectableText)).data, json);
      expect(closed, isEmpty);

      await _tapVisible(tester, _button('Kopieren'));
      expect(copied, json);
      expect(files.saveCalls, 0);
      expect(find.text('JSON in die Zwischenablage kopiert.'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tapVisible(tester, _button('Schließen'));
      expect(closed, [true]);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Export $width dp: Datei speichern ohne JSON-Veränderung', (
      tester,
    ) async {
      final files = _FakeBackupFiles();
      final closed = <bool>[];
      final json = _longJson();
      await _openExport(
        tester,
        width: width,
        json: json,
        files: files,
        closed: closed,
      );

      await _tapVisible(tester, _button('Als Datei speichern'));
      expect(files.saveCalls, 1);
      expect(files.savedName, 'kampagne.json');
      expect(files.savedJson, json);
      expect(jsonDecode(files.savedJson!), jsonDecode(json));
      expect(find.text('JSON-Datei gespeichert.'), findsOneWidget);
      expect(closed, isEmpty);
      expect(tester.takeException(), isNull);

      await _tapVisible(tester, _button('Schließen'));
      expect(closed, [true]);
    });
  }

  testWidgets('320 dp: ausstehender Export sperrt doppelte Aktionen und Zurück', (
    tester,
  ) async {
    final pending = Completer<bool>();
    final files = _FakeBackupFiles()..save = () => pending.future;
    final closed = <bool>[];
    final json = _longJson();
    await _openExport(
      tester,
      width: 320,
      json: json,
      files: files,
      closed: closed,
    );

    await tester.ensureVisible(_button('Als Datei speichern'));
    await tester.pumpAndSettle();
    await tester.tap(_button('Als Datei speichern'));
    // The pending file operation keeps a progress indicator animating.
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    for (final label in ['Als Datei speichern', 'Schließen', 'Kopieren']) {
      expect(tester.widget<FantasyTextButton>(_button(label)).onPressed, isNull);
    }
    expect(files.saveCalls, 1);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(closed, isEmpty);

    pending.complete(false);
    await tester.pumpAndSettle();
    expect(
      find.text('Speichern abgebrochen. Dein Spielstand bleibt unverändert.'),
      findsOneWidget,
    );
    expect(tester.widget<FantasyTextButton>(_button('Kopieren')).onPressed, isNotNull);
    expect(files.savedJson, json);
    await _tapVisible(tester, _button('Schließen'));
    expect(closed, [true]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp: Dateifehler sicher als Screenreader-Live-Region', (
    tester,
  ) async {
    final files = _FakeBackupFiles()
      ..save = () async => throw StateError('/private/secret-token');
    final closed = <bool>[];
    await _openExport(
      tester,
      width: 360,
      json: _longJson(),
      files: files,
      closed: closed,
    );

    await _tapVisible(tester, _button('Als Datei speichern'));
    const safeMessage =
        'Die Datei konnte nicht verarbeitet werden. Versuche es erneut oder nutze den JSON-Text.';
    expect(find.text(safeMessage), findsOneWidget);
    expect(find.textContaining('secret-token'), findsNothing);
    expect(
      tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.text(safeMessage),
              matching: find.byType(Semantics),
            ),
          )
          .any((widget) => widget.properties.liveRegion ?? false),
      isTrue,
    );
    expect(tester.widget<FantasyTextButton>(_button('Kopieren')).onPressed, isNotNull);
    expect(closed, isEmpty);
    await _tapVisible(tester, _button('Schließen'));
    expect(closed, [true]);
    expect(tester.takeException(), isNull);
  });
}
