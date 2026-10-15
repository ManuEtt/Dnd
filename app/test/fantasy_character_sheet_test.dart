import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

void main() {
  testWidgets('Deutscher Charakterbogen berechnet Übungsbonus und Rettungswürfe',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final hero = HeroCharacter(
      id: 'lyonel',
      name: 'Lyonel Soutmight',
      species: 'Mensch',
      className: 'Barde',
      level: 20,
      hitPoints: 123,
      maxHitPoints: 123,
      speed: 9,
      armorClass: 12,
      abilities: const {
        'strength': 11,
        'dexterity': 15,
        'constitution': 13,
        'intelligence': 14,
        'wisdom': 9,
        'charisma': 18,
      },
      savingThrowProficiencies: const ['dexterity', 'charisma'],
      skills: const ['Auftreten'],
    );
    await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(hero: hero)));
    expect(find.text('Charakterbogen'), findsOneWidget);
    expect(find.text('Lyonel Soutmight'), findsOneWidget);
    expect(find.text('Mensch  •  Barde  •  Stufe 20'), findsOneWidget);
    expect(find.text('+6'), findsOneWidget);
    expect(find.text('9 m'), findsOneWidget);
    expect(find.text('RÜSTUNGSKLASSE'), findsOneWidget);
    expect(find.text('123 / 123'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rettungswürfe'.toUpperCase()), 260,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('+8'), findsOneWidget); // Geschicklichkeit +2 + 6
    expect(find.text('+10'), findsOneWidget); // Charisma +4 + 6
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unbestätigte Angaben bleiben unbekannt und Bereiche sind erreichbar',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(
      hero: HeroCharacter(id: 'a', name: 'Arescan', level: 1),
    )));
    expect(find.text('– / –'), findsOneWidget);
    expect(find.text('Noch nicht erfasst'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('sheet-tab-1')));
    await tester.tap(find.byKey(const ValueKey('sheet-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('Keine Zustände eingetragen.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sheet-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('Resistenzen und Immunitäten sind im aktuellen Charaktermodell nicht gesondert erfasst.'), findsOneWidget);
    expect(find.text('Nicht erfasst'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bearbeiten bleibt als explizite Aktion erreichbar', (tester) async {
    var edits = 0;
    await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(
      hero: HeroCharacter(id: 'c', name: 'Elowen'),
      onEdit: () => edits++,
    )));
    await tester.tap(find.byTooltip('Charakter bearbeiten'));
    expect(edits, 1);
    expect(tester.takeException(), isNull);
  });
}
