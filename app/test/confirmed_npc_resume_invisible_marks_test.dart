import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_resume_selection.dart';

Campaign _campaign(WorldNpc npc, String note) => Campaign(
  id: 'confirmed-npc-unicode',
  name: 'Die verborgene Spur',
  world: 'Valdorn',
  sessionId: 'session-confirmed',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Das Gold wurde verdoppelt.',
  revision: 4,
  npcs: [npc],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'note-1',
      npcId: npc.id,
      relationship: 'bestätigt',
      note: note,
      recordedAt: DateTime.utc(2026, 11, 3),
    ),
  ],
);

void main() {
  test('confirmed NPC overview strips legacy invisible formatting marks', () {
    const marks = '\u00ad\u034f\u180e\u206a\u206b\u206c\u206d\u206e\u206f';
    final campaign = _campaign(
      WorldNpc(
        id: 'mira',
        name: 'Mi${marks}ra',
        relationship: 'ver${marks}traut',
      ),
      'Das Si${marks}egel bleibt verschlossen.',
    );
    final before = jsonEncode(campaign.toJson());

    final selection = ConfirmedNpcResumeSelector.read(
      campaign,
      expectedRevision: 4,
    );
    final overview = selection.playerOverview;

    expect(selection.entries.single.name, 'Mira');
    expect(overview, contains('NPC-ID: mira'));
    expect(overview, contains('Bestätigte Notiz:'));
    for (final mark in marks.runes) {
      expect(overview.contains(String.fromCharCode(mark)), isFalse);
    }
    expect(overview, isNot(contains('Gold wurde verdoppelt')));
    expect(overview.length, lessThanOrEqualTo(2400));
    selection.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('legitimate accented letters and emoji variation selectors remain', () {
    final campaign = _campaign(
      const WorldNpc(
        id: 'elise',
        name: 'Élise ✨️',
        relationship: 'freundlich und zuverlässig',
      ),
      'Grüße aus der Straße – das Licht ✨️ bleibt.',
    );
    final selection = ConfirmedNpcResumeSelector.read(
      campaign,
      expectedRevision: 4,
    );

    expect(selection.entries.single.name, 'Élise ✨️');
    expect(selection.playerOverview, contains('zuverlässig'));
    expect(selection.playerOverview, contains('Grüße aus der Straße'));
    expect(selection.playerOverview, contains('✨️ bleibt'));
    expect(selection.playerOverview, contains('NPC-ID: elise'));
    selection.requireCurrent(campaign);
  });

  test('JSON resume preserves notes and rejects same-revision edits', () {
    final campaign = _campaign(
      const WorldNpc(
        id: 'mira',
        name: 'Mi\u00adra',
        relationship: 'hilfsbereit',
      ),
      'Bestätigte Spur mit \u034f unsichtbarem Zeichen.',
    );
    final saved = jsonEncode(campaign.toJson());
    final restored = Campaign.fromJson(
      jsonDecode(saved) as Map<String, dynamic>,
    );
    final selection = ConfirmedNpcResumeSelector.read(
      restored,
      expectedRevision: restored.revision,
    );

    expect(selection.entries.single.name, 'Mira');
    selection.requireCurrent(restored);
    expect(jsonEncode(restored.toJson()), saved);

    final changed = restored.copyWith(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira', relationship: 'hilfsbereit'),
      ],
    );
    expect(
      () => selection.requireCurrent(changed),
      throwsFormatException,
    );
    expect(jsonEncode(restored.toJson()), saved);
    expect(restored.hero.hitPoints, 17);
  });
}
