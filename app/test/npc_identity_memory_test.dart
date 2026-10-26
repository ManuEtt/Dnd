import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_memory.dart';

NpcRelationshipNote _note({
  required String id,
  required String npcId,
  required String relationship,
  required String value,
  required DateTime at,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: relationship,
  note: value,
  recordedAt: at,
);

Campaign _campaign({
  String id = 'identity-campaign',
  int revision = 7,
  List<WorldNpc>? npcs,
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: id,
  name: 'Würfelraunen',
  world: 'Valdorn',
  sessionId: 'second-session',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 13),
  scene: 'Ein unbestätigtes Gerücht über Mira.',
  npcs: npcs ??
      const [
        WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-b', name: 'Mira', relationship: 'feindlich'),
      ],
  npcRelationshipNotes: notes,
  revision: revision,
);

void main() {
  test('same-name NPCs remain distinct by confirmed ID', () {
    final campaign = _campaign(
      notes: [
        _note(
          id: 'a',
          npcId: 'mira-a',
          relationship: 'freundlich',
          value: 'Mira A zeigt die Karte.',
          at: DateTime.utc(2026, 10, 20),
        ),
        _note(
          id: 'b',
          npcId: 'mira-b',
          relationship: 'feindlich',
          value: 'Mira B bewacht das Stadttor.',
          at: DateTime.utc(2026, 10, 22),
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final a = NpcIdentityMemory.read(
      campaign,
      npcId: 'mira-a',
      expectedRevision: 7,
    );
    final b = NpcIdentityMemory.read(
      campaign,
      npcId: 'mira-b',
      expectedRevision: 7,
    );
    expect(a.npcName, b.npcName);
    expect(a.npcId, isNot(b.npcId));
    expect(a.relationship, 'freundlich');
    expect(b.relationship, 'feindlich');
    expect(a.notes.single.note, contains('Karte'));
    expect(b.notes.single.note, contains('Stadttor'));
    expect(a.toContextMap().toString(), isNot(contains('Stadttor')));
    expect(b.toContextMap().toString(), isNot(contains('Karte')));
    NpcIdentityMemory.requireCurrent(campaign, a);
    NpcIdentityMemory.requireCurrent(campaign, b);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('JSON-restored history sorts by date then recorded order', () {
    final time = DateTime.utc(2026, 10, 22);
    final original = _campaign(
      notes: [
        _note(
          id: 'older',
          npcId: 'mira-a',
          relationship: 'neutral',
          value: 'Älterer Hinweis',
          at: DateTime.utc(2026, 10, 18),
        ),
        _note(
          id: 'first',
          npcId: 'mira-a',
          relationship: 'freundlich',
          value: 'Erster Gleichstand',
          at: time,
        ),
        _note(
          id: 'foreign',
          npcId: 'mira-b',
          relationship: 'feindlich',
          value: 'Anderer NPC',
          at: DateTime.utc(2026, 10, 23),
        ),
        _note(
          id: 'second',
          npcId: 'mira-a',
          relationship: 'freundlich',
          value: 'Zweiter Gleichstand',
          at: time,
        ),
      ],
    );
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final snapshot = NpcIdentityMemory.read(
      restored,
      npcId: 'mira-a',
      expectedRevision: restored.revision,
      maxNotes: 2,
    );
    expect(snapshot.notes.map((entry) => entry.id).toList(), [
      'second',
      'first',
    ]);
    expect(snapshot.toContextMap()['campaignRevision'], 7);
    expect(snapshot.toContextMap()['npcId'], 'mira-a');
    expect(snapshot.toContextMap().toString(), isNot(contains('Anderer NPC')));
    NpcIdentityMemory.requireCurrent(restored, snapshot);
  });

  test('stale revisions, foreign campaigns and same-revision edits fail', () {
    final campaign = _campaign(
      notes: [
        _note(
          id: 'first',
          npcId: 'mira-a',
          relationship: 'freundlich',
          value: 'Die alte Karte',
          at: DateTime.utc(2026, 10, 20),
        ),
      ],
    );
    final context = NpcIdentityMemory.read(
      campaign,
      npcId: 'mira-a',
      expectedRevision: 7,
    );
    expect(
      () => NpcIdentityMemory.read(
        campaign,
        npcId: 'mira-a',
        expectedRevision: 6,
      ),
      throwsFormatException,
    );
    expect(
      () => NpcIdentityMemory.requireCurrent(
        campaign.copyWith(revision: 8),
        context,
      ),
      throwsFormatException,
    );
    expect(
      () => NpcIdentityMemory.requireCurrent(
        _campaign(id: 'another-campaign'),
        context,
      ),
      throwsFormatException,
    );
    final changed = campaign.copyWith(
      npcs: [
        const WorldNpc(
          id: 'mira-a',
          name: 'Mira',
          relationship: 'misstrauisch',
        ),
        const WorldNpc(
          id: 'mira-b',
          name: 'Mira',
          relationship: 'feindlich',
        ),
      ],
    );
    expect(
      () => NpcIdentityMemory.requireCurrent(changed, context),
      throwsFormatException,
    );
  });

  test('missing or duplicate IDs and invalid limits are rejected', () {
    final original = _campaign();
    for (final id in ['', 'unknown', ' mira-a', 'mira-a ']) {
      expect(
        () => NpcIdentityMemory.read(
          original,
          npcId: id,
          expectedRevision: 7,
        ),
        throwsFormatException,
      );
    }
    final duplicated = _campaign(
      npcs: const [
        WorldNpc(id: 'mira-a', name: 'Mira'),
        WorldNpc(id: 'mira-a', name: 'Andere Mira'),
      ],
    );
    expect(
      () => NpcIdentityMemory.read(
        duplicated,
        npcId: 'mira-a',
        expectedRevision: 7,
      ),
      throwsFormatException,
    );
    for (final limit in [0, -1, 21]) {
      expect(
        () => NpcIdentityMemory.read(
          original,
          npcId: 'mira-a',
          expectedRevision: 7,
          maxNotes: limit,
        ),
        throwsFormatException,
      );
    }
  });

  test('history and context projection cannot modify campaign rules', () {
    final campaign = _campaign(
      notes: [
        _note(
          id: 'confirmed',
          npcId: 'mira-a',
          relationship: 'freundlich',
          value: 'Mira A rät zu einer Rast.',
          at: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    final heroBefore = jsonEncode(campaign.hero.toJson());
    final snapshot = NpcIdentityMemory.read(
      campaign,
      npcId: 'mira-a',
      expectedRevision: 7,
    );
    expect(
      () => snapshot.notes.clear(),
      throwsUnsupportedError,
    );
    final serialized = snapshot.toContextMap();
    final entries = serialized['notes'] as List;
    expect((entries.single as Map)['npcId'], 'mira-a');
    expect(serialized.containsKey('hitPoints'), isFalse);
    expect(serialized.containsKey('quests'), isFalse);
    expect(jsonEncode(campaign.hero.toJson()), heroBefore);
    expect(campaign.revision, 7);
  });

  test('empty legacy notes and multiline text are safe after restore', () {
    final legacy = _campaign(
      npcs: const [WorldNpc(id: 'mira-a', name: 'Mira')],
    ).toJson()..remove('npcRelationshipNotes');
    final recovered = Campaign.fromJson(legacy);
    final empty = NpcIdentityMemory.read(
      recovered,
      npcId: 'mira-a',
      expectedRevision: 7,
    );
    expect(empty.notes, isEmpty);
    NpcIdentityMemory.requireCurrent(recovered, empty);

    final note = _note(
      id: 'new',
      npcId: 'mira-a',
      relationship: 'neutral',
      value: 'Eine Zeile\nEin zweiter Satz',
      at: DateTime.utc(2026, 10, 25),
    );
    final refreshed = recovered.copyWith(
      npcRelationshipNotes: [note],
      revision: 8,
    );
    expect(
      () => NpcIdentityMemory.requireCurrent(refreshed, empty),
      throwsFormatException,
    );
    final current = NpcIdentityMemory.read(
      refreshed,
      npcId: 'mira-a',
      expectedRevision: 8,
    );
    expect(current.toContextMap().toString(), contains('Eine Zeile Ein'));
    NpcIdentityMemory.requireCurrent(refreshed, current);
  });
}
