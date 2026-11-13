import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
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

Campaign _campaign() {
  final engine = GameEngine();
  final game = engine.createDemo().copyWith(
    hero: _hero(),
    encounter: const Encounter(
      id: 'foe',
      enemyName: 'Hauptgegner',
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
  return engine
      .establishManualTurnQueue(
        game,
        orderedActorIds: const ['orc', 'hero', 'foe', 'goblin'],
        baseInitiativeConfirmed: true,
        tiedOrderConfirmed: false,
      )
      .campaign;
}

Finder _field(String id) => find.byKey(ValueKey('manual-attack-$id'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String id, String value) async {
  final field = _field(id);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

String _input(WidgetTester tester, String id) =>
    tester.widget<TextField>(_field(id)).controller!.text;

bool _checked(WidgetTester tester, String id) =>
    tester.widget<CheckboxListTile>(_field(id)).value ?? false;

Future<void> _selectTarget(WidgetTester tester, String label) async {
  await _tap(tester, _field('target'));
  await _tap(tester, find.text(label).last);
}

Future<void> _launch(
  WidgetTester tester, {
  required Campaign Function() campaign,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<ManualAttackChoice?> onResult,
}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final result = await showDialog<ManualAttackChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, repaint) {
                    onRebuild(repaint);
                    return ManualExtraCreatureAttackDialog(
                      campaign: campaign(),
                    );
                  },
                ),
              );
              onResult(result);
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Öffnen'));
}

void main() {
  testWidgets('Same campaign retains a deliberate unfinished attack', (
    tester,
  ) async {
    final campaign = _campaign();
    StateSetter? rebuild;
    final outcomes = <ManualAttackChoice?>[];
    await _launch(
      tester,
      campaign: () => campaign,
      onRebuild: (repaint) => rebuild = repaint,
      onResult: outcomes.add,
    );
    await _selectTarget(tester, 'Goblin (12 TP)');
    await _enter(tester, 'bonus', '+4');
    await _enter(tester, 'damage', '1d6+2');
    await _tap(tester, _field('reach'));
    rebuild!(() {});
    await tester.pumpAndSettle();

    expect(_input(tester, 'bonus'), '+4');
    expect(_input(tester, 'damage'), '1d6+2');
    expect(_checked(tester, 'reach'), isTrue);
    expect(find.text('Goblin (12 TP)'), findsOneWidget);
    expect(outcomes, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(outcomes, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next attacker revokes previous target, values and approvals', (
    tester,
  ) async {
    var campaign = _campaign();
    StateSetter? rebuild;
    final outcomes = <ManualAttackChoice?>[];
    await _launch(
      tester,
      campaign: () => campaign,
      onRebuild: (repaint) => rebuild = repaint,
      onResult: outcomes.add,
    );
    await _selectTarget(tester, 'Goblin (12 TP)');
    await _enter(tester, 'bonus', '+5');
    await _enter(tester, 'damage', '2d6+1');
    await _enter(tester, 'ac', '13');
    await _tap(tester, _field('reach'));
    await _tap(tester, _field('actor'));
    await _tap(tester, _field('defenses'));

    rebuild!(() {
      campaign = campaign.copyWith(
        manualTurnQueue: campaign.manualTurnQueue!.copyWith(
          activeIndex: 3,
          round: 2,
        ),
      );
    });
    await tester.pumpAndSettle();

    expect(find.textContaining('Angreifer-ID: goblin'), findsOneWidget);
    expect(_input(tester, 'bonus'), isEmpty);
    expect(_input(tester, 'damage'), isEmpty);
    expect(_input(tester, 'ac'), isEmpty);
    expect(_checked(tester, 'reach'), isFalse);
    expect(_checked(tester, 'actor'), isFalse);
    expect(_checked(tester, 'defenses'), isFalse);
    expect(find.text('Goblin (12 TP)'), findsNothing);
    await _selectTarget(tester, 'Orc (10 TP)');
    await _tap(tester, _field('confirm'));
    expect(_field('error'), findsOneWidget);
    expect(outcomes, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(outcomes, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spent action invalidates pending attack without dispatch', (
    tester,
  ) async {
    var campaign = _campaign();
    StateSetter? rebuild;
    final outcomes = <ManualAttackChoice?>[];
    await _launch(
      tester,
      campaign: () => campaign,
      onRebuild: (repaint) => rebuild = repaint,
      onResult: outcomes.add,
    );
    await _selectTarget(tester, 'Goblin (12 TP)');
    await _enter(tester, 'bonus', '+4');
    await _tap(tester, _field('reach'));

    rebuild!(() {
      campaign = campaign.copyWith(
        manualTurnQueue: campaign.manualTurnQueue!.copyWith(actionUsed: true),
      );
    });
    await tester.pumpAndSettle();

    expect(_input(tester, 'bonus'), isEmpty);
    expect(_checked(tester, 'reach'), isFalse);
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );
    expect(outcomes, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(outcomes, [null]);
    expect(tester.takeException(), isNull);
  });
}
