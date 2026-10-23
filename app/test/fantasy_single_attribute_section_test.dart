import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

void main() {
  final hero = HeroCharacter(
    id: 'unique-attributes',
    name: 'Liora',
    className: 'Kleriker',
    level: 5,
    hitPoints: 26,
    maxHitPoints: 26,
    armorClass: 16,
    abilities: const {
      'strength': 10,
      'dexterity': 14,
      'constitution': 16,
      'intelligence': 12,
      'wisdom': 18,
      'charisma': 13,
    },
    savingThrowProficiencies: const ['wisdom', 'charisma'],
    skills: const ['Medizin', 'Wahrnehmung'],
  );

  for (final width in [320.0, 360.0, 820.0]) {
    testWidgets('Attribute nur einmal bei $width dp, Regeln bleiben nutzbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final before = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(home: CharacterSheetPage(hero: hero)),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('sheet-fixed-quick-navigation')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sheet-parchment-abilities')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sheet-preview-attributes-grid')),
        findsOneWidget,
      );
      expect(find.text('Attribute'), findsOneWidget);
      expect(find.byKey(const ValueKey('sheet-abilities-grid')), findsNothing);

      final rulesTab = find.byKey(const ValueKey('sheet-tab-0'));
      await tester.scrollUntilVisible(
        rulesTab,
        210,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(rulesTab, findsOneWidget);
      expect(find.text('Regeln'), findsOneWidget);
      expect(find.byKey(const ValueKey('sheet-abilities-grid')), findsNothing);
      await tester.scrollUntilVisible(
        find.text('RETTUNGSWÜRFE'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('RETTUNGSWÜRFE'), findsOneWidget);
      for (final id in [
        'strength',
        'dexterity',
        'constitution',
        'intelligence',
        'wisdom',
        'charisma',
      ]) {
        expect(find.byKey(ValueKey('sheet-saving-throw-$id')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('sheet-abilities-grid')), findsNothing);
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Der Mehr-Dialog verweist auf Regeln statt zweite Attribute', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(hero: hero)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sheet-quick-mehr')));
    await tester.pumpAndSettle();
    expect(find.text('Regeln und Rettungswürfe'), findsOneWidget);
    expect(find.text('Attribute und Rettungswürfe'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
