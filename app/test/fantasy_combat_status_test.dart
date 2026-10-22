import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_status.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Deckung und Aktionsstatus bleiben bei $width dp lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 860);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                FantasyCombatCoverPanel(
                  heroCover: CoverLevel.threeQuarters,
                  enemyCover: CoverLevel.half,
                  canChange: true,
                  onAction: (_) {},
                ),
                const SizedBox(height: 12),
                const FantasyCombatActionEconomy(
                  actionUsed: true,
                  bonusActionUsed: false,
                  reactionUsed: true,
                  movementRemainingLabel: '6 m',
                  spellSlotExpendedThisTurn: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Held: Dreivierteldeckung'), findsOneWidget);
      expect(find.text('Gegner: halbe Deckung'), findsOneWidget);
      expect(find.text('Aktion: verbraucht'), findsOneWidget);
      expect(find.text('Bonusaktion: verfügbar'), findsOneWidget);
      expect(find.text('Reaktion: verbraucht'), findsOneWidget);
      expect(find.text('Bewegung: 6 m'), findsOneWidget);
      expect(find.text('Zauberplatz: in diesem Zug verbraucht'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Deckungsmenü sendet nur bestätigten SRD-Befehl', (
    tester,
  ) async {
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: FantasyCombatCoverPanel(
            heroCover: CoverLevel.none,
            enemyCover: CoverLevel.none,
            canChange: true,
            onAction: actions.add,
          ),
        ),
      ),
    );

    final heroCover = find.byKey(const ValueKey('combat-hero-cover'));
    expect(tester.widget<PopupMenuButton<CoverLevel>>(heroCover).enabled, true);
    await tester.tap(heroCover);
    await tester.pumpAndSettle();
    await tester.tap(find.text('halbe Deckung').last);
    await tester.pumpAndSettle();
    expect(actions, ['Deckung: Held halb']);

    final enemyCover = find.byKey(const ValueKey('combat-enemy-cover'));
    await tester.tap(enemyCover);
    await tester.pumpAndSettle();
    await tester.tap(find.text('vollständige Deckung').last);
    await tester.pumpAndSettle();
    expect(actions, ['Deckung: Held halb', 'Deckung: Gegner voll']);
    expect(find.text('Held: keine Deckung'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Deckungsmenüs sind im Gegnerzug gesperrt', (tester) async {
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: FantasyCombatCoverPanel(
            heroCover: CoverLevel.none,
            enemyCover: CoverLevel.total,
            canChange: false,
            onAction: actions.add,
          ),
        ),
      ),
    );
    final heroCover = tester.widget<PopupMenuButton<CoverLevel>>(
      find.byKey(const ValueKey('combat-hero-cover')),
    );
    final enemyCover = tester.widget<PopupMenuButton<CoverLevel>>(
      find.byKey(const ValueKey('combat-enemy-cover')),
    );
    expect(heroCover.enabled, false);
    expect(enemyCover.enabled, false);
    expect(actions, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Freie Aktionen zeigen keine erfundenen Restwerte', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: const Scaffold(
          body: FantasyCombatActionEconomy(
            actionUsed: false,
            bonusActionUsed: false,
            reactionUsed: false,
            movementRemainingLabel: 'nicht bestätigt',
            spellSlotExpendedThisTurn: false,
          ),
        ),
      ),
    );
    expect(find.text('Aktion: verfügbar'), findsOneWidget);
    expect(find.text('Reaktion: verfügbar'), findsOneWidget);
    expect(find.text('Bewegung: nicht bestätigt'), findsOneWidget);
    expect(find.textContaining('Zauberplatz:'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
