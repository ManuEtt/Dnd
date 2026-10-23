import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_landscape.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0, 1024.0]) {
    testWidgets('Neue Fantasy-Landschaft bleibt bei $width dp bedienbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var pressed = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: FantasyBackdrop(
              child: Center(
                child: FilledButton(
                  onPressed: () => pressed++,
                  child: const Text('Abenteuer starten'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FantasyMoonlitScenery), findsOneWidget);
      await tester.tap(find.text('Abenteuer starten'));
      expect(pressed, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Charakterbogen verwendet eigene Heldenkulisse', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final hero = HeroCharacter(
      id: 'moonlit-ui-test',
      name: 'Testheld',
      level: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: CharacterSheetPage(hero: hero),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fantasy-backdrop-heroes')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fantasy-backdrop-art-heroes')),
      findsOneWidget,
    );
    expect(find.byType(FantasyMoonlitScenery), findsNothing);
    expect(find.text('Testheld'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
