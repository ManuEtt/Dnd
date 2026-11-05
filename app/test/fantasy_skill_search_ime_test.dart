import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_overview.dart';

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Fertigkeitensuche bleibt bei $width dp und 200 % über IME', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final hero = HeroCharacter(
        id: 'skill-sheet-ime',
        name: 'Elowen',
        abilities: const {
          'strength': 10,
          'dexterity': 14,
          'constitution': 12,
          'intelligence': 16,
          'wisdom': 14,
          'charisma': 10,
        },
        skills: const ['Religion'],
      );
      final original = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(children: [FantasyCharacterOverview(hero: hero)]),
          ),
        ),
      );
      final panel = find.byKey(const ValueKey('sheet-preview-fertigkeiten'));
      await tester.ensureVisible(panel);
      await tester.pumpAndSettle();
      final showAll = find.descendant(
        of: panel,
        matching: find.widgetWithText(TextButton, 'Alle anzeigen'),
      );
      await tester.tap(showAll);
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('sheet-skill-search'));
      expect(search.hitTestable(), findsOneWidget);

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      expect(search.hitTestable(), findsOneWidget);
      expect(tester.getBottomLeft(search).dy, lessThan(520));
      await tester.enterText(search, 'Religion');
      await tester.pumpAndSettle();
      expect(find.textContaining('Religion:'), findsWidgets);
      expect(find.textContaining('Wahrnehmung:'), findsNothing);
      expect(hero.toJson(), original);
      expect(tester.takeException(), isNull);

      await tester.enterText(search, 'nichtvorhandenefertigkeit');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sheet-skill-search-empty')),
        findsOneWidget,
      );
      expect(hero.toJson(), original);
      expect(tester.takeException(), isNull);
    });
  }
}
