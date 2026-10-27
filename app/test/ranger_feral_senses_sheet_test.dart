import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter rangerForSheet(int level) => HeroCharacter(
  id: 'ranger-sight-sheet',
  name: 'Waldwacht',
  className: 'Waldläufer',
  level: level,
  hitPoints: 18,
  maxHitPoints: 18,
  speed: 9,
  armorClass: 14,
  abilities: const {
    'strength': 12,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 16,
    'charisma': 10,
  },
);

Future<void> showDefenses(WidgetTester tester, HeroCharacter hero) async {
  tester.view.physicalSize = const Size(360, 900);
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
  testWidgets('At level 18 the Ranger sheet displays Blindsight 9m', (
    tester,
  ) async {
    await showDefenses(tester, rangerForSheet(18));
    expect(find.text('Blindsicht (Feral Senses)'), findsOneWidget);
    expect(find.text('9 m (30 Fuß)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('At level 17 the sheet does not invent Blindsight', (
    tester,
  ) async {
    await showDefenses(tester, rangerForSheet(17));
    expect(find.text('Blindsicht (Feral Senses)'), findsNothing);
    expect(find.text('9 m (30 Fuß)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
