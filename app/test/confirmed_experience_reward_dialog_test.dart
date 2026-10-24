import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/confirmed_experience_reward_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

class _QuietVoice extends VoiceController {
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> speak(String text) async {}
}

void main() {
  setUpAll(sqfliteFfiInit);

  Future<void> showReward(
    WidgetTester tester,
    Campaign campaign, {
    double width = 360,
    double fontScale = 1,
    void Function(ConfirmedExperienceRewardChoice?)? onResult,
  }) async {
    tester.view.physicalSize = Size(width, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      theme: fantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(fontScale),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                final result = await showDialog<ConfirmedExperienceRewardChoice>(
                  context: context,
                  builder: (_) =>
                      ConfirmedExperienceRewardDialog(campaign: campaign),
                );
                onResult?.call(result);
              },
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmedExperienceRewardDialog), findsOneWidget);
  }

  Future<void> fillReward(WidgetTester tester, {String id = 'kapitel-1', String amount = '300'}) async {
    await tester.enterText(find.byKey(const ValueKey('xp-reward-id')), id);
    await tester.enterText(find.byKey(const ValueKey('xp-reward-amount')), amount);
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0]) {
    testWidgets('Fantasy-Vorschau und Abbrechen bei $width dp', (tester) async {
      final campaign = GameEngine().createDemo();
      ConfirmedExperienceRewardChoice? selected;
      await showReward(
        tester,
        campaign,
        width: width,
        fontScale: 1.3,
        onResult: (value) => selected = value,
      );
      await fillReward(tester);
      expect(find.text('Bisher: 0 EP'), findsOneWidget);
      expect(find.text('Danach: 300 EP'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-cancel')));
      await tester.tap(find.byKey(const ValueKey('xp-reward-cancel')));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(campaign.hero.experience, 0);
      expect(campaign.revision, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Validierung, ausdrückliche Zustimmung und stabile Request-ID', (tester) async {
    final campaign = GameEngine().createDemo();
    ConfirmedExperienceRewardChoice? selection;
    await showReward(tester, campaign, onResult: (value) => selection = value);

    await fillReward(tester, id: 'enthält Leerzeichen', amount: '300');
    await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-confirm')));
    await tester.tap(find.byKey(const ValueKey('xp-reward-confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1–100 Zeichen'), findsOneWidget);
    expect(selection, isNull);

    await fillReward(tester, id: 'kapitel-1', amount: '0');
    await tester.tap(find.byKey(const ValueKey('xp-reward-confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 bis 100.000'), findsOneWidget);
    expect(selection, isNull);

    await fillReward(tester);
    expect(find.text('Danach: 300 EP'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('xp-reward-confirm')));
    await tester.pumpAndSettle();
    expect(selection, isNotNull);
    expect(selection!.rewardId, 'kapitel-1');
    expect(selection!.amount, 300);
    expect(selection!.requestId, 'xp-ui-kapitel-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Historische unbekannte EP sperren manuelle Bestätigung', (tester) async {
    final engine = GameEngine();
    final original = engine.createDemo();
    final unknown = original.copyWith(
      hero: original.hero.copyWith(experience: null),
    );
    await showReward(tester, unknown);
    await fillReward(tester);
    expect(
      find.byKey(const ValueKey('xp-reward-unconfirmed-history')),
      findsOneWidget,
    );
    expect(find.text('Danach: —'), findsOneWidget);
    final confirmation = tester.widget<FantasyTextButton>(
      find.byKey(const ValueKey('xp-reward-confirm')),
    );
    expect(confirmation.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bestätigte Belohnung zeigt Null-Zuwachs statt erneuter XP', (tester) async {
    final initial = GameEngine().createDemo();
    final stored = initial.copyWith(
      hero: initial.hero.copyWith(experience: 300),
      facts: {...initial.facts, 'xp.reward.kapitel-1': '300'},
      revision: 1,
    );
    ConfirmedExperienceRewardChoice? selection;
    await showReward(tester, stored, onResult: (value) => selection = value);
    await fillReward(tester);
    expect(find.text('Bisher: 300 EP'), findsOneWidget);
    expect(find.text('Danach: 300 EP'), findsOneWidget);
    expect(find.byKey(const ValueKey('xp-reward-already-confirmed')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-confirm')));
    await tester.tap(find.byKey(const ValueKey('xp-reward-confirm')));
    await tester.pumpAndSettle();
    expect(selection!.requestId, 'xp-ui-kapitel-1');
    expect(stored.hero.experience, 300);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abenteuer: erst Zustimmung, dann ein SQLite-EP-Ereignis', (tester) async {
    tester.view.physicalSize = const Size(360, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dir = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('xp-dialog-ui-'),
    ))!;
    final path = paths.join(dir.path, 'campaign.sqlite');
    final database = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      ),
    ))!;
    final controller = GameController(repository: database);
    final voice = _QuietVoice();
    try {
      await tester.runAsync(controller.createDemo);
      final initial = controller.currentCampaign!;
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(
        const Duration(milliseconds: 100),
      ));
      await tester.pumpAndSettle();

      const openKey = ValueKey('adventure-confirm-xp-reward');
      await tester.scrollUntilVisible(
        find.byKey(openKey),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(openKey));
      await tester.pumpAndSettle();

      await fillReward(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-cancel')));
      await tester.tap(find.byKey(const ValueKey('xp-reward-cancel')));
      await tester.pumpAndSettle();
      expect(controller.currentCampaign!.revision, initial.revision);
      expect((await tester.runAsync(() => database.getCampaign(initial.id)))!.hero.experience, 0);

      await tester.ensureVisible(find.byKey(openKey));
      await tester.tap(find.byKey(openKey));
      await tester.pumpAndSettle();
      await fillReward(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('xp-reward-confirm')));
      await tester.tap(find.byKey(const ValueKey('xp-reward-confirm')));
      await tester.pump();
      for (var i = 0; i < 100; i++) {
        await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 20),
        ));
        await tester.pump();
        if (!controller.busy && controller.currentCampaign?.revision == 1) break;
      }
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.hero.experience, 300);
      expect(controller.currentCampaign!.events.last.type, 'xp.reward.confirmed');
      expect(
        controller.currentCampaign!.events.last.payload['actionRequestId'],
        'xp-ui-kapitel-1',
      );
      final persisted = (await tester.runAsync(
        () => database.getCampaign(initial.id),
      ))!;
      expect(persisted.hero.experience, 300);
      expect(persisted.revision, 1);
      expect(persisted.events, hasLength(1));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(() async {
        await database.close();
        await dir.delete(recursive: true);
      });
    }
  });
}
