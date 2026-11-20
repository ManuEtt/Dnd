import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/ui/equipment_catalog_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const _searchKey = ValueKey('equipment-catalog-search');
const _categoryKey = ValueKey('equipment-catalog-category');
const _resetKey = ValueKey('equipment-catalog-reset-filters');

Finder _allResults() =>
    find.text('${SrdEquipmentCatalog.all.length} Treffer');

EquipmentCategory? _selectedCategory(WidgetTester tester) => tester
    .widget<DropdownButton<EquipmentCategory?>>(find.byKey(_categoryKey))
    .value;

Future<List<EquipmentEntry?>> _showCatalog(
  WidgetTester tester, {
  required double width,
  double scale = 1,
  double keyboardHeight = 0,
}) async {
  tester.view.physicalSize = Size(width, 940);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  final selections = <EquipmentEntry?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selections.add(
                await showDialog<EquipmentEntry>(
                  context: context,
                  builder: (_) => const EquipmentCatalogDialog(),
                ),
              );
            },
            child: const Text('Katalog öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Katalog öffnen'));
  await tester.pumpAndSettle();
  return selections;
}

Future<void> _chooseSimpleMelee(WidgetTester tester) async {
  final category = find.byKey(_categoryKey);
  await tester.ensureVisible(category);
  await tester.pumpAndSettle();
  await tester.tap(category);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Einfache Nahkampfwaffen').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Suchtext und Kategorie in einem Schritt zurücksetzen', (
    tester,
  ) async {
    final selections = await _showCatalog(tester, width: 360);
    final search = find.byKey(_searchKey);

    expect(find.byKey(_resetKey), findsNothing);
    expect(_allResults(), findsOneWidget);

    await tester.enterText(search, 'Langschwert');
    await tester.pumpAndSettle();
    expect(find.text('1 Treffer'), findsOneWidget);

    await _chooseSimpleMelee(tester);
    expect(find.text('0 Treffer'), findsOneWidget);
    expect(
      _selectedCategory(tester),
      EquipmentCategory.simpleMelee,
    );

    final reset = find.byKey(_resetKey);
    expect(reset, findsOneWidget);
    expect(
      find.byTooltip('Suchtext und Kategorie zurücksetzen'),
      findsOneWidget,
    );
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    expect(reset.hitTestable(), findsOneWidget);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(search).controller!.text, isEmpty);
    expect(
      _selectedCategory(tester),
      isNull,
    );
    expect(_allResults(), findsOneWidget);
    expect(find.byKey(_resetKey), findsNothing);
    expect(selections, isEmpty);

    await tester.enterText(search, 'Langschwert');
    await tester.pumpAndSettle();
    final sword = find.byKey(
      const ValueKey('equipment-catalog-item-weapon-longsword'),
    );
    await tester.ensureVisible(sword);
    await tester.tap(sword);
    await tester.pumpAndSettle();

    expect(selections.map((entry) => entry?.id), ['weapon-longsword']);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('Filter löschen bei $width dp, 200 % Schrift und IME', (
      tester,
    ) async {
      final selections = await _showCatalog(
        tester,
        width: width,
        scale: 2,
        keyboardHeight: 220,
      );
      final search = find.byKey(_searchKey);
      await tester.enterText(search, 'nicht-vorhandener-gegenstand');
      await tester.pumpAndSettle();
      expect(find.text('0 Treffer'), findsOneWidget);

      final reset = find.byKey(_resetKey);
      await tester.ensureVisible(reset);
      await tester.pumpAndSettle();
      expect(reset.hitTestable(), findsOneWidget);
      expect(tester.getSize(reset).height, greaterThanOrEqualTo(48));
      await tester.tap(reset);
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(_allResults(), findsOneWidget);
      expect(find.byKey(_resetKey), findsNothing);
      expect(selections, isEmpty);
      expect(find.byType(EquipmentCatalogDialog), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Abbrechen'));
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(selections, [null]);
    });
  }

  testWidgets('Kategorie ohne Suchtext zurücksetzen, Auswahl nicht erfinden', (
    tester,
  ) async {
    final selections = await _showCatalog(tester, width: 360);
    await _chooseSimpleMelee(tester);
    final simpleMeleeCount = SrdEquipmentCatalog.search(
      '',
      category: EquipmentCategory.simpleMelee,
    ).length;
    expect(find.text('$simpleMeleeCount Treffer'), findsOneWidget);
    final reset = find.byKey(_resetKey);
    await tester.ensureVisible(reset);
    await tester.tap(reset);
    await tester.pumpAndSettle();

    expect(
      _selectedCategory(tester),
      isNull,
    );
    expect(_allResults(), findsOneWidget);
    expect(find.byKey(_resetKey), findsNothing);
    expect(selections, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
