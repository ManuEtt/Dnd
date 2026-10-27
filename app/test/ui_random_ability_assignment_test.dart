import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/ability_assignment_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

Future<void> choose(WidgetTester tester, Finder dropdown, String label) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Würfelmethode bleibt vor ausdrücklicher Bestätigung Entwurf', (
    tester,
  ) async {
    const dice = [
      6,
      6,
      6,
      1,
      5,
      5,
      5,
      1,
      4,
      4,
      4,
      1,
      3,
      3,
      3,
      1,
      2,
      2,
      2,
      1,
      1,
      1,
      1,
      1,
    ];
    var calls = 0;
    AbilityAssignment? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                saved = await showDialog<AbilityAssignment>(
                  context: context,
                  builder: (_) =>
                      AbilityAssignmentDialog(rollD6: () => dice[calls++]),
                );
              },
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await choose(
      tester,
      find.byKey(const ValueKey('ability-generation-method')),
      'Würfeln (4W6, niedrigster entfällt)',
    );
    expect(calls, 24);
    expect(find.byKey(const ValueKey('dice-roll-5')), findsOneWidget);
    final apply = find.byKey(const ValueKey('apply-ability-assignment'));
    expect(tester.widget<FantasyTextButton>(apply).onPressed, isNull);
    await choose(
      tester,
      find.byKey(const ValueKey('ability-background')),
      'Soldat',
    );
    await choose(
      tester,
      find.byKey(const ValueKey('ability-bonus-pattern')),
      '+1 auf alle drei',
    );
    expect(tester.widget<FantasyTextButton>(apply).onPressed, isNull);
    final confirm = find.byKey(const ValueKey('confirm-random-assignment'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(tester.widget<FantasyTextButton>(apply).onPressed, isNotNull);
    await tester.tap(apply);
    await tester.pumpAndSettle();
    expect(saved!.scores, {
      'strength': 19,
      'dexterity': 16,
      'constitution': 13,
      'intelligence': 9,
      'wisdom': 6,
      'charisma': 3,
    });
    expect(saved!.background, 'Soldat');
    expect(calls, 24);
  });
}
