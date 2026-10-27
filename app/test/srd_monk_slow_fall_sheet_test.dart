import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter heroForSlowFallSheet({
  String className = 'Mönch',
  int level = 4,
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
}) => HeroCharacter(
  id: 'slow-fall-sheet',
  name: 'Leiser Schritt',
  className: className,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  level: level,
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 13,
  speed: 9,
  abilities: const {
    'strength': 10,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 16,
    'charisma': 10,
  },
);

Future<void> showSlowFallDefenses(
  WidgetTester tester,
  HeroCharacter hero,
) async {
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
  testWidgets('Monk 4 shows 20 damage reduction, without UI overflow', (
    tester,
  ) async {
    await showSlowFallDefenses(tester, heroForSlowFallSheet());
    expect(find.text('Sanfter Fall (Reaktion)'), findsOneWidget);
    expect(find.text('Bis zu 20 Schaden verhindern'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Monk 3 does not show a premature Reaction', (tester) async {
    await showSlowFallDefenses(tester, heroForSlowFallSheet(level: 3));
    expect(find.text('Sanfter Fall (Reaktion)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Secondary Monk 4 shows the class-level reduction', (
    tester,
  ) async {
    final hero = heroForSlowFallSheet(
      className: 'Kämpfer',
      level: 7,
      secondaryClassName: 'Mönch',
      secondaryClassLevel: 4,
    );
    await showSlowFallDefenses(tester, hero);
    expect(find.text('Sanfter Fall (Reaktion)'), findsOneWidget);
    expect(find.text('Bis zu 20 Schaden verhindern'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Secondary Monk 3 does not inherit a total-level benefit', (
    tester,
  ) async {
    final hero = heroForSlowFallSheet(
      className: 'Kämpfer',
      level: 6,
      secondaryClassName: 'Mönch',
      secondaryClassLevel: 3,
    );
    await showSlowFallDefenses(tester, hero);
    expect(find.text('Sanfter Fall (Reaktion)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
