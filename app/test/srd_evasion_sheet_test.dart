import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter _heroForSheet({
  String className = 'Mönch',
  int level = 7,
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
}) => HeroCharacter(
  id: 'evasion-sheet',
  name: 'Nebeltritt',
  className: className,
  level: level,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  hitPoints: 30,
  maxHitPoints: 30,
  armorClass: 15,
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

Future<void> _openDefenseTab(WidgetTester tester, HeroCharacter hero) async {
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
  testWidgets('360px Monk 7 and Rogue 7 sheet show Evasion correctly', (
    tester,
  ) async {
    for (final name in ['Mönch', 'Schurke']) {
      await _openDefenseTab(
        tester,
        _heroForSheet(className: name, level: 7),
      );
      expect(find.text('Entrinnen (Evasion)'), findsOneWidget);
      expect(
        find.text(
          'GE-Rettung: Erfolg 0 Schaden, Fehlschlag halber Schaden',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Below class level 7 no Evasion is invented', (tester) async {
    await _openDefenseTab(tester, _heroForSheet(level: 6));
    expect(find.text('Entrinnen (Evasion)'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Secondary Rogue level 7 displays Evasion', (tester) async {
    await _openDefenseTab(
      tester,
      _heroForSheet(
        className: 'Kämpfer',
        level: 12,
        secondaryClassName: 'Schurke',
        secondaryClassLevel: 7,
      ),
    );
    expect(find.text('Entrinnen (Evasion)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
