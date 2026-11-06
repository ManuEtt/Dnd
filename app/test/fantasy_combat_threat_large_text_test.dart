import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_threat_status.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

Widget _screen({
  double textScale = 2,
  bool finished = false,
  bool withKeyboard = true,
}) => MaterialApp(
  theme: buildFantasyTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      textScaler: TextScaler.linear(textScale),
      viewInsets: EdgeInsets.only(bottom: withKeyboard ? 220 : 0),
    ),
    child: child!,
  ),
  home: Scaffold(
    body: ListView(
      padding: const EdgeInsets.all(12),
      children: [
        FantasyCombatThreatStatus(
          enemyAttacksPerTurn: 3,
          enemyAttacksRemaining: 2,
          activeParticipant: 'enemy',
          pendingShieldDecision: true,
          heroShieldActive: true,
          enemyShieldActive: true,
          enemyShieldReactionUsed: true,
          isFinished: finished,
        ),
      ],
    ),
  ),
);

const _activeKeys = [
  'combat-enemy-turn-state',
  'combat-remaining-attacks',
  'combat-pending-shield',
  'combat-hero-shield-active',
  'combat-enemy-shield-active',
  'combat-enemy-reaction-used',
];

const _activeLabels = [
  'Gegnerzug läuft',
  '2 weitere Gegnerangriffe',
  'Schildentscheidung offen – Schaden nicht gewürfelt',
  'Schild des Helden aktiv',
  'Gegnerschild aktiv',
  'Gegnerreaktion verbraucht',
];

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Kampfhinweise auf $width dp bei 200 % und IME vollbreit', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      await tester.pumpWidget(_screen());
      await tester.pumpAndSettle();

      final first = find.byKey(ValueKey(_activeKeys.first));
      final fullWidth = tester.getSize(first).width;
      expect(fullWidth, greaterThan(200));
      for (var i = 0; i < _activeKeys.length; i++) {
        final seal = find.byKey(ValueKey(_activeKeys[i]));
        expect(seal, findsOneWidget);
        expect(tester.getSize(seal).width, closeTo(fullWidth, 0.1));
        expect(find.bySemanticsLabel(_activeLabels[i]), findsOneWidget);

        final text = tester.widget<Text>(
          find.descendant(of: seal, matching: find.text(_activeLabels[i])),
        );
        expect(text.softWrap, isTrue);
        expect(text.maxLines, isNull);
        if (i > 0) {
          final previous = find.byKey(ValueKey(_activeKeys[i - 1]));
          expect(
            tester.getTopLeft(seal).dy,
            greaterThan(tester.getTopLeft(previous).dy),
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Normale Schrift behält die kompakte Nebeneinander-Anordnung', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_screen(textScale: 1, withKeyboard: false));
    await tester.pumpAndSettle();

    final first = find.byKey(const ValueKey('combat-enemy-turn-state'));
    final second = find.byKey(const ValueKey('combat-remaining-attacks'));
    expect(tester.getTopLeft(second).dy, tester.getTopLeft(first).dy);
    expect(
      tester.getTopLeft(second).dx,
      greaterThan(tester.getTopLeft(first).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Beendete Begegnung zeigt nur den bestätigten Abschluss', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await tester.pumpWidget(_screen(finished: true));
    await tester.pumpAndSettle();

    for (final key in _activeKeys) {
      expect(find.byKey(ValueKey(key)), findsNothing);
    }
    expect(find.byKey(const ValueKey('combat-threat-finished')), findsOneWidget);
    expect(find.bySemanticsLabel('Begegnung beendet'), findsOneWidget);
    expect(find.bySemanticsLabel(_activeLabels[2]), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
