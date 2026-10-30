import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/experience_reward_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  Future<void> scrollToConsent(WidgetTester tester) async {
    await scrollToConsent(tester);
    await tester.tap(find.byKey(const ValueKey('xp-reward-consent')));
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('xp-reward-confirm'));
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNotNull);
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect(results.single?.rewardId, 'quest-ime');
    expect(results.single?.requestId, 'xp_quest-ime');
    expect(results.single?.amount, 300);
    // The dialog returns a choice; it never books XP before controller commit.
    expect(campaign.hero.experience, 0);
    expect(campaign.events, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Ungültiger Betrag bleibt trotz scrollbarem IME-Dialog gesperrt',
    (tester) async {
      final results = <ExperienceRewardChoice?>[];
      final campaign = await showReward(
        tester,
        width: 320,
        height: 680,
        textScale: 2,
        onResult: results.add,
      );
      await tester.enterText(
        find.byKey(const ValueKey('xp-reward-id')),
        'quest-invalid',
      );
      await tester.enterText(
        find.byKey(const ValueKey('xp-reward-amount')),
        '0',
      );
      await scrollToConsent(tester);
      await tester.tap(find.byKey(const ValueKey('xp-reward-consent')));
      await tester.pumpAndSettle();
      final confirm = find.byKey(const ValueKey('xp-reward-confirm'));
      expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNull);
      expect(find.textContaining('1 bis 100000 EP'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('xp-reward-cancel')).hitTestable(),
        findsOneWidget,
      );
      expect(results, isEmpty);
      expect(campaign.hero.experience, 0);
      expect(campaign.events, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
