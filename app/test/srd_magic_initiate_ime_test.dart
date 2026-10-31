import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_initiate_choice.dart';
import 'package:lebendiger_spielleiter/ui/srd_magic_initiate_dialog.dart';

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required SrdBackground background,
  required ValueChanged<SrdMagicInitiateChoice?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showDialog<SrdMagicInitiateChoice>(
                  context: context,
                  builder: (_) => SrdMagicInitiateDialog(
                    background: background,
                  ),
                ),
              );
            },
            child: const Text('Auswahl öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Auswahl öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String key, String value) async {
  final dropdown = find.byKey(ValueKey(key));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  expect(dropdown.hitTestable(), findsOneWidget);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  // Long spell lists build entries lazily inside the dropdown overlay.
  if (find.text(value).evaluate().isEmpty) {
    await tester.dragUntilVisible(
      find.text(value),
      find.byType(Scrollable).last,
      const Offset(0, -160),
      maxIteration: 45,
    );
    await tester.pumpAndSettle();
  }
  final option = find.text(value).last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  expect(option.hitTestable(), findsOneWidget);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Magieinitiierter bei $width dp/200 %/IME sicher abbrechen', (
      tester,
    ) async {
      final results = <SrdMagicInitiateChoice?>[];
      await _open(
        tester,
        width: width,
        background: SrdBackground.sage,
        onResult: results.add,
      );
      final dialog = find.byType(AlertDialog);
      expect(tester.widget<AlertDialog>(dialog).scrollable, isTrue);
      final content = find.byKey(const ValueKey('magic-initiate-ability'));
      expect(
        find.ancestor(of: content, matching: find.byType(Scrollable)),
        findsOneWidget,
      );
      final confirm = find.byKey(const ValueKey('confirm-magic-initiate-choice'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      await tester.ensureVisible(content);
      await tester.pumpAndSettle();
      expect(content.hitTestable(), findsOneWidget);
      final cancel = find.text('Abbrechen');
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(results, [null]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: doppelte Tricks bleiben gesperrt', (
    tester,
  ) async {
    final results = <SrdMagicInitiateChoice?>[];
    await _open(
      tester,
      width: 320,
      background: SrdBackground.acolyte,
      onResult: results.add,
    );
    final confirm = find.byKey(const ValueKey('confirm-magic-initiate-choice'));
    await _choose(tester, 'magic-initiate-cantrip-one', 'Guidance');
    await _choose(tester, 'magic-initiate-cantrip-two', 'Guidance');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(
      find.text('Bitte zwei unterschiedliche Zaubertricks auswählen.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: vier gültige Wahlen bestätigen', (
    tester,
  ) async {
    final results = <SrdMagicInitiateChoice?>[];
    await _open(
      tester,
      width: 360,
      background: SrdBackground.acolyte,
      onResult: results.add,
    );
    final confirm = find.byKey(const ValueKey('confirm-magic-initiate-choice'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await _choose(tester, 'magic-initiate-cantrip-one', 'Guidance');
    await _choose(tester, 'magic-initiate-cantrip-two', 'Light');
    await _choose(tester, 'magic-initiate-level-one', 'Bless');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await _choose(tester, 'magic-initiate-ability', 'wisdom');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.background, SrdBackground.acolyte);
    expect(results.single!.cantrips, ['Guidance', 'Light']);
    expect(results.single!.levelOneSpell, 'Bless');
    expect(results.single!.castingAbility, 'wisdom');
    expect(tester.takeException(), isNull);
  });
}
