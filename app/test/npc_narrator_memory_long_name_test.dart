import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_narrator_memory.dart';

String _longName(String ending) => 'Hüterin ${'A' * 380} $ending';

NpcRelationshipNote _note({
  required String id,
  required String npcId,
  required String text,
  required int day,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'freundlich',
  note: text,
  recordedAt: DateTime.utc(2026, 10, day),
);

Campaign _campaign(
  List<WorldNpc> npcs,
  List<NpcRelationshipNote> notes,
) => Campaign(
  id: 'npc-long-wire',
  name: 'Zwei Hüterinnen',
  world: 'Valdorn',
  sessionId: 'memory-session',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 12),
  scene: 'Nur unbestätigte Erzählung.',
  revision: 4,
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  test('long distinct NPC names use saved IDs and survive JSON restore', () {
    final firstName = _longName('Nord');
    final secondName = _longName('Süd');
    final original = _campaign(
      [
        WorldNpc(id: 'keeper-north', name: firstName),
        WorldNpc(id: 'keeper-south', name: secondName),
      ],
      [
        _note(
          id: 'north-note',
          npcId: 'keeper-north',
          text: 'Die nördliche Hüterin kennt das Siegel.',
          day: 27,
        ),
        _note(
          id: 'south-note',
          npcId: 'keeper-south',
          text: 'Die südliche Hüterin kennt das Tor.',
          day: 28,
        ),
      ],
    );
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());

    final result = NpcNarratorMemory.merge(
      restored,
      'Ich frage $firstName und $secondName.',
      [],
      npcNoteLimit: 2,
    );

    expect(result, hasLength(2));
    expect(result[0], contains('(NPC-ID: keeper-south)'));
    expect(result[0], contains('kennt das Tor'));
    expect(result[1], contains('(NPC-ID: keeper-north)'));
    expect(result[1], contains('kennt das Siegel'));
    expect(result.every((item) => item.length <= 400), isTrue);
    expect(result.join(' '), isNot(contains('Hüterin ${'A' * 40}')));
    expect(jsonEncode(restored.toJson()), before);
    expect(restored.hero.hitPoints, 12);
    expect(() => result.add('Fremde Erinnerung'), throwsUnsupportedError);
  });

  test('unsafe fallback ID is omitted and does not consume NPC note quota', () {
    final unsafeName = _longName('Gefahr');
    final campaign = _campaign(
      [
        WorldNpc(id: 'untrusted\nid', name: unsafeName),
        const WorldNpc(id: 'mira', name: 'Mira'),
      ],
      [
        _note(
          id: 'bad',
          npcId: 'untrusted\nid',
          text: 'Diese Notiz darf nicht falsch zugeordnet werden.',
          day: 28,
        ),
        _note(
          id: 'valid',
          npcId: 'mira',
          text: 'Mira kennt die Stadtmauer.',
          day: 27,
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());

    final result = NpcNarratorMemory.merge(
      campaign,
      'Ich frage $unsafeName und Mira.',
      ['Bestätigter allgemeiner Hinweis'],
      npcNoteLimit: 1,
    );

    expect(result, hasLength(2));
    expect(result.first, contains('Mira kennt die Stadtmauer'));
    expect(result.last, 'Bestätigter allgemeiner Hinweis');
    expect(result.join(' '), isNot(contains('Diese Notiz')));
    expect(result.join(' '), isNot(contains('untrusted')));
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('ambiguous long names never select one NPC from free prose', () {
    final sameName = _longName('Nord');
    final campaign = _campaign(
      [
        WorldNpc(id: 'first', name: sameName),
        WorldNpc(id: 'second', name: sameName.toUpperCase()),
      ],
      [
        _note(
          id: 'first-note',
          npcId: 'first',
          text: 'Nur die erste Figur kennt den Brief.',
          day: 28,
        ),
        _note(
          id: 'second-note',
          npcId: 'second',
          text: 'Nur die zweite Figur kennt die Truhe.',
          day: 27,
        ),
      ],
    );
    final result = NpcNarratorMemory.merge(
      campaign,
      'Ich spreche mit $sameName.',
      ['Allgemein bekannter Ort'],
    );
    expect(result, ['Allgemein bekannter Ort']);
  });

  test('normal names retain the old narrator format', () {
    final campaign = _campaign(
      [const WorldNpc(id: 'mira', name: 'Mira')],
      [
        _note(
          id: 'short',
          npcId: 'mira',
          text: 'Mira führt die Gruppe.',
          day: 28,
        ),
      ],
    );
    expect(
      NpcNarratorMemory.merge(campaign, 'Mira', []).single,
      'Bestätigte NPC-Beziehungsnotiz zu Mira (freundlich): '
      'Mira führt die Gruppe.',
    );
    expect(
      NpcNarratorMemory.merge(campaign, 'Mira', [], npcNoteLimit: 0),
      isEmpty,
    );
  });
}
