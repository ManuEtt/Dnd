import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/ui/equipment_fields.dart';
import 'package:lebendiger_spielleiter/ui/equipment_catalog_dialog.dart';

void main() {
  final sword = SrdEquipmentCatalog.byId('weapon-longsword')!;

  test('Eigene Werte statt Freitext', () {
    final attributes = EquipmentFields.attributes(sword);
    final map = {for (final field in attributes) field.id: field.value};
    expect(map['damage'], sword.damage);
    expect(map['damageType'], sword.damageType);
    expect(map['price'], sword.priceLabel);
    expect(map['weight'], isNotNull);
    expect(map.containsKey('note'), false);
  });

  testWidgets('Katalog zeigt Einzelwerte und öffnet das Detailblatt',
      (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showDialog<EquipmentEntry>(
          context: context,
          builder: (_) => const EquipmentCatalogDialog(),
        ),
        child: const Text('Katalog'),
      ),
    ))));
    await tester.tap(find.text('Katalog'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('equipment-catalog-search')), 'Langschwert');
    await tester.pumpAndSettle();
    expect(find.text(sword.detail), findsNothing);
    await tester.tap(find.byTooltip('Werte für Langschwert anzeigen'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('equipment-value-weapon-longsword-damage')),
        findsOneWidget);
    expect(find.text('Schadensart'), findsOneWidget);
    expect(find.text('Waffeneigenschaften'), findsOneWidget);
    expect(find.text('Gewicht'), findsOneWidget);
    expect(find.text('Preis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
