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
  testWidgets(
    'Damage preview never spends Reaction without two confirmations',
    (tester) async {
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

      await tester.tap(
        find.byKey(const ValueKey('slow-fall-confirm-defenses')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );

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
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('slow-fall-confirm-fall')),
          )
          .value,
      isFalse,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('slow-fall-confirm-defenses')),
          )
          .value,
      isFalse,
    );
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-fall')));
    await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-defenses')));
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
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('slow-fall-commit')))
          .onPressed,
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
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('slow-fall-commit')))
          .onPressed,
      isNull,
    );
  });

  Future<void> tapReachable(WidgetTester tester, Finder target) async {
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  Future<void> openImeDialog(
    WidgetTester tester, {
    required double width,
    required HeroCharacter hero,
    required Encounter encounter,
    required void Function(ConfirmedSlowFallChoice?) onClosed,
  }) async {
    tester.view.physicalSize = Size(width, 850);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onClosed(
                await showDialog<ConfirmedSlowFallChoice>(
                  context: context,
                  builder: (_) =>
                      MonkSlowFallDialog(hero: hero, encounter: encounter),
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

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Sanfter Fall bei ${width.toInt()} dp/200 %/IME: erneute Zustimmung',
      (tester) async {
        final hero = _monk(4);
        final before = hero.toJson();
        ConfirmedSlowFallChoice? result;
        await openImeDialog(
          tester,
          width: width,
          hero: hero,
          encounter: _encounter,
          onClosed: (value) => result = value,
        );
        final dialog = find.byKey(const ValueKey('slow-fall-dialog'));
        final damage = find.byKey(const ValueKey('slow-fall-damage-input'));
        final fall = find.byKey(const ValueKey('slow-fall-confirm-fall'));
        final defenses = find.byKey(
          const ValueKey('slow-fall-confirm-defenses'),
        );
        final submit = find.byKey(const ValueKey('slow-fall-commit'));
        expect(tester.widget<AlertDialog>(dialog).scrollable, isTrue);
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        await tester.enterText(damage, '37');
        await tester.pumpAndSettle();
        await tapReachable(tester, fall);
        await tapReachable(tester, defenses);
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
        expect(find.textContaining('17 Schaden verbleiben'), findsOneWidget);

        // The already approved amount must not silently authorize a new one.
        await tester.ensureVisible(damage);
        await tester.enterText(damage, '28');
        await tester.pumpAndSettle();
        expect(tester.widget<CheckboxListTile>(fall).value, isFalse);
        expect(tester.widget<CheckboxListTile>(defenses).value, isFalse);
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        await tapReachable(tester, fall);
        expect(tester.widget<FilledButton>(submit).onPressed, isNull);
        await tapReachable(tester, defenses);
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
        await tapReachable(tester, submit);
        expect(result?.damageAfterDefenses, 28);
        expect(hero.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('320 dp/200 %/IME: Abbruch lässt Reaktion unberührt', (
    tester,
  ) async {
    final hero = _monk(4);
    final before = hero.toJson();
    ConfirmedSlowFallChoice? result;
    var returned = false;
    await openImeDialog(
      tester,
      width: 320,
      hero: hero,
      encounter: _encounter,
      onClosed: (value) {
        returned = true;
        result = value;
      },
    );
    final damage = find.byKey(const ValueKey('slow-fall-damage-input'));
    await tester.enterText(damage, '25');
    await tester.pumpAndSettle();
    await tapReachable(
      tester,
      find.byKey(const ValueKey('slow-fall-confirm-fall')),
    );
    await tapReachable(
      tester,
      find.byKey(const ValueKey('slow-fall-confirm-defenses')),
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('slow-fall-commit')))
          .onPressed,
      isNotNull,
    );
    await tapReachable(tester, find.byKey(const ValueKey('slow-fall-cancel')));
    expect(returned, isTrue);
    expect(result, isNull);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp/200 %/IME: verbrauchte Reaktion bleibt gesperrt', (
    tester,
  ) async {
    ConfirmedSlowFallChoice? result;
    await openImeDialog(
      tester,
      width: 320,
      hero: _monk(4),
      encounter: _encounter.copyWith(reactionUsed: true),
      onClosed: (value) => result = value,
    );
    await tester.enterText(
      find.byKey(const ValueKey('slow-fall-damage-input')),
      '18',
    );
    await tester.pumpAndSettle();
    await tapReachable(
      tester,
      find.byKey(const ValueKey('slow-fall-confirm-fall')),
    );
    await tapReachable(
      tester,
      find.byKey(const ValueKey('slow-fall-confirm-defenses')),
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('slow-fall-commit')))
          .onPressed,
      isNull,
    );
    await tapReachable(tester, find.byKey(const ValueKey('slow-fall-cancel')));
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}
