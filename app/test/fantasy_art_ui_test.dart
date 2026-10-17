import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Alle neuen Fantasy-Illustrationen sind als echte App-Assets vorhanden',
    () async {
      for (final path in <String>[
        FantasyArtwork.ruins,
        FantasyArtwork.castle,
        FantasyArtwork.shadowForest,
        FantasyArtwork.bloodMountains,
        FantasyArtwork.forgottenWoods,
        FantasyArtwork.sword,
        FantasyArtwork.shield,
        FantasyArtwork.potion,
        FantasyArtwork.book,
        FantasyArtwork.bag,
        FantasyArtwork.scroll,
        FantasyArtwork.crystal,
      ]) {
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(100), reason: path);
      }
    },
  );

  test('Illustrationen erzeugen keine erfundenen Inventardaten', () {
    expect(FantasyArtwork.inventoryItem('Altes Schwert'), FantasyArtwork.sword);
    expect(FantasyArtwork.inventoryItem('Heiltrank'), FantasyArtwork.potion);
    expect(FantasyArtwork.inventoryItem('Ein rätselhafter Stein'), isNull);
    expect(FantasyArtwork.campaign(3), FantasyArtwork.shadowForest);
  });

  for (final width in [320.0, 360.0, 400.0, 950.0]) {
    testWidgets('Illustrative Banner und Aktionskarte passen bei $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                FantasyIllustratedBanner(
                  image: FantasyArtwork.ruins,
                  eyebrow: 'Kampagne fortsetzen',
                  title: 'Der Schattenwald',
                  description:
                      'Eine lange Abenteuergeschichte in deutscher Sprache.',
                  actionLabel: 'Fortsetzen',
                  onPressed: () => taps++,
                ),
                const SizedBox(height: 12),
                FantasyShortcutTile(
                  label: 'Untersuchen',
                  icon: Icons.search,
                  color: FantasyPalette.blue,
                  onTap: () => taps++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Fortsetzen'));
      expect(taps, 1);
    });
  }

  testWidgets('Inventar zeigt nur gespeicherte Gegenstände und ihre Anzahl', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: ListView(
            children: [
              FantasyInventoryCards(
                items: const [
                  InventoryItem(
                    id: 's',
                    name: 'Silberklinge',
                    quantity: 2,
                    description: 'Ein bestätigter Fund.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Silberklinge'), findsOneWidget);
    expect(find.text('× 2'), findsOneWidget);
    expect(find.text('Ring der Beredsamkeit'), findsNothing);
    await tester.tap(find.text('Silberklinge'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ein bestätigter Fund.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
