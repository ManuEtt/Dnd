import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_skill_ability_catalog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_overview.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter _hero({List<String> skills = const ['Heilkunde']}) =>
    HeroCharacter(
      id: 'complete-skills',
      name: 'Liora',
      className: 'Kleriker',
      level: 5,
      abilities: const {
        'strength': 10,
        'dexterity': 14,
        'constitution': 16,
        'intelligence': 12,
        'wisdom': 18,
        'charisma': 13,
      },
      skills: skills,
    );

Future<void> _openAllSkills(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: FantasyCharacterOverview(hero: _hero()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final skillsCard = find.byKey(const ValueKey('sheet-preview-fertigkeiten'));
  await tester.ensureVisible(skillsCard);
  await tester.pumpAndSettle();
  final showAll = find.descendant(
    of: skillsCard,
    matching: find.text('Alle anzeigen'),
  );
  await tester.tap(showAll);
  await tester.pumpAndSettle();
}

void main() {
  test(
    '18 Standardfertigkeiten entsprechen vollständig dem Klassenkatalog',
    () {
      expect(srdSkillAbilities.length, 18);
      expect(srdSkillAbilities.map((skill) => skill.name).toList(), srdSkills);
      expect(srdSkillAbilities.map((skill) => skill.name).toSet().length, 18);
      expect(srdSkillAbilities.map((skill) => skill.ability).toSet(), {
        'strength',
        'dexterity',
        'intelligence',
        'wisdom',
        'charisma',
      });
      expect(
        srdSkillAbilities
            .firstWhere((skill) => skill.name == 'Heilkunde')
            .ability,
        'wisdom',
      );
      expect(srdLegacySkillAliases['Heilkunde'], 'Medizin');
    },
  );

  testWidgets('Alle anzeigen listet 18 Fertigkeiten mit korrekten Boni', (
    tester,
  ) async {
    await _openAllSkills(tester);
    expect(find.text('Fertigkeiten'), findsWidgets);
    expect(find.text('Akrobatik: +2'), findsOneWidget);
    expect(find.text('Mit Tieren umgehen: +4'), findsOneWidget);
    final list = tester.widget<ListView>(find.byType(ListView).last);
    // Eighteen SRD skills; the introductory title and divider are separate.
    expect(
      (list.childrenDelegate as SliverChildListDelegate).children.length,
      20,
    );
    await tester.scrollUntilVisible(
      find.text('Heilkunde: +7 · geübt'),
      130,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Heilkunde: +7 · geübt'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Überlebenskunst: +4'),
      130,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Überlebenskunst: +4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final spelling in ['Heilkunde', 'Medizin']) {
    testWidgets('Vorhandene Fertigkeit $spelling wird nicht vergessen', (
      tester,
    ) async {
      final hero = _hero(skills: [spelling]);
      final saved = hero.toJson();
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
      final card = find.byKey(const ValueKey('sheet-preview-fertigkeiten'));
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      final button = find.descendant(
        of: card,
        matching: find.text('Alle anzeigen'),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView).last);
      expect(
        (list.childrenDelegate as SliverChildListDelegate).children.length,
        20,
      ); // one canonical row, no duplicate
      await tester.scrollUntilVisible(
        find.text('Heilkunde: +7 · geübt'),
        135,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Heilkunde: +7 · geübt'), findsOneWidget);
      expect(
        find.textContaining('Medizin · historischer Eintrag'),
        findsNothing,
      );
      expect(hero.toJson(), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Unbekannte Werte und fremde historische Skills bleiben sicher', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'imported-skills',
      name: 'Archivierte Figur',
      skills: const ['Medizin', 'Alte Hausregel'],
    );
    final saved = hero.toJson();
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
    final button = find.descendant(
      of: find.byKey(const ValueKey('sheet-preview-fertigkeiten')),
      matching: find.text('Alle anzeigen'),
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    final list = tester.widget<ListView>(find.byType(ListView).last);
    expect(
      (list.childrenDelegate as SliverChildListDelegate).children.length,
      21,
    ); // 18 + one genuine legacy + title/divider
    await tester.scrollUntilVisible(
      find.text('Heilkunde: – · geübt'),
      135,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('Heilkunde: – · geübt'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(
        'Alte Hausregel · historischer Eintrag (keine automatische Berechnung)',
      ),
      145,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('keine automatische Berechnung'),
      findsOneWidget,
    );
    expect(hero.toJson(), saved);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Charakterbogen bleibt bei genau einer Attributtafel und festem W20',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: CharacterSheetPage(hero: _hero())),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sheet-fixed-quick-navigation')),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('sheet-parchment-abilities')),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Attribute'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sheet-preview-attributes-grid')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('sheet-abilities-grid')), findsNothing);
      expect(find.byKey(const ValueKey('sheet-quick-roll')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
