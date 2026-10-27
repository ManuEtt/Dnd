import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter sheetHero(int rangerLevel, {bool heavy = false}) => HeroCharacter(
  id: 'roving-sheet',
  name: 'Ari',
  className: 'Waldläufer',
  level: rangerLevel,
  hitPoints: 18,
  maxHitPoints: 18,
  speed: 9,
  armorClass: 14,
  abilities: const {
    'strength': 16,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 14,
    'charisma': 10,
  },
  inventory: const [
    InventoryItem(
      id: 'heavy',
      name: 'Plattenrüstung',
      catalogId: 'armor-plate-armor',
    ),
  ],
  equippedArmorId: heavy ? 'heavy' : '',
  equippedArmorTrained: true,
);

Future<void> openDefenses(WidgetTester tester, HeroCharacter hero) async {
  tester.view.physicalSize = const Size(400, 940);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(hero: hero)));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('sheet-tab-2')),
    190,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.byKey(const ValueKey('sheet-tab-2')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Waldläufer Stufe 6 zeigt Roving-Geschwindigkeiten', (
    tester,
  ) async {
    await openDefenses(tester, sheetHero(6));
    expect(find.text('Roving: Klettern / Schwimmen'), findsOneWidget);
    expect(find.text('12 m / 12 m'), findsOneWidget);
    expect(find.textContaining('12 m (Basis 9 m)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mit schwerer Rüstung werden beide Tempi ohne Bonus gezeigt', (
    tester,
  ) async {
    await openDefenses(tester, sheetHero(6, heavy: true));
    expect(find.text('Roving: Klettern / Schwimmen'), findsOneWidget);
    expect(find.text('9 m / 9 m'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unter Stufe 6 kein irreführender Roving-Eintrag', (
    tester,
  ) async {
    await openDefenses(tester, sheetHero(5));
    expect(find.text('Roving: Klettern / Schwimmen'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
