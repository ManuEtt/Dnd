import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/experience_progression.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/experience_reward_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

class _SilentRewardVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> speak(String text) async {}
}

void main() {
  setUpAll(sqfliteFfiInit);
  Future<void> openDialog(
    WidgetTester tester,
    Campaign campaign, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: fantasyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
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
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('xp-reward-confirm')),
          )
          .onPressed,
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
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('xp-reward-confirm')),
          )
          .onPressed,
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
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('xp-reward-confirm')),
          )
          .onPressed,
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

  testWidgets(
    '320 dp und große Schrift: Eingaben und Zustimmung bleiben bedienbar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await openDialog(tester, GameEngine().createDemo(), textScale: 1.4);
      await tester.enterText(
        find.byKey(const ValueKey('xp-reward-id')),
        'quest-eng',
      );
      await tester.enterText(
        find.byKey(const ValueKey('xp-reward-amount')),
        '200',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('xp-reward-consent')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('xp-reward-consent')).hitTestable(),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('xp-reward-cancel')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unbestätigte historische EP sperren die Buchung', (
    tester,
  ) async {
    final initial = GameEngine().createDemo();
    await openDialog(
      tester,
      initial.copyWith(hero: initial.hero.copyWith(experience: null)),
    );
    expect(
      find.textContaining('zuerst den bisherigen EP-Stand'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('xp-reward-confirm')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'Abenteuerdialog bestätigt XP wirklich einmal im SQLite-Journal',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _SilentRewardVoice();
      try {
        await tester.runAsync(controller.createDemo);
        await tester.pumpWidget(
          LivingGameApp(controller: controller, voice: voice),
        );
        await tester.tap(find.text('Abenteuer'));
        await tester.pumpAndSettle();
        final action = find.byKey(
          const ValueKey('adventure-confirm-xp-reward'),
        );
        await tester.scrollUntilVisible(
          action,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.byType(ExperienceRewardDialog), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('xp-reward-id')),
          'musterquest-1',
        );
        await tester.enterText(
          find.byKey(const ValueKey('xp-reward-amount')),
          '300',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('xp-reward-consent')),
        );
        await tester.tap(find.byKey(const ValueKey('xp-reward-consent')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('xp-reward-confirm')));
        for (var retry = 0; retry < 100; retry++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
          if (controller.currentCampaign?.revision == 1 && !controller.busy) {
            break;
          }
        }
        expect(controller.error, isNull);
        final campaign = controller.currentCampaign!;
        expect(campaign.hero.experience, 300);
        expect(campaign.revision, 1);
        expect(campaign.events.single.type, 'xp.reward.confirmed');
        expect(
          campaign.events.single.payload['actionRequestId'],
          'xp_musterquest-1',
        );
        expect(
          (await tester.runAsync(
            () => repository.getCampaign(campaign.id),
          ))!.toJson(),
          campaign.toJson(),
        );
        expect(find.byKey(const ValueKey('xp-reward-receipt')), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        voice.dispose();
        await tester.runAsync(repository.close);
      }
    },
  );
}
