import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/ui/srd_background_package_dialog.dart';

Future<void> openDialog(
  WidgetTester tester,
  SrdBackground background,
  void Function(SrdBackgroundPackageChoice?) onDone,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final choice = await showDialog<SrdBackgroundPackageChoice>(
                context: context,
                builder: (_) =>
                    SrdBackgroundPackageDialog(background: background),
              );
              onDone(choice);
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
  testWidgets('gold option must be explicitly confirmed', (tester) async {
    SrdBackgroundPackageChoice? answer;
    await openDialog(
      tester,
      SrdBackground.criminal,
      (choice) => answer = choice,
    );
    expect(answer, isNull);
    await tester.tap(find.byKey(const ValueKey('background-gold-option')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-background-package')));
    await tester.pumpAndSettle();
    expect(answer, isNotNull);
    expect(answer!.takeGold, true);
    expect(answer!.startingGold, 50);
    expect(answer!.kitItems, isEmpty);
  });

  testWidgets('soldier game required and cancel leaves proposal empty', (
    tester,
  ) async {
    SrdBackgroundPackageChoice? answer;
    await openDialog(
      tester,
      SrdBackground.soldier,
      (choice) => answer = choice,
    );
    final confirm = find.byKey(const ValueKey('confirm-background-package'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(answer, isNull);
  });

  testWidgets('magic initiate pending spells are explicitly visible', (
    tester,
  ) async {
    SrdBackgroundPackageChoice? answer;
    await openDialog(
      tester,
      SrdBackground.acolyte,
      (choice) => answer = choice,
    );
    expect(find.textContaining('Zaubertricks'), findsOneWidget);
    final confirm = find.byKey(const ValueKey('confirm-background-package'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    expect(
      find.byKey(const ValueKey('background-holy-symbol')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('background-holy-symbol')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heiliges Symbol: Amulett').last);
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(answer!.background, SrdBackground.acolyte);
    expect(answer!.requiresFeatSpellChoices, true);
    expect(answer!.holySymbolCatalogId, 'item-holy-symbol-amulet');
  });

  testWidgets('acolyte 50 GP option skips holy symbol selection', (
    tester,
  ) async {
    SrdBackgroundPackageChoice? answer;
    await openDialog(tester, SrdBackground.acolyte, (value) => answer = value);
    final confirm = find.byKey(const ValueKey('confirm-background-package'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('background-gold-option')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('background-holy-symbol')), findsNothing);
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(answer!.takeGold, true);
    expect(answer!.holySymbolCatalogId, isEmpty);
    expect(answer!.startingGold, 50);
  });
}
