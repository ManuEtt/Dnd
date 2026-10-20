import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/tracked_creature_initiative_dialog.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'hero-1',
  name: 'Aria',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 13,
);

Campaign _game() => GameEngine().createDemo().copyWith(
  hero: _hero(),
  encounter: const Encounter(
    id: 'foe',
    enemyName: 'Wächter',
    enemyHitPoints: 30,
    enemyMaxHitPoints: 30,
    heroInitiative: 15,
    enemyInitiative: 15,
  ),
  trackedAreaCreatures: const [
    TrackedAreaCreature(
      id: 'goblin',
      name: 'Goblin',
      hitPoints: 5,
      maxHitPoints: 5,
    ),
  ],
);

void main() {
  testWidgets('Initiative preview shows missing values and unresolved ties', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackedCreatureInitiativeDialog(campaign: _game()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Mehrgegner-Initiative'), findsOneWidget);
    expect(
      find.text('Gleichstand – Reihenfolge ausdrücklich klären.'),
      findsOneWidget,
    );
    expect(find.textContaining('Ohne bestätigte Initiative:'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('initiative-base-confirmed')),
          )
          .value,
      false,
    );
  });

  testWidgets('Missing confirmation cannot save a fabricated initiative', (
    tester,
  ) async {
    ConfirmedInitiativeChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<ConfirmedInitiativeChoice>(
                  context: context,
                  builder: (_) =>
                      TrackedCreatureInitiativeDialog(campaign: _game()),
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
    await tester.tap(find.byKey(const ValueKey('initiative-save')));
    await tester.pumpAndSettle();
    expect(choice, isNull);
    expect(
      find.textContaining('Kreatur, vollständiges Initiativeergebnis'),
      findsOneWidget,
    );
  });
}
