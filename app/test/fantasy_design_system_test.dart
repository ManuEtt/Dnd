import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  test(
    'Dark-Fantasy-Palette ist für Hauptansichten und Dialoge einheitlich',
    () {
      final theme = buildFantasyTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, FantasyPalette.night);
      expect(theme.colorScheme.primary, FantasyPalette.gold);
      expect(theme.cardTheme.color, FantasyPalette.surface);
      expect(theme.appBarTheme.backgroundColor, FantasyPalette.ink);
      expect(theme.dialogTheme.backgroundColor, FantasyPalette.ink);
      expect(theme.navigationBarTheme.backgroundColor, FantasyPalette.ink);
    },
  );

  for (final width in [320.0, 360.0, 1000.0]) {
    testWidgets('Fantasy-Komponenten bleiben bei $width px zugänglich', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: FantasyBackdrop(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: const [
                  FantasySectionTitle(
                    title: 'Kampagnen',
                    icon: Icons.auto_stories,
                  ),
                  FantasyPanel(
                    title: 'Chronik',
                    icon: Icons.menu_book,
                    child: Text('Bestätigte Ereignisse'),
                  ),
                  FantasyStatTile(
                    icon: Icons.favorite,
                    title: 'Trefferpunkte',
                    value: 'TP ?/?',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Kampagnen'), findsOneWidget);
      expect(find.text('Chronik'), findsOneWidget);
      expect(find.text('TP ?/?'), findsOneWidget);
      expect(find.text('Bestätigte Ereignisse'), findsOneWidget);
    });
  }
}
