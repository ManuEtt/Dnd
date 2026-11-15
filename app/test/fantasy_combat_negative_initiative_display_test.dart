import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_turn_tracker.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const _heroName = 'Elowen die Wanderin';
const _enemyName = 'Schattenwächter des vergessenen Passes';

Widget _screen({
  required int heroInitiative,
  required int enemyInitiative,
  String active = 'hero',
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
      children: [
        FantasyCombatTurnTracker(
          round: 2,
          heroName: _heroName,
          enemyName: _enemyName,
          heroInitiative: heroInitiative,
          enemyInitiative: enemyInitiative,
          activeParticipant: active,
          isFinished: false,
        ),
      ],
    ),
  ),
);

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Negative Initiative bei $width dp und 200 % lesbar und sortiert',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final semantics = tester.ensureSemantics();
        addTearDown(semantics.dispose);

        await tester.pumpWidget(
          _screen(
            heroInitiative: -2,
            enemyInitiative: -6,
            textScale: 2,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('INI -2'), findsOneWidget);
        expect(find.text('INI -6'), findsOneWidget);
        expect(
          find.text('Initiative noch nicht vollständig bestätigt'),
          findsNothing,
        );
        expect(
          find.text('Initiative-Gleichstand: aktiver Zug ist maßgeblich'),
          findsNothing,
        );
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('combat-turn-hero'))).dy,
          lessThan(
            tester.getTopLeft(find.byKey(const ValueKey('combat-turn-enemy')))
                .dy,
          ),
        );
        expect(
          find.bySemanticsLabel(
            'Held: $_heroName. Initiative -2. Jetzt am Zug.',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'Gegner: $_enemyName. Initiative -6. Nicht am Zug.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Negativer Gegnerwert bestimmt die Reihenfolge, nicht den Zug', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(heroInitiative: -9, enemyInitiative: -3),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey('combat-turn-enemy'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('combat-turn-hero'))).dy,
      ),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('combat-turn-hero')),
        matching: find.byKey(const ValueKey('turn-tracker-active-marker')),
      ),
      findsOneWidget,
    );
    expect(find.text('INI -9'), findsOneWidget);
    expect(find.text('INI -3'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Negativer Gleichstand bleibt ungeklärt', (tester) async {
    await tester.pumpWidget(
      _screen(heroInitiative: -4, enemyInitiative: -4, active: 'enemy'),
    );

    expect(
      find.text('Initiative-Gleichstand: aktiver Zug ist maßgeblich'),
      findsOneWidget,
    );
    expect(find.text('INI -4'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('combat-turn-enemy'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('combat-turn-hero'))).dy,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Legacy-Null bleibt unbekannt, negative Gegenzahl sichtbar', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(
      _screen(heroInitiative: 0, enemyInitiative: -3, active: 'enemy'),
    );

    expect(
      find.text('Initiative noch nicht vollständig bestätigt'),
      findsOneWidget,
    );
    expect(find.text('INI ?'), findsOneWidget);
    expect(find.text('INI -3'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Held: $_heroName. Initiative unbekannt. Nicht am Zug.',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Gegner: $_enemyName. Initiative -3. Jetzt am Zug.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
