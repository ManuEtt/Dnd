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
      expect(
        find.text('Zauberplatz: in diesem Zug verbraucht'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Deckungsmenü sendet nur bestätigten SRD-Befehl', (tester) async {
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

  for (final width in [320.0, 360.0]) {
    testWidgets('Deckung bei $width dp und 200 % vollständig auswählbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final actions = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: [
                FantasyCombatCoverPanel(
                  heroCover: CoverLevel.threeQuarters,
                  enemyCover: CoverLevel.half,
                  canChange: true,
                  onAction: actions.add,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final heroText = find.text('Held: Dreivierteldeckung');
      final enemyText = find.text('Gegner: halbe Deckung');
      expect(tester.widget<Text>(heroText).maxLines, isNull);
      expect(tester.widget<Text>(enemyText).maxLines, isNull);
      final heroControl = find.byKey(const ValueKey('combat-hero-cover'));
      final enemyControl = find.byKey(const ValueKey('combat-enemy-cover'));
      expect(
        tester.getTopLeft(enemyControl).dx,
        closeTo(tester.getTopLeft(heroControl).dx, 1),
      );
      expect(
        tester.getTopLeft(enemyControl).dy,
        greaterThan(tester.getBottomLeft(heroControl).dy),
      );
      expect(
        find.bySemanticsLabel(
          'Deckung für Held: Dreivierteldeckung. Änderbar.',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Deckung für Gegner: halbe Deckung. Änderbar.'),
        findsOneWidget,
      );

      await tester.tap(heroControl);
      await tester.pumpAndSettle();
      await tester.tap(find.text('vollständige Deckung').last);
      await tester.pumpAndSettle();
      expect(actions, ['Deckung: Held voll']);
      expect(find.text('Held: Dreivierteldeckung'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('Gesperrte Deckung bleibt bei 200 % nicht änderbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: ListView(
            children: [
              FantasyCombatCoverPanel(
                heroCover: CoverLevel.none,
                enemyCover: CoverLevel.total,
                canChange: false,
                onAction: actions.add,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final hero = find.byKey(const ValueKey('combat-hero-cover'));
    final enemy = find.byKey(const ValueKey('combat-enemy-cover'));
    expect(tester.widget<PopupMenuButton<CoverLevel>>(hero).enabled, false);
    expect(tester.widget<PopupMenuButton<CoverLevel>>(enemy).enabled, false);
    expect(
      find.bySemanticsLabel('Deckung für Held: keine Deckung. Nicht änderbar.'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Deckung für Gegner: vollständige Deckung. Nicht änderbar.',
      ),
      findsOneWidget,
    );
    expect(find.text('Held: keine Deckung'), findsOneWidget);
    expect(find.text('Gegner: vollständige Deckung'), findsOneWidget);
    await tester.tap(hero);
    await tester.pumpAndSettle();
    expect(find.text('halbe Deckung'), findsNothing);
    expect(actions, isEmpty);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
