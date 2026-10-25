import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_narrator_memory.dart';

NpcRelationshipNote _note({
  required String id,
  required String npcId,
  required String value,
  required DateTime time,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'freundlich',
  note: value,
  recordedAt: time,
);

Campaign _campaign({
  List<NpcRelationshipNote> notes = const [],
  List<WorldNpc>? npcs,
}) => Campaign(
  id: 'npc-context',
  name: 'Würfelraunen',
  world: 'Valdorn',
  sessionId: 'second-session',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 13),
  scene: 'Mira verrät angeblich alle.',
  messages: [
    NarrativeMessage(
      id: 'unconfirmed',
      role: 'gm',
      text: 'Tarek hat dir 999 Gold gegeben.',
      timestamp: DateTime.utc(2026, 10, 25),
    ),
  ],
  npcs:
      npcs ??
      const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'tarek', name: 'Tarek'),
      ],
  npcRelationshipNotes: notes,
);

void main() {
  test('matching NPC receives newest confirmed note before general facts', () {
    final campaign = _campaign(
      notes: [
        _note(
          id: 'old',
          npcId: 'mira',
          value: 'Mira schenkte Aria eine Karte.',
          time: DateTime.utc(2026, 10, 21),
        ),
        _note(
          id: 'other',
          npcId: 'tarek',
          value: 'Tarek brachte die Kerze.',
          time: DateTime.utc(2026, 10, 24),
        ),
        _note(
          id: 'new',
          npcId: 'mira',
          value: 'Mira verweigerte den Zugang.',
          time: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    final saved = Campaign.fromJson(
      jsonDecode(jsonEncode(campaign.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(saved.toJson());
    final selected = NpcNarratorMemory.merge(
      saved,
      'Ich rede mit Mira über den Zugang.',
      ['Unwichtige Geschichte', 'Noch ein allgemeiner Fakt'],
      limit: 3,
      npcNoteLimit: 2,
    );

    expect(selected, hasLength(3));
    expect(selected.first, contains('Mira verweigerte'));
    expect(selected[1], contains('Mira schenkte'));
    expect(selected.last, 'Unwichtige Geschichte');
    expect(selected.join(' '), isNot(contains('Tarek brachte')));
    expect(selected.join(' '), isNot(contains('999 Gold')));
    expect(selected.join(' '), isNot(contains('verrät angeblich')));
    expect(jsonEncode(saved.toJson()), before);
    expect(() => selected.add('Erfundene Notiz'), throwsUnsupportedError);
  });

  test('no matching NPC does not inject unrelated NPC history', () {
    final campaign = _campaign(
      notes: [
        _note(
          id: 'note',
          npcId: 'mira',
          value: 'Mira zeigte den Brief.',
          time: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    expect(
      NpcNarratorMemory.merge(campaign, 'Ich gehe zum Tor.', ['Tor bestätigt']),
      ['Tor bestätigt'],
    );
    expect(NpcNarratorMemory.merge(campaign, 'Ich frage Mirabella.', ['Tor']), [
      'Tor',
    ]);
  });

  test('German names are matched at word boundaries, not as substrings', () {
    final campaign = _campaign(
      npcs: const [WorldNpc(id: 'keeper', name: 'Große Hüterin')],
      notes: [
        _note(
          id: 'history',
          npcId: 'keeper',
          value: 'Sie kennt den Brunnen.',
          time: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    expect(
      NpcNarratorMemory.merge(campaign, 'Die GROSSE HUETERIN spricht.', []),
      hasLength(1),
    );
    expect(
      NpcNarratorMemory.merge(campaign, 'Ein Hueterinnenhaus.', []),
      isEmpty,
    );
  });

  test('equal timestamps prefer latest recorded event and deduplicate', () {
    final time = DateTime.utc(2026, 10, 25);
    final campaign = _campaign(
      notes: [
        _note(
          id: 'a',
          npcId: 'mira',
          value: 'Mira zeigte die Brücke.',
          time: time,
        ),
        _note(
          id: 'b',
          npcId: 'mira',
          value: 'Mira bewachte den Turm.',
          time: time,
        ),
      ],
    );
    final selected = NpcNarratorMemory.merge(campaign, 'Ich besuche Mira.', [
      'Beziehung zu Mira: Mira bewachte den Turm.',
      'Historischer Fakt',
    ], npcNoteLimit: 2);
    expect(selected[0], contains('Turm'));
    expect(selected[1], contains('Brücke'));
    expect(selected, hasLength(3));
    expect(selected.last, 'Historischer Fakt');
  });

  test('unknown NPC notes and duplicated IDs never become context', () {
    final time = DateTime.utc(2026, 10, 25);
    final badNotes = [
      _note(
        id: 'wrong',
        npcId: 'ghost',
        value: 'Der Phantom-NPC erfindet eine Belohnung.',
        time: time,
      ),
      _note(
        id: 'same',
        npcId: 'mira',
        value: 'Unsichere Zuordnung.',
        time: time,
      ),
    ];
    final duplicate = _campaign(
      notes: badNotes,
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'mira', name: 'Mira'),
      ],
    );
    expect(NpcNarratorMemory.merge(duplicate, 'Mira und Ghost', []), isEmpty);
  });

  test('limits, line breaks and emoji are wire-safe', () {
    final campaign = _campaign(
      notes: [
        _note(
          id: 'long',
          npcId: 'mira',
          value: 'Langer Bericht:\n' + ('🐉' * 300),
          time: DateTime.utc(2026, 10, 25),
        ),
      ],
    );
    final selected = NpcNarratorMemory.merge(
      campaign,
      'Mira',
      List.filled(30, 'Allgemeiner Fakt'),
    );
    expect(selected.length, lessThanOrEqualTo(12));
    expect(selected.first.length, lessThanOrEqualTo(400));
    expect(selected.first, isNot(contains('\n')));
    expect(selected.first.endsWith('…'), isTrue);
    expect(selected.first.runes.any((rune) => rune >= 0xd800), isFalse);
    for (final limit in [0, 21]) {
      expect(
        () => NpcNarratorMemory.merge(campaign, 'Mira', [], limit: limit),
        throwsFormatException,
      );
    }
    expect(
      () => NpcNarratorMemory.merge(
        campaign,
        'Mira',
        [],
        limit: 2,
        npcNoteLimit: 3,
      ),
      throwsFormatException,
    );
  });

  test('missing note fields in old JSON keep general context unchanged', () {
    final legacy = _campaign().toJson()..remove('npcRelationshipNotes');
    final loaded = Campaign.fromJson(legacy);
    expect(NpcNarratorMemory.merge(loaded, 'Ich frage Mira.', ['Alter Fakt']), [
      'Alter Fakt',
    ]);
  });
}
