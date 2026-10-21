import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/manual_turn_queue_dialog.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'hero',
  name: 'Aria',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 14,
);

Campaign _game() => GameEngine().createDemo().copyWith(
  hero: _hero(),
  encounter: const Encounter(
    id: 'foe',
    enemyName: 'Wächter',
    enemyHitPoints: 10,
    enemyMaxHitPoints: 10,
    heroInitiative: 15,
    enemyInitiative: 15,
  ),
  trackedAreaCreatures: const [
    TrackedAreaCreature(
      id: 'goblin',
      name: 'Goblin',
      hitPoints: 5,
      maxHitPoints: 5,
      initiativeTotal: 13,
      initiativeController: 'gm',
    ),
  ],
);

void main() {
  testWidgets('Preview never quietly resolves ties or creates fake turns', (
    tester,
  ) async {
    ManualTurnQueueChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<ManualTurnQueueChoice>(
                  context: context,
                  builder: (_) => ManualTurnQueueDialog(campaign: _game()),
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
    expect(find.text('Manuelle Kampf-Zugfolge'), findsOneWidget);
    expect(find.textContaining('keine automatische'), findsWidgets);
    final save = find.byKey(const ValueKey('queue-establish'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(choice, isNull);
    expect(find.textContaining('Vor dem Speichern'), findsOneWidget);
  });

  testWidgets('Dialog exposes stored marker without performing combat action', (
    tester,
  ) async {
    final engine = GameEngine();
    final campaign = _game();
    final after = engine.establishManualTurnQueue(
      campaign,
      orderedActorIds: const ['hero', 'foe', 'goblin'],
      baseInitiativeConfirmed: true,
      tiedOrderConfirmed: true,
    ).campaign;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ManualTurnQueueDialog(campaign: after),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Manuelle Runde:'), findsOneWidget);
    expect(find.textContaining('Aktueller Marker:'), findsOneWidget);
    expect(find.byKey(const ValueKey('queue-advance')), findsOneWidget);
  });
}
