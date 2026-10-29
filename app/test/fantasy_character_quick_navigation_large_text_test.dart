import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_overview.dart';

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('200 % Schrift: fünf Charakteraktionen bei $width dp lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final calls = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: const Center(child: Text('Charakterbogen')),
            bottomNavigationBar: FantasyCharacterQuickNavigation(
              onCharacter: () => calls.add('charakter'),
              onInventory: () => calls.add('inventar'),
              onRoll: () => calls.add('roll'),
              onSpells: () => calls.add('zauber'),
              onMore: () => calls.add('mehr'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final first = find.byKey(const ValueKey('sheet-quick-charakter'));
      final roll = find.byKey(const ValueKey('sheet-quick-roll'));
      final spells = find.byKey(const ValueKey('sheet-quick-zauber'));
      expect(
        tester.getTopLeft(spells).dy,
        greaterThan(tester.getTopLeft(roll).dy),
      );
      expect(
        tester.getTopLeft(roll).dy,
        closeTo(tester.getTopLeft(first).dy, 1),
      );
      expect(
        find.descendant(of: first, matching: find.byType(FittedBox)),
        findsNothing,
      );

      for (final name in ['charakter', 'inventar', 'roll', 'zauber', 'mehr']) {
        final action = find.byKey(ValueKey('sheet-quick-$name'));
        expect(action.hitTestable(), findsOneWidget);
        await tester.tap(action);
        await tester.pump();
      }
      expect(calls, ['charakter', 'inventar', 'roll', 'zauber', 'mehr']);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Standardtext behält alle fünf Aktionen auf einer Reihe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var rolls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: FantasyCharacterQuickNavigation(
            onCharacter: () {},
            onInventory: () {},
            onRoll: () => rolls++,
            onSpells: () {},
            onMore: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final roll = find.byKey(const ValueKey('sheet-quick-roll'));
    final spells = find.byKey(const ValueKey('sheet-quick-zauber'));
    expect(
      tester.getTopLeft(spells).dy,
      closeTo(tester.getTopLeft(roll).dy, 1),
    );
    await tester.tap(roll);
    expect(rolls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('200 % Schrift mit Android-IME: alle fünf Aktionen bleiben da', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 270);
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
          body: const TextField(),
          bottomNavigationBar: FantasyCharacterQuickNavigation(
            onCharacter: () {},
            onInventory: () {},
            onRoll: () {},
            onSpells: () {},
            onMore: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final name in ['charakter', 'inventar', 'roll', 'zauber', 'mehr']) {
      expect(
        find.byKey(ValueKey('sheet-quick-$name')).hitTestable(),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
