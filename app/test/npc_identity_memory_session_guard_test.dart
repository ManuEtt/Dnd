import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_memory.dart';

Campaign _campaign({String sessionId = 'first-session', bool withNotes = true}) =>
    Campaign(
      id: 'campaign-identity',
      name: 'Die zwei Miras',
      world: 'Valdorn',
      sessionId: sessionId,
      hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 12),
      scene: 'Zwei Figuren warten am Stadttor.',
      revision: 9,
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-two', name: 'MIRA', relationship: 'misstrauisch'),
      ],
      npcRelationshipNotes: withNotes
          ? [
              NpcRelationshipNote(
                id: 'note-one',
                npcId: 'mira-one',
                relationship: 'freundlich',
                note: 'Die erste Mira besitzt die Seekarte.',
                recordedAt: DateTime.utc(2026, 10, 28),
              ),
              NpcRelationshipNote(
                id: 'note-two',
                npcId: 'mira-two',
                relationship: 'misstrauisch',
                note: 'Die zweite Mira bewacht das Tor.',
                recordedAt: DateTime.utc(2026, 10, 29),
              ),
            ]
          : const [],
    );

NpcIdentityContext _snapshot(Campaign campaign) => NpcIdentityMemory.read(
  campaign,
  npcId: 'mira-one',
  expectedRevision: campaign.revision,
);

void main() {
  test('JSON restored snapshot remains valid within the same session', () {
    final original = _campaign();
    final snapshot = _snapshot(original);
    final before = jsonEncode(original.toJson());
    final recovered = Campaign.fromJson(
      jsonDecode(before) as Map<String, dynamic>,
    );

    NpcIdentityMemory.requireCurrent(recovered, snapshot);
    final current = _snapshot(recovered);
    expect(current.sessionId, 'first-session');
    expect(current.npcId, 'mira-one');
    expect(current.notes.single.note, contains('Seekarte'));
    expect(current.toContextMap().toString(), isNot(contains('bewacht das Tor')));
    expect(current.toContextMap(), snapshot.toContextMap());
    expect(current.toContextMap().containsKey('sessionId'), isFalse);
    expect(jsonEncode(recovered.toJson()), before);
    expect(recovered.hero.toJson(), original.hero.toJson());
  });

  test('other session rejects unchanged NPC and revision without mutation', () {
    final original = _campaign();
    final snapshot = _snapshot(original);
    final shifted = Campaign.fromJson({
      ...original.toJson(),
      'sessionId': 'later-session',
    });
    final before = jsonEncode(shifted.toJson());

    expect(shifted.id, original.id);
    expect(shifted.revision, original.revision);
    expect(shifted.npcs.first.toJson(), original.npcs.first.toJson());
    expect(_snapshot(shifted).toContextMap(), snapshot.toContextMap());
    expect(
      () => NpcIdentityMemory.requireCurrent(shifted, snapshot),
      throwsFormatException,
    );
    final renewed = _snapshot(shifted);
    NpcIdentityMemory.requireCurrent(shifted, renewed);
    expect(renewed.sessionId, 'later-session');
    expect(jsonEncode(shifted.toJson()), before);
    expect(shifted.hero.toJson(), original.hero.toJson());
  });

  test('legacy empty-note snapshot also rejects cross-session reuse', () {
    final original = _campaign(withNotes: false);
    final legacyJson = original.toJson()..remove('npcRelationshipNotes');
    final legacy = Campaign.fromJson(legacyJson);
    final snapshot = _snapshot(legacy);
    expect(snapshot.notes, isEmpty);
    NpcIdentityMemory.requireCurrent(legacy, snapshot);

    final foreign = Campaign.fromJson({
      ...legacy.toJson(),
      'sessionId': 'different-session',
    });
    final before = jsonEncode(foreign.toJson());
    expect(
      () => NpcIdentityMemory.requireCurrent(foreign, snapshot),
      throwsFormatException,
    );
    expect(_snapshot(foreign).notes, isEmpty);
    expect(jsonEncode(foreign.toJson()), before);
  });

  test('unrelated NPC changes do not invalidate selected identity', () {
    final original = _campaign();
    final snapshot = _snapshot(original);
    final modified = original.copyWith(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-two', name: 'MIRA', relationship: 'feindlich'),
      ],
    );
    final before = jsonEncode(modified.toJson());
    NpcIdentityMemory.requireCurrent(modified, snapshot);
    expect(jsonEncode(modified.toJson()), before);
    expect(modified.hero.toJson(), original.hero.toJson());
  });
}
