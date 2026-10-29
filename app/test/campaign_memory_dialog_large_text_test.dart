import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/ui/campaign_memory_panel.dart';

class _MemoryRepository implements CampaignRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Campaign _campaign() => Campaign(
  id: 'small-dialog-campaign',
  name: 'Gedächtnis',
  world: 'Nordmark',
  sessionId: 'small-dialog-session',
  hero: HeroCharacter(id: 'hero', name: 'Elowen'),
  scene: 'Am alten Brunnen',
  npcs: const [
    WorldNpc(
      id: 'mira',
      name: 'Mira vom weit entfernten Mondlichtturm',
    ),
  ],
);

void main() {
  for (final dialog in ['thread', 'npc']) {
    testWidgets('320 dp, 200 % und IME: $dialog bleibt abbrechbar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      final controller = GameController(repository: _MemoryRepository());
      final campaign = _campaign();
      controller.currentCampaign = campaign;
      final before = campaign.toJson();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: CampaignMemoryPanel(controller: controller),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final open = find.byKey(
        ValueKey(
          dialog == 'thread'
              ? 'create-story-thread'
              : 'edit-npc-relationship',
        ),
      );
      await tester.ensureVisible(open);
      await tester.tap(open);
      await tester.pumpAndSettle();

      final alert = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alert.scrollable, isTrue);
      final save = find.byKey(
        ValueKey(
          dialog == 'thread'
              ? 'save-story-thread'
              : 'save-npc-relationship',
        ),
      );
      expect(save.hitTestable(), findsOneWidget);
      expect(find.text('Abbrechen').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(identical(controller.currentCampaign, campaign), isTrue);
      expect(campaign.toJson(), before);
      expect(tester.takeException(), isNull);
      controller.dispose();
    });
  }
}
