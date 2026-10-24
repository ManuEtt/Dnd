import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  test('Jede vorhandene Hauptansicht besitzt eine eigene Art-Zuordnung', () {
    expect(FantasyBackdropArtwork.imageFor(FantasyBackdropScene.home), isNull);
    expect(
      FantasyBackdropArtwork.imageFor(FantasyBackdropScene.adventure),
      'assets/art/shadow_forest.webp',
    );
    expect(
      FantasyBackdropArtwork.imageFor(FantasyBackdropScene.combat),
      'assets/art/blood_mountains.webp',
    );
    expect(
      FantasyBackdropArtwork.imageFor(FantasyBackdropScene.heroes),
      'assets/art/castle.webp',
    );
    expect(
      FantasyBackdropArtwork.imageFor(FantasyBackdropScene.journal),
      'assets/art/forgotten_woods.webp',
    );
    expect(
      FantasyBackdropArtwork.imageFor(FantasyBackdropScene.settings),
      'assets/fantasy/night_sky.webp',
    );
  });

  for (final scene in FantasyBackdropScene.values) {
    testWidgets('${scene.name}: Hintergrund blockiert keine Aktion', (
      tester,
    ) async {
      var clicks = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: FantasyBackdrop(
              scene: scene,
              child: Center(
                child: FilledButton(
                  onPressed: () => clicks++,
                  child: const Text('Aktion ausführen'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey('fantasy-backdrop-${scene.name}')),
        findsOneWidget,
      );
      if (scene == FantasyBackdropScene.home) {
        expect(
          find.byKey(const ValueKey('fantasy-backdrop-art-home')),
          findsNothing,
        );
      } else {
        expect(
          find.byKey(ValueKey('fantasy-backdrop-art-${scene.name}')),
          findsOneWidget,
        );
      }
      await tester.tap(find.text('Aktion ausführen'));
      await tester.pump();
      expect(clicks, 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final material in FantasyPanelMaterial.values) {
    testWidgets('${material.name}: Materialpanel bleibt bedienbar', (
      tester,
    ) async {
      var clicked = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: Center(
              child: FantasyPanel(
                material: material,
                title: 'Kampagnenchronik',
                child: TextButton(
                  onPressed: () => clicked = true,
                  child: const Text('Öffnen'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kampagnenchronik'), findsOneWidget);
      await tester.tap(find.text('Öffnen'));
      expect(clicked, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
