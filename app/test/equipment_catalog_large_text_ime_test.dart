import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/ui/equipment_catalog_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

Future<List<EquipmentEntry?>> _openCatalog(
  WidgetTester tester, {
  required double width,
  double textScale = 2,
  double keyboardHeight = 220,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardHeight);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  final results = <EquipmentEntry?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
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
  return results;
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Ausrüstungskatalog $width dp, 200 % und IME: Name und Aktionen erreichbar',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final results = await _openCatalog(tester, width: width);

        final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
        expect(dialog.scrollable, isTrue);
        final search = find.byKey(const ValueKey('equipment-catalog-search'));
        expect(
          tester.widget<TextField>(search).textInputAction,
          TextInputAction.search,
        );

        await tester.enterText(search, 'Langschwert');
        await tester.pumpAndSettle();

        // The search controls share one lazily built result list. At 200%
        // text and with the IME open, the first matching item is initially
        // below the viewport; scroll it into the render tree before checking.
        final item = find.byKey(
          const ValueKey('equipment-catalog-item-weapon-longsword'),
        );
        await tester.scrollUntilVisible(
          item,
          120,
          scrollable: find.descendant(
            of: find.byKey(const ValueKey('equipment-catalog-results')),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(item, findsOneWidget);
        final tile = tester.widget<ListTile>(item);
        expect(tile.trailing, isNull);
        expect((tile.title! as Text).data, 'Langschwert');
        expect((tile.subtitle! as Text).maxLines, isNull);

        final add = find.byTooltip('Langschwert hinzufügen');
        final info = find.byTooltip('Werte für Langschwert anzeigen');
        expect(add, findsOneWidget);
        expect(info, findsOneWidget);
        expect(find.bySemanticsLabel('Langschwert hinzufügen'), findsOneWidget);
        await tester.ensureVisible(add);
        await tester.pumpAndSettle();
        expect(add.hitTestable(), findsOneWidget);
        await tester.tap(add);
        await tester.pumpAndSettle();

        expect(results.map((entry) => entry?.id), ['weapon-longsword']);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets(
    'IME und große Schrift: keine Treffer, Abbruch liefert keine Auswahl',
    (tester) async {
      final results = await _openCatalog(tester, width: 320);
      final search = find.byKey(const ValueKey('equipment-catalog-search'));

      await tester.enterText(search, 'unauffindbarer Gegenstand xyz');
      await tester.pumpAndSettle();
      expect(find.text('0 Treffer'), findsOneWidget);
      // The empty-state item is also built lazily below the search form.
      final empty = find.text('Keine Gegenstände gefunden.');
      await tester.scrollUntilVisible(
        empty,
        120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('equipment-catalog-results')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(empty, findsOneWidget);
      final cancel = find.text('Abbrechen');
      await tester.ensureVisible(cancel);
      await tester.pumpAndSettle();
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(results, [null]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Normale Schrift behält kompakte Gegenstandszeilen und die Auswahl',
    (tester) async {
      final results = await _openCatalog(
        tester,
        width: 360,
        textScale: 1,
        keyboardHeight: 0,
      );
      await tester.enterText(
        find.byKey(const ValueKey('equipment-catalog-search')),
        'Langschwert',
      );
      await tester.pumpAndSettle();
      final item = find.byKey(
        const ValueKey('equipment-catalog-item-weapon-longsword'),
      );
      expect(item, findsOneWidget);
      expect(tester.widget<ListTile>(item).trailing, isA<Row>());
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
      expect(results.map((entry) => entry?.id), ['weapon-longsword']);
      expect(tester.takeException(), isNull);
    },
  );
}
