import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_chronicle.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_dice_breakdown.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

GameEvent confirmed(String id, String type, Map<String, dynamic> payload) =>
    GameEvent(
      id: id,
      campaignId: 'campaign',
      sessionId: 'session',
      timestamp: DateTime.utc(2026, 10, 22, 9),
      type: type,
      payload: payload,
    );

Widget chronicle(List<GameEvent> events) => MaterialApp(
  theme: buildFantasyTheme(),
  home: Scaffold(
    body: ListView(children: [FantasyCombatChronicle(events: events)]),
  ),
);

void main() {
  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Bestätigte Angriffswürfel bei $width dp vollständig lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        chronicle([
          confirmed('crit', 'roll.resolved', {
            'attackRoll': {
              'expression': '1d20+5',
              'rolls': [7, 19],
              'natural': 19,
              'modifier': 5,
              'total': 24,
            },
            'critical': true,
            'hit': true,
            'damage': 18,
            'damageRoll': {
              'expression': '1d8+3',
              'rolls': [6],
              'modifier': 3,
              'total': 9,
            },
            'criticalExtra': {
              'expression': '1d8+3',
              'rolls': [4],
              'modifier': 3,
              'total': 7,
            },
            'sneakAttackRoll': {
              'expression': '2d6',
              'rolls': [3, 6],
              'modifier': 0,
              'total': 9,
            },
          }),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('chronicle-dice-crit')), findsOneWidget);
      expect(
        find.text('Angriffswürfel: 7, 19 · W20 gewählt: 19 · Bonus: +5'),
        findsOneWidget,
      );
      expect(find.text('KRITISCHER TREFFER bestätigt'), findsOneWidget);
      expect(find.text('Schadenswürfel: 6 · Bonus: +3'), findsOneWidget);
      expect(find.text('Kritische Zusatzwürfel: 4'), findsOneWidget);
      expect(find.text('Hinterhältige Angriffswürfel: 3, 6'), findsOneWidget);
      expect(find.text('Wurf: 24 · Treffer · Schaden: 18'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Offene Schildwahl zeigt keinen unbestätigten Schaden', (
    tester,
  ) async {
    await tester.pumpWidget(
      chronicle([
        confirmed('pending', 'combat.turnCompleted', {
          'attackRoll': {
            'rolls': [20],
            'natural': 20,
            'modifier': 4,
            'total': 24,
          },
          'pendingEnemyShieldHit': true,
        }),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Angriffswürfel: 20 · Bonus: +4'), findsOneWidget);
    expect(find.text('Wurf: 24 · Schildentscheidung offen'), findsOneWidget);
    expect(find.textContaining('KRITISCHER TREFFER'), findsNothing);
    expect(find.textContaining('Schadenswürfel:'), findsNothing);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Offene Schildwahl auf $width dp/200 % verschweigt spekulativen Schaden',
      (tester) async {
        tester.view.physicalSize = Size(width, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        final unresolved = confirmed('pending-private', 'combat.turnCompleted', {
          'attackRoll': {
            'rolls': [20],
            'natural': 20,
            'modifier': 4,
            'total': 24,
          },
          'pendingEnemyShieldHit': true,
          'hit': true,
          'critical': true,
          'damage': 99,
          'damageRoll': {'rolls': [9], 'modifier': 3},
          'criticalExtraRoll': {'rolls': [8]},
          'sneakAttackRoll': {'rolls': [7]},
          'stateAfter': {'private': 'UNRELEASED_CHECKPOINT'},
        });
        await tester.pumpWidget(
          MaterialApp(
            theme: buildFantasyTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: ListView(children: [FantasyCombatChronicle(events: [unresolved])]),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Angriffswürfel: 20 · Bonus: +4'), findsOneWidget);
        expect(find.text('Wurf: 24 · Schildentscheidung offen'), findsOneWidget);
        expect(find.textContaining('Schaden: 99'), findsNothing);
        expect(find.textContaining('Schadenswürfel:'), findsNothing);
        expect(find.textContaining('Kritische Zusatzwürfel:'), findsNothing);
        expect(find.textContaining('Hinterhältige Angriffswürfel:'), findsNothing);
        expect(find.textContaining('KRITISCHER TREFFER'), findsNothing);
        expect(find.bySemanticsLabel(RegExp(r'Schaden: 99|KRITISCHER TREFFER|Treffer,')), findsNothing);
        expect(
          find.bySemanticsLabel(RegExp(r'Kampfrunde abgeschlossen, .*Schildentscheidung offen')),
          findsOneWidget,
        );
        expect(find.textContaining('UNRELEASED_CHECKPOINT'), findsNothing);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets('Manuelles Gesamtergebnis erfindet keine Einzelwürfel', (
    tester,
  ) async {
    await tester.pumpWidget(
      chronicle([
        confirmed('manual', 'dice.freeRoll', {
          'roll': {
            'expression': 'Manuelles Gesamtergebnis',
            'rolls': <int>[],
            'modifier': 0,
            'natural': null,
            'total': 21,
          },
        }),
      ]),
    );
    expect(find.text('Wurf: 21'), findsOneWidget);
    expect(find.byKey(const ValueKey('chronicle-dice-manual')), findsNothing);
  });

  testWidgets('Technische Zustandskopie und fremde Texte bleiben verborgen', (
    tester,
  ) async {
    final event = confirmed('private', 'roll.resolved', {
      'roll': {
        'expression': 'PRIVATER_WURFAUSDRUCK',
        'rolls': [11],
        'modifier': 0,
        'total': 11,
      },
      'damageRoll': {
        'rolls': ['secret-face'],
        'total': 123,
      },
      'critical': true,
      'hit': false,
      'stateAfter': {'secret': 'PASSWORD_DO_NOT_SHOW'},
      'narratorInstruction': 'DO_NOT_PRINT_RAW_EVENTS',
    });
    await tester.pumpWidget(chronicle([event]));
    expect(find.text('Würfel: 11'), findsOneWidget);
    expect(find.textContaining('PASSWORD_DO_NOT_SHOW'), findsNothing);
    expect(find.textContaining('PRIVATER_WURFAUSDRUCK'), findsNothing);
    expect(find.textContaining('secret-face'), findsNothing);
    expect(find.textContaining('DO_NOT_PRINT_RAW_EVENTS'), findsNothing);
    expect(find.textContaining('KRITISCHER TREFFER'), findsNothing);
    expect(find.textContaining('Schadenswürfel:'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('Mehr als acht sichere Würfel zeigen gekennzeichneten Ausschnitt', () {
    final event = confirmed('many', 'dice.freeRoll', {
      'roll': {'rolls': List<int>.filled(12, 4), 'total': 48, 'modifier': 0},
    });
    final details = FantasyDiceBreakdown.describe(event);
    expect(details, hasLength(1));
    expect(details.single, contains('(+4 weitere)'));
    expect(event.payload['roll'], isNotNull);
  });

  test('Zusatzschaden ignoriert erneuten Attributsbonus', () {
    final event = confirmed('critical', 'attack', {
      'critical': true,
      'hit': true,
      'criticalExtraRoll': {
        'rolls': [5, 2],
        'modifier': 7,
        'total': 14,
      },
    });
    expect(FantasyDiceBreakdown.describe(event), [
      'KRITISCHER TREFFER bestätigt',
      'Kritische Zusatzwürfel: 5, 2',
    ]);
  });
  for (final width in [320.0, 360.0]) {
    testWidgets('Würfelplaketten bei $width dp und 200 % ohne Ziericon', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
                FantasyDiceBreakdown(
                  event: confirmed('accessible', 'roll.resolved', {
                    'attackRoll': {
                      'rolls': [7, 19],
                      'natural': 19,
                      'modifier': 5,
                    },
                    'critical': true,
                    'hit': true,
                    'damageRoll': {
                      'rolls': [6],
                      'modifier': 3,
                    },
                  }),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Angriffswürfel: 7, 19 · W20 gewählt: 19 · Bonus: +5'),
        findsOneWidget,
      );
      expect(find.text('KRITISCHER TREFFER bestätigt'), findsOneWidget);
      expect(find.text('Schadenswürfel: 6 · Bonus: +3'), findsOneWidget);
      expect(find.byIcon(Icons.casino_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
