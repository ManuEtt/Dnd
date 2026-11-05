import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_opportunity_attack_rules.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/opportunity_movement_dialog.dart';

Campaign _campaign() {
  final demo = GameEngine().createDemo();
  return demo.copyWith(
    hero: demo.hero.copyWith(
      equippedWeaponId: 'dagger',
      inventory: const [
        InventoryItem(id: 'dagger', name: 'Dolch', catalogId: 'weapon-dagger'),
      ],
    ),
    encounter: const Encounter(
      id: 'confirmed-enemy',
      enemyName: 'Bestätigter Gegner',
      enemyHitPoints: 20,
      enemyMaxHitPoints: 20,
      activeParticipant: 'enemy',
      enemyAttacksPerTurn: 2,
      enemyAttacksRemaining: 1,
    ),
  );
}

Finder _key(String id) => find.byKey(ValueKey(id));
Finder get _confirm => _key('opportunity-movement-confirm');

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required Campaign campaign,
  required ValueChanged<ConfirmedOpportunityTrigger?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 840);
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
                await showDialog<ConfirmedOpportunityTrigger>(
                  context: context,
                  builder: (_) => OpportunityMovementDialog(campaign: campaign),
                ),
              );
            },
            child: const Text('Bewegung öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Bewegung öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final target = tester.widget(finder) is CheckboxListTile
      ? find.descendant(of: finder, matching: find.byType(Checkbox))
      : finder;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String key, String label) async {
  await _tap(tester, _key(key));
  await _tap(tester, find.text(label).last);
}

Future<void> _fill(WidgetTester tester, {String after = '10'}) async {
  await _choose(
    tester,
    'opportunity-movement-kind',
    'Eigene gewöhnliche Bewegung',
  );
  await _choose(tester, 'opportunity-strike', 'Dolch');
  for (final entry in {'before': '5', 'after': after, 'reach': '5'}.entries) {
    final field = _key('opportunity-${entry.key}');
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
    await tester.pumpAndSettle();
  }
  await _tap(tester, _key('opportunity-visible'));
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final width in [320.0, 360.0]) {
    testWidgets('Bewegung bei $width dp, 200 % und IME abbrechen', (
      tester,
    ) async {
      final campaign = _campaign();
      final original = campaign.toJson();
      final results = <ConfirmedOpportunityTrigger?>[];
      await _open(
        tester,
        width: width,
        campaign: campaign,
        onResult: results.add,
      );

      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      expect(
        find.ancestor(
          of: _key('opportunity-after'),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
      expect(
        (tester.widget<CheckboxListTile>(_key('opportunity-authorized')).title!
                as Text)
            .semanticsLabel,
        contains('Noch keine Reaktion verbrauchen'),
      );
      expect(find.text('Bewegung ausdrücklich bestätigen'), findsOneWidget);

      await _tap(tester, _key('opportunity-movement-cancel'));
      expect(results, [null]);
      expect(campaign.toJson(), original);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp, 200 % und IME: bestätigtes Angebot ohne Mutation', (
    tester,
  ) async {
    final campaign = _campaign();
    final original = campaign.toJson();
    final results = <ConfirmedOpportunityTrigger?>[];
    await _open(tester, width: 320, campaign: campaign, onResult: results.add);
    await _fill(tester);
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
    await _tap(tester, _key('opportunity-authorized'));
    expect(_key('opportunity-movement-preview'), findsOneWidget);
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNotNull);
    await _tap(tester, _confirm);

    expect(results, hasLength(1));
    final trigger = results.single!;
    expect(trigger.beforeDistanceFeet, 5);
    expect(trigger.afterDistanceFeet, 10);
    expect(trigger.reachFeet, 5);
    expect(trigger.weaponId, 'dagger');
    expect(trigger.playerAuthorizedReaction, isTrue);
    expect(campaign.toJson(), original);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp, 200 % und IME: ungültige Bewegung bleibt gesperrt', (
    tester,
  ) async {
    final campaign = _campaign();
    final original = campaign.toJson();
    final results = <ConfirmedOpportunityTrigger?>[];
    await _open(tester, width: 360, campaign: campaign, onResult: results.add);
    await _fill(tester);
    await _tap(tester, _key('opportunity-authorized'));
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNotNull);

    final after = _key('opportunity-after');
    await tester.ensureVisible(after);
    await tester.enterText(after, '5');
    await tester.pumpAndSettle();
    expect(
      tester.widget<CheckboxListTile>(_key('opportunity-authorized')).value,
      isFalse,
    );
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
    await _tap(tester, _key('opportunity-authorized'));
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);

    await _tap(tester, _key('opportunity-movement-cancel'));
    expect(results, [null]);
    expect(campaign.toJson(), original);
    expect(tester.takeException(), isNull);
  });
}
