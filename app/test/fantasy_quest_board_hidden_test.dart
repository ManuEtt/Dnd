import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_adventure_hud.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final resolvedCount in [3, 4, 5]) {
    testWidgets('Verborgene Aufträge: $resolvedCount erledigt', (tester) async {
      tester.view.physicalSize = const Size(320, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final quests = <Quest>[
        const Quest(id: 'active', title: 'Ein aktiver Auftrag'),
        for (var i = 0; i < resolvedCount; i++)
          Quest(
            id: 'resolved-$i',
            title: 'Erledigter Auftrag $i',
            status: i.isEven ? 'completed' : 'failed',
          ),
      ];
      final originalIds = quests.map((quest) => quest.id).toList();
      final originalStatuses = quests.map((quest) => quest.status).toList();
      final campaign = Campaign(
        id: 'hidden-quests',
        name: 'Rabenwacht',
        world: 'Nordmark',
        sessionId: 'hidden-quests-session',
        hero: HeroCharacter(id: 'hero', name: 'Elowen'),
        scene: 'Am Tor.',
        quests: quests,
      );
      var journalOpens = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: ListView(
              children: [
                FantasyAdventureQuestBoard(
                  campaign: campaign,
                  onOpenJournal: () => journalOpens++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auftragsübersicht'));
      await tester.pumpAndSettle();

      expect(
        find.text('Abgeschlossen / gescheitert: $resolvedCount'),
        findsOneWidget,
      );
      for (var i = 0; i < resolvedCount; i++) {
        final quest = find.byKey(ValueKey('adventure-quest-resolved-$i'));
        expect(quest, i < 3 ? findsOneWidget : findsNothing);
      }

      final hint = find.byKey(
        const ValueKey('adventure-quest-hidden-count'),
      );
      if (resolvedCount == 3) {
        expect(hint, findsNothing);
      } else {
        expect(hint, findsOneWidget);
        expect(
          find.text(
            resolvedCount == 4
                ? 'Ein weiterer Auftrag im Tagebuch'
                : '2 weitere Aufträge im Tagebuch',
          ),
          findsOneWidget,
        );
      }

      final journal = find.byKey(
        const ValueKey('adventure-quest-open-journal'),
      );
      await tester.ensureVisible(journal);
      await tester.pumpAndSettle();
      await tester.tap(journal);
      expect(journalOpens, 1);
      expect(campaign.quests.map((quest) => quest.id).toList(), originalIds);
      expect(
        campaign.quests.map((quest) => quest.status).toList(),
        originalStatuses,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
