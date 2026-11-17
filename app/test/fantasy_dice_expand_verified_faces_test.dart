import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_chronicle.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_dice_breakdown.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

GameEvent _event(String id, String type, Map<String, dynamic> payload) =>
    GameEvent(
      id: id,
      campaignId: 'campaign',
      sessionId: 'session',
      timestamp: DateTime.utc(2026, 11, 17),
      type: type,
      payload: payload,
    );

Widget _screen(
  GameEvent event, {
  bool inChronicle = false,
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
        if (inChronicle)
          FantasyCombatChronicle(events: [event])
        else
          FantasyDiceBreakdown(event: event),
      ],
    ),
  ),
);

void main() {
  final faces = List<int>.generate(12, (index) => index + 1);
  const compact =
      'Freie Würfel: 1, 2, 3, 4, 5, 6, 7, 8 (+4 weitere)';
  const complete =
      'Freie Würfel: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12';

  test('Standardvorschau bleibt kompakt, Volltext enthält alle Würfel', () {
    final event = _event('full-12', 'dice.freeRoll', {
      'roll': {'rolls': faces, 'total': 78},
    });
    final before = event.toJson();

    expect(FantasyDiceBreakdown.describe(event), [compact]);
    expect(
      FantasyDiceBreakdown.describe(event, showAllFaces: true),
      [complete],
    );
    expect(event.toJson(), before);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Chronik bei $width dp/200 %/IME zeigt alle Würfel auf Wunsch',
      (tester) async {
        tester.view.physicalSize = Size(width, 1250);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final semantics = tester.ensureSemantics();
        addTearDown(semantics.dispose);
        final event = _event('expand-12', 'dice.freeRoll', {
          'roll': {'rolls': faces, 'total': 78},
        });
        final before = event.toJson();

        await tester.pumpWidget(
          _screen(event, inChronicle: true, textScale: 2),
        );
        await tester.pumpAndSettle();

        expect(find.text(compact), findsOneWidget);
        expect(find.text(complete), findsNothing);
        final toggle = find.byKey(
          const ValueKey('chronicle-dice-toggle-expand-12'),
        );
        await tester.ensureVisible(toggle);
        await tester.pumpAndSettle();
        expect(toggle.hitTestable(), findsOneWidget);
        expect(
          find.bySemanticsLabel('Alle Würfel anzeigen'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp('Alle bestätigten Würfel:')),
          findsNothing,
        );

        await tester.tap(toggle);
        await tester.pumpAndSettle();

        expect(find.text(complete), findsOneWidget);
        expect(find.text(compact), findsNothing);
        expect(
          find.bySemanticsLabel('Weniger Würfel anzeigen'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Alle bestätigten Würfel: $complete'),
          findsOneWidget,
        );

        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(find.text(compact), findsOneWidget);
        expect(find.text(complete), findsNothing);
        expect(event.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Wenige oder ungültige Würfel erzeugen keinen Volltextschalter', (
    tester,
  ) async {
    final short = _event('short', 'dice.freeRoll', {
      'roll': {'rolls': [1, 3, 5], 'total': 9},
    });
    await tester.pumpWidget(_screen(short));
    expect(find.text('Freie Würfel: 1, 3, 5'), findsOneWidget);
    expect(find.text('Alle Würfel anzeigen'), findsNothing);

    final invalid = _event('invalid', 'dice.freeRoll', {
      'roll': {'rolls': [1, 2, 0, 4, 5, 6, 7, 8, 9], 'total': 42},
    });
    await tester.pumpWidget(_screen(invalid));
    expect(find.byKey(const ValueKey('chronicle-dice-invalid')), findsNothing);
    expect(find.text('Alle Würfel anzeigen'), findsNothing);

    final oversized = _event('oversized', 'dice.freeRoll', {
      'roll': {'rolls': List<int>.filled(101, 1), 'total': 101},
    });
    expect(FantasyDiceBreakdown.describe(oversized), isEmpty);
    expect(
      FantasyDiceBreakdown.describe(oversized, showAllFaces: true),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Offene Schildentscheidung bleibt auch ausgeklappt geheim', (
    tester,
  ) async {
    final event = _event('shield', 'combat.turnCompleted', {
      'attackRoll': {'rolls': faces, 'modifier': 3},
      'pendingEnemyShieldHit': true,
      'damageRoll': {'rolls': List<int>.filled(12, 99)},
      'criticalExtraRoll': {'rolls': List<int>.filled(12, 98)},
      'sneakAttackRoll': {'rolls': List<int>.filled(12, 97)},
      'critical': true,
      'hit': true,
      'stateAfter': {'private': 'NEVER_SHOW'},
    });
    final before = event.toJson();

    await tester.pumpWidget(_screen(event, inChronicle: true));
    expect(find.textContaining('Schadenswürfel:'), findsNothing);
    final toggle = find.byKey(const ValueKey('chronicle-dice-toggle-shield'));
    expect(toggle, findsOneWidget);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Angriffswürfel: 1, 2, 3, 4, 5, 6, 7, 8, 9'),
      findsOneWidget,
    );
    expect(find.textContaining('Schadenswürfel:'), findsNothing);
    expect(find.textContaining('Kritische Zusatzwürfel:'), findsNothing);
    expect(find.textContaining('Hinterhältige Angriffswürfel:'), findsNothing);
    expect(find.textContaining('KRITISCHER TREFFER'), findsNothing);
    expect(find.textContaining('NEVER_SHOW'), findsNothing);
    expect(event.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Neuer Ereignis-Snapshot schließt alte Würfelfolge', (
    tester,
  ) async {
    final first = _event('reused-id', 'dice.freeRoll', {
      'roll': {'rolls': faces, 'total': 78},
    });
    final second = _event('reused-id', 'dice.freeRoll', {
      'roll': {'rolls': List<int>.filled(10, 6), 'total': 60},
    });
    await tester.pumpWidget(_screen(first));
    final toggle = find.byKey(
      const ValueKey('chronicle-dice-toggle-reused-id'),
    );
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text(complete), findsOneWidget);

    await tester.pumpWidget(_screen(second));
    await tester.pumpAndSettle();

    expect(find.text(complete), findsNothing);
    expect(
      find.text('Freie Würfel: 6, 6, 6, 6, 6, 6, 6, 6 (+2 weitere)'),
      findsOneWidget,
    );
    expect(find.text('Alle Würfel anzeigen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
