import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/ui/equipment_catalog_dialog.dart';

void main() {
  testWidgets('equipment can be searched and explicitly selected', (
    tester,
  ) async {
    EquipmentEntry? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showDialog<EquipmentEntry>(
                  context: context,
                  builder: (_) => const EquipmentCatalogDialog(),
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
    expect(find.text('SRD-Ausrüstungskatalog'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('equipment-catalog-search')),
      'Langschwert',
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('equipment-catalog-item-weapon-longsword')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('equipment-catalog-item-weapon-longsword')),
    );
    await tester.pumpAndSettle();
    expect(selected?.id, 'weapon-longsword');
    expect(find.text('SRD-Ausrüstungskatalog'), findsNothing);
  });

  testWidgets('closing catalog creates no selection', (tester) async {
    EquipmentEntry? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showDialog<EquipmentEntry>(
                  context: context,
                  builder: (_) => const EquipmentCatalogDialog(),
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
}
