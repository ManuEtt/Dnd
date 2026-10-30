import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_continuity_reader.dart';

Campaign _campaign({
  required List<WorldNpc> npcs,
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'confirmed-npc-context',
  name: 'Testkampagne',
  world: 'Valdorn',
  sessionId: 'session-1',
  hero: HeroCharacter(id: 'hero-1', name: 'Aria'),
  scene: 'Der Brunnen vor dem Dorf.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  test('confirmed NPC text removes invisible controls but retains facts', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(
          id: 'mira',
          name: 'Mira\u202e',
          relationship: 'freundlich\u2069',
        ),
      ],
      notes: [
        NpcRelationshipNote(
          id: 'note-1',
          npcId: 'mira',
          relationship: 'vorsichtig\u2066',
          note: 'Bestätigt\u0000\u001b\u007f\u0085\u2028\u202e\u2069 und gespeichert.',
          recordedAt: DateTime.utc(2026, 10, 30, 5),
        ),
      ],
    );
    final original = campaign.toJson();
    final context =
        NpcContinuityReader.read(campaign, npcId: 'mira').confirmedContext;

    expect(context.split('\n'), hasLength(4));
    expect(context, startsWith('NPC: Mira\nStatus: lebendig\n'));
    expect(context, contains('Aktuelle Beziehung: freundlich'));
    expect(context, contains('(vorsichtig): Bestätigt'));
    expect(context, contains('und gespeichert.'));
    for (final codePoint in [
      0x00,
      0x1b,
      0x7f,
      0x85,
      0x2028,
      0x202e,
      0x2066,
      0x2069,
    ]) {
      expect(context.runes, isNot(contains(codePoint)));
    }
    expect(campaign.toJson(), original);
  });

  test('bidi formatting cannot hide duplicate displayed NPC names', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira'),
        WorldNpc(id: 'mira-two', name: 'Mira\u202e'),
      ],
    );

    final first = NpcContinuityReader.read(campaign, npcId: 'mira-one');
    final second = NpcContinuityReader.read(campaign, npcId: 'mira-two');
    expect(first.disambiguateName, isTrue);
    expect(second.disambiguateName, isTrue);
    expect(first.confirmedContext, contains('NPC: Mira (NPC-ID: mira-one)'));
    expect(second.confirmedContext, contains('NPC: Mira (NPC-ID: mira-two)'));
    expect(first.confirmedContext, isNot(contains('mira-two')));
  });

  test('unsafe duplicate NPC identity is still rejected', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'bad id', name: 'Mira\u202e'),
        WorldNpc(id: 'mira-two', name: 'Mira'),
      ],
    );
    expect(
      () => NpcContinuityReader.read(campaign, npcId: 'bad id'),
      throwsFormatException,
    );
  });

  test('ordinary German names and legacy notes stay readable', () {
    final old = Campaign.fromJson(
      _campaign(
        npcs: const [
          WorldNpc(
            id: 'elin',
            name: 'Älin – Hüterin',
            relationship: 'wohlgesinnt',
          ),
        ],
      ).toJson(),
    );
    final snapshot = NpcContinuityReader.read(old, npcId: 'elin');

    expect(snapshot.confirmedContext, contains('Älin – Hüterin'));
    expect(snapshot.confirmedContext, contains('Keine bestätigten'));
    expect(snapshot.disambiguateName, isFalse);
    expect(old.hero.name, 'Aria');
  });
}
