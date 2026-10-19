import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_experience.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Neue Fantasy-Oberfläche passt auf $width dp', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: FantasyBackdrop(
              child: ListView(
                children: [
                  const FantasyBrandPlaque(),
                  const FantasyChapterHeading(
                    label: 'Deine Reisen',
                    rune: FantasyRune.compass,
                  ),
                  const FantasyJourneyCard(
                    title: 'Rabenwacht',
                    description: 'Ein Soloabenteuer',
                    image: FantasyArtwork.ruins,
                    rune: FantasyRune.dice,
                    onTap: null,
                  ),
                  const FantasyIllustratedBanner(
                    image: FantasyArtwork.forgottenWoods,
                    eyebrow: 'Deine Chronik',
                    title: 'Das Abenteuer',
                    description: 'Alle gespeicherten Ereignisse',
                    height: 145,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Würfelraunen'), findsOneWidget);
      expect(find.text('Rabenwacht'), findsOneWidget);
      expect(find.byType(FantasyRuneEmblem), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Alle sechs neuen Vektor-Grafiken sind zeichnbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final rune in FantasyRune.values)
                FantasyRuneEmblem(rune: rune, size: 64),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byType(FantasyRuneEmblem),
      findsNWidgets(FantasyRune.values.length),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Illustrierte Abenteuerkarte reagiert auf Berührung', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FantasyJourneyCard(
              title: 'Heldengalerie',
              description: 'Charaktere öffnen',
              image: FantasyArtwork.castle,
              rune: FantasyRune.hero,
              onTap: () => opened++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heldengalerie'));
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });
}
