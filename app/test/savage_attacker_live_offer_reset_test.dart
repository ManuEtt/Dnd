import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/savage_attacker_selection_dialog.dart';

DiceResult _dice(List<int> faces) => DiceResult(
  expression: '2d6+3',
  rolls: faces,
  modifier: 3,
  total: faces.fold<int>(3, (total, face) => total + face),
);

Campaign _readyCampaign() {
  final demo = GameEngine().createDemo();
  return demo.copyWith(
    hero: demo.hero.copyWith(
      background: SrdBackground.soldier.label,
      startingBackgroundPackage: SrdBackgroundPackageChoice(
        background: SrdBackground.soldier,
        takeGold: true,
        gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
      ),
    ),
    encounter: const Encounter(
      id: 'enemy-1',
      enemyName: 'Wächter',
      enemyHitPoints: 40,
      enemyMaxHitPoints: 40,
      activeParticipant: 'hero',
    ),
  );
}

Widget _screen(
  Campaign campaign, {
  required String attackId,
  required DiceResult original,
  required DiceResult alternative,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SavageAttackerSelectionDialog(
        campaign: campaign,
        attackRollId: attackId,
        encounterId: 'enemy-1',
        weaponDamageExpression: '2d6+3',
        original: original,
        alternative: alternative,
        confirmedWeaponHit: true,
        confirmedWeaponAttack: true,
      ),
    ),
  ),
);

bool _canSubmit(WidgetTester tester) {
  final confirm = tester.widget<FantasyTextButton>(
    find.byKey(const ValueKey('savage-attacker-confirm')),
  );
  return confirm.onPressed != null;
}

Future<void> _select(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('same confirmed attack keeps its explicit choice on rebuild', (
    tester,
  ) async {
    final campaign = _readyCampaign();
    final before = campaign.toJson();
    final original = _dice([2, 3]);
    final alternative = _dice([5, 6]);

    await tester.pumpWidget(
      _screen(
        campaign,
        attackId: 'attack-17',
        original: original,
        alternative: alternative,
      ),
    );
    expect(_canSubmit(tester), isFalse);
    await _select(tester, 'savage-attacker-alternative');
    expect(_canSubmit(tester), isTrue);

    await tester.pumpWidget(
      _screen(
        campaign,
        attackId: 'attack-17',
        original: original,
        alternative: alternative,
      ),
    );
    expect(_canSubmit(tester), isTrue);
    expect(campaign.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('new attack at $width dp/200 %/IME needs fresh selection', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 840);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final campaign = _readyCampaign();
      final before = campaign.toJson();
      final original = _dice([2, 3]);
      final alternative = _dice([5, 6]);
      await tester.pumpWidget(
        _screen(
          campaign,
          attackId: 'attack-17',
          original: original,
          alternative: alternative,
        ),
      );
      await _select(tester, 'savage-attacker-alternative');
      expect(_canSubmit(tester), isTrue);

      await tester.pumpWidget(
        _screen(
          campaign,
          attackId: 'attack-18',
          original: original,
          alternative: alternative,
        ),
      );
      expect(_canSubmit(tester), isFalse);
      final semantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('savage-attacker-alternative-semantics')),
      );
      expect(semantics.properties.selected, isFalse);
      await _select(tester, 'savage-attacker-original');
      expect(_canSubmit(tester), isTrue);
      expect(campaign.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('new revision and expired turn cannot reuse earlier approval', (
    tester,
  ) async {
    final campaign = _readyCampaign();
    final original = _dice([2, 3]);
    final alternative = _dice([5, 6]);
    await tester.pumpWidget(
      _screen(
        campaign,
        attackId: 'attack-17',
        original: original,
        alternative: alternative,
      ),
    );
    await _select(tester, 'savage-attacker-original');
    expect(_canSubmit(tester), isTrue);

    final spent = campaign.copyWith(
      revision: campaign.revision + 1,
      encounter: campaign.encounter!.copyWith(
        savageAttackerUsedThisTurn: true,
      ),
    );
    final before = spent.toJson();
    await tester.pumpWidget(
      _screen(
        spent,
        attackId: 'attack-17',
        original: original,
        alternative: alternative,
      ),
    );
    expect(
      find.byKey(const ValueKey('savage-attacker-invalid')),
      findsOneWidget,
    );
    expect(_canSubmit(tester), isFalse);

    final fresh = campaign.copyWith(revision: spent.revision + 1);
    await tester.pumpWidget(
      _screen(
        fresh,
        attackId: 'attack-17',
        original: original,
        alternative: alternative,
      ),
    );
    expect(_canSubmit(tester), isFalse);
    await _select(tester, 'savage-attacker-alternative');
    expect(_canSubmit(tester), isTrue);
    expect(spent.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replaced dice cannot inherit a previous damage choice', (
    tester,
  ) async {
    final campaign = _readyCampaign();
    final before = campaign.toJson();
    final original = _dice([2, 3]);
    final alternative = _dice([5, 6]);
    await tester.pumpWidget(
      _screen(
        campaign,
        attackId: 'attack-17',
        original: original,
        alternative: alternative,
      ),
    );
    await _select(tester, 'savage-attacker-original');
    expect(_canSubmit(tester), isTrue);

    await tester.pumpWidget(
      _screen(
        campaign,
        attackId: 'attack-17',
        original: original,
        alternative: _dice([4, 4]),
      ),
    );
    expect(find.textContaining('Zweiter Wurf: 8'), findsOneWidget);
    expect(_canSubmit(tester), isFalse);
    expect(campaign.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
