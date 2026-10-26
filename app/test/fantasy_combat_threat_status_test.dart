import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_threat_status.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  Widget screen({
    int attacks = 3,
    int remaining = 2,
    String participant = 'enemy',
    bool pendingShield = false,
    bool heroShield = false,
    bool enemyShield = false,
    bool enemyReactionUsed = false,
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
          FantasyCombatThreatStatus(
            enemyAttacksPerTurn: attacks,
            enemyAttacksRemaining: remaining,
            activeParticipant: participant,
            pendingShieldDecision: pendingShield,
            heroShieldActive: heroShield,
            enemyShieldActive: enemyShield,
            enemyShieldReactionUsed: enemyReactionUsed,
            isFinished: finished,
          ),
        ],
      ),
    ),
  );

  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Mehrfachangriffe auf $width dp ohne Textüberlauf', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 820);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        screen(
          pendingShield: true,
          heroShield: true,
          enemyShield: true,
          enemyReactionUsed: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 bestätigte Angriffe je Gegnerzug'), findsOneWidget);
      expect(find.text('2 weitere Gegnerangriffe'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('combat-pending-shield')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('combat-hero-shield-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('combat-enemy-shield-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('combat-enemy-reaction-used')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Standardwert ist nicht fälschlich als Mehrfachangriff markiert',
    (tester) async {
      await tester.pumpWidget(
        screen(attacks: 1, remaining: 0, participant: 'hero'),
      );
      expect(
        find.text(
          '1 Gegnerangriff (Standardwert; kein Mehrfachangriff bestätigt)',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('combat-no-pending-threat')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('combat-remaining-attacks')),
        findsNothing,
      );
    },
  );

  testWidgets('Restliche Gegnerangriffe werden nur im Gegnerzug angezeigt', (
    tester,
  ) async {
    await tester.pumpWidget(screen(participant: 'hero', remaining: 2));
    expect(find.text('3 bestätigte Angriffe je Gegnerzug'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('combat-remaining-attacks')),
      findsNothing,
    );

    await tester.pumpWidget(screen(participant: 'enemy', remaining: 2));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('combat-remaining-attacks')),
      findsOneWidget,
    );
  });

  testWidgets('Schildentscheidung zeigt ausstehenden Schaden als offen', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(participant: 'enemy', pendingShield: true, remaining: 1),
    );
    expect(
      find.text('Schildentscheidung offen – Schaden nicht gewürfelt'),
      findsOneWidget,
    );
    expect(find.text('1 weiterer Gegnerangriff'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Beendete Begegnung blendet Angriffe und Reaktionen aus', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(
        finished: true,
        pendingShield: true,
        heroShield: true,
        enemyShield: true,
        enemyReactionUsed: true,
      ),
    );
    expect(
      find.byKey(const ValueKey('combat-threat-finished')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('combat-pending-shield')), findsNothing);
    expect(
      find.byKey(const ValueKey('combat-remaining-attacks')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('combat-hero-shield-active')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('combat-enemy-shield-active')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('combat-enemy-reaction-used')),
      findsNothing,
    );
  });

  testWidgets('Status reagiert auf bestätigte Änderungen ohne Regelaktionen', (
    tester,
  ) async {
    await tester.pumpWidget(screen(remaining: 2));
    expect(find.text('2 weitere Gegnerangriffe'), findsOneWidget);
    await tester.pumpWidget(screen(remaining: 1, heroShield: true));
    await tester.pumpAndSettle();
    expect(find.text('1 weiterer Gegnerangriff'), findsOneWidget);
    expect(find.text('2 weitere Gegnerangriffe'), findsNothing);
    expect(find.text('Schild des Helden aktiv'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 360.0]) {
    testWidgets('200 %: einzelne Kampfhinweise auf $width dp vorlesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        screen(
          textScale: 2,
          pendingShield: true,
          heroShield: true,
          enemyShield: true,
          enemyReactionUsed: true,
        ),
      );
      await tester.pumpAndSettle();

      const labels = [
        'Gegnerzug läuft',
        '2 weitere Gegnerangriffe',
        'Schildentscheidung offen – Schaden nicht gewürfelt',
        'Schild des Helden aktiv',
        'Gegnerschild aktiv',
        'Gegnerreaktion verbraucht',
      ];
      for (final label in labels) {
        expect(
          find.bySemanticsLabel(label),
          findsOneWidget,
          reason: 'TalkBack muss $label getrennt ankündigen',
        );
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('Abgeschlossen: nur Abschluss-Siegel vorlesbar', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      screen(
        finished: true,
        pendingShield: true,
        heroShield: true,
        enemyShield: true,
        enemyReactionUsed: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Begegnung beendet'), findsOneWidget);
    expect(find.bySemanticsLabel('Gegnerzug läuft'), findsNothing);
    expect(find.bySemanticsLabel('Gegnerschild aktiv'), findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
