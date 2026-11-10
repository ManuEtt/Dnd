import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/srd_material_inventory_dialog.dart';

HeroCharacter _hero(List<InventoryItem> inventory) => HeroCharacter(
  id: 'live-material-hero',
  name: 'Prüfmagierin',
  className: 'Magier',
  level: 9,
  hitPoints: 34,
  maxHitPoints: 34,
  inventory: inventory,
);

Finder _field(String suffix) => find.byKey(ValueKey('material-$suffix'));

Future<void> _open(
  WidgetTester tester, {
  required ValueNotifier<HeroCharacter> hero,
  required ValueNotifier<SrdSpellDefinition> spell,
  required List<SrdMaterialInventoryChoice?> results,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showDialog<SrdMaterialInventoryChoice>(
                  context: context,
                  builder: (_) => ValueListenableBuilder<HeroCharacter>(
                    valueListenable: hero,
                    builder: (_, currentHero, __) =>
                        ValueListenableBuilder<SrdSpellDefinition>(
                          valueListenable: spell,
                          builder: (_, currentSpell, __) =>
                              SrdMaterialInventoryDialog(
                                hero: currentHero,
                                spell: currentSpell,
                              ),
                        ),
                  ),
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

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _select(
  WidgetTester tester,
  String materialId,
  String visibleStack,
) async {
  await _tap(tester, _field('stack-$materialId'));
  await tester.tap(find.text(visibleStack).last);
  await tester.pumpAndSettle();
}

Future<void> _approve(WidgetTester tester, String materialId) async {
  await _tap(tester, _field('identity-$materialId'));
  await _tap(tester, _field('quantity-$materialId'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  testWidgets('new hero snapshot revokes old material choices and approvals', (
    tester,
  ) async {
    final original = _hero(const [
      InventoryItem(id: 'large', name: 'Alte Truhe'),
      InventoryItem(id: 'tiny', name: 'Alte Miniatur'),
    ]);
    final updated = _hero(const [
      InventoryItem(id: 'large', name: 'Neue Truhe'),
      InventoryItem(id: 'tiny', name: 'Neue Miniatur'),
    ]);
    final beforeOriginal = original.toJson();
    final beforeUpdated = updated.toJson();
    final hero = ValueNotifier<HeroCharacter>(original);
    final spell = ValueNotifier<SrdSpellDefinition>(
      catalog.find('Secret Chest')!,
    );
    addTearDown(hero.dispose);
    addTearDown(spell.dispose);
    final results = <SrdMaterialInventoryChoice?>[];
    await _open(tester, hero: hero, spell: spell, results: results);

    await _select(tester, 'secret-large-chest', 'Alte Truhe (1×) · large');
    await _approve(tester, 'secret-large-chest');
    await _select(tester, 'secret-tiny-replica', 'Alte Miniatur (1×) · tiny');
    await _approve(tester, 'secret-tiny-replica');

    hero.value = updated;
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('material-form-1')), findsOneWidget);
    expect(find.text('Alte Truhe (1×) · large'), findsNothing);
    for (final material in ['secret-large-chest', 'secret-tiny-replica']) {
      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        _field('stack-$material'),
      );
      expect(dropdown.initialValue, isNull);
      expect(
        tester.widget<CheckboxListTile>(_field('identity-$material')).value,
        isFalse,
      );
      expect(
        tester.widget<CheckboxListTile>(_field('quantity-$material')).value,
        isFalse,
      );
    }
    await _tap(tester, _field('confirm'));
    expect(_field('validation-error'), findsOneWidget);
    expect(results, isEmpty);

    await _select(tester, 'secret-large-chest', 'Neue Truhe (1×) · large');
    await _approve(tester, 'secret-large-chest');
    await _select(tester, 'secret-tiny-replica', 'Neue Miniatur (1×) · tiny');
    await _approve(tester, 'secret-tiny-replica');
    await _tap(tester, _field('confirm'));
    expect(results, hasLength(1));
    expect(results.single, isNotNull);
    expect(results.single!.bindings.map((binding) => binding.inventoryId), [
      'large',
      'tiny',
    ]);
    expect(original.toJson(), beforeOriginal);
    expect(updated.toJson(), beforeUpdated);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spell change rebuilds recipe and clears validation state', (
    tester,
  ) async {
    final original = _hero(const [
      InventoryItem(id: 'large', name: 'Truhe'),
      InventoryItem(id: 'tiny', name: 'Miniatur'),
    ]);
    final before = original.toJson();
    final hero = ValueNotifier<HeroCharacter>(original);
    final spell = ValueNotifier<SrdSpellDefinition>(
      catalog.find('Secret Chest')!,
    );
    addTearDown(hero.dispose);
    addTearDown(spell.dispose);
    final results = <SrdMaterialInventoryChoice?>[];
    await _open(tester, hero: hero, spell: spell, results: results);

    await _select(tester, 'secret-large-chest', 'Truhe (1×) · large');
    await _approve(tester, 'secret-large-chest');
    spell.value = catalog.find('Clone')!;
    await tester.pumpAndSettle();

    expect(_field('stack-secret-large-chest'), findsNothing);
    expect(_field('stack-clone-diamond'), findsOneWidget);
    expect(_field('stack-clone-vessel'), findsOneWidget);
    await _tap(tester, _field('confirm'));
    expect(_field('validation-error'), findsOneWidget);
    expect(results, isEmpty);

    spell.value = catalog.find('Magic Missile')!;
    await tester.pumpAndSettle();
    expect(_field('setup-error'), findsOneWidget);
    expect(_field('validation-error'), findsNothing);
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );

    spell.value = catalog.find('Secret Chest')!;
    await tester.pumpAndSettle();
    expect(_field('setup-error'), findsNothing);
    expect(_field('validation-error'), findsNothing);
    expect(
      tester.widget<DropdownButtonFormField<String>>(
        _field('stack-secret-large-chest'),
      ).initialValue,
      isNull,
    );
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(original.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid inventory snapshot blocks and later recovers', (
    tester,
  ) async {
    final valid = _hero(const [
      InventoryItem(id: 'large', name: 'Truhe'),
      InventoryItem(id: 'tiny', name: 'Miniatur'),
    ]);
    final invalid = _hero(const [
      InventoryItem(id: 'same', name: 'Doppelt A'),
      InventoryItem(id: 'same', name: 'Doppelt B'),
    ]);
    final validBefore = valid.toJson();
    final invalidBefore = invalid.toJson();
    final hero = ValueNotifier<HeroCharacter>(valid);
    final spell = ValueNotifier<SrdSpellDefinition>(
      catalog.find('Secret Chest')!,
    );
    addTearDown(hero.dispose);
    addTearDown(spell.dispose);
    final results = <SrdMaterialInventoryChoice?>[];
    await _open(tester, hero: hero, spell: spell, results: results);

    hero.value = invalid;
    await tester.pumpAndSettle();
    expect(_field('setup-error'), findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );
    expect(find.text('Doppelt A (1×) · same'), findsNothing);

    hero.value = valid;
    await tester.pumpAndSettle();
    expect(_field('setup-error'), findsNothing);
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNotNull,
    );
    await _tap(tester, _field('confirm'));
    expect(_field('validation-error'), findsOneWidget);
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(valid.toJson(), validBefore);
    expect(invalid.toJson(), invalidBefore);
    expect(tester.takeException(), isNull);
  });
}
