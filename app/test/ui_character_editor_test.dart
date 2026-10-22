import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

Finder field(String label) => find.widgetWithText(TextFormField, label);

Future<void> openEditor(
  WidgetTester tester,
  HeroCharacter? hero,
  void Function(HeroCharacter?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              onResult(
                await Navigator.push<HeroCharacter>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CharacterEditor(hero: hero),
                  ),
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

Future<void> save(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final button = find.text('Charakter speichern');
  await tester.scrollUntilVisible(
    button,
    500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  expect(button.hitTestable(), findsOneWidget);
  final saveControl = tester.widget<FantasyTextButton>(
    find.byKey(const ValueKey('editor-save-fixed')),
  );
  expect(saveControl.style, FantasyButtonStyle.woodGold);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
  testWidgets(
    'Editing imported unknown scores preserves null and historical notes',
    (tester) async {
      final original = HeroCharacter(
        id: 'arescan',
        name: 'Arescan',
        className: 'Waldläufer',
        unverifiedNotes: [
          'Geschicklichkeitsmodifikator +7 war historisch unbestätigt.',
        ],
        inventory: [
          const InventoryItem(id: 'key', name: 'Magischer Schlüssel'),
        ],
      );
      HeroCharacter? result;
      await openEditor(tester, original, (hero) => result = hero);
      await save(tester);
      expect(result, isNotNull);
      expect(result!.abilities.values, everyElement(isNull));
      expect(result!.hitPoints, isNull);
      expect(result!.gold, isNull);
      expect(result!.experience, isNull);
      expect(result!.weaponDamage, isEmpty);
      expect(result!.unverifiedNotes, original.unverifiedNotes);
      expect(result!.inventory.single.name, 'Magischer Schlüssel');
      expect(result!.isComplete, isFalse);
    },
  );

  testWidgets('New character is saved using supported versioned schema', (
    tester,
  ) async {
    HeroCharacter? result;
    await openEditor(tester, null, (hero) => result = hero);
    await tester.enterText(field('Charaktername'), 'Elowen');
    await save(tester);
    expect(result, isNotNull);
    expect(result!.name, 'Elowen');
    expect(result!.level, 1);
    expect(HeroCharacter.fromJson(result!.toJson()).id, result!.id);
    expect(result!.abilities['dexterity'], isNull);
    expect(result!.gold, isNull);
    expect(result!.experience, 0);
  });

  testWidgets(
    'new character starts at 0 EP and advances to the SRD threshold',
    (tester) async {
      HeroCharacter? result;
      await openEditor(tester, null, (hero) => result = hero);
      await tester.enterText(field('Charaktername'), 'Talyn');
      final level = field('Stufe');
      await tester.scrollUntilVisible(
        level,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(level, '3');
      await tester.pumpAndSettle();
      final xp = tester.widget<TextFormField>(field('Erfahrungspunkte'));
      expect(xp.controller!.text, '900');
      await save(tester);
      expect(result?.level, 3);
      expect(result?.experience, 900);
    },
  );

  testWidgets('HP above maximum is rejected instead of silently clamped', (
    tester,
  ) async {
    HeroCharacter? result;
    await openEditor(
      tester,
      HeroCharacter(id: 'hero', name: 'Elowen'),
      (hero) => result = hero,
    );
    await tester.scrollUntilVisible(
      field('Aktuelle TP'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field('Aktuelle TP'), '99');
    await tester.enterText(field('Maximale TP'), '12');
    await save(tester);
    expect(result, isNull);
    expect(
      find.textContaining('das Maximum nicht überschreiten'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Inventory can be added with quantity through accessible fields',
    (tester) async {
      HeroCharacter? result;
      await openEditor(
        tester,
        HeroCharacter(id: 'hero', name: 'Elowen'),
        (hero) => result = hero,
      );
      final addItemButton = find.byKey(
        const ValueKey('character-inventory-add'),
      );
      final editorList = find.byType(ListView).first;
      // Inventory is near the end of a lazily built ListView. Large
      // scrollUntilVisible steps can move past the short button before it is
      // built, resulting in StateError: Bad state: No element. Advance the
      // actual editor list in small increments and wait for each layout.
      for (var step = 0; step < 60; step++) {
        if (addItemButton.hitTestable().evaluate().isNotEmpty) break;
        await tester.drag(editorList, const Offset(0, -160));
        await tester.pumpAndSettle();
      }
      expect(addItemButton.hitTestable(), findsOneWidget);
      await tester.tap(addItemButton);
      await tester.pumpAndSettle();
      await tester.enterText(field('Name'), 'Seil');
      await tester.enterText(field('Anzahl'), '2');
      await tester.tap(find.widgetWithText(FantasyTextButton, 'Speichern'));
      await tester.pumpAndSettle();
      await save(tester);
      expect(result!.inventory.single.name, 'Seil');
      expect(result!.inventory.single.quantity, 2);
    },
  );

  testWidgets('Abbrechen bei eigener Ausrüstung übernimmt keinen Gegenstand', (
    tester,
  ) async {
    HeroCharacter? result;
    await openEditor(
      tester,
      HeroCharacter(id: 'cancel-hero', name: 'Elowen'),
      (hero) => result = hero,
    );
    final addItemButton = find.byKey(const ValueKey('character-inventory-add'));
    final editorList = find.byType(ListView).first;
    for (var step = 0; step < 60; step++) {
      if (addItemButton.hitTestable().evaluate().isNotEmpty) break;
      await tester.drag(editorList, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
    expect(addItemButton.hitTestable(), findsOneWidget);
    await tester.tap(addItemButton);
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Nicht übernommenes Seil');
    // The editor footer has another Abbrechen action beneath the modal.
    // Target the dialog's own action so closing the item never closes the hero.
    final cancel = find.byKey(const ValueKey('inventory-item-cancel'));
    expect(cancel, findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(cancel).style,
      FantasyButtonStyle.iron,
    );
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await save(tester);
    expect(result, isNotNull);
    expect(result!.inventory, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Eigene Waffenwerte stehen in getrennten Inventarfeldern', (
    tester,
  ) async {
    HeroCharacter? result;
    await openEditor(
      tester,
      HeroCharacter(id: 'custom-hero', name: 'Elowen'),
      (hero) => result = hero,
    );
    final addItemButton = find.byKey(const ValueKey('character-inventory-add'));
    final list = find.byType(ListView).first;
    for (var step = 0; step < 60; step++) {
      if (addItemButton.hitTestable().evaluate().isNotEmpty) break;
      await tester.drag(list, const Offset(0, -160));
      await tester.pumpAndSettle();
    }
    await tester.tap(addItemButton);
    await tester.pumpAndSettle();
    await tester.enterText(field('Name'), 'Eigener Säbel');
    await tester.tap(find.byKey(const ValueKey('item-stat-kind')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Waffe').last);
    await tester.pumpAndSettle();
    final damage = find.byKey(const ValueKey('item-stat-damage'));
    await tester.ensureVisible(damage);
    await tester.enterText(damage, '1d6');
    final damageType = find.byKey(const ValueKey('item-stat-damageType'));
    await tester.ensureVisible(damageType);
    await tester.enterText(damageType, 'Hieb');
    await tester.tap(find.widgetWithText(FantasyTextButton, 'Speichern'));
    await tester.pumpAndSettle();
    await save(tester);
    expect(result, isNotNull);
    final item = result!.inventory.single;
    expect(item.stats!.kind, InventoryItemKind.weapon);
    expect(item.stats!.damage, '1d6');
    expect(item.stats!.damageType, 'Hieb');
    expect(item.catalogId, isEmpty);
    expect(item.description, isEmpty);
  });

  testWidgets(
    'SRD catalog item is stored with an immutable catalog reference',
    (tester) async {
      HeroCharacter? result;
      await openEditor(
        tester,
        HeroCharacter(id: 'hero', name: 'Elowen'),
        (hero) => result = hero,
      );
      final open = find.byKey(const ValueKey('character-catalog-open'));
      final list = find.byType(ListView).first;
      for (var step = 0; step < 60; step++) {
        if (open.hitTestable().evaluate().isNotEmpty) break;
        await tester.drag(list, const Offset(0, -160));
        await tester.pumpAndSettle();
      }
      expect(open.hitTestable(), findsOneWidget);
      await tester.tap(open);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('equipment-catalog-search')),
        'Longsword',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('equipment-catalog-item-weapon-longsword')),
      );
      await tester.pumpAndSettle();
      await save(tester);
      expect(result, isNotNull);
      expect(result!.inventory, hasLength(1));
      expect(result!.inventory.single.name, 'Langschwert');
      expect(result!.inventory.single.catalogId, 'weapon-longsword');
      expect(result!.inventory.single.stats!.damage, '1d8');
      expect(result!.inventory.single.description, isEmpty);
    },
  );
}
