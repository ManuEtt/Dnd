import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_experience.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  testWidgets('Alle sechs Runen besitzen ein zeichnbares Auswahlmedaillon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: Wrap(
            children: [
              for (final rune in FantasyRune.values)
                FantasySelectedNavigationRune(rune: rune, size: 32),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(FantasySelectedNavigationRune), findsNWidgets(6));
    expect(find.byType(ExcludeSemantics), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 960.0]) {
    testWidgets('Auswahlmedaillon bleibt bei $width dp skalierbar', (
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
            body: Center(
              child: FantasySelectedNavigationRune(
                key: const ValueKey('rune-selected'),
                rune: FantasyRune.dice,
                size: width < 400 ? 26 : 36,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('rune-selected')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
