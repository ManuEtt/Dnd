import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combat_chronicle.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

GameEvent event(
  String id,
  String type, {
  Map<String, dynamic> payload = const {},
}) => GameEvent(
  id: id,
  campaignId: 'camp',
  sessionId: 'session',
  timestamp: DateTime.utc(2026, 10, 22, 9, 12),
  type: type,
  payload: payload,
);

Widget screen(List<GameEvent> events, {int limit = 8}) => MaterialApp(
  theme: buildFantasyTheme(),
  home: Scaffold(
    body: SingleChildScrollView(
      child: FantasyCombatChronicle(events: events, maxEntries: limit),
    ),
  ),
);

void main() {
  testWidgets(
    'Bestätigte Würfe, Treffer und Schaden erscheinen chronologisch',
    (tester) async {
      await tester.pumpWidget(
        screen([
          event(
            'attack-1',
            'attack',
            payload: {
              'roll': {'total': 19, 'natural': 16},
              'hit': true,
              'damage': 6,
              'stateAfter': {
                'secretToken': 'PRIVATE_CHECKPOINT_SHOULD_NEVER_BE_SHOWN',
                'hero': {'name': 'Unsichtbare Speicherkopie'},
              },
            },
          ),
          event(
            'enemy-1',
            'combat.enemyAttackContinued',
            payload: {
              'attackRoll': {'total': 7},
              'hit': false,
              'enemyAttacksRemaining': 2,
            },
          ),
          event('heal-1', 'effect.healing', payload: {'hitPointsRestored': 8}),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kampf- & Würfelchronik'), findsOneWidget);
      expect(find.text('Angriffswurf'), findsOneWidget);
      expect(find.text('Gegnerangriff fortgesetzt'), findsOneWidget);
      expect(find.text('Heilung bestätigt'), findsOneWidget);
      expect(find.text('Wurf: 19 · Treffer · Schaden: 6'), findsOneWidget);
      expect(
        find.text('Wurf: 7 · Verfehlt · Weitere Gegnerangriffe: 2'),
        findsOneWidget,
      );
      expect(find.text('Geheilte TP: 8'), findsOneWidget);
      final first = tester.getTopLeft(
        find.byKey(const ValueKey('chronicle-event-heal-1')),
      );
      final last = tester.getTopLeft(
        find.byKey(const ValueKey('chronicle-event-attack-1')),
      );
      expect(first.dy, lessThan(last.dy));
      expect(find.textContaining('PRIVATE_CHECKPOINT'), findsNothing);
      expect(find.textContaining('Unsichtbare Speicherkopie'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Kampfchronik bleibt bei $width dp ohne Überlauf lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        screen([
          event(
            'start',
            'combat.started',
            payload: {
              'heroInitiative': {'total': 14},
            },
          ),
          event(
            'attack',
            'attack',
            payload: {
              'roll': {'total': 17},
              'hit': true,
              'damage': 6,
            },
          ),
          event(
            'shield',
            'combat.shieldHitResolved',
            payload: {
              'choice': 'cast',
              'attackRoll': {'total': 18},
              'hit': false,
            },
          ),
        ]),
      );
      await tester.pumpAndSettle();
      expect(find.text('Wurf: 18 · Verfehlt · Schild gewirkt'), findsOneWidget);
      expect(find.text('Kampf begonnen'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Nur bestätigte Regelereignisse ohne rohe Zustandskopien', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen([
        event(
          'story',
          'narrative.turn',
          payload: {'text': 'Vertrauliche Erzählung'},
        ),
        event(
          'cover',
          'combat.coverConfirmed',
          payload: {
            'target': 'held',
            'grade': 'half',
            'stateAfter': {'password': 'NOT_A_UI_FIELD'},
          },
        ),
        event(
          'start',
          'combat.enemyAttackCountConfirmed',
          payload: {'count': 3},
        ),
      ]),
    );
    expect(find.text('Deckung bestätigt'), findsOneWidget);
    expect(find.text('Held: halbe Deckung'), findsOneWidget);
    expect(find.text('Gegnerangriffe: 3'), findsOneWidget);
    expect(find.textContaining('NOT_A_UI_FIELD'), findsNothing);
    expect(find.textContaining('Vertrauliche Erzählung'), findsNothing);
    expect(find.byKey(const ValueKey('chronicle-event-story')), findsNothing);
  });

  testWidgets('Chronik begrenzt Ereignisse, ohne Spielstand zu verändern', (
    tester,
  ) async {
    final events = [
      for (var i = 0; i < 12; i++)
        event('event-$i', 'combat.moved', payload: {'meters': i + 1}),
    ];
    await tester.pumpWidget(screen(events, limit: 3));
    expect(
      find.byKey(const ValueKey('chronicle-event-event-11')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chronicle-event-event-10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chronicle-event-event-9')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('chronicle-event-event-0')), findsNothing);
    expect(
      find.text('Zeige die letzten 3 von 12 bestätigten Ereignissen.'),
      findsOneWidget,
    );
    expect(events, hasLength(12));
  });

  testWidgets('Leere Chronik zeigt keine erfundenen Kampfereignisse', (
    tester,
  ) async {
    await tester.pumpWidget(screen([event('narrative', 'narrative.turn')]));
    expect(
      find.text('Noch keine bestätigten Kampf- oder Würfelereignisse.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('chronicle-event-narrative')),
      findsNothing,
    );
  });
  for (final width in [320.0, 360.0]) {
    testWidgets('Chronik bei $width dp und 200 % getrennt vorlesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
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
            body: SingleChildScrollView(
              child: FantasyCombatChronicle(
                events: [
                  event(
                    'roll-accessible',
                    'attack',
                    payload: {
                      'roll': {'total': 19},
                      'hit': true,
                      'damage': 6,
                      'stateAfter': {
                        'private': 'DO_NOT_ANNOUNCE_INTERNAL_CHECKPOINT',
                      },
                    },
                  ),
                  event(
                    'heal-accessible',
                    'effect.healing',
                    payload: {'hitPointsRestored': 8},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'^Angriffswurf, .*Wurf: 19, Treffer, Schaden: 6')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Heilung bestätigt, .*Geheilte TP: 8')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(
          find.byKey(const ValueKey('chronicle-event-heal-accessible')),
        ).dy,
        lessThan(
          tester.getTopLeft(
            find.byKey(const ValueKey('chronicle-event-roll-accessible')),
          ).dy,
        ),
      );
      expect(
        find.bySemanticsLabel(RegExp('DO_NOT_ANNOUNCE_INTERNAL_CHECKPOINT')),
        findsNothing,
      );
      expect(find.textContaining('DO_NOT_ANNOUNCE_INTERNAL_CHECKPOINT'),
          findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

}
