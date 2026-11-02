import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/srd_material_inventory_dialog.dart';

HeroCharacter _hero(List<InventoryItem> inventory) => HeroCharacter(
  id: 'material-ime',
  name: 'Prüfmagierin',
  className: 'Magier',
  level: 9,
  hitPoints: 34,
  maxHitPoints: 34,
  inventory: inventory,
);

Finder _key(String name) => find.byKey(ValueKey('material-$name'));

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required HeroCharacter hero,
  required SrdSpellDefinition spell,
  required ValueChanged<SrdMaterialInventoryChoice?> onResult,
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
                await showDialog<SrdMaterialInventoryChoice>(
                  context: context,
                  builder: (_) =>
                      SrdMaterialInventoryDialog(hero: hero, spell: spell),
                ),
              );
            },
            child: const Text('Materialien öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Materialien öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _stack(
  WidgetTester tester,
  String material,
  String display,
) async {
  await _tap(tester, _key('stack-$material'));
  final option = find.text(display).last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _checks(WidgetTester tester, String material) async {
  await _tap(tester, _key('identity-$material'));
  await _tap(tester, _key('quantity-$material'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('Material-Dialog $width dp/200 %/IME: fehlendes Rezept', (
      tester,
    ) async {
      final hero = _hero(const []);
      final snapshot = hero.toJson();
      final results = <SrdMaterialInventoryChoice?>[];
      await _open(
        tester,
        width: width,
        hero: hero,
        spell: catalog.find('Magic Missile')!,
        onResult: results.add,
      );

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      expect(_key('setup-error'), findsOneWidget);
      expect(
        tester.widget<FantasyTextButton>(_key('confirm')).onPressed,
        isNull,
      );
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Semantics) return false;
          return widget.properties.liveRegion ?? false;
        }),
        findsWidgets,
      );
      await _tap(tester, find.text('Abbrechen'));
      expect(results, [null]);
      expect(hero.toJson(), snapshot);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: unbestätigte Stapel ohne Ressourcenbuchung', (
    tester,
  ) async {
    final hero = _hero(const [
      InventoryItem(id: 'large', name: 'Truhe'),
      InventoryItem(id: 'tiny', name: 'Miniatur'),
    ]);
    final snapshot = hero.toJson();
    final results = <SrdMaterialInventoryChoice?>[];
    await _open(
      tester,
      width: 320,
      hero: hero,
      spell: catalog.find('Secret Chest')!,
      onResult: results.add,
    );

    final last = _key('quantity-secret-tiny-replica');
    expect(
      find.ancestor(of: last, matching: find.byType(Scrollable)),
      findsOneWidget,
    );
    await _tap(tester, _key('confirm'));
    expect(_key('validation-error'), findsOneWidget);
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(hero.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: geprüfte Stapel nur als Auswahl zurückgeben', (
    tester,
  ) async {
    final hero = _hero(const [
      InventoryItem(id: 'large', name: 'Truhe'),
      InventoryItem(id: 'tiny', name: 'Miniatur'),
    ]);
    final snapshot = hero.toJson();
    final results = <SrdMaterialInventoryChoice?>[];
    await _open(
      tester,
      width: 360,
      hero: hero,
      spell: catalog.find('Secret Chest')!,
      onResult: results.add,
    );

    await _stack(tester, 'secret-large-chest', 'Truhe (1×) · large');
    await _checks(tester, 'secret-large-chest');
    await _stack(tester, 'secret-tiny-replica', 'Miniatur (1×) · tiny');
    await _checks(tester, 'secret-tiny-replica');
    await _tap(tester, _key('confirm'));

    expect(results, hasLength(1));
    expect(results.single!.bindings.map((b) => b.inventoryId).toList(), [
      'large',
      'tiny',
    ]);
    expect(
      results.single!.confirmations.every((c) => c.requiredQuantityConfirmed),
      isTrue,
    );
    expect(hero.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp/200 %/IME: Astral Projection Zieleingabe erreichbar', (
    tester,
  ) async {
    final hero = _hero(const []);
    final snapshot = hero.toJson();
    final results = <SrdMaterialInventoryChoice?>[];
    await _open(
      tester,
      width: 320,
      hero: hero,
      spell: catalog.find('Astral Projection')!,
      onResult: results.add,
    );

    final targetCount = _key('target-count');
    expect(targetCount, findsOneWidget);
    await tester.ensureVisible(targetCount);
    await tester.pumpAndSettle();
    await tester.enterText(targetCount, '3');
    await tester.pumpAndSettle();
    final editable = find.descendant(
      of: targetCount,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(editable).controller.text, '3');
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(hero.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });
}
