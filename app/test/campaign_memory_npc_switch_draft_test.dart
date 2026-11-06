import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/ui/campaign_memory_panel.dart';

class _RecordingRepository implements CampaignRepository {
  Campaign? saved;

  @override
  Future<void> saveCampaign(
    Campaign campaign, {
    List<GameEvent> events = const [],
    int? expectedRevision,
  }) async {
    saved = campaign;
  }

  @override
  Future<List<Campaign>> loadCampaigns() async => [if (saved != null) saved!];

  @override
  Future<List<HeroCharacter>> loadCharacters() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Campaign _campaign() => Campaign(
  id: 'npc-note-switch',
  name: 'Testkampagne',
  world: 'Testwelt',
  sessionId: 'session',
  hero: HeroCharacter(id: 'hero', name: 'Held'),
  scene: 'Marktplatz',
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'Vertraut'),
    WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'Neutral'),
  ],
);

Future<void> _openNpcDialog(
  WidgetTester tester,
  GameController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CampaignMemoryPanel(controller: controller),
        ),
      ),
    ),
  );
  final edit = find.byKey(const ValueKey('edit-npc-relationship'));
  await tester.ensureVisible(edit);
  await tester.tap(edit);
  await tester.pumpAndSettle();
  expect(find.text('NPC-Beziehung festhalten'), findsOneWidget);
}

Future<void> _selectNpc(WidgetTester tester, String name) async {
  final selector = find.byKey(const ValueKey('npc-relationship-target'));
  await tester.ensureVisible(selector);
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.tap(find.text(name).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('NPC-Wechsel trennt alte und neue Notiz', (tester) async {
    final repository = _RecordingRepository();
    final controller = GameController(repository: repository);
    final original = _campaign();
    final before = jsonEncode(original.toJson());
    controller.currentCampaign = original;
    addTearDown(controller.dispose);

    await _openNpcDialog(tester, controller);
    final note = find.byKey(const ValueKey('npc-relationship-note'));
    await tester.enterText(note, 'Mira hat mir den Schlüssel gegeben.');
    final oldNoteState = tester.state<FormFieldState<String>>(note);

    await _selectNpc(tester, 'Tarek');
    expect(
      tester.state<FormFieldState<String>>(note),
      isNot(same(oldNoteState)),
    );
    expect(tester.state<FormFieldState<String>>(note).value, '');
    expect(find.text('Mira hat mir den Schlüssel gegeben.'), findsNothing);
    expect(
      tester
          .state<FormFieldState<String>>(
            find.byKey(const ValueKey('npc-relationship-value')),
          )
          .value,
      'Neutral',
    );

    // The former NPC's text must not satisfy the new NPC's required note.
    await tester.tap(find.text('Bestätigen'));
    await tester.pumpAndSettle();
    expect(find.text('NPC-Beziehung festhalten'), findsOneWidget);
    expect(repository.saved, isNull);
    expect(jsonEncode(original.toJson()), before);

    await tester.enterText(note, 'Tarek hat die Brücke bewacht.');
    await tester.tap(find.text('Bestätigen'));
    await tester.pumpAndSettle();
    expect(find.text('NPC-Beziehung festhalten'), findsNothing);
    expect(controller.error, isNull);
    expect(repository.saved, isNotNull);
    expect(repository.saved!.npcRelationshipNotes, hasLength(1));
    expect(repository.saved!.npcRelationshipNotes.single.npcId, 'tarek');
    expect(
      repository.saved!.npcRelationshipNotes.single.note,
      'Tarek hat die Brücke bewacht.',
    );
    expect(jsonEncode(original.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zurückwechseln stellt keinen alten Entwurf wieder her', (
    tester,
  ) async {
    final repository = _RecordingRepository();
    final controller = GameController(repository: repository);
    final original = _campaign();
    final before = jsonEncode(original.toJson());
    controller.currentCampaign = original;
    addTearDown(controller.dispose);

    await _openNpcDialog(tester, controller);
    final note = find.byKey(const ValueKey('npc-relationship-note'));
    await tester.enterText(note, 'Nur für Mira');
    await _selectNpc(tester, 'Tarek');
    await tester.enterText(note, 'Nur für Tarek');
    await _selectNpc(tester, 'Mira');
    expect(tester.state<FormFieldState<String>>(note).value, '');
    expect(find.text('Nur für Mira'), findsNothing);
    expect(find.text('Nur für Tarek'), findsNothing);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(repository.saved, isNull);
    expect(jsonEncode(original.toJson()), before);
    expect(tester.takeException(), isNull);
  });
}
