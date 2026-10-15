import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

void main() {
  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets('Statistik- und Attributkarten bei ${width.toInt()} dp ohne Überlauf',
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
      // The sheet deliberately has separate summary, abilities and saves
      // grids. Looking up an arbitrary GridView is ambiguous on phones.
      final summary = tester.widget<GridView>(
        find.byKey(const ValueKey('sheet-summary-grid')),
      );
      final summaryDelegate = summary.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(summaryDelegate.crossAxisCount, 2);
      expect(summaryDelegate.mainAxisExtent, greaterThanOrEqualTo(124));
      expect(tester.takeException(), isNull);
      // Scroll the full section into view to exercise the six actual cards,
      // not only the four summary stats above them.
      await tester.scrollUntilVisible(find.text('Rettungswürfe'.toUpperCase()),
          240, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      final abilities = tester.widget<GridView>(
        find.byKey(const ValueKey('sheet-abilities-grid')),
      );
      final abilitiesDelegate = abilities.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(abilitiesDelegate.crossAxisCount, 2);
      expect(abilitiesDelegate.mainAxisExtent, greaterThanOrEqualTo(160));
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
    await tester.scrollUntilVisible(find.text('Rettungswürfe'.toUpperCase()),
        240, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final abilities = tester.widget<GridView>(
      find.byKey(const ValueKey('sheet-abilities-grid')),
    );
    final delegate = abilities.gridDelegate
        as SliverGridDelegateWithFixedCrossAxisCount;
    // 1.4x system text needs more vertical space than normal text; no clips.
    expect(delegate.mainAxisExtent, greaterThan(200));
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
    // On 320 dp the illustrated character header makes the tab navigation
    // a lazily built child below the viewport. ensureVisible requires the
    // widget to exist already, so first scroll until it is built and visible.
    final conditionsTab = find.byKey(const ValueKey('sheet-tab-1'));
    await tester.scrollUntilVisible(
      conditionsTab, 180, scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(conditionsTab);
    await tester.pumpAndSettle();
    expect(conditionsTab.hitTestable(), findsOneWidget);
    await tester.tap(conditionsTab);
    await tester.pumpAndSettle();
    expect(find.text('Keine Zustände eingetragen.'), findsOneWidget);
    final defensesTab = find.byKey(const ValueKey('sheet-tab-2'));
    await tester.scrollUntilVisible(
      defensesTab, 180, scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(defensesTab);
    await tester.pumpAndSettle();
    expect(defensesTab.hitTestable(), findsOneWidget);
    await tester.tap(defensesTab);
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
  testWidgets('Charakterbogen zeigt verbliebene Trefferwürfel der Mehrklassen',
      (tester) async {
    final hero = HeroCharacter(
      id: 'rest-sheet', name: 'Elowen', className: 'Kämpfer',
      level: 3, secondaryClassName: 'Magier', secondaryClassLevel: 1,
      hitPoints: 11, maxHitPoints: 18, armorClass: 15, speed: 9,
      spentHitDice: const {'d10': 1},
    );
    await tester.pumpWidget(MaterialApp(home: CharacterSheetPage(hero: hero)));
    await tester.pumpAndSettle();
    final section = find.byKey(const ValueKey('sheet-tab-2'));
    await tester.scrollUntilVisible(section, 180,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(section);
    await tester.pumpAndSettle();
    await tester.tap(section);
    await tester.pumpAndSettle();
    expect(find.text('Verfügbare Trefferwürfel'), findsOneWidget);
    expect(find.text('D10: 1/2 · D6: 1/1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
