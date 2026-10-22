import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_ornaments.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_overview.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'rune-medallion',
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
  spells: const ['Segen'],
  inventory: const [InventoryItem(id: 'mace', name: 'Streitkolben')],
);

void main() {
  testWidgets('Runenporträt zeigt echten Kindinhalt unverändert', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: InkWell(
              onTap: () => taps++,
              child: const FantasyPortraitMedallion(
                child: ColoredBox(
                  color: Colors.blueGrey,
                  child: Center(child: Text('Heldinnenporträt')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('sheet-portrait-medallion')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-portrait-halo')), findsOneWidget);
    expect(find.text('Heldinnenporträt'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sheet-portrait-medallion')));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 820.0]) {
    testWidgets('Eingravierte Panels auf $width dp malen ohne Überlauf', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = _hero();
      final before = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FantasyCharacterOverview(hero: hero),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('sheet-parchment-abilities')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('sheet-parchment-filigree')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('sheet-panel-filigree')),
          findsNWidgets(4));
      expect(find.byKey(const ValueKey('sheet-preview-fertigkeiten')),
          findsOneWidget);
      final buttons = find.text('Alle anzeigen');
      await tester.ensureVisible(buttons.first);
      await tester.tap(buttons.first);
      await tester.pumpAndSettle();
      expect(find.text('Fertigkeiten'), findsWidgets);
      expect(find.textContaining('Medizin: +7'), findsOneWidget);
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp + große Schrift: Rahmen bleiben passiv', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.4),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FantasyCharacterOverview(hero: _hero()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sheet-parchment-filigree')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-panel-filigree')),
        findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Charakterbogen: kein Porträtpreset wird hinzuerfunden', (
    tester,
  ) async {
    final original = HeroCharacter(id: 'legacy', name: 'Unbekannte Heldin');
    final before = original.toJson();
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterSheetPage(hero: original),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sheet-reference-header')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-portrait-medallion')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-avatar-placeholder')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('sheet-hero-portrait')), findsNothing);
    expect(original.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
