import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';

Campaign _campaign({
  String id = 'campaign-one',
  int revision = 8,
  List<WorldNpc>? npcs,
  List<NpcRelationshipNote>? notes,
}) => Campaign(
  id: id,
  name: 'Die zwei Miras',
  world: 'Valdorn',
  sessionId: 'second-session',
  hero: HeroCharacter(id: 'aria', name: 'Aria'),
  scene: 'Der Marktplatz',
  revision: revision,
  npcs:
      npcs ??
      const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-two', name: 'MIRA', relationship: 'misstrauisch'),
      ],
  npcRelationshipNotes:
      notes ??
      [
        NpcRelationshipNote(
          id: 'note-first',
          npcId: 'mira-one',
          relationship: 'freundlich',
          note: 'Die erste Mira besitzt die alte Karte.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
        NpcRelationshipNote(
          id: 'note-second',
          npcId: 'mira-two',
          relationship: 'misstrauisch',
          note: 'Die zweite Mira bewacht das Stadttor.',
          recordedAt: DateTime.utc(2026, 10, 26),
        ),
      ],
);

void main() {
  test('explicit saved ID disambiguates two NPCs with identical names', () {
    final campaign = _campaign();
    final unchanged = jsonEncode(campaign.toJson());
    expect(
      NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira nach dem Weg.'),
      isNull,
    );

    final first = NpcStorySelection.choose(campaign, 'mira-one');
    final firstPayload = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich frage Mira nach dem Weg.',
      selectedNpc: first,
    );
    expect(firstPayload, isNotNull);
    expect(firstPayload!.npcContexts, hasLength(1));
    expect(firstPayload.selectedNpcId, 'mira-one');
    expect(firstPayload.npcContexts.single['npcId'], 'mira-one');
    expect(firstPayload.npcContexts.toString(), contains('alte Karte'));
    expect(firstPayload.npcContexts.toString(), isNot(contains('Stadttor')));

    final second = NpcStorySelection.choose(campaign, 'mira-two');
    final secondPayload = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich frage Mira nach dem Weg.',
      selectedNpc: second,
    );
    expect(secondPayload, isNotNull);
    expect(secondPayload!.npcContexts.single['npcId'], 'mira-two');
    expect(secondPayload.selectedNpcId, 'mira-two');
    expect(secondPayload.npcContexts.toString(), contains('Stadttor'));
    expect(secondPayload.npcContexts.toString(), isNot(contains('alte Karte')));
    firstPayload.requireCurrent(campaign);
    secondPayload.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), unchanged);
  });

  test(
    'explicit identity is sufficient without guessing from player prose',
    () {
      final campaign = _campaign();
      final choice = NpcStorySelection.choose(campaign, 'mira-two');
      final payload = NpcIdentityStoryPayload.prepare(
        campaign,
        'Ich möchte die Karte untersuchen.',
        selectedNpc: choice,
      );
      expect(payload!.npcContexts.single['npcId'], 'mira-two');
      expect(
        NpcIdentityStoryPayload.prepare(
          campaign,
          'Ich möchte die Karte untersuchen.',
        ),
        isNull,
      );
    },
  );

  test('stale revision and foreign campaign reject a selected identity', () {
    final campaign = _campaign();
    final choice = NpcStorySelection.choose(campaign, 'mira-one');
    for (final changed in [
      campaign.copyWith(revision: 9),
      _campaign(id: 'other-campaign'),
    ]) {
      expect(() => choice.requireCurrent(changed), throwsFormatException);
      expect(
        () => NpcIdentityStoryPayload.prepare(
          changed,
          'Ich spreche Mira an.',
          selectedNpc: choice,
        ),
        throwsFormatException,
      );
    }
  });

  test('renamed or replaced NPC at same revision cannot inherit selection', () {
    final campaign = _campaign();
    final choice = NpcStorySelection.choose(campaign, 'mira-one');
    final changed = campaign.copyWith(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'feindlich'),
        WorldNpc(id: 'mira-two', name: 'MIRA'),
      ],
    );
    expect(() => choice.requireCurrent(changed), throwsFormatException);
    final missing = campaign.copyWith(
      npcs: const [WorldNpc(id: 'mira-two', name: 'MIRA')],
    );
    expect(() => choice.requireCurrent(missing), throwsFormatException);
    final duplicated = campaign.copyWith(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira'),
        WorldNpc(id: 'mira-one', name: 'Mira'),
      ],
    );
    expect(
      () => NpcStorySelection.choose(duplicated, 'mira-one'),
      throwsFormatException,
    );
  });

  test('invalid or missing selected IDs never fall back to another NPC', () {
    final campaign = _campaign();
    for (final id in ['', 'unknown', ' mira-one', 'mira-one ']) {
      expect(
        () => NpcStorySelection.choose(campaign, id),
        throwsFormatException,
      );
    }
    final choice = NpcStorySelection.choose(campaign, 'mira-one');
    final onlyOtherNote = campaign.copyWith(
      npcRelationshipNotes: [campaign.npcRelationshipNotes.last],
    );
    expect(
      NpcIdentityStoryPayload.prepare(
        onlyOtherNote,
        'Ich spreche Mira an.',
        selectedNpc: choice,
      ),
      isNull,
    );
  });

  test('selection and sent payload reject in-place note edits', () {
    final campaign = _campaign();
    final selected = NpcStorySelection.choose(campaign, 'mira-one');
    final prepared = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich frage Mira.',
      selectedNpc: selected,
    )!;
    final amended = campaign.copyWith(
      npcRelationshipNotes: [
        NpcRelationshipNote(
          id: 'note-first',
          npcId: 'mira-one',
          relationship: 'freundlich',
          note: 'Ein anderer ungeprüfter Verlauf.',
          recordedAt: DateTime.utc(2026, 10, 25),
        ),
        campaign.npcRelationshipNotes.last,
      ],
    );
    selected.requireCurrent(amended);
    expect(() => prepared.requireCurrent(amended), throwsFormatException);
    final revived = Campaign.fromJson(
      jsonDecode(jsonEncode(campaign.toJson())) as Map<String, dynamic>,
    );
    selected.requireCurrent(revived);
    prepared.requireCurrent(revived);
  });
}
