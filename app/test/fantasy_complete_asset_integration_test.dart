import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/character_portrait_picker.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  test('Vollstaendiges Grafikpaket hat vier eindeutige Rahmentypen', () {
    expect(FantasyOptionalArt.panel, contains('ornate_panel_background.webp'));
    expect(
      FantasyOptionalArt.button,
      contains('ornate_button_background.webp'),
    );
    expect(FantasyOptionalArt.card, contains('ornate_card_background.webp'));
    expect(
      FantasyOptionalArt.portrait,
      contains('ornate_portrait_border.webp'),
    );
  });

  testWidgets('Auch ohne optionale Grafik bleibt ein Panel bedienbar', (
    tester,
  ) async {
    var clicks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyPanel(
              title: 'Kampagne',
              child: FilledButton(
                onPressed: () => clicks++,
                child: const Text('Spielen'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FantasyOptionalImageFrame), findsOneWidget);
    await tester.tap(find.text('Spielen'));
    expect(clicks, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Original-Buttonrahmen blockiert keine Schnellaktion', (
    tester,
  ) async {
    var clicks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyShortcutTile(
              label: 'W20',
              icon: Icons.casino_outlined,
              color: FantasyPalette.gold,
              approvedIconIndex: 7,
              onTap: () => clicks++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FantasyOptionalImageFrame), findsOneWidget);
    await tester.tap(find.text('W20'));
    expect(clicks, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Portraet-Rahmen wird nur als Dekoration aufgelegt', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyCharacterPortrait(
              preset: -1,
              photoBase64: '',
              size: 120,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final frames = tester.widgetList<FantasyOptionalImageFrame>(
      find.byType(FantasyOptionalImageFrame),
    );
    expect(frames, hasLength(1));
    expect(frames.first.foreground, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fehlende Rahmendatei wirft keine Bild-Ausnahme', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FantasyOptionalImageFrame(
            image: 'assets/fantasy/absent_custom_frame.webp',
            child: Text('Weiterhin spielbar'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Weiterhin spielbar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
