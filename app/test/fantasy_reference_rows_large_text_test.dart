import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_overview.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const longSpell = 'Schutzformel der vier verborgenen Mondtore jenseits des Nebels';
const longItem = 'Streitkolben der vergessenen Stadt hinter den Nebelbergen';

HeroCharacter _hero() => HeroCharacter(
  id: 'large-reference-rows',
  name: 'Elowen',
  className: 'Kleriker',
  level: 5,
  spells: const [longSpell],
  concentratingOn: longSpell,
  inventory: const [
    InventoryItem(id: 'long-item', name: longItem, quantity: 3),
  ],
);

Widget _screen(HeroCharacter hero, {double textScale = 1}) => MaterialApp(
  theme: buildFantasyTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: FantasyCharacterOverview(hero: hero),
    ),
  ),
);

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('200 %: volle Zauber- und Inventarnamen bei $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = _hero();
      final original = hero.toJson();

      await tester.pumpWidget(_screen(hero, textScale: 2));
      await tester.pumpAndSettle();

      final spells = find.byKey(const ValueKey('sheet-preview-zauber'));
      final inventory = find.byKey(const ValueKey('sheet-preview-ausrüstung'));
      final spell = find.descendant(
        of: spells,
        matching: find.text(longSpell),
      );
      final concentration = find.descendant(
        of: spells,
        matching: find.text('Konz.'),
      );
      final item = find.descendant(
        of: inventory,
        matching: find.text(longItem),
      );
      final count = find.descendant(
        of: inventory,
        matching: find.text('×3'),
      );

      for (final name in [spell, item]) {
        expect(name, findsOneWidget);
        final text = tester.widget<Text>(name);
        expect(text.maxLines, isNull);
        expect(text.overflow, TextOverflow.visible);
      }
      expect(concentration, findsOneWidget);
      expect(count, findsOneWidget);
      expect(
        tester.getTopLeft(concentration).dy,
        greaterThan(tester.getTopLeft(spell).dy),
      );
      expect(
        tester.getTopLeft(count).dy,
        greaterThan(tester.getTopLeft(item).dy),
      );
      expect(hero.toJson(), original);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Standardansicht behält kompakte Zeilen und Werte rechts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_screen(_hero()));
    await tester.pumpAndSettle();

    final spells = find.byKey(const ValueKey('sheet-preview-zauber'));
    final spell = find.descendant(of: spells, matching: find.text(longSpell));
    final concentration = find.descendant(
      of: spells,
      matching: find.text('Konz.'),
    );
    expect(tester.widget<Text>(spell).maxLines, 1);
    expect(tester.widget<Text>(spell).overflow, TextOverflow.ellipsis);
    expect(
      tester.getTopLeft(concentration).dx,
      greaterThan(tester.getTopLeft(spell).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unbekannte Fertigkeitswerte bleiben ohne erfundene Boni', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final hero = HeroCharacter(id: 'unknown-skills', name: 'Archiv');
    final original = hero.toJson();

    await tester.pumpWidget(_screen(hero, textScale: 2));
    await tester.pumpAndSettle();

    final skills = find.byKey(const ValueKey('sheet-preview-fertigkeiten'));
    final label = find.descendant(
      of: skills,
      matching: find.text('Einschüchtern'),
    );
    expect(label, findsOneWidget);
    expect(tester.widget<Text>(label).maxLines, isNull);
    expect(tester.widget<Text>(label).overflow, TextOverflow.visible);
    expect(
      find.descendant(of: skills, matching: find.text('–')),
      findsWidgets,
    );
    expect(hero.toJson(), original);
    expect(tester.takeException(), isNull);
  });
}
