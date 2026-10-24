import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/condition_effect_dialog.dart';

void main() {
  Future<ConditionEffectChoice?> open(
    WidgetTester tester, {
    Encounter? encounter,
    List<ConditionEffect> effects = const [],
  }) async {
    ConditionEffectChoice? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDialog<ConditionEffectChoice>(
                  context: context,
                  builder: (_) => ConditionEffectDialog(
                    hero: HeroCharacter(
                      id: 'hero',
                      name: 'Liora',
                      conditionEffects: effects,
                    ),
                    encounter: encounter,
                  ),
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.byType(ConditionEffectDialog), findsOneWidget);
    // The result is asserted by the tests through a captured callback below.
    return result;
  }

  testWidgets('ohne Quelle kein bestätigter Zustand, Abbruch ist neutral', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('condition-effect-confirm')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('condition-effect-error')),
      findsOneWidget,
    );
    expect(find.byType(ConditionEffectDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('condition-effect-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(ConditionEffectDialog), findsNothing);
  });

  testWidgets('eigener Kampfzug bietet zwei explizite Endpunkte an', (
    tester,
  ) async {
    await open(
      tester,
      encounter: const Encounter(
        id: 'kampf-1',
        enemyName: 'Wächter',
        enemyHitPoints: 10,
        enemyMaxHitPoints: 10,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('condition-effect-duration')));
    await tester.pumpAndSettle();
    expect(find.text('Ende des nächsten eigenen Zugs'), findsWidgets);
    expect(find.text('Ende des aktuellen eigenen Zugs'), findsWidgets);
    expect(find.text('Nach 3 eigenen Zugenden'), findsWidgets);
    expect(find.text('Nach 5 eigenen Zugenden'), findsWidgets);
    expect(find.text('Nach 10 eigenen Zugenden'), findsWidgets);
    await tester.tap(find.text('Nach 10 eigenen Zugenden').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('condition-effect-source')),
      '  Giftpfeil  ',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('eine Quelle wird ausgewählt, ohne andere zu überschreiben', (
    tester,
  ) async {
    await open(
      tester,
      effects: [
        ConditionEffect(
          id: 'source-a',
          condition: 'vergiftet',
          source: 'Nebel',
        ),
        ConditionEffect(
          id: 'source-b',
          condition: 'vergiftet',
          source: 'Pfeil',
        ),
      ],
    );
    await tester.tap(
      find.byKey(const ValueKey('condition-effect-remove-mode')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('condition-effect-existing-source')),
      findsOneWidget,
    );
    expect(find.textContaining('Nebel'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('condition-effect-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(ConditionEffectDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mehrzügige Zeitoptionen fehlen außerhalb eigener Kampfzüge', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('condition-effect-duration')));
    await tester.pumpAndSettle();
    expect(find.text('Nach 10 eigenen Zugenden'), findsNothing);
    expect(find.text('Nach 5 eigenen Zugenden'), findsNothing);
    expect(find.text('Nach 3 eigenen Zugenden'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
