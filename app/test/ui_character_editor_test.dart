import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';

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
    expect(result!.experience, isNull);
  });

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
      final addItemButton =
          find.byKey(const ValueKey('character-inventory-add'));
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
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();
      await save(tester);
      expect(result!.inventory.single.name, 'Seil');
      expect(result!.inventory.single.quantity, 2);
    },
  );
}
