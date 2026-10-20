import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/sacred_flame_dialog.dart';

HeroCharacter _hero({List<String> spells = const ['Heilige Flamme']}) =>
    HeroCharacter(
      id: 'sacred-dialog',
      name: 'Arina',
      className: 'Kleriker',
      level: 5,
      spells: spells,
      abilities: const {
        'strength': 10,
        'dexterity': 12,
        'constitution': 14,
        'intelligence': 16,
        'wisdom': 16,
        'charisma': 14,
      },
      hitPoints: 20,
      maxHitPoints: 20,
    );

const _fight = Encounter(
  id: 'save-foe',
  enemyName: 'Wächter',
  enemyHitPoints: 20,
  enemyMaxHitPoints: 20,
);

void main() {
  testWidgets('Unconfirmed Sacred Flame saving throw cannot start', (
    tester,
  ) async {
    SacredFlameChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<SacredFlameChoice>(
                  context: context,
                  builder: (_) =>
                      SacredFlameDialog(hero: _hero(), encounter: _fight),
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Heilige Flamme wirken'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('sacred-flame-visible')),
          )
          .value,
      false,
    );
    await tester.tap(find.byKey(const ValueKey('sacred-flame-cast')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Gegner-Rettungswurfbonus'), findsOneWidget);
    expect(choice, isNull);
  });

  testWidgets('Unprepared Sacred Flame has no confirmation action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SacredFlameDialog(
            hero: _hero(spells: const []),
            encounter: _fight,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Kein bestätigter Kleriker-Zaubertrick verfügbar.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('sacred-flame-cast')))
          .onPressed,
      isNull,
    );
  });
}
