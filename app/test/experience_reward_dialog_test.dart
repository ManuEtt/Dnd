import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/experience_progression.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/experience_reward_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    Campaign campaign, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: fantasyTheme(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                key: const ValueKey('open-xp-dialog'),
                onPressed: () => showDialog<ExperienceRewardChoice>(
                  context: context,
                  builder: (_) => ExperienceRewardDialog(campaign: campaign),
                ),
                child: const Text('Dialog öffnen'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-xp-dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('Abbrechen bucht nichts und Bestätigung braucht Zustimmung', (
    tester,
  ) async {
    final campaign = GameEngine().createDemo();
    await openDialog(tester, campaign);
    expect(
      tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('xp-reward-confirm')),
      ).onPressed,
      isNull,
    );
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-id')),
      'quest-eins',
    );
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-amount')),
      '300',
    );
    await tester.pump();
    expect(find.textContaining('Nach Bestätigung: 300 EP'), findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('xp-reward-confirm')),
      ).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('xp-reward-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(ExperienceRewardDialog), findsNothing);
    expect(campaign.hero.experience, 0);
    expect(campaign.events, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bestätigung liefert stabile IDs und ändert kein Domainmodell', (
    tester,
  ) async {
    final campaign = GameEngine().createDemo();
    ExperienceRewardChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: fantasyTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<ExperienceRewardChoice>(
                  context: context,
                  builder: (_) => ExperienceRewardDialog(campaign: campaign),
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
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-id')),
      'quest_2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-amount')),
      '300',
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-consent')));
    await tester.tap(find.byKey(const ValueKey('xp-reward-consent')));
    await tester.pump();
    expect(
      tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('xp-reward-confirm')),
      ).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('xp-reward-confirm')));
    await tester.pumpAndSettle();
    expect(choice?.rewardId, 'quest_2');
    expect(choice?.requestId, 'xp_quest_2');
    expect(choice?.amount, 300);
    expect(campaign.hero.experience, 0);
    expect(campaign.events, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bereits bestätigter Beleg zeigt keine zweite Vergabe an', (
    tester,
  ) async {
    final initial = GameEngine().createDemo();
    final confirmed = Campaign.fromJson(
      ExperienceProgression.grant(
        initial,
        rewardId: 'quest-zwei',
        amount: 300,
      ).toJson(),
    );
    await openDialog(tester, confirmed);
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-id')),
      'quest-zwei',
    );
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-amount')),
      '300',
    );
    await tester.pump();
    expect(find.textContaining('Bereits gebucht'), findsOneWidget);
    final action = tester.widget<FantasyTextButton>(
      find.byKey(const ValueKey('xp-reward-confirm')),
    );
    expect(action.label, 'Buchung prüfen');
    expect(action.onPressed, isNull);
    expect(confirmed.hero.experience, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp und große Schrift: Eingaben und Zustimmung bleiben bedienbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openDialog(
      tester,
      GameEngine().createDemo(),
      textScale: 1.4,
    );
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-id')),
      'quest-eng',
    );
    await tester.enterText(
      find.byKey(const ValueKey('xp-reward-amount')),
      '200',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-consent')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('xp-reward-consent')).hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('xp-reward-cancel')).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unbestätigte historische EP sperren die Buchung', (
    tester,
  ) async {
    final initial = GameEngine().createDemo();
    await openDialog(
      tester,
      initial.copyWith(hero: initial.hero.copyWith(experience: null)),
    );
    expect(find.textContaining('zuerst den bisherigen EP-Stand'), findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('xp-reward-confirm')),
      ).onPressed,
      isNull,
    );
  });
}
