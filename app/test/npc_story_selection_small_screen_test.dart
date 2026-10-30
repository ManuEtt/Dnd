import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';
import 'package:lebendiger_spielleiter/ui/npc_story_selection_dialog.dart';

Campaign _campaign({int count = 12, bool withNotes = true}) => Campaign(
  id: 'small-npc-picker',
  name: 'Die Chroniken der Wächter',
  world: 'Valdorn',
  sessionId: 'small-npc-picker-session',
  hero: HeroCharacter(id: 'hero', name: 'Aria'),
  scene: 'Vor dem Stadttor',
  revision: 7,
  npcs: [
    for (var i = 0; i < count; i++)
      WorldNpc(
        id: 'npc-$i',
        name: 'Mira die Hüterin der vergessenen Geschichten',
        relationship: 'Wächterin mit besonderer Verantwortung',
      ),
  ],
  npcRelationshipNotes: withNotes
      ? [
          for (var i = 0; i < count; i++)
            NpcRelationshipNote(
              id: 'note-$i',
              npcId: 'npc-$i',
              relationship: 'Wächterin',
              note: 'Die Identität wurde im Tagebuch bestätigt.',
              recordedAt: DateTime.utc(2026, 10, 30),
            ),
        ]
      : const [],
);

void _smallScreen(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Campaign campaign, ValueChanged<NpcStorySelection?> onResult) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(await showNpcStorySelectionDialog(context, campaign));
            },
            child: const Text('NPC auswählen'),
          ),
        ),
      ),
    );

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('200 % Schrift: NPC-Auswahl bei $width dp bleibt scrollbar', (
      tester,
    ) async {
      _smallScreen(tester, width, 560);
      final campaign = _campaign();
      final before = campaign.toJson();
      NpcStorySelection? selected;
      await tester.pumpWidget(_app(campaign, (value) => selected = value));
      await tester.tap(find.text('NPC auswählen'));
      await tester.pumpAndSettle();

      expect(tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable, isTrue);
      final list = find.byKey(const ValueKey('npc-picker-list'));
      expect(list, findsOneWidget);
      expect(find.byKey(const ValueKey('npc-picker-cancel')), findsOneWidget);
      expect(tester.takeException(), isNull);

      final target = find.byKey(const ValueKey('npc-picker-npc-11'));
      await tester.scrollUntilVisible(
        target,
        120,
        scrollable: find.descendant(
          of: list,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      await tester.tap(target);
      await tester.pumpAndSettle();

      expect(selected?.npcId, 'npc-11');
      expect(selected?.revision, 7);
      expect(campaign.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp: ohne bestätigte Erinnerung keine NPC-Auswahl', (
    tester,
  ) async {
    _smallScreen(tester, 320, 440);
    final campaign = _campaign(count: 2, withNotes: false);
    final before = campaign.toJson();
    NpcStorySelection? selected;
    await tester.pumpWidget(_app(campaign, (value) => selected = value));
    await tester.tap(find.text('NPC auswählen'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('npc-picker-empty')), findsOneWidget);
    expect(find.byKey(const ValueKey('npc-picker-list')), findsNothing);
    expect(find.byKey(const ValueKey('npc-picker-npc-0')), findsNothing);
    final cancel = find.byKey(const ValueKey('npc-picker-cancel'));
    await tester.ensureVisible(cancel);
    await tester.pumpAndSettle();
    expect(cancel.hitTestable(), findsOneWidget);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(selected, isNull);
    expect(campaign.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
