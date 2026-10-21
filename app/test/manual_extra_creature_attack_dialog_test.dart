import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/manual_extra_creature_attack_dialog.dart';

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
  speed: 9,
  weaponDamage: '1d4',
);

Campaign _game({bool used = false}) {
  final engine = GameEngine();
  final game = engine.createDemo().copyWith(
    hero: _hero(),
    encounter: const Encounter(
      id: 'foe',
      enemyName: 'Main foe',
      enemyHitPoints: 20,
      enemyMaxHitPoints: 20,
      heroInitiative: 15,
      enemyInitiative: 12,
    ),
    trackedAreaCreatures: const [
      TrackedAreaCreature(
        id: 'orc',
        name: 'Orc',
        hitPoints: 10,
        maxHitPoints: 10,
        initiativeTotal: 20,
        initiativeController: 'gm',
      ),
      TrackedAreaCreature(
        id: 'goblin',
        name: 'Goblin',
        hitPoints: 12,
        maxHitPoints: 12,
        initiativeTotal: 10,
        initiativeController: 'gm',
      ),
    ],
  );
  final queued = engine.establishManualTurnQueue(
    game,
    orderedActorIds: const ['orc', 'hero', 'foe', 'goblin'],
    baseInitiativeConfirmed: true,
    tiedOrderConfirmed: false,
  ).campaign;
  return used
      ? queued.copyWith(
          manualTurnQueue: queued.manualTurnQueue!.copyWith(
            actionUsed: true,
          ),
        )
      : queued;
}

void main() {
  testWidgets('Without confirmed monster stats no attack is submitted', (
    tester,
  ) async {
    ManualAttackChoice? choice;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            child: const Text('Open'),
            onPressed: () async {
              choice = await showDialog<ManualAttackChoice>(
                context: context,
                builder: (_) =>
                    ManualExtraCreatureAttackDialog(campaign: _game()),
              );
            },
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Zusätzlicher Kreaturenangriff'), findsOneWidget);
    expect(find.byKey(const ValueKey('manual-attack-bonus')), findsOneWidget);
    final submit = find.byKey(const ValueKey('manual-attack-confirm'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(choice, isNull);
    expect(find.textContaining('Bestätigte Angriffs- und Zielwerte'),
        findsOneWidget);
  });

  testWidgets('One used action disables additional attack confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ManualExtraCreatureAttackDialog(campaign: _game(used: true)),
      ),
    ));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(
        find.byKey(const ValueKey('manual-attack-confirm')),
      ).onPressed,
      isNull,
    );
  });
}
