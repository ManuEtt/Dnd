import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_approved_icons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Freigegebene Fantasy-Atlanten sind gültige Offline-Assets', () async {
    for (final file in [
      'night_sky.webp.b64',
      'portrait_atlas.webp.b64',
      'ui_icon_atlas.webp.b64',
    ]) {
      final text = await rootBundle.loadString('assets/fantasy/$file');
      final bytes = base64Decode(text.trim());
      final native = await rootBundle.load(
        'assets/fantasy/${file.substring(0, file.length - 4)}',
      );
      final binary = Uint8List.sublistView(native);
      expect(binary, bytes, reason: 'Native WebP und Textatlas unterscheiden sich: $file');
      expect(bytes, isNotEmpty, reason: file);
      // The approved artwork is stored as base64-encoded WebP (RIFF).
      expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF', reason: file);
      expect(ascii.decode(bytes.sublist(8, 12)), 'WEBP', reason: file);
    }
  });

  testWidgets('Schnellaktionen zeigen die echten Fantasy-Symbole', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FantasyPinnedActionBar(
            busy: false,
            listening: false,
            onSpeech: () {},
            onInspect: () {},
            onAttack: () {},
            onRoll: () {},
          ),
        ),
      ),
    );
    expect(find.byType(FantasyApprovedIcon), findsNWidgets(3));
    expect(find.byKey(const ValueKey('adventure-shortcut-attack')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('adventure-shortcut-roll')),
        findsOneWidget);
  });

  testWidgets('Fantasy-Hintergrund erhält den Vordergrund', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FantasyBackdrop(
            child: Center(child: Text('Inhalt bleibt sichtbar')),
          ),
        ),
      ),
    );
    expect(find.text('Inhalt bleibt sichtbar'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
