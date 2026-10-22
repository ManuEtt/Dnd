import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/ui/campaign_memory_panel.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

// Only tests visible controls and dialog behavior. Persistence is exercised
// separately by repository tests and new domain round-trip coverage.
class _MemoryRepository implements CampaignRepository {
  Campaign? campaign;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('campaign memory controls show all three editable areas', (
    tester,
  ) async {
    final repository = _MemoryRepository();
    final controller = GameController(repository: repository);
    controller.currentCampaign = Campaign(
      id: 'campaign',
      name: 'Test',
      world: 'Aetheria',
      sessionId: 'session',
      hero: HeroCharacter(id: 'hero', name: 'Held'),
      scene: 'Waldschrein',
      npcs: const [WorldNpc(id: 'mira', name: 'Mira')],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CampaignMemoryPanel(controller: controller),
          ),
        ),
      ),
    );
    expect(find.text('Sitzungsrückblicke'), findsOneWidget);
    expect(find.text('Offene Handlungsstränge'), findsOneWidget);
    expect(find.text('NPC-Beziehungen'), findsOneWidget);
    final create = find.byKey(const ValueKey('create-story-thread'));
    expect(tester.widget<FantasyTextButton>(create).style,
        FantasyButtonStyle.woodGold);
    await tester.ensureVisible(create);
    await tester.tap(create);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const ValueKey('story-thread-title')), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
