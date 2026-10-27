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

Future<void> _waitForCommit(
  WidgetTester tester,
  GameController controller,
  int beforeRevision,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (!controller.busy &&
        controller.currentCampaign!.revision > beforeRevision) {
      break;
    }
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(sqfliteFfiInit);

  testWidgets(
    '360px adventure: confirmed Slow Fall commits HP and Reaction exactly once',
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
          id: 'slow-fall-ui',
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
      expect(action, findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Sanfter Fall – Reaktion'), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();
      expect(controller.currentCampaign!.revision, before.revision);
      expect(controller.currentCampaign!.encounter!.reactionUsed, false);

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
      expect(find.textContaining('20 Schaden verhindert'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('slow-fall-commit')));
      await _waitForCommit(tester, controller, before.revision);
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(after.revision, before.revision + 1);
      expect(after.hero.hitPoints, 12);
      expect(after.encounter!.reactionUsed, isTrue);
      expect(after.events.last.type, 'combat.slowFallResolved');
      expect(after.events.last.payload['damagePrevented'], 20);
      expect(after.events.last.payload['damage'], 8);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('A spent Reaction leaves the adventure action disabled', (
    tester,
  ) async {
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
      hero: demo.hero.copyWith(className: 'Mönch', level: 4),
      encounter: const Encounter(
        id: 'spent-reaction-ui',
        enemyName: 'Wache',
        enemyHitPoints: 10,
        enemyMaxHitPoints: 10,
        activeParticipant: 'enemy',
        reactionUsed: true,
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
    expect(action, findsOneWidget);
    await tester.tap(action, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Sanfter Fall – Reaktion'), findsNothing);
    expect(controller.currentCampaign!.revision, before.revision);
    expect(tester.takeException(), isNull);
  });
}
