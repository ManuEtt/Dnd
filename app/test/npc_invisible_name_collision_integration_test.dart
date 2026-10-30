import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_continuity_reader.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_narrator_memory.dart';

Campaign _campaign(String secondName) => Campaign(
  id: 'npc-name-collision',
  name: 'Hafen',
  world: 'Valdorn',
  sessionId: 'session',
  hero: HeroCharacter(id: 'hero', name: 'Aria'),
  scene: 'Der Kai.',
  npcs: [
    const WorldNpc(id: 'mira-one', name: 'Mira'),
    WorldNpc(id: 'mira-two', name: secondName),
  ],
  npcRelationshipNotes: [
    for (final id in ['mira-one', 'mira-two'])
      NpcRelationshipNote(
        id: 'note-$id',
        npcId: id,
        relationship: 'freundlich',
        note: '$id kennt einen anderen Weg.',
        recordedAt: DateTime.utc(2026, 10, 30),
      ),
  ],
);

void main() {
  for (final marker in [
    '\u061c',
    '\u200e',
    '\u200f',
    '\u202a',
    '\u202b',
    '\u202c',
    '\u202d',
    '\u202e',
    '\u2066',
    '\u2067',
    '\u2068',
    '\u2069',
  ]) {
    test(
      'all NPC projections retain ambiguity for U+${marker.codeUnitAt(0).toRadixString(16)} inside a name',
      () {
        final campaign = _campaign('Mi${marker}ra');
        final before = campaign.toJson();

        for (final action in ['Ich frage Mira.', 'Ich frage Mi${marker}ra.']) {
          expect(NpcNarratorMemory.merge(campaign, action, []), isEmpty);
          expect(NpcIdentityStoryPayload.prepare(campaign, action), isNull);
        }
        for (final id in ['mira-one', 'mira-two']) {
          final explicit = NpcContinuityReader.read(campaign, npcId: id);
          expect(explicit.disambiguateName, isTrue);
          expect(explicit.confirmedContext, contains('(NPC-ID: $id)'));
          expect(explicit.confirmedContext, isNot(contains(marker)));
        }
        expect(campaign.toJson(), before);
      },
    );
  }

  test('actual spaces remain meaningful name characters', () {
    final campaign = _campaign('Mi ra');
    final context = NpcContinuityReader.read(campaign, npcId: 'mira-one');
    expect(context.disambiguateName, isFalse);
    final memory = NpcNarratorMemory.merge(campaign, 'Ich frage Mira.', []);
    expect(memory, hasLength(1));
    expect(memory.single, contains('mira-one kennt einen anderen Weg.'));
    expect(memory.single, isNot(contains('mira-two')));
  });
}
