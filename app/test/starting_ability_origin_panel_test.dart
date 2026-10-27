import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';
import 'package:lebendiger_spielleiter/ui/ability_assignment_dialog.dart'
    show abilityLabels;
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/starting_ability_origin_panel.dart';

HeroCharacter _restoredHero() {
  final origin = StartingAbilityOrigin.confirmed(
    method: 'randomRoll',
    baseScores: const {
      'strength': 18,
      'dexterity': 15,
      'constitution': 12,
      'intelligence': 9,
      'wisdom': 6,
      'charisma': 3,
    },
    background: 'Soldat',
    increases: const {'strength': 1, 'dexterity': 1, 'constitution': 1},
    diceRolls: const [
      [6, 6, 6, 1],
      [5, 5, 5, 1],
      [4, 4, 4, 1],
      [3, 3, 3, 1],
      [2, 2, 2, 1],
      [1, 1, 1, 1],
    ],
  );
  final saved = HeroCharacter(
    id: 'origin-sheet',
    name: 'Startheld',
    className: 'Kämpfer',
    species: 'Mensch',
    level: 5,
    background: 'Soldat',
    abilities: {...origin.startingScores, 'strength': 20},
    startingAbilityOrigin: origin,
    hitPoints: 38,
    maxHitPoints: 38,
    armorClass: 14,
    speed: 9,
  );
  return HeroCharacter.fromJson(
    Map<String, dynamic>.from(jsonDecode(jsonEncode(saved.toJson())) as Map),
  );
}

Future<void> _openSheet(WidgetTester tester, HeroCharacter hero) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CharacterSheetPage(hero: hero),
                ),
              ),
              child: const Text('Charakter öffnen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Charakter öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'JSON-neugeladene Startwerte im echten Bogen: 360 dp und 200 % Schrift',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = _restoredHero();
      final before = jsonEncode(hero.toJson());

      await _openSheet(tester, hero);
      expect(find.byType(CharacterSheetPage), findsOneWidget);
      await _reveal(tester, find.text('Startwerte der Attribute'));
      expect(find.byType(StartingAbilityOriginPanel), findsOneWidget);
      expect(find.text('Gewürfelt (4W6)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('starting-ability-origin-score-strength')),
        findsNothing,
      );
      await tester.tap(find.text('Startwerte der Attribute'));
      await tester.pumpAndSettle();

      expect(find.text('Hintergrund: Soldat'), findsOneWidget);
      expect(
        find.text(
          'Gespeicherte Werte bei der Erstellung. Aktuelle Attribute können '
          'inzwischen abweichen.',
        ),
        findsOneWidget,
      );
      const starts = [19, 16, 13, 9, 6, 3];
      for (var index = 0; index < abilityNames.length; index++) {
        final ability = abilityNames[index];
        final text = tester.widget<Text>(
          find.byKey(ValueKey('starting-ability-origin-score-$ability')),
        );
        expect(
          text.data,
          '${abilityLabels[ability]}: Basis '
          '${hero.startingAbilityOrigin!.baseScores[ability]} '
          '+ Hintergrund ${hero.startingAbilityOrigin!.increases[ability] ?? 0} '
          '= Startwert ${starts[index]}.',
        );
      }
      const rolls = [18, 15, 12, 9, 6, 3];
      for (var index = 0; index < rolls.length; index++) {
        final text = tester.widget<Text>(
          find.byKey(ValueKey('starting-ability-origin-roll-$index')),
        );
        expect(
          text.data,
          '${index + 1}. Wurf: '
          '${hero.startingAbilityOrigin!.diceRolls[index].join(' · ')} '
          '→ ${rolls[index]}',
        );
      }
      final lastRoll = find.byKey(
        const ValueKey('starting-ability-origin-roll-5'),
      );
      await _reveal(tester, lastRoll);
      expect(lastRoll.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(hero.abilities['strength'], 20);
      expect(jsonEncode(hero.toJson()), before);

      await _reveal(tester, find.text('Startwerte der Attribute'));
      await tester.tap(find.text('Startwerte der Attribute'));
      await tester.pumpAndSettle();
      expect(lastRoll, findsNothing);
      expect(jsonEncode(hero.toJson()), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Historischer Charakter ohne Herkunft erhält kein neues Panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final hero = HeroCharacter.fromJson(
      _restoredHero().copyWith(startingAbilityOrigin: null).toJson(),
    );
    final before = jsonEncode(hero.toJson());

    await _openSheet(tester, hero);
    await _reveal(tester, find.text('RETTUNGSWÜRFE'));
    expect(find.byType(StartingAbilityOriginPanel), findsNothing);
    expect(find.text('Startwerte der Attribute'), findsNothing);
    expect(hero.startingAbilityOrigin, isNull);
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });
}
