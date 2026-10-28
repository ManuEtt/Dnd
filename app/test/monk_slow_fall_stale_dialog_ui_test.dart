import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';

class _SilentVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
}

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets(
    'Slow Fall: old open dialog cannot spend Reaction after another commit',
    (tester) async {
      tester.view.physicalSize = const Size(360, 900);
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
      final voice = _SilentVoice();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        voice.dispose();
        await tester.runAsync(repository.close);
      });

      final demo = GameEngine().createDemo();
      final before = demo.copyWith(
        hero: demo.hero.copyWith(
          className: 'Mönch',
          level: 4,
          hitPoints: 20,
          maxHitPoints: 20,
        ),
        encounter: const Encounter(
          id: 'fall-stale-ui',
          enemyName: 'Wache',
          enemyHitPoints: 10,
          enemyMaxHitPoints: 10,
          activeParticipant: 'enemy',
        ),
      );
      await tester.runAsync(() => repository.saveCampaign(before));
      await tester.runAsync(() => controller.openCampaign(before.id));
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Abenteuer'),
        ),
      );
      await tester.pumpAndSettle();

      final action = find.byKey(const ValueKey('adventure-monk-slow-fall'));
      await tester.scrollUntilVisible(
        action,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('slow-fall-damage-input')),
        '28',
      );
      await tester.tap(find.byKey(const ValueKey('slow-fall-confirm-fall')));
      await tester.tap(
        find.byKey(const ValueKey('slow-fall-confirm-defenses')),
      );
      await tester.pumpAndSettle();

      final submit = find.byKey(const ValueKey('slow-fall-commit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

      // Simulate a separate confirmed action committing during the open
      // dialog. Its original snapshot must not authorize a second Reaction.
      await tester.runAsync(
        () => controller.applyConfirmedSlowFall(
          campaignId: before.id,
          expectedRevision: before.revision,
          encounterId: 'fall-stale-ui',
          confirmedFallDamage: 12,
          fallConfirmed: true,
          playerConfirmedReaction: true,
          damageAfterOtherDefensesConfirmed: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.error, isNull);
      final committed = controller.currentCampaign!;
      expect(committed.revision, before.revision + 1);
      expect(committed.encounter!.reactionUsed, isTrue);
      expect(committed.events.last.type, 'combat.slowFallResolved');

      // The old dialog still displays its prior preview. The UI detects
      // the stale revision and explains why a second commit was rejected.
      expect(submit, findsOneWidget);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('slow-fall-stale-feedback')),
        findsOneWidget,
      );
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), committed.toJson());
      expect(
        controller.currentCampaign!.events.where(
          (event) => event.type == 'combat.slowFallResolved',
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
