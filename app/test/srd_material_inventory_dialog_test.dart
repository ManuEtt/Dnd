import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/ui/srd_material_inventory_dialog.dart';

HeroCharacter _hero(List<InventoryItem> inventory) => HeroCharacter(
  id: 'material-dialog-hero',
  name: 'Prüfmagierin',
  className: 'Magier',
  level: 9,
  hitPoints: 34,
  maxHitPoints: 34,
  inventory: inventory,
);

Future<void> _open(
  WidgetTester tester,
  HeroCharacter hero,
  SrdSpellDefinition spell,
  void Function(SrdMaterialInventoryChoice?) receive,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              receive(
                await showDialog<SrdMaterialInventoryChoice>(
                  context: context,
                  builder: (_) =>
                      SrdMaterialInventoryDialog(hero: hero, spell: spell),
                ),
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
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selectStack(
  WidgetTester tester,
  String materialId,
  String display,
) async {
  final picker = find.byKey(ValueKey('material-stack-$materialId'));
  await _tapVisible(tester, picker);
  await tester.tap(find.text(display).last);
  await tester.pumpAndSettle();
}

Future<void> _confirmPosition(
  WidgetTester tester,
  String materialId, {
  bool consumed = false,
}) async {
  await _tapVisible(
    tester,
    find.byKey(ValueKey('material-identity-$materialId')),
  );
  await _tapVisible(
    tester,
    find.byKey(ValueKey('material-quantity-$materialId')),
  );
  if (consumed) {
    await _tapVisible(
      tester,
      find.byKey(ValueKey('material-reserved-$materialId')),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  testWidgets('missing confirmations never submit or spend resources', (
    tester,
  ) async {
    SrdMaterialInventoryChoice? selected;
    final hero = _hero(const [
      InventoryItem(id: 'large', name: 'Truhe'),
      InventoryItem(id: 'tiny', name: 'Miniatur'),
    ]);
    await _open(tester, hero, catalog.find('Secret Chest')!, (v) {
      selected = v;
    });
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('material-confirm')),
    );
    expect(find.byKey(const ValueKey('material-validation-error')), findsOneWidget);
    expect(selected, isNull);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.inventory, hasLength(2));
    await _tapVisible(tester, find.text('Abbrechen'));
    expect(selected, isNull);
  });

  testWidgets('both Secret Chest stacks confirmed return read-only choice', (
    tester,
  ) async {
    SrdMaterialInventoryChoice? selected;
    final hero = _hero(const [
      InventoryItem(id: 'large', name: 'Truhe'),
      InventoryItem(id: 'tiny', name: 'Miniatur'),
    ]);
    await _open(tester, hero, catalog.find('Secret Chest')!, (v) {
      selected = v;
    });
    await _selectStack(tester, 'secret-large-chest', 'Truhe (1×) · large');
    await _confirmPosition(tester, 'secret-large-chest');
    await _selectStack(tester, 'secret-tiny-replica', 'Miniatur (1×) · tiny');
    await _confirmPosition(tester, 'secret-tiny-replica');
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('material-confirm')),
    );
    expect(selected, isNotNull);
    expect(selected!.bindings.map((b) => b.inventoryId).toList(), [
      'large',
      'tiny',
    ]);
    expect(selected!.confirmations.every((c) => c.requiredQuantityConfirmed), isTrue);
    expect(selected!.confirmedTargetCount, isNull);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.inventory.map((e) => e.quantity).toList(), [1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate inventory selection is blocked, not guessed', (
    tester,
  ) async {
    SrdMaterialInventoryChoice? selected;
    final hero = _hero(const [
      InventoryItem(id: 'large', name: 'Truhe', quantity: 2),
      InventoryItem(id: 'tiny', name: 'Miniatur'),
    ]);
    await _open(tester, hero, catalog.find('Secret Chest')!, (v) {
      selected = v;
    });
    await _selectStack(tester, 'secret-large-chest', 'Truhe (2×) · large');
    await _confirmPosition(tester, 'secret-large-chest');
    await _selectStack(tester, 'secret-tiny-replica', 'Truhe (2×) · large');
    await _confirmPosition(tester, 'secret-tiny-replica');
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('material-confirm')),
    );
    expect(find.byKey(const ValueKey('material-validation-error')), findsOneWidget);
    expect(selected, isNull);
  });

  testWidgets('Clone diamond explicitly requires consumption confirmation', (
    tester,
  ) async {
    SrdMaterialInventoryChoice? selected;
    final hero = _hero(const [
      InventoryItem(id: 'diamond', name: 'Diamant'),
      InventoryItem(id: 'vessel', name: 'Gefäß'),
    ]);
    await _open(tester, hero, catalog.find('Clone')!, (v) {
      selected = v;
    });
    await _selectStack(tester, 'clone-diamond', 'Diamant (1×) · diamond');
    await _confirmPosition(tester, 'clone-diamond');
    await _selectStack(tester, 'clone-vessel', 'Gefäß (1×) · vessel');
    await _confirmPosition(tester, 'clone-vessel');
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('material-confirm')),
    );
    expect(find.byKey(const ValueKey('material-validation-error')), findsOneWidget);
    expect(selected, isNull);
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('material-reserved-clone-diamond')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('material-confirm')),
    );
    expect(selected, isNotNull);
    expect(selected!.confirmations.first.consumptionReservedConfirmed, isTrue);
    expect(selected!.confirmations.last.consumptionReservedConfirmed, isFalse);
    expect(hero.spentSpellSlots, isEmpty);
  });

  testWidgets('unknown recipe stays disabled without inventing materials', (
    tester,
  ) async {
    SrdMaterialInventoryChoice? selected;
    await _open(
      tester,
      _hero(const []),
      catalog.find('Magic Missile')!,
      (v) => selected = v,
    );
    expect(find.byKey(const ValueKey('material-setup-error')), findsOneWidget);
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });
}
