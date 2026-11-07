import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/spellcasting_dialog.dart';

Future<List<SpellcastingChoice?>> _openDialog(
  WidgetTester tester,
  HeroCharacter hero,
) async {
  final results = <SpellcastingChoice?>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showDialog<SpellcastingChoice>(
                  context: context,
                  builder: (_) => SpellcastingDialog(hero: hero),
                ),
              );
            },
            child: const Text('Zauber öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Zauber öffnen'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('Ungültiger normaler Platzverbrauch zeigt Fehler statt Absturz', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'invalid-mage',
      name: 'Mira',
      className: 'Magier',
      level: 1,
      spells: ['Licht'],
      spentSpellSlots: {'1': 99},
    );
    final results = await _openDialog(tester, hero);
    expect(
      find.byKey(const ValueKey('spell-dialog-resource-error')),
      findsOneWidget,
    );
    expect(
      find.text('Zauberplatzverbrauch passt nicht zu den Klassenstufen.'),
      findsOneWidget,
    );
    expect(find.text('Keine regulären Zauberplätze'), findsNothing);
    expect(
      tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('spell-dialog-cast')),
      ).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(hero.spentSpellSlots['1'], 99);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ungültiger Paktverbrauch sperrt Bestätigung ohne Mutation', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'invalid-warlock',
      name: 'Tarek',
      className: 'Hexenmeister',
      level: 1,
      spells: ['Licht'],
      spentPactSlots: -1,
    );
    final results = await _openDialog(tester, hero);
    expect(
      find.text('Paktmagie-Verbrauch passt nicht zur Stufe.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('spell-dialog-cast')),
      ).onPressed,
      isNull,
    );
    expect(find.textContaining('Paktmagie Grad'), findsNothing);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(hero.spentPactSlots, -1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gültige Ressourcen behalten die ausdrückliche Bestätigung', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'valid-mage',
      name: 'Liora',
      className: 'Magier',
      level: 1,
      spells: ['Licht'],
    );
    final results = await _openDialog(tester, hero);
    expect(
      find.byKey(const ValueKey('spell-dialog-resource-error')),
      findsNothing,
    );
    expect(find.textContaining('1: 2 frei'), findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('spell-dialog-cast')),
      ).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('spell-dialog-cast')));
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect(results.single?.name, 'Licht');
    expect(results.single?.level, 0);
    expect(hero.spentSpellSlots, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
