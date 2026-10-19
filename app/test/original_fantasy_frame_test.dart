import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/character_portrait_picker.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Die echte Goldverzierung wird offline als WebP ausgeliefert', () async {
    final bytes = await rootBundle.load(
      'assets/fantasy/ornate_gold_corner.webp',
    );
    final data = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    expect(data.length, greaterThan(500));
    expect(ascii.decode(data.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(data.sublist(8, 12)), 'WEBP');
  });

  testWidgets('Rahmen zeigen vier Original-Ecken ohne Aktionen zu blockieren', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyPanel(
              child: FilledButton(
                onPressed: () => tapped = true,
                child: const Text('Beginnen'),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('approved-corner-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('approved-corner-3')), findsOneWidget);
    await tester.tap(find.text('Beginnen'));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schnellaktion bleibt trotz Original-Rahmen bedienbar', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyShortcutTile(
              label: 'Untersuchen',
              icon: Icons.search,
              color: FantasyPalette.gold,
              onTap: () => presses++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Untersuchen'));
    expect(presses, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Charakterbildauswahl passt auch auf schmale Android-Displays', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CharacterPortraitPicker(initialPreset: 0, initialPhotoBase64: ''),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('portrait-current-preview')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('portrait-own-image')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
