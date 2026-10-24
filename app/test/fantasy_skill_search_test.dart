import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_overview.dart';

void main() {
  testWidgets('Alle 18 Fertigkeiten sind filterbar, ohne Charakteränderung', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'search-skills',
      name: 'Liora',
      level: 5,
      abilities: const {
        'strength': 10,
        'dexterity': 14,
        'constitution': 16,
        'intelligence': 12,
        'wisdom': 18,
        'charisma': 13,
      },
      skills: const ['Medizin', 'Wahrnehmung'],
    );
    final original = hero.toJson();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FantasyCharacterOverview(hero: hero),
          ),
        ),
      ),
    );
    final panel = find.byKey(const ValueKey('sheet-preview-fertigkeiten'));
    await tester.ensureVisible(panel);
    await tester.tap(
      find.descendant(of: panel, matching: find.text('Alle anzeigen')),
    );
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('sheet-skill-search'));
    expect(search, findsOneWidget);
    final list = tester.widget<ListView>(find.byType(ListView).last);
    expect(
      (list.childrenDelegate as SliverChildListDelegate).children.length,
      20,
    );
    await tester.enterText(search, 'HEIL');
    await tester.pumpAndSettle();
    expect(find.text('Heilkunde: +7 · geübt'), findsOneWidget);
    expect(find.text('Athletik: +0'), findsNothing);
    await tester.enterText(search, 'kein treffer');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('sheet-skill-search-empty')),
      findsOneWidget,
    );
    expect(find.text('Keine passenden Fertigkeiten.'), findsOneWidget);
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    final restored = tester.widget<ListView>(find.byType(ListView).last);
    expect(
      (restored.childrenDelegate as SliverChildListDelegate).children.length,
      20,
    );
    expect(hero.toJson(), original);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fertigkeitssuche ist auf schmalem Android bedienbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FantasyCharacterOverview(
              hero: HeroCharacter(id: 'old', name: 'Historisch'),
            ),
          ),
        ),
      ),
    );
    final panel = find.byKey(const ValueKey('sheet-preview-fertigkeiten'));
    await tester.ensureVisible(panel);
    await tester.tap(
      find.descendant(of: panel, matching: find.text('Alle anzeigen')),
    );
    await tester.pumpAndSettle();
    final search = find.byKey(const ValueKey('sheet-skill-search'));
    expect(search.hitTestable(), findsOneWidget);
    await tester.enterText(search, 'Akrobatik');
    await tester.pumpAndSettle();
    expect(find.text('Akrobatik: –'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
