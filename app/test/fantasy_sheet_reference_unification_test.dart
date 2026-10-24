import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'sheet-audit',
  name: 'Liora Mondhain',
  species: 'Mensch',
  className: 'Kleriker',
  level: 5,
  hitPoints: 38,
  maxHitPoints: 38,
  armorClass: 17,
  speed: 9,
  abilities: const {
    'strength': 10,
    'dexterity': 14,
    'constitution': 16,
    'intelligence': 12,
    'wisdom': 18,
    'charisma': 13,
  },
  skills: const ['Medizin', 'Wahrnehmung', 'Religion'],
  spells: const ['Segen', 'Heilendes Wort'],
  inventory: const [
    InventoryItem(id: 'mace', name: 'Streitkolben'),
    InventoryItem(id: 'potion', name: 'Heiltrank', quantity: 3),
  ],
);

void main() {
  testWidgets('Referenzübersicht zeigt echte Übungsboni statt Attributliste', (
    tester,
  ) async {
    final hero = _hero();
    final before = hero.toJson();
    await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(hero: hero)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sheet-preview-fertigkeiten')),
      230,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final skills = find.byKey(const ValueKey('sheet-preview-fertigkeiten'));
    expect(skills, findsOneWidget);
    expect(
      find.descendant(of: skills, matching: find.text('Medizin')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: skills, matching: find.text('Wahrnehmung')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: skills, matching: find.text('+7')),
      findsNWidgets(2),
    ); // Wisdom +4 + level-5 proficiency +3.
    expect(
      find.descendant(of: skills, matching: find.text('Athletik')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: skills, matching: find.text('+0')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: skills, matching: find.text('Religion')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: skills, matching: find.text('+4')),
      findsOneWidget,
    ); // Intelligence +1 + proficiency +3.
    expect(
      find.byKey(const ValueKey('sheet-parchment-abilities')),
      findsOneWidget,
    );
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 820.0]) {
    testWidgets('W20-Dock bleibt bei Scrollen auf $width dp fest', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var rolls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSheetPage(hero: _hero(), onRoll: () => rolls++),
        ),
      );
      await tester.pumpAndSettle();
      final bar = find.byKey(const ValueKey('sheet-fixed-quick-navigation'));
      final top = tester.getTopLeft(bar).dy;
      for (final key in [
        'sheet-quick-charakter',
        'sheet-quick-inventar',
        'sheet-quick-roll',
        'sheet-quick-zauber',
        'sheet-quick-mehr',
      ]) {
        expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
      }
      await tester.drag(
        find.byKey(const ValueKey('fantasy-character-sheet-scroll')),
        const Offset(0, -450),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(bar).dy, closeTo(top, 1));
      expect(find.byKey(const ValueKey('sheet-d20-medallion')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sheet-quick-roll')));
      expect(rolls, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Große Android-Schrift erhält alle fünf Aktionen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.6)),
          child: child!,
        ),
        home: CharacterSheetPage(hero: _hero()),
      ),
    );
    await tester.pumpAndSettle();
    for (final key in [
      'sheet-quick-charakter',
      'sheet-quick-inventar',
      'sheet-quick-roll',
      'sheet-quick-zauber',
      'sheet-quick-mehr',
    ]) {
      expect(find.byKey(ValueKey(key)).hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Unbekannte Charakterwerte bleiben auch in der neuen Übersicht unbekannt',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSheetPage(
            hero: HeroCharacter(id: 'historical', name: 'Historisch'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sheet-parchment-abilities')),
        230,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sheet-parchment-abilities')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
