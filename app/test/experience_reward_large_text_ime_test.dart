import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/experience_reward_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  Future<Campaign> showReward(
    WidgetTester tester, {
    required double width,
    required double height,
    required double textScale,
    required ValueChanged<ExperienceRewardChoice?> onResult,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final campaign = GameEngine().createDemo();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open-xp-ime-dialog'),
              onPressed: () async {
                final value = await showDialog<ExperienceRewardChoice>(
                  context: context,
                  builder: (_) => ExperienceRewardDialog(campaign: campaign),
                );
                onResult(value);
              },
              child: const Text('EP-Dialog öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-xp-ime-dialog')));
    await tester.pumpAndSettle();
    return campaign;
  }

  for (final width in [320.0, 360.0]) {
    testWidgets('EP-Dialog bei $width dp, 200 % und IME: Abbruch erreichbar', (
      tester,
    ) async {
      final results = <ExperienceRewardChoice?>[];
      final campaign = await showReward(
        tester,
        width: width,
        height: 680,
        textScale: 2,
        onResult: results.add,
      );
      final cancel = find.byKey(const ValueKey('xp-reward-cancel'));
      final confirm = find.byKey(const ValueKey('xp-reward-confirm'));
      expect(find.byType(ExperienceRewardDialog), findsOneWidget);
      expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNull);
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-id')));
      await tester.enterText(
        find.byKey(const ValueKey('xp-reward-id')),
        'quest-nicht-gebucht',
      );
      await tester.pumpAndSettle();
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(campaign.hero.experience, 0);
      expect(campaign.events, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('EP-Buchungswahl bei 320 dp, 200 % und IME erreichbar', (
    tester,
  ) async {
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
      'quest-ime',
    );
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-amount')),
      '300',
    );
    final consent = find.byKey(const ValueKey('xp-reward-consent'));
    await tester.scrollUntilVisible(
      consent,
      160,
      scrollable: find
          .descendant(
            of: find.byType(ExperienceRewardDialog),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ExperienceRewardDialog),
          matching: find.byType(Scrollable),
        )
        .first;
    final scrollPosition = tester.state<ScrollableState>(scrollable).position;
    debugPrint(
      'XP-IME viewport=${tester.getRect(scrollable)} '
      'consent=${tester.getRect(consent)} '
      'cancel=${tester.getRect(find.byKey(const ValueKey('xp-reward-cancel')))} '
      'scroll=${scrollPosition.pixels}/${scrollPosition.maxScrollExtent} '
      'inset=${MediaQuery.of(tester.element(consent)).viewInsets.bottom}',
    );
    expect(consent.hitTestable(), findsOneWidget);
    await tester.tap(consent);
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
      final consent = find.byKey(const ValueKey('xp-reward-consent'));
      await tester.scrollUntilVisible(
        consent,
        160,
        scrollable: find
            .descendant(
              of: find.byType(ExperienceRewardDialog),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      final scrollable = find
        .descendant(
          of: find.byType(ExperienceRewardDialog),
          matching: find.byType(Scrollable),
        )
        .first;
    final scrollPosition = tester.state<ScrollableState>(scrollable).position;
    debugPrint(
      'XP-IME viewport=${tester.getRect(scrollable)} '
      'consent=${tester.getRect(consent)} '
      'cancel=${tester.getRect(find.byKey(const ValueKey('xp-reward-cancel')))} '
      'scroll=${scrollPosition.pixels}/${scrollPosition.maxScrollExtent} '
      'inset=${MediaQuery.of(tester.element(consent)).viewInsets.bottom}',
    );
    expect(consent.hitTestable(), findsOneWidget);
      await tester.tap(consent);
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
