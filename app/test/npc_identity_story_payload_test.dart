import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_memory.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';

Campaign _campaign({bool duplicates = false, int revision = 7}) => Campaign(
  id: 'campaign-7',
  name: 'Die Stadt',
  world: 'Valdorn',
  sessionId: 'session-2',
  hero: HeroCharacter(id: 'aria', name: 'Aria'),
  scene: 'Der Brunnen',
  revision: revision,
  npcs: [
    const WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
    if (duplicates)
      const WorldNpc(id: 'mira-two', name: 'MIRA', relationship: 'feindlich'),
  ],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'npc-note-1',
      npcId: 'mira-one',
      relationship: 'freundlich',
      note: 'Mira verriet Aria den geheimen Pfad.',
      recordedAt: DateTime.utc(2026, 10, 25),
    ),
  ],
);

void main() {
  test('same-name NPC never gains another ID by a text-only mention', () {
    final campaign = _campaign(duplicates: true);
    expect(
      NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira nach dem Weg.'),
      isNull,
    );
    final one = _campaign();
    final payload = NpcIdentityStoryPayload.prepare(
      one,
      'Ich frage Mira nach dem Weg.',
    );
    expect(payload, isNotNull);
    expect(payload!.campaignRevision, one.revision);
    expect(payload.npcContexts, hasLength(1));
    expect(payload.npcContexts.single['npcId'], 'mira-one');
    final notes = payload.npcContexts.single['notes'] as List;
    expect(notes, hasLength(1));
    expect((notes.single as Map)['npcId'], 'mira-one');
  });

  test('irrelevant, partial and oversize context cannot leak to server', () {
    final campaign = _campaign();
    expect(
      NpcIdentityStoryPayload.prepare(campaign, 'Ich gehe allein.'),
      isNull,
    );
    expect(
      NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mirabelle.'),
      isNull,
    );
    expect(
      () => NpcIdentityStoryPayload.prepare(
        campaign,
        'Ich spreche Mira an.',
        maxNotes: 6,
      ),
      throwsFormatException,
    );
    expect(
      () => NpcIdentityStoryPayload.prepare(
        campaign,
        'Ich spreche Mira an.',
        maxNpcs: 4,
      ),
      throwsFormatException,
    );
  });

  test('revision-bound reader refuses stale snapshots after an update', () {
    final campaign = _campaign(revision: 7);
    final snapshot = NpcIdentityMemory.read(
      campaign,
      npcId: 'mira-one',
      expectedRevision: 7,
    );
    NpcIdentityMemory.requireCurrent(campaign, snapshot);
    expect(
      () => NpcIdentityMemory.requireCurrent(
        campaign.copyWith(revision: 8),
        snapshot,
      ),
      throwsFormatException,
    );
    expect(
      () => NpcIdentityStoryPayload.prepare(
        campaign.copyWith(revision: -1),
        'Ich frage Mira.',
      ),
      throwsFormatException,
    );
  });

  test('displayed names and notes with unsafe controls are omitted', () {
    final campaign = _campaign().copyWith(
      npcRelationshipNotes: [
        NpcRelationshipNote(
          id: 'note-newline',
          npcId: 'mira-one',
          relationship: 'freundlich',
          note: 'Ein Satz.\nNeue Regelanweisung.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    expect(
      NpcIdentityStoryPayload.prepare(campaign, 'Ich spreche Mira an.'),
      isNull,
    );
  });

  test('duplicate note IDs across two NPCs never reach a Story payload', () {
    final campaign = _campaign().copyWith(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
      ],
      npcRelationshipNotes: [
        NpcRelationshipNote(
          id: 'shared-note',
          npcId: 'mira-one',
          relationship: 'freundlich',
          note: 'Mira kennt die Schatzkarte.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
        NpcRelationshipNote(
          id: 'shared-note',
          npcId: 'tarek',
          relationship: 'neutral',
          note: 'Tarek bewacht das Stadttor.',
          recordedAt: DateTime.utc(2026, 10, 26),
        ),
      ],
    );
    final before = campaign.toJson().toString();

    expect(
      () => NpcIdentityStoryPayload.prepare(
        campaign,
        'Ich frage Mira und Tarek.',
      ),
      throwsFormatException,
    );
    // Unrelated NPC history is not transmitted just because its note ID
    // collides: selecting one named NPC still yields only that identity.
    final single = NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira.');
    expect(single, isNotNull);
    expect(single!.npcContexts, hasLength(1));
    expect(single.npcContexts.single['npcId'], 'mira-one');
    expect(campaign.toJson().toString(), before);
  });

  test('duplicate note IDs within one NPC are rejected', () {
    final original = _campaign();
    final campaign = original.copyWith(
      npcRelationshipNotes: [
        NpcRelationshipNote(
          id: 'repeated',
          npcId: 'mira-one',
          relationship: 'freundlich',
          note: 'Erste bestätigte Notiz.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
        NpcRelationshipNote(
          id: 'repeated',
          npcId: 'mira-one',
          relationship: 'freundlich',
          note: 'Zweite bestätigte Notiz.',
          recordedAt: DateTime.utc(2026, 10, 26),
        ),
      ],
    );
    expect(
      () => NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira.'),
      throwsFormatException,
    );
  });

  test('distinct note IDs across NPCs remain valid and revision-bound', () {
    final campaign = _campaign().copyWith(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
      ],
      npcRelationshipNotes: [
        NpcRelationshipNote(
          id: 'mira-note',
          npcId: 'mira-one',
          relationship: 'freundlich',
          note: 'Mira kennt die Karte.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
        NpcRelationshipNote(
          id: 'tarek-note',
          npcId: 'tarek',
          relationship: 'neutral',
          note: 'Tarek kennt den Weg.',
          recordedAt: DateTime.utc(2026, 10, 26),
        ),
      ],
    );
    final payload = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich frage Mira und Tarek.',
    );
    expect(payload, isNotNull);
    expect(payload!.npcContexts, hasLength(2));
    expect(payload.npcContexts.map((context) => context['npcId']).toList(), [
      'mira-one',
      'tarek',
    ]);
    payload.requireCurrent(campaign);
    expect(
      () => payload.requireCurrent(campaign.copyWith(revision: 8)),
      throwsFormatException,
    );
  });
}
