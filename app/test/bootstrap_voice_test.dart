import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart' as sqlite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  testWidgets(
    'local home opens while the native voice enumeration is pending',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('living-gm-boot-'),
      ))!;
      final factory = createDatabaseFactoryFfi();
      await tester.runAsync(() => factory.setDatabasesPath(directory.path));
      final original = sqlite.databaseFactoryOrNull;
      sqlite.databaseFactoryOrNull = factory;
      const ttsChannel = MethodChannel('flutter_tts');
      final queried = Completer<void>();
      final nativeVoices = Completer<List<Map<String, String>>>();
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        ttsChannel,
        (call) async {
          calls.add(call.method);
          if (call.method == 'getVoices') {
            if (!queried.isCompleted) queried.complete();
            return nativeVoices.future;
          }
          if (call.method == 'getDefaultEngine') return 'test.android.tts';
          return 1;
        },
      );
      addTearDown(() async {
        if (!nativeVoices.isCompleted) nativeVoices.complete([]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() async {
          await factory.deleteDatabase(
            paths.join(directory.path, 'living_gm.sqlite'),
          );
        });
        sqlite.databaseFactoryOrNull = original;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          ttsChannel,
          null,
        );
        await tester.runAsync(() => directory.delete(recursive: true));
      });

      await tester.pumpWidget(const BootstrapApp());
      // SQLite uses filesystem/isolate work, while boot began in FakeAsync.
      // Alternate real I/O time with frame/microtask pumps instead of waiting
      // on a native callback without draining the widget-test zone.
      for (var attempt = 0; attempt < 200 && !queried.isCompleted; attempt++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(queried.isCompleted, isTrue);
      await tester.pump();
      expect(nativeVoices.isCompleted, isFalse);
      expect(find.text('Das Abenteuer erwacht …'), findsNothing);
      expect(find.text('Kostenlose Demo starten'), findsOneWidget);
      expect(calls, contains('getVoices'));
      expect(tester.takeException(), isNull);

      nativeVoices.complete([
        {'name': 'German test voice', 'locale': 'de-DE'},
      ]);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Einstellungen'));
      await tester.pumpAndSettle();
      expect(
        find.text('Sprachausgabe: Anbieter meldet Deutsch'),
        findsOneWidget,
      );
      expect(find.text('Sprachdienst: test.android.tts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
