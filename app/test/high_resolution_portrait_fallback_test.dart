import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/character_portrait_picker.dart';

void main() {
  test('Preset-Indices 0 bis 8 passen zu den neun Originaldateien', () {
    for (var i = 0; i < 9; i++) {
      expect(
        FantasyApprovedAssets.highResolutionPortraitPath(i),
        'assets/fantasy/portrait_${i + 1}.webp',
      );
    }
  });

  testWidgets('Ohne Einzelportraets bleibt der alte Bildatlas verwendbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyCharacterPortrait(
              preset: 3,
              photoBase64: '',
              size: 96,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FantasyCharacterPortrait), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Eigene Portraetdaten behalten Vorrang vor Presets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FantasyCharacterPortrait(
            preset: 1,
            photoBase64: 'ungueltige-bilddaten',
            size: 96,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
