import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/backup_files.dart';
import 'package:lebendiger_spielleiter/ui/backup_dialogs.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

class _FakeBackupFiles implements BackupFiles {
  Future<String?> Function()? open;
  int openCalls = 0;

  @override
  Future<String?> openJson() {
    openCalls++;
    return open?.call() ?? Future<String?>.value(null);
  }

  @override
  Future<bool> saveJson({required String name, required String json}) async {
    return true;
  }
}

Finder _button(String label) => find.widgetWithText(FantasyTextButton, label);

Future<void> _openDialog(
  WidgetTester tester, {
  required double width,
  required _FakeBackupFiles files,
  required List<String?> results,
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
              results.add(
                await showImportBackupDialog(
                  context,
                  title: 'Spielstand importieren',
                  files: files,
                ),
              );
            },
            child: const Text('Importdialog öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Importdialog öffnen'));
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

  for (final width in [320.0, 360.0]) {
    testWidgets('Import $width dp bei 200 % und IME: explizit bestätigen', (
      tester,
    ) async {
      final files = _FakeBackupFiles();
      final results = <String?>[];
      await _openDialog(tester, width: width, files: files, results: results);

      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      final field = find.widgetWithText(TextField, 'JSON-Spielstand');
      expect(tester.widget<TextField>(field).minLines, 3);
      await tester.ensureVisible(field);
      await tester.enterText(field, '{"held":"Prüfheld"}');
      await tester.pumpAndSettle();

      expect(results, isEmpty);
      final confirm = _button('Importieren');
      expect(confirm.hitTestable(), findsOneWidget);
      await _tapVisible(tester, confirm);
      expect(results, ['{"held":"Prüfheld"}']);
      expect(files.openCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Import $width dp: Abbruch verwirft nur die Dialogauswahl', (
      tester,
    ) async {
      final files = _FakeBackupFiles();
      final results = <String?>[];
      await _openDialog(tester, width: width, files: files, results: results);
      final field = find.widgetWithText(TextField, 'JSON-Spielstand');
      await tester.ensureVisible(field);
      await tester.enterText(field, 'unfertiger Entwurf');
      await tester.pumpAndSettle();

      expect(results, isEmpty);
      await _tapVisible(tester, _button('Abbrechen'));
      expect(results, [null]);
      expect(files.openCalls, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp: Dateiauswahl abbrechen erhält getippten JSON-Entwurf', (
    tester,
  ) async {
    final pending = Completer<String?>();
    final files = _FakeBackupFiles()..open = () => pending.future;
    final results = <String?>[];
    await _openDialog(tester, width: 320, files: files, results: results);

    final field = find.widgetWithText(TextField, 'JSON-Spielstand');
    await tester.ensureVisible(field);
    await tester.enterText(field, '{"entwurf":true}');
    await tester.pumpAndSettle();
    // A deliberately pending picker keeps the progress indicator animating.
    // Pump one frame rather than waiting for every animation to settle.
    await tester.ensureVisible(_button('Datei wählen'));
    await tester.pumpAndSettle();
    await tester.tap(_button('Datei wählen'));
    await tester.pump();

    expect(files.openCalls, 1);
    expect(tester.widget<TextField>(field).readOnly, isTrue);
    expect(
      tester.widget<FantasyTextButton>(_button('Importieren')).onPressed,
      isNull,
    );
    expect(
      tester.widget<FantasyTextButton>(_button('Abbrechen')).onPressed,
      isNull,
    );
    expect(results, isEmpty);

    pending.complete(null);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field).controller!.text,
      '{"entwurf":true}',
    );
    expect(find.textContaining('Dateiauswahl abgebrochen'), findsOneWidget);
    await _tapVisible(tester, _button('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp: Dateifehler wird vorgelesen, Text bleibt erhalten', (
    tester,
  ) async {
    final files = _FakeBackupFiles()
      ..open = () async =>
          throw const BackupFileException('Datei nicht verfügbar.');
    final results = <String?>[];
    await _openDialog(tester, width: 360, files: files, results: results);

    final field = find.widgetWithText(TextField, 'JSON-Spielstand');
    await tester.ensureVisible(field);
    await tester.enterText(field, 'mein Entwurf');
    await tester.pumpAndSettle();
    await _tapVisible(tester, _button('Datei wählen'));

    expect(find.text('Datei nicht verfügbar.'), findsOneWidget);
    expect(
      tester
          .widgetList<Semantics>(
            find.ancestor(
              of: find.text('Datei nicht verfügbar.'),
              matching: find.byType(Semantics),
            ),
          )
          .any((widget) => widget.properties.liveRegion ?? false),
      isTrue,
    );
    expect(tester.widget<TextField>(field).controller!.text, 'mein Entwurf');
    expect(results, isEmpty);
    await _tapVisible(tester, _button('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });
}
