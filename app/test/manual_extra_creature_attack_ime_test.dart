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
  final queued = engine
      .establishManualTurnQueue(
        game,
        orderedActorIds: const ['orc', 'hero', 'foe', 'goblin'],
        baseInitiativeConfirmed: true,
        tiedOrderConfirmed: false,
      )
      .campaign;
  return used
      ? queued.copyWith(
          manualTurnQueue: queued.manualTurnQueue!.copyWith(actionUsed: true),
        )
      : queued;
}

Future<void> _showAtLargeText(
  WidgetTester tester,
  Campaign campaign,
  ValueChanged<ManualAttackChoice?> onResult, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 720);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showDialog<ManualAttackChoice>(
                  context: context,
                  builder: (_) =>
                      ManualExtraCreatureAttackDialog(campaign: campaign),
                ),
              );
            },
            child: const Text('Angriff öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Angriff öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilTouchable(WidgetTester tester, Finder target) async {
  final scrollable = find
      .descendant(
        of: find.byType(ManualExtraCreatureAttackDialog),
        matching: find.byType(Scrollable),
      )
      .first;
  for (var i = 0; i < 40; i++) {
    if (target.hitTestable().evaluate().isNotEmpty) return;
    await tester.drag(scrollable, const Offset(0, -125));
    await tester.pumpAndSettle();
  }
  expect(target.hitTestable(), findsOneWidget);
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Zusatzangriff: Abbrechen bei $width dp, 200 % und IME', (
      tester,
    ) async {
      final campaign = _game();
      final before = campaign.toJson();
      final results = <ManualAttackChoice?>[];
      await _showAtLargeText(tester, campaign, results.add, width: width);

      expect(find.byType(ManualExtraCreatureAttackDialog), findsOneWidget);
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      expect(find.text('Angreifer handlungsfähig'), findsOneWidget);
      expect(
        find.text(
          'Alle Angriffs-Modifikatoren einschließlich '
          'Sonderfähigkeiten geprüft.',
        ),
        findsNothing,
      );
      final cancel = find.text('Abbrechen');
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(campaign.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Fehlende Pflichtwerte zeigen Fehler ohne Kampfmutation', (
    tester,
  ) async {
    final campaign = _game();
    final before = campaign.toJson();
    final results = <ManualAttackChoice?>[];
    await _showAtLargeText(tester, campaign, results.add, width: 320);

    final confirm = find.byKey(const ValueKey('manual-attack-confirm'));
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('manual-attack-error')), findsOneWidget);
    expect(find.byType(ManualExtraCreatureAttackDialog), findsOneWidget);
    expect(results, isEmpty);
    expect(campaign.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bestätigter Zusatzangriff ist bei 320 dp und IME erreichbar', (
    tester,
  ) async {
    final campaign = _game();
    final before = campaign.toJson();
    final results = <ManualAttackChoice?>[];
    await _showAtLargeText(tester, campaign, results.add, width: 320);

    final target = find.byKey(const ValueKey('manual-attack-target'));
    await _scrollUntilTouchable(tester, target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Goblin (12 TP)').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manual-attack-bonus')),
      '4',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manual-attack-damage')),
      '1d6+2',
    );
    final damage = find.byKey(const ValueKey('manual-attack-damage-type'));
    await _scrollUntilTouchable(tester, damage);
    await tester.tap(damage);
    await tester.pumpAndSettle();
    await tester.tap(find.text('acid').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manual-attack-ac')),
      '12',
    );
    final cover = find.byKey(const ValueKey('manual-attack-cover'));
    await _scrollUntilTouchable(tester, cover);
    await tester.tap(cover);
    await tester.pumpAndSettle();
    await tester.tap(find.text('keine Deckung').last);
    await tester.pumpAndSettle();

    for (final suffix in [
      'reach',
      'actor',
      'target-valid',
      'modifiers',
      'defenses',
      'reactions',
      'no-effects',
    ]) {
      final checkbox = find.byKey(ValueKey('manual-attack-$suffix'));
      await _scrollUntilTouchable(tester, checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();
    }

    final confirm = find.byKey(const ValueKey('manual-attack-confirm'));
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single?.attackerId, 'orc');
    expect(results.single?.targetId, 'goblin');
    expect(results.single?.attack.attackBonus, 4);
    expect(results.single?.attack.targetArmorClass, 12);
    expect(campaign.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
