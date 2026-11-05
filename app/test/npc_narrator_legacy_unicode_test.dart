import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_narrator_memory.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  required List<WorldNpc> npcs,
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'npc-legacy-narrator-wire',
  name: 'Die Nebelstadt',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 13),
  scene: 'Unbestätigt: Mira behauptet, 999 Gold gefunden zu haben.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

NpcRelationshipNote _note(String id, String npcId, String value, {
  String relationship = 'freundlich',
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: relationship,
  note: value,
  recordedAt: DateTime.utc(2026, 11, 5),
);

void main() {
  sqfliteFfiInit();

  test('invisible legacy marks never select one of two visible Miras', () {
    const codePoints = [
      0x00ad,
      0x034f,
      0x180e,
      0x206a,
      0x206b,
      0x206c,
      0x206d,
      0x206e,
      0x206f,
    ];
    for (final point in codePoints) {
      final mark = String.fromCharCode(point);
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira-one', name: 'Mira'),
          WorldNpc(id: 'mira-two', name: 'Mi${mark}ra'),
        ],
        notes: [
          _note('one', 'mira-one', 'Nur die erste Mira kennt das Tor.'),
          _note('two', 'mira-two', 'Nur die zweite Mira kennt die Karte.'),
        ],
      );
      final original = jsonEncode(campaign.toJson());

      for (final action in ['Ich frage Mira.', 'Ich frage Mi${mark}ra.']) {
        final selected = NpcNarratorMemory.merge(
          campaign,
          action,
          ['Bestätigter Hafen'],
        );
        expect(selected, ['Bestätigter Hafen']);
        expect(selected.join(' '), isNot(contains('erste Mira')));
        expect(selected.join(' '), isNot(contains('zweite Mira')));
        expect(selected.join(' '), isNot(contains('999 Gold')));
      }
      expect(jsonEncode(campaign.toJson()), original);
    }
  });

  test('one unique NPC and general memories are sanitized for wire output', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(
          id: 'mira',
          name: 'Mi\u00adra',
          relationship: 'ver\u034ftraut',
        ),
      ],
      notes: [
        _note(
          'first',
          'mira',
          'Die\u180e Chronik\u206a liegt am Hafen.',
          relationship: 'freund\u206flich',
        ),
      ],
    );
    final original = jsonEncode(campaign.toJson());
    final memories = NpcNarratorMemory.merge(
      campaign,
      'Ich frage Mira nach der Chronik.',
      ['Das\u206d Tor bleibt verschlossen.'],
      limit: 2,
      npcNoteLimit: 1,
    );

    expect(memories, hasLength(2));
    expect(
      memories.first,
      startsWith('Bestätigte NPC-Beziehungsnotiz zu Mira (freund lich):'),
    );
    expect(memories.first, contains('Die Chronik liegt am Hafen.'));
    expect(memories.last, 'Das Tor bleibt verschlossen.');
    for (final point in [
      0x00ad,
      0x034f,
      0x180e,
      0x206a,
      0x206d,
      0x206f,
    ]) {
      expect(memories.join(' ').runes, isNot(contains(point)));
    }
    expect(memories.every((line) => line.length <= 400), isTrue);
    expect(() => memories.add('Erfundene Notiz'), throwsUnsupportedError);
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('ordinary German names and limits remain compatible', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'elin', name: 'Älin ✨'),
        WorldNpc(id: 'mira', name: 'Mira'),
      ],
      notes: [
        _note('elin-note', 'elin', 'Älin kennt die Karte.'),
        _note('mira-note', 'mira', 'Mira kennt den Turm.'),
      ],
    );
    final chosen = NpcNarratorMemory.merge(
      campaign,
      'Ich frage Älin ✨ nach der Karte.',
      ['Ein allgemeiner Fakt.'],
      limit: 2,
      npcNoteLimit: 1,
    );
    expect(chosen, hasLength(2));
    expect(chosen.first, contains('Älin ✨'));
    expect(chosen.first, contains('Älin kennt die Karte.'));
    expect(chosen.join(' '), isNot(contains('Mira kennt den Turm')));
    expect(chosen.last, 'Ein allgemeiner Fakt.');

    expect(
      NpcNarratorMemory.merge(
        campaign,
        'Ich frage Mirabella nach dem Turm.',
        [],
      ),
      isEmpty,
    );
    expect(
      () => NpcNarratorMemory.merge(campaign, 'Mira', [], limit: 0),
      throwsFormatException,
    );
    expect(
      () => NpcNarratorMemory.merge(
        campaign,
        'Mira',
        [],
        limit: 1,
        npcNoteLimit: 2,
      ),
      throwsFormatException,
    );
  });

  test('JSON and SQLite restart preserve raw legacy text and rule state', () async {
    final original = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mi\u00adra', relationship: 'neutral'),
      ],
      notes: [
        _note('one', 'mira', 'Der\u206c Schlüssel liegt am Kai.'),
      ],
    );
    final roundTrip = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('npc-wire-legacy-');
    final file = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: file,
    );
    try {
      await repository.saveCampaign(roundTrip);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: file,
      );
      final loaded = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(loaded.toJson());
      final memories = NpcNarratorMemory.merge(
        loaded,
        'Ich rede mit Mira.',
        ['Bekannter\u00ad Hafen.'],
        limit: 2,
        npcNoteLimit: 1,
      );

      expect(memories, hasLength(2));
      expect(memories.first, contains('Der Schlüssel liegt am Kai.'));
      expect(memories.last, 'Bekannter Hafen.');
      expect(memories.join(' '), isNot(contains('\u206c')));
      expect(memories.join(' '), isNot(contains('\u00ad')));
      expect(loaded.npcs.single.name, 'Mi\u00adra');
      expect(loaded.npcRelationshipNotes.single.note, contains('\u206c'));
      expect(loaded.hero.toJson(), original.hero.toJson());
      expect(loaded.revision, original.revision);
      expect(jsonEncode(loaded.toJson()), before);
      expect(
        (await repository.reconstructCampaign(original.id))!.toJson(),
        loaded.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
