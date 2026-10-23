import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'single-attribute-preview',
  name: 'Liora',
  className: 'Kleriker',
  level: 5,
  hitPoints: 38,
  maxHitPoints: 38,
  armorClass: 17,
  abilities: const {
    'strength': 10,
    'dexterity': 14,
    'constitution': 16,
    'intelligence': 12,
    'wisdom': 18,
    'charisma': 13,
  },
  savingThrowProficiencies: const ['dexterity', 'wisdom'],
  skills: const ['Medizin', 'Wahrnehmung'],
);

void main() {
  for (final width in [320.0, 360.0, 820.0]) {
    testWidgets(
      'Ein Attributraster bei $width dp, Rettungswürfe bleiben erhalten',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final hero = _hero();
        final unchanged = hero.toJson();

        await tester.pumpWidget(
          MaterialApp(home: CharacterSheetPage(hero: hero)),
        );
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('sheet-parchment-abilities')),
          220,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();

        final parchment = find.byKey(
          const ValueKey('sheet-preview-attributes-grid'),
        );
        expect(parchment, findsOneWidget);
        final grid = tester.widget<GridView>(parchment);
        expect(grid.childrenDelegate.estimatedChildCount, 6);
        for (final label in [
          'Stärke',
          'Geschicklichkeit',
          'Konstitution',
          'Intelligenz',
          'Weisheit',
          'Charisma',
        ]) {
          expect(
            find.byKey(ValueKey('sheet-parchment-ability-$label')),
            findsOneWidget,
          );
        }
        // The historical secondary grid must not reappear below the tabs.
        expect(
          find.byKey(const ValueKey('sheet-abilities-grid')),
          findsNothing,
        );

        final rulesTab = find.byKey(const ValueKey('sheet-tab-0'));
        await tester.scrollUntilVisible(
          rulesTab,
          220,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<FantasyToggleButton>(rulesTab).label, 'Regeln');

        await tester.scrollUntilVisible(
          find.text('RETTUNGSWÜRFE'),
          220,
          scrollable: scrollable,
        );
        await tester.pumpAndSettle();
        expect(find.text('RETTUNGSWÜRFE'), findsOneWidget);
        expect(find.text('+5'), findsWidgets); // Dex +2 + level-5 +3.
        expect(find.text('+7'), findsWidgets); // Wisdom +4 + level-5 +3.
        expect(
          find.byKey(const ValueKey('sheet-abilities-grid')),
          findsNothing,
        );
        expect(find.byKey(const ValueKey('sheet-quick-roll')), findsOneWidget);
        expect(hero.toJson(), unchanged);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
