import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/monk_slow_fall_dialog.dart';

HeroCharacter _monk(int level) {
  final hero = GameEngine().createDemo().hero;
  return hero.copyWith(className: 'Mönch', level: level);
}

const _encounter = Encounter(
  id: 'fall-dialog',
  enemyName: 'Wache',
  enemyHitPoints: 10,
  enemyMaxHitPoints: 10,
);

Future<void> _openDialog(
  WidgetTester tester, {
  int monkLevel = 4,
  Encounter encounter = _encounter,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<ConfirmedSlowFallChoice>(
              context: context,
              builder: (_) => MonkSlowFallDialog(
                hero: _monk(monkLevel),
                encounter: encounter,
              ),
            ),
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Damage preview never spends Reaction without two confirmations', (
    tester,
  ) async {
    await _openDialog(tester);
    final submit = find.byKey(const ValueKey('slow-fall-commit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.enterText(
      find.byKey(const ValueKey('slow-fall-damage-input')),
      '37',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('20 Schaden verhindert'), findsOneWidget);
    expect(find.textContaining('17 Schaden verbleiben'), findsOneWidget);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-fall')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-defenses')));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invalid and unconfirmed fall damage cannot be committed', (
    tester,
  ) async {
    await _openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-fall')));
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-defenses')));
    final submit = find.byKey(const ValueKey('slow-fall-commit'));
    for (final invalid in ['', '100001', '999999']) {
      await tester.enterText(
        find.byKey(const ValueKey('slow-fall-damage-input')),
        invalid,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    }
    await tester.enterText(
      find.byKey(const ValueKey('slow-fall-damage-input')),
      '0',
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spent Reaction and below-level Monk never permit submission', (
    tester,
  ) async {
    await _openDialog(
      tester,
      encounter: _encounter.copyWith(reactionUsed: true),
    );
    await tester.enterText(
      find.byKey(const ValueKey('slow-fall-damage-input')),
      '10',
    );
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-fall')));
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-defenses')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(
        find.byKey(const ValueKey('slow-fall-commit')),
      ).onPressed,
      isNull,
    );
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());

    await _openDialog(tester, monkLevel: 3);
    await tester.enterText(
      find.byKey(const ValueKey('slow-fall-damage-input')),
      '10',
    );
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-fall')));
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-defenses')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(
        find.byKey(const ValueKey('slow-fall-commit')),
      ).onPressed,
      isNull,
    );
  });
}
