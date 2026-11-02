import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/savage_attacker_selection_dialog.dart';

DiceResult dice(List<int> faces) => DiceResult(
  expression: '2d6+3',
  rolls: faces,
  modifier: 3,
  total: faces.fold<int>(3, (total, die) => total + die),
);

Campaign combat({
  bool spent = false,
  bool soldier = true,
  bool enemyTurn = false,
  bool finished = false,
}) {
  final demo = GameEngine().createDemo();
  final hero = demo.hero.copyWith(
    background: soldier ? SrdBackground.soldier.label : 'Krimineller',
    startingBackgroundPackage: soldier
        ? SrdBackgroundPackageChoice(
            background: SrdBackground.soldier,
            takeGold: true,
            gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
          )
        : null,
  );
  return demo.copyWith(
    hero: hero,
    encounter: Encounter(
      id: 'enemy-1',
      enemyName: 'Wächter',
      enemyHitPoints: finished ? 0 : 40,
      enemyMaxHitPoints: 40,
      activeParticipant: enemyTurn ? 'enemy' : 'hero',
      savageAttackerUsedThisTurn: spent,
    ),
  );
}

void main() {
  Future<void> showChoice(
    WidgetTester tester, {
    Campaign? state,
    ValueNotifier<SavageAttackerSelectionRequest?>? resultSink,
    bool hit = true,
    bool weapon = true,
    bool critical = false,
    DiceResult? original,
    DiceResult? alternative,
    DiceResult? firstCrit,
    DiceResult? secondCrit,
    String targetId = 'enemy-1',
  }) async {
    final campaign = state ?? combat();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final selected =
                    await showDialog<SavageAttackerSelectionRequest>(
                      context: context,
                      builder: (_) => SavageAttackerSelectionDialog(
                        campaign: campaign,
                        attackRollId: 'attack-17',
                        encounterId: targetId,
                        weaponDamageExpression: '2d6+3',
                        original: original ?? dice([2, 3]),
                        alternative: alternative ?? dice([5, 6]),
                        confirmedWeaponHit: hit,
                        confirmedWeaponAttack: weapon,
                        critical: critical,
                        originalCriticalExtra: firstCrit,
                        alternativeCriticalExtra: secondCrit,
                      ),
                    );
                resultSink?.value = selected;
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'no automatic selection; explicit alternative returns revision only',
    (tester) async {
      final before = combat();
      final initial = before.toJson();
      final result = ValueNotifier<SavageAttackerSelectionRequest?>(null);
      addTearDown(result.dispose);
      await showChoice(tester, state: before, resultSink: result);
      final button = find.byKey(const ValueKey('savage-attacker-confirm'));
      expect(tester.widget<FantasyTextButton>(button).onPressed, isNull);
      expect(find.textContaining('Erster Wurf: 5'), findsOneWidget);
      expect(find.textContaining('Zweiter Wurf: 11'), findsOneWidget);
      expect(find.textContaining('Fester Waffenbonus: +3'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('savage-attacker-alternative')),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<FantasyTextButton>(button).onPressed, isNotNull);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(result.value?.attackRollId, 'attack-17');
      expect(result.value?.encounterId, 'enemy-1');
      expect(result.value?.expectedRevision, before.revision);
      expect(result.value?.chooseAlternative, true);
      expect(before.toJson(), initial);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('first lower result may be chosen without forced max', (
    tester,
  ) async {
    final result = ValueNotifier<SavageAttackerSelectionRequest?>(null);
    addTearDown(result.dispose);
    await showChoice(tester, resultSink: result);
    await tester.tap(find.byKey(const ValueKey('savage-attacker-original')));
    await tester.pumpAndSettle();
    final button = find.byKey(const ValueKey('savage-attacker-confirm'));
    expect(tester.widget<FantasyTextButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result.value?.chooseAlternative, false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel never confirms an attack', (tester) async {
    final result = ValueNotifier<SavageAttackerSelectionRequest?>(null);
    addTearDown(result.dispose);
    await showChoice(tester, resultSink: result);
    await tester.tap(find.byKey(const ValueKey('savage-attacker-cancel')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('savage-attacker-selection-dialog')),
      findsNothing,
    );
    expect(result.value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid origin, turn, target or fake dice fail closed', (
    tester,
  ) async {
    for (final caseIndex in [0, 1, 2, 3, 4, 5, 6]) {
      final state = switch (caseIndex) {
        0 => combat(spent: true),
        1 => combat(soldier: false),
        2 => combat(enemyTurn: true),
        3 => combat(finished: true),
        _ => combat(),
      };
      await showChoice(
        tester,
        state: state,
        hit: caseIndex != 4,
        weapon: caseIndex != 5,
        targetId: caseIndex == 6 ? 'enemy-forged' : 'enemy-1',
      );
      expect(
        find.byKey(const ValueKey('savage-attacker-invalid')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FantasyTextButton>(
              find.byKey(const ValueKey('savage-attacker-confirm')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('savage-attacker-cancel')));
      await tester.pumpAndSettle();
    }
    await showChoice(
      tester,
      alternative: DiceResult(
        expression: '2d6+3',
        rolls: [5, 6],
        modifier: 3,
        total: 99,
      ),
    );
    expect(
      find.byKey(const ValueKey('savage-attacker-invalid')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('savage-attacker-cancel')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('critical shows separately verified critical dice', (
    tester,
  ) async {
    await showChoice(
      tester,
      critical: true,
      firstCrit: dice([6, 6]),
      secondCrit: dice([1, 1]),
    );
    expect(
      find.byKey(const ValueKey('savage-attacker-critical-explanation')),
      findsOneWidget,
    );
    expect(find.textContaining('Erster Wurf: 17'), findsOneWidget);
    expect(find.textContaining('Zweiter Wurf: 13'), findsOneWidget);
    expect(find.textContaining('kritisch: 6 + 6'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('savage-attacker-cancel')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('small Android viewport with large text remains scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await showChoice(tester);
    final alternative = find.byKey(
      const ValueKey('savage-attacker-alternative'),
    );
    await tester.ensureVisible(alternative);
    await tester.pumpAndSettle();
    await tester.tap(alternative);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('savage-attacker-confirm')),
          )
          .onPressed,
      isNotNull,
    );
  });
  Future<void> showImeChoice(
    WidgetTester tester, {
    required double width,
    Campaign? state,
    ValueNotifier<SavageAttackerSelectionRequest?>? resultSink,
    bool hit = true,
    bool critical = false,
  }) async {
    tester.view.physicalSize = Size(width, 840);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await showChoice(
      tester,
      state: state,
      resultSink: resultSink,
      hit: hit,
      critical: critical,
      firstCrit: critical ? dice([6, 6]) : null,
      secondCrit: critical ? dice([1, 1]) : null,
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0]) {
    testWidgets('Wilder Angreifer $width dp/200 %/IME: Auswahl und Abbruch', (
      tester,
    ) async {
      final campaign = combat();
      final snapshot = campaign.toJson();
      final chosen = ValueNotifier<SavageAttackerSelectionRequest?>(null);
      addTearDown(chosen.dispose);
      await showImeChoice(
        tester,
        width: width,
        state: campaign,
        resultSink: chosen,
      );
      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      final first = find.byKey(const ValueKey('savage-attacker-original'));
      final second = find.byKey(const ValueKey('savage-attacker-alternative'));
      expect(
        find.ancestor(of: first, matching: find.byType(Scrollable)),
        findsOneWidget,
      );
      final firstSemantics = find.byKey(
        const ValueKey('savage-attacker-original-semantics'),
      );
      final secondSemantics = find.byKey(
        const ValueKey('savage-attacker-alternative-semantics'),
      );
      expect(
        tester.widget<Semantics>(firstSemantics).properties.selected,
        isFalse,
      );
      expect(
        tester.widget<Semantics>(secondSemantics).properties.selected,
        isFalse,
      );
      await tapVisible(tester, first);
      expect(
        tester.widget<Semantics>(firstSemantics).properties.selected,
        isTrue,
      );
      expect(
        tester.widget<Semantics>(secondSemantics).properties.selected,
        isFalse,
      );
      await tapVisible(tester, second);
      expect(
        tester.widget<Semantics>(firstSemantics).properties.selected,
        isFalse,
      );
      expect(
        tester.widget<Semantics>(secondSemantics).properties.selected,
        isTrue,
      );
      await tapVisible(
        tester,
        find.byKey(const ValueKey('savage-attacker-cancel')),
      );
      expect(chosen.value, isNull);
      expect(campaign.toJson(), snapshot);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: kritischer Wurf bleibt unverbindlich', (
    tester,
  ) async {
    final campaign = combat();
    final snapshot = campaign.toJson();
    final chosen = ValueNotifier<SavageAttackerSelectionRequest?>(null);
    addTearDown(chosen.dispose);
    await showImeChoice(
      tester,
      width: 320,
      state: campaign,
      resultSink: chosen,
      critical: true,
    );
    final submit = find.byKey(const ValueKey('savage-attacker-confirm'));
    expect(tester.widget<FantasyTextButton>(submit).onPressed, isNull);
    expect(
      find.byKey(const ValueKey('savage-attacker-critical-explanation')),
      findsOneWidget,
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savage-attacker-original')),
    );
    expect(tester.widget<FantasyTextButton>(submit).onPressed, isNotNull);
    await tapVisible(tester, submit);
    expect(chosen.value?.chooseAlternative, isFalse);
    expect(chosen.value?.expectedRevision, campaign.revision);
    expect(campaign.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp/200 %/IME: ungültiger Angriff bleibt gesperrt', (
    tester,
  ) async {
    final campaign = combat(spent: true);
    final snapshot = campaign.toJson();
    await showImeChoice(tester, width: 320, state: campaign);
    expect(
      find.byKey(const ValueKey('savage-attacker-invalid')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('savage-attacker-confirm')),
          )
          .onPressed,
      isNull,
    );
    await tapVisible(
      tester,
      find.byKey(const ValueKey('savage-attacker-cancel')),
    );
    expect(campaign.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });}
