import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';
import 'package:lebendiger_spielleiter/ui/npc_story_selection_dialog.dart';

Campaign _campaign({bool withNotes = true}) => Campaign(
  id: 'npc-dialog',
  name: 'Die zwei Miras',
  world: 'Valdorn',
  sessionId: 'npc-session',
  hero: HeroCharacter(id: 'hero', name: 'Aria'),
  scene: 'Vor dem Tor',
  revision: 4,
  npcs: const [
    WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
    WorldNpc(id: 'mira-two', name: 'Mira', relationship: 'misstrauisch'),
  ],
  npcRelationshipNotes: withNotes
      ? [
          NpcRelationshipNote(
            id: 'first',
            npcId: 'mira-one',
            relationship: 'freundlich',
            note: 'Die erste Mira verwahrt die Karte.',
            recordedAt: DateTime.utc(2026, 10, 24),
          ),
          NpcRelationshipNote(
            id: 'second',
            npcId: 'mira-two',
            relationship: 'misstrauisch',
            note: 'Die zweite Mira bewacht das Tor.',
            recordedAt: DateTime.utc(2026, 10, 25),
          ),
        ]
      : const [],
);

void main() {
  testWidgets('same display names require explicit identity selection', (
    tester,
  ) async {
    NpcStorySelection? selected;
    final campaign = _campaign();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selected = await showNpcStorySelectionDialog(context, campaign);
              },
              child: const Text('NPC auswählen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('NPC auswählen'));
    await tester.pumpAndSettle();
    expect(find.text('Gesprächspartner auswählen'), findsOneWidget);
    expect(find.text('Mira'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('npc-picker-mira-one')), findsOneWidget);
    expect(find.byKey(const ValueKey('npc-picker-mira-two')), findsOneWidget);
    expect(find.textContaining('Kennung: mira-one'), findsOneWidget);
    expect(find.textContaining('Kennung: mira-two'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('npc-picker-mira-two')));
    await tester.pumpAndSettle();
    expect(selected?.npcId, 'mira-two');
    expect(selected?.revision, 4);
    expect(selected?.name, 'Mira');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancellation does not silently select an NPC', (tester) async {
    NpcStorySelection? chosen;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                chosen = await showNpcStorySelectionDialog(
                  context,
                  _campaign(),
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
    await tester.tap(find.byKey(const ValueKey('npc-picker-cancel')));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no confirmed notes never offers an invented identity', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showNpcStorySelectionDialog(
                context,
                _campaign(withNotes: false),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('npc-picker-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('npc-picker-mira-one')), findsNothing);
    expect(find.byKey(const ValueKey('npc-picker-mira-two')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
