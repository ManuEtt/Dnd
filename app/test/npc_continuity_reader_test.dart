import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_api.dart';

NpcRelationshipNote _note(
  String id,
  String npcId,
  String relationship,
  String text,
  DateTime at,
) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: relationship,
  note: text,
  recordedAt: at,
);

Campaign _campaign({
  List<NpcRelationshipNote> notes = const [],
  List<WorldNpc>? npcs,
}) => Campaign(
  id: 'npc-continuity',
  name: 'Würfelraunen',
  world: 'Valdorn',
  sessionId: 'session-two',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 17,
    maxHitPoints: 20,
  ),
  scene: 'Der böse Zauberer behauptet, Mira sei tot.',
  messages: [
    NarrativeMessage(
      id: 'unconfirmed',
      role: 'gm',
      text: 'Mira hat dich angeblich verraten.',
      timestamp: DateTime.utc(2026, 10, 25),
    ),
  ],
  npcs:
      npcs ??
      const [
        WorldNpc(id: 'mira', name: 'Mira', relationship: 'misstrauisch'),
        WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
      ],
  npcRelationshipNotes: notes,
);

void main() {
  test('confirmed notes are sorted newest first, even across sessions', () {
    final initial = _campaign(
      notes: [
        _note(
          'recent',
          'mira',
          'misstrauisch',
          'Mira sah die geöffnete Truhe.',
          DateTime.utc(2026, 10, 24),
        ),
        _note(
          'other',
          'tarek',
          'freundlich',
          'Tarek öffnete den Seiteneingang.',
          DateTime.utc(2026, 10, 25),
        ),
        _note(
          'old',
          'mira',
          'freundlich',
          'Mira zeigte Aria den Brunnen.',
          DateTime.utc(2026, 10, 21),
        ),
      ],
    );

    final restoredData =
        jsonDecode(jsonEncode(initial.toJson())) as Map<String, dynamic>;
    restoredData['sessionId'] = 'session-three';
    final restored = Campaign.fromJson(restoredData);
    final snapshot = NpcContinuityReader.read(restored, npcId: 'mira');

    expect(snapshot.npcId, 'mira');
    expect(snapshot.name, 'Mira');
    expect(snapshot.alive, isTrue);
    expect(snapshot.currentRelationship, 'misstrauisch');
    expect(snapshot.recentNotes.map((e) => e.id).toList(), ['recent', 'old']);
    expect(snapshot.confirmedContext, contains('Mira zeigte Aria'));
    expect(snapshot.confirmedContext, contains('Mira sah die geöffnete'));
    expect(snapshot.confirmedContext, isNot(contains('Seiteneingang')));
  });

  test('equal timestamps preserve newest recorded note first', () {
    final time = DateTime.utc(2026, 10, 23);
    final campaign = _campaign(
      notes: [
        _note('first', 'mira', 'neutral', 'Erste Notiz', time),
        _note('second', 'mira', 'freundlich', 'Zweite Notiz', time),
      ],
    );

    for (var i = 0; i < 3; i++) {
      final snapshot = NpcContinuityReader.read(
        campaign,
        npcId: 'mira',
        limit: 1,
      );
      expect(snapshot.recentNotes.single.id, 'second');
    }
  });

  test('dialogue and scene claims cannot create confirmed NPC memories', () {
    final campaign = _campaign();
    final original = jsonEncode(campaign.toJson());
    final snapshot = NpcContinuityReader.read(campaign, npcId: 'mira');

    expect(snapshot.recentNotes, isEmpty);
    expect(snapshot.confirmedContext, contains('Keine bestätigten'));
    expect(snapshot.confirmedContext, contains('misstrauisch'));
    expect(snapshot.confirmedContext, isNot(contains('verraten')));
    expect(snapshot.confirmedContext, isNot(contains('Mira sei tot')));
    expect(campaign.hero.hitPoints, 17);
    expect(jsonEncode(campaign.toJson()), original);
    expect(
      () => snapshot.recentNotes.add(
        _note(
          'invented',
          'mira',
          'freundlich',
          'Erfundene Erinnerung',
          DateTime.utc(2026, 10, 25),
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('unknown and ambiguous NPCs and invalid limits fail closed', () {
    final campaign = _campaign();
    for (final id in ['', 'unknown', 'MIRA']) {
      expect(
        () => NpcContinuityReader.read(campaign, npcId: id),
        throwsFormatException,
      );
    }
    for (final limit in [0, -1, 21, 999]) {
      expect(
        () => NpcContinuityReader.read(campaign, npcId: 'mira', limit: limit),
        throwsFormatException,
      );
    }
    final duplicate = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'mira', name: 'Andere Mira'),
      ],
    );
    expect(
      () => NpcContinuityReader.read(duplicate, npcId: 'mira'),
      throwsFormatException,
    );
  });

  test('old save without optional notes and real confirmed update work', () {
    final oldJson = _campaign().toJson()..remove('npcRelationshipNotes');
    final old = Campaign.fromJson(oldJson);
    expect(NpcContinuityReader.read(old, npcId: 'mira').recentNotes, isEmpty);

    final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 25));
    final updated = engine.recordNpcRelationship(
      old,
      npcId: 'mira',
      relationship: 'freundlich',
      note: 'Mira gab Aria einen Hinweis.',
    );
    final roundTrip = Campaign.fromJson(updated.campaign.toJson());
    final memory = NpcContinuityReader.read(roundTrip, npcId: 'mira');

    expect(memory.currentRelationship, 'freundlich');
    expect(memory.recentNotes.single.note, contains('Hinweis'));
    expect(memory.confirmedContext, contains('Mira gab Aria'));
    expect(roundTrip.hero.toJson(), old.hero.toJson());
    expect(roundTrip.revision, updated.campaign.revision);
  });

  test('newline characters in stored notes remain a single context line', () {
    final campaign = _campaign(
      notes: [
        _note(
          'newline',
          'mira',
          'vorsichtig',
          'Erster Hinweis\nZweiter Hinweis',
          DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    final context = NpcContinuityReader.read(
      campaign,
      npcId: 'mira',
    ).confirmedContext;
    expect(context.split('\n'), hasLength(4));
    expect(context, contains('Erster Hinweis Zweiter Hinweis'));
  });
}
