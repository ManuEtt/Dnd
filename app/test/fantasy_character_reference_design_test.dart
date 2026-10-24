import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter _sample() => HeroCharacter(
  id: 'reference-preview',
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
  skills: const ['Religion', 'Medizin', 'Wahrnehmung'],
  spells: const ['Heilendes Wort', 'Segen', 'Wunden heilen'],
  concentratingOn: 'Segen',
  inventory: const [
    InventoryItem(id: 'mace', name: 'Streitkolben'),
    InventoryItem(id: 'shield', name: 'Schild'),
    InventoryItem(id: 'potion', name: 'Heiltrank', quantity: 3),
  ],
);

void main() {
  for (final width in [320.0, 360.0, 400.0, 820.0]) {
    testWidgets('Fantasy-Referenzlayout auf $width dp ohne Überlauf', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: CharacterSheetPage(hero: _sample())),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sheet-reference-header')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('sheet-summary-hp')), findsOneWidget);
      expect(find.byKey(const ValueKey('sheet-summary-ac')), findsOneWidget);
      expect(find.text('38 / 38'), findsOneWidget);
      expect(find.text('RÜSTUNGSKLASSE'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sheet-parchment-abilities')),
        170,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sheet-parchment-abilities')),
        findsOneWidget,
      );
      final grid = tester.widget<GridView>(
        find.byKey(const ValueKey('sheet-preview-attributes-grid')),
      );
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, width < 705 ? 3 : 6);
      expect(find.byKey(const ValueKey('sheet-quick-roll')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sheet-preview-fertigkeiten')),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sheet-preview-fertigkeiten')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Feste untere Navigation nutzt echte Aktionen und speichert nichts',
    (tester) async {
      var rolls = 0;
      final hero = _sample();
      final before = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(
          home: CharacterSheetPage(hero: hero, onRoll: () => rolls++),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('sheet-quick-roll')));
      expect(rolls, 1);
      await tester.tap(find.byKey(const ValueKey('sheet-quick-inventar')));
      await tester.pumpAndSettle();
      expect(find.text('Ausrüstung und Inventar'), findsOneWidget);
      expect(find.textContaining('Heiltrank'), findsWidgets);
      await tester.tapAt(const Offset(5, 90));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('sheet-quick-zauber')));
      await tester.pumpAndSettle();
      expect(find.text('Bekannte Zauber'), findsOneWidget);
      expect(find.text('Segen'), findsWidgets);
      await tester.tapAt(const Offset(5, 90));
      await tester.pumpAndSettle();
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ohne aktiven Abenteuercontroller simuliert W20 keinen Wurf', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CharacterSheetPage(hero: _sample())),
    );
    await tester.tap(find.byKey(const ValueKey('sheet-quick-roll')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Würfelwürfe werden im aktiven Abenteuer'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unbekannte Attribute und leere Daten werden nicht erfunden', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterSheetPage(
          hero: HeroCharacter(id: 'legacy', name: 'Historischer Held'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('– / –'), findsOneWidget);
    expect(find.text('Noch nicht erfasst'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sheet-avatar-placeholder')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('sheet-parchment-abilities')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Große Schrift auf kleinem Android-Gerät bleibt ohne Überlauf', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.4)),
          child: child!,
        ),
        home: CharacterSheetPage(hero: _sample()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('sheet-parchment-abilities')),
      170,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('sheet-parchment-abilities')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
