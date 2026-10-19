import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/character_portrait_picker.dart';

void main() {
  test('Alle vier neuen Originalrahmen haben feste Ressourcennamen', () {
    expect(FantasyGraphicAssets.panel,
        'assets/fantasy/ornate_panel_background.webp');
    expect(FantasyGraphicAssets.card,
        'assets/fantasy/ornate_card_background.webp');
    expect(FantasyGraphicAssets.button,
        'assets/fantasy/ornate_button_background.webp');
    expect(FantasyGraphicAssets.portraitBorder,
        'assets/fantasy/ornate_portrait_border.webp');
  });

  testWidgets('Fehlende Originalrahmen verdecken keine Schaltflächen', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyOptionalArtBackground(
              asset: 'assets/fantasy/nicht_vorhanden.webp',
              centerSlice: const Rect.fromLTWH(10, 10, 20, 20),
              foreground: true,
              child: FilledButton(
                onPressed: () => taps++,
                child: const Text('Aktion'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aktion'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Originalrahmen halten Schnellaktionen bedienbar', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyShortcutTile(
              label: 'Würfeln',
              icon: Icons.casino_outlined,
              color: FantasyPalette.gold,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Würfeln'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Porträt-Auswahl funktioniert auch bei fehlenden Originalen', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyCharacterPortrait(
              preset: 6,
              photoBase64: '',
              size: 100,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FantasyCharacterPortrait), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
