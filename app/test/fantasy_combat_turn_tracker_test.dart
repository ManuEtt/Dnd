import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_turn_tracker.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  Widget timeline({
    int round = 2,
    int heroInitiative = 18,
    int enemyInitiative = 11,
    String active = 'hero',
    bool finished = false,
    double textScale = 1,
  }) => MaterialApp(
    theme: buildFantasyTheme(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FantasyCombatTurnTracker(
            round: round,
            heroName: 'Elowen die Wanderin',
            enemyName: 'Schattenwächter des vergessenen Passes',
            heroInitiative: heroInitiative,
            enemyInitiative: enemyInitiative,
            activeParticipant: active,
            isFinished: finished,
          ),
        ],
      ),
    ),
  );

  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Zugfolge bleibt bei $width dp ohne Überlauf sichtbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(timeline());
      await tester.pumpAndSettle();

      expect(find.text('Runde 2 · Zugfolge'), findsOneWidget);
      expect(find.byKey(const ValueKey('combat-turn-hero')), findsOneWidget);
      expect(find.byKey(const ValueKey('combat-turn-enemy')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('turn-tracker-active-marker')),
        findsOneWidget,
      );
      expect(find.text('INI 18'), findsOneWidget);
      expect(find.text('INI 11'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Aktiver Gegner wird korrekt markiert, Initiative bleibt gleich',
    (tester) async {
      await tester.pumpWidget(timeline(active: 'enemy'));
      await tester.pumpAndSettle();

      final marker = find.byKey(const ValueKey('turn-tracker-active-marker'));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('combat-turn-enemy')),
          matching: marker,
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('combat-turn-hero')),
          matching: marker,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Nicht bestätigte Initiative wird nie als Zugfolge erfunden', (
    tester,
  ) async {
    await tester.pumpWidget(
      timeline(heroInitiative: 0, enemyInitiative: 0, active: 'enemy'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Initiative noch nicht vollständig bestätigt'),
      findsOneWidget,
    );
    expect(find.text('INI ?'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gleichstand meldet Unklarheit statt erfundener Priorität', (
    tester,
  ) async {
    await tester.pumpWidget(
      timeline(heroInitiative: 15, enemyInitiative: 15, active: 'enemy'),
    );
    expect(
      find.text('Initiative-Gleichstand: aktiver Zug ist maßgeblich'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Beendeter Kampf zeigt keinen aktiven Zug', (tester) async {
    await tester.pumpWidget(timeline(finished: true));
    expect(find.text('Begegnung beendet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('turn-tracker-active-marker')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zuganzeige übernimmt bestätigten Rundenwechsel', (tester) async {
    await tester.pumpWidget(timeline());
    expect(find.text('Runde 2 · Zugfolge'), findsOneWidget);

    await tester.pumpWidget(timeline(round: 3, active: 'enemy'));
    await tester.pumpAndSettle();

    expect(find.text('Runde 3 · Zugfolge'), findsOneWidget);
    expect(find.text('Runde 2 · Zugfolge'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('Kampfzugfolge bei $width dp und 200 % vollständig lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(timeline(textScale: 2));
      await tester.pumpAndSettle();

      final heroName = find.text('Elowen die Wanderin');
      final enemyName = find.text('Schattenwächter des vergessenen Passes');
      expect(tester.widget<Text>(heroName).maxLines, isNull);
      expect(tester.widget<Text>(enemyName).maxLines, isNull);
      expect(
        tester.getTopLeft(find.text('INI 18')).dy,
        greaterThan(tester.getBottomLeft(heroName).dy),
      );
      expect(
        tester.getTopLeft(find.text('INI 11')).dy,
        greaterThan(tester.getBottomLeft(enemyName).dy),
      );
      expect(
        find.bySemanticsLabel(
          'Held: Elowen die Wanderin. Initiative 18. Jetzt am Zug.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Gegner: Schattenwächter des vergessenen Passes. '
          'Initiative 11. Nicht am Zug.',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('turn-tracker-active-marker')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('Unbekannte Initiative bleibt bei 200 % unbestätigt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      timeline(
        heroInitiative: 0,
        enemyInitiative: 0,
        active: 'enemy',
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Initiative noch nicht vollständig bestätigt'),
      findsOneWidget,
    );
    expect(find.text('INI ?'), findsNWidgets(2));
    expect(
      find.bySemanticsLabel(
        'Gegner: Schattenwächter des vergessenen Passes. '
        'Initiative unbekannt. Jetzt am Zug.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Held: Elowen die Wanderin. Initiative unbekannt. Nicht am Zug.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('combat-turn-enemy'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('combat-turn-hero'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Beendeter Kampf zeigt bei 200 % keinen aktiven Zug', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(timeline(finished: true, textScale: 2));
    await tester.pumpAndSettle();
    expect(find.text('Begegnung beendet'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('turn-tracker-active-marker')),
      findsNothing,
    );
    expect(
      find.bySemanticsLabel(
        'Held: Elowen die Wanderin. Initiative 18. Begegnung beendet.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
