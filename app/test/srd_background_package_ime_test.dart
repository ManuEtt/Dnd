import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/ui/srd_background_package_dialog.dart';

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required SrdBackground background,
  required ValueChanged<SrdBackgroundPackageChoice?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 680);
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
                await showDialog<SrdBackgroundPackageChoice>(
                  context: context,
                  builder: (_) =>
                      SrdBackgroundPackageDialog(background: background),
                ),
              );
            },
            child: const Text('Hintergrund öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Hintergrund öffnen'));
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Soldat: $width dp/200 %/IME sperrt und bricht sicher ab', (
      tester,
    ) async {
      final results = <SrdBackgroundPackageChoice?>[];
      await _open(
        tester,
        width: width,
        background: SrdBackground.soldier,
        onResult: results.add,
      );

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      final gaming = find.byKey(const ValueKey('background-gaming-set'));
      final dropdown = find.descendant(
        of: gaming,
        matching: find.byType(DropdownButton<String>),
      );
      expect(
        tester.widget<DropdownButton<String>>(dropdown).isExpanded,
        isTrue,
      );
      expect(
        find.ancestor(of: gaming, matching: find.byType(Scrollable)),
        findsOneWidget,
      );
      final confirm = find.byKey(const ValueKey('confirm-background-package'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
      final cancel = find.text('Abbrechen');
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(results, [null]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: Goldwahl bleibt erreichbar und bestätigt', (
    tester,
  ) async {
    final results = <SrdBackgroundPackageChoice?>[];
    await _open(
      tester,
      width: 320,
      background: SrdBackground.acolyte,
      onResult: results.add,
    );
    final holySymbol = find.byKey(const ValueKey('background-holy-symbol'));
    final dropdown = find.descendant(
      of: holySymbol,
      matching: find.byType(DropdownButton<String>),
    );
    expect(tester.widget<DropdownButton<String>>(dropdown).isExpanded, isTrue);
    final confirm = find.byKey(const ValueKey('confirm-background-package'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    final gold = find.byKey(const ValueKey('background-gold-option'));
    await tester.ensureVisible(gold);
    await tester.pumpAndSettle();
    expect(gold.hitTestable(), findsOneWidget);
    await tester.tap(gold);
    await tester.pumpAndSettle();

    expect(holySymbol, findsNothing);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.background, SrdBackground.acolyte);
    expect(results.single!.takeGold, isTrue);
    expect(results.single!.startingGold, 50);
    expect(results.single!.holySymbolCatalogId, isEmpty);
    expect(results.single!.kitItems, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: Spielset-Auswahl wird übernommen', (
    tester,
  ) async {
    final results = <SrdBackgroundPackageChoice?>[];
    await _open(
      tester,
      width: 360,
      background: SrdBackground.soldier,
      onResult: results.add,
    );
    final set = SrdBackgroundPackageChoice.gamingSets.first;
    final gaming = find.byKey(const ValueKey('background-gaming-set'));
    await tester.ensureVisible(gaming);
    await tester.pumpAndSettle();
    await tester.tap(gaming);
    await tester.pumpAndSettle();
    final option = find.text(set.name).last;
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();

    final confirm = find.byKey(const ValueKey('confirm-background-package'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.background, SrdBackground.soldier);
    expect(results.single!.takeGold, isFalse);
    expect(results.single!.gamingSetCatalogId, set.id);
    expect(tester.takeException(), isNull);
  });
}
