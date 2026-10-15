import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

void main() {
  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets('Statistikkacheln bei ${width.toInt()} dp ohne Überlauf',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = HeroCharacter(
        id: 'narrow-screen',
        name: 'Elowen',
        level: 5,
        hitPoints: 30,
        maxHitPoints: 30,
        armorClass: 15,
        speed: 9,
        abilities: const {'dexterity': 15},
      );
      await tester.pumpWidget(MaterialApp(
        home: CharacterSheetPage(hero: hero),
      ));
      await tester.pumpAndSettle();
      expect(find.text('RÜSTUNGSKLASSE'), findsOneWidget);
      expect(find.text('ÜBUNGSBONUS'), findsOneWidget);
      // Regression: the explicit delegate is required for mainAxisExtent.
      // Passing mainAxisExtent to GridView.count breaks flutter analyze.
      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.mainAxisExtent, greaterThanOrEqualTo(124));
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text('Rettungswürfe'.toUpperCase()),
          240, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Statistikkacheln respektieren größere Systemschrift',
      (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.4),
        ),
        child: child!,
      ),
      home: CharacterSheetPage(hero: HeroCharacter(
        id: 'large-font', name: 'Elowen', level: 1,
        hitPoints: 8, maxHitPoints: 8, speed: 9, armorClass: 12,
      )),
    ));
    await tester.pumpAndSettle();
    expect(find.text('RÜSTUNGSKLASSE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
