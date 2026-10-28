import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/ui/ability_assignment_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const _dice = [
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
const _randomLabel = 'Würfeln (4W6, niedrigster entfällt)';
Finder get _method => find.byKey(const ValueKey('ability-generation-method'));
Finder get _apply => find.byKey(const ValueKey('apply-ability-assignment'));

Future<void> choose(WidgetTester tester, Finder dropdown, String label) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final choice = find.text(label).last;
  await tester.ensureVisible(choice);
  await tester.pumpAndSettle();
  await tester.tap(choice);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester, {
  required int Function() rollD6,
  required ValueChanged<AbilityAssignment?> onResult,
  bool hasExistingValues = false,
  double textScale = 1,
  double keyboardInset = 0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              onResult(
                await showDialog<AbilityAssignment>(
                  context: context,
                  builder: (_) => AbilityAssignmentDialog(
                    rollD6: rollD6,
                    hasExistingValues: hasExistingValues,
                  ),
                ),
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
}

Future<void> _soldier(WidgetTester tester) async {
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
}

Future<void> _confirm(WidgetTester tester, String id) async {
  final checkbox = find.byKey(ValueKey(id));
  await tester.ensureVisible(checkbox);
  await tester.pumpAndSettle();
  await tester.tap(checkbox);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Würfelmethode bleibt vor ausdrücklicher Bestätigung Entwurf', (
    tester,
  ) async {
    var calls = 0;
    AbilityAssignment? saved;
    await _open(
      tester,
      rollD6: () => _dice[calls++],
      onResult: (value) => saved = value,
    );
    await choose(tester, _method, _randomLabel);
    expect(calls, 24);
    expect(find.byKey(const ValueKey('dice-roll-5')), findsOneWidget);
    expect(tester.widget<FantasyTextButton>(_apply).onPressed, isNull);
    await _soldier(tester);
    expect(tester.widget<FantasyTextButton>(_apply).onPressed, isNull);
    await _confirm(tester, 'confirm-random-assignment');
    expect(tester.widget<FantasyTextButton>(_apply).onPressed, isNotNull);
    await tester.tap(_apply);
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
    expect(saved!.origin.method, 'randomRoll');
    expect(saved!.origin.background, 'Soldat');
    expect(saved!.origin.baseScores, {
      'strength': 18,
      'dexterity': 15,
      'constitution': 12,
      'intelligence': 9,
      'wisdom': 6,
      'charisma': 3,
    });
    expect(saved!.origin.increases, {
      'strength': 1,
      'dexterity': 1,
      'constitution': 1,
    });
    expect(saved!.origin.diceRolls, [
      for (var i = 0; i < 6; i++) _dice.sublist(i * 4, i * 4 + 4),
    ]);
    expect(saved!.origin.startingScores, saved!.scores);
    expect(calls, 24);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Methodenwechsel bewahrt Würfe; Tausch verlangt neue Zustimmung',
    (tester) async {
      var calls = 0;
      AbilityAssignment? saved;
      await _open(
        tester,
        rollD6: () => _dice[calls++ % _dice.length],
        onResult: (value) => saved = value,
      );
      await choose(tester, _method, _randomLabel);
      await _soldier(tester);
      await _confirm(tester, 'confirm-random-assignment');
      final before = [
        for (var i = 0; i < 6; i++)
          tester.widget<Text>(find.byKey(ValueKey('dice-roll-$i'))).data,
      ];
      await choose(tester, _method, 'Punkte-Kauf (27 Punkte)');
      await choose(tester, _method, _randomLabel);
      expect(calls, 24);
      expect([
        for (var i = 0; i < 6; i++)
          tester.widget<Text>(find.byKey(ValueKey('dice-roll-$i'))).data,
      ], before);
      expect(tester.widget<FantasyTextButton>(_apply).onPressed, isNotNull);
      await choose(
        tester,
        find.byKey(const ValueKey('rolled-strength-18')),
        '15',
      );
      expect(tester.widget<FantasyTextButton>(_apply).onPressed, isNull);
      expect(saved, isNull);
      await _confirm(tester, 'confirm-random-assignment');
      await tester.tap(_apply);
      await tester.pumpAndSettle();
      expect(saved!.origin.baseScores['strength'], 15);
      expect(saved!.origin.baseScores['dexterity'], 18);
      expect(saved!.scores['strength'], 16);
      expect(saved!.scores['dexterity'], 19);
      expect(saved!.origin.diceRolls.first, [6, 6, 6, 1]);
      expect(calls, 24);
      expect(tester.takeException(), isNull);
    },
  );

  for (final failure in [
    'ungültiger W6',
    'Quellenfehler',
    'fehlende Entropie',
  ]) {
    testWidgets(
      'Wurffehler $failure bewahrt Entwurf und erlaubt neuen Versuch',
      (tester) async {
        var calls = 0;
        var fail = true;
        AbilityAssignment? saved;
        await _open(
          tester,
          hasExistingValues: true,
          rollD6: () {
            calls++;
            if (fail && calls == 3) {
              if (failure == 'ungültiger W6') return 0;
              if (failure == 'Quellenfehler') throw StateError('Test source');
              throw UnsupportedError('Secure random unavailable');
            }
            return 3;
          },
          onResult: (value) => saved = value,
        );
        await choose(tester, _method, 'Punkte-Kauf (27 Punkte)');
        await _soldier(tester);
        final increase = find.byKey(const ValueKey('increase-strength'));
        await tester.ensureVisible(increase);
        await tester.pumpAndSettle();
        await tester.tap(increase);
        await tester.pumpAndSettle();
        await choose(tester, _method, _randomLabel);
        expect(tester.takeException(), isNull);
        expect(calls, 3);
        expect(saved, isNull);
        expect(
          find.byKey(const ValueKey('ability-roll-error')),
          findsOneWidget,
        );
        expect(
          tester.state<FormFieldState<AbilityGenerationMethod>>(_method).value,
          AbilityGenerationMethod.pointBuy,
        );
        expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('point-value-strength')))
              .data,
          '9',
        );
        expect(find.byKey(const ValueKey('dice-roll-0')), findsNothing);
        expect(tester.widget<FantasyTextButton>(_apply).onPressed, isNull);
        fail = false;
        await choose(tester, _method, _randomLabel);
        expect(find.byKey(const ValueKey('ability-roll-error')), findsNothing);
        expect(calls, 27);
        await _confirm(tester, 'confirm-random-assignment');
        expect(tester.widget<FantasyTextButton>(_apply).onPressed, isNull);
        await _confirm(tester, 'confirm-ability-replacement');
        await tester.tap(_apply);
        await tester.pumpAndSettle();
        expect(saved!.origin.method, 'randomRoll');
        expect(saved!.origin.diceRolls, List.generate(6, (_) => [3, 3, 3, 3]));
        expect(saved!.scores['strength'], 10);
        expect(calls, 27);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Abbruch nach Wurffehler liefert keine neuen Charakterwerte', (
    tester,
  ) async {
    final existing = {'strength': 17, 'wisdom': 12};
    Map<String, int> stored = existing;
    var callbacks = 0;
    await _open(
      tester,
      hasExistingValues: true,
      rollD6: () => throw UnsupportedError('Test'),
      onResult: (value) {
        callbacks++;
        if (value != null) stored = value.scores;
      },
    );
    await choose(tester, _method, _randomLabel);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('ability-roll-error')), findsOneWidget);
    expect(callbacks, 0);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(callbacks, 1);
    expect(stored, same(existing));
    expect(stored, {'strength': 17, 'wisdom': 12});
  });

  testWidgets('360 dp, 200 Prozent und Tastatur: Würfe bleiben bestätigbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var calls = 0;
    AbilityAssignment? saved;
    await _open(
      tester,
      textScale: 2,
      keyboardInset: 200,
      rollD6: () => _dice[calls++],
      onResult: (value) => saved = value,
    );
    await choose(tester, _method, _randomLabel);
    await _soldier(tester);
    await _confirm(tester, 'confirm-random-assignment');
    expect(tester.takeException(), isNull);
    await tester.tap(_apply);
    await tester.pumpAndSettle();
    expect(saved!.origin.diceRolls, hasLength(6));
    expect(saved!.scores['strength'], 19);
    expect(calls, 24);
    expect(tester.takeException(), isNull);
  });
}
