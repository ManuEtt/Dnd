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

  testWidgets('360 px: Roving terrain actions fit and commit a confirmed climb', (
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
      hero: demo.hero.copyWith(className: 'Waldläufer', level: 6),
      encounter: const Encounter(
        id: 'terrain-ui',
        enemyName: 'Wache',
        enemyHitPoints: 10,
        enemyMaxHitPoints: 10,
        movementRemaining: 9,
      ),
    );
    await tester.runAsync(() => repository.saveCampaign(before));
    await tester.runAsync(() => controller.openCampaign(before.id));
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Abenteuer'),
    ));
    await tester.pumpAndSettle();

    final climb = find.byKey(const ValueKey('adventure-terrain-climb'));
    await tester.scrollUntilVisible(
      climb,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final swim = find.byKey(const ValueKey('adventure-terrain-swim'));
    expect(climb, findsOneWidget);
    expect(swim, findsOneWidget);
    expect(find.text('Klettern'), findsOneWidget);
    expect(find.text('Schwimmen'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(climb);
    await tester.pumpAndSettle();
    final choice = find.textContaining('1.5 m klettern (normales Gelände');
    expect(choice, findsOneWidget);
    await tester.tap(choice);
    await tester.pump();
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
      if (!controller.busy && controller.currentCampaign!.revision > before.revision) {
        break;
      }
    }
    await tester.pumpAndSettle();
    expect(controller.error, isNull);
    expect(controller.currentCampaign!.events.last.type, 'combat.climbed');
    expect(controller.currentCampaign!.encounter!.movementRemainingLabel, '7.5 m');
    expect(tester.takeException(), isNull);
  });
}
