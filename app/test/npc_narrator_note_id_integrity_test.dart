import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_narrator_memory.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _now = DateTime.utc(2026, 11, 6, 11);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String value, {
  int hoursAgo = 0,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'freundlich',
  note: value,
  recordedAt: _now.subtract(Duration(hours: hoursAgo)),
);

Campaign _campaign({
  List<WorldNpc> npcs = const [
    WorldNpc(id: 'mira', name: 'Mira'),
    WorldNpc(id: 'tarek', name: 'Tarek'),
  ],
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'npc-note-identity',
  name: 'Die Chronik von Valdorn',
  world: 'Valdorn',
  sessionId: 'session-two',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Die Heldin erhält 9999 Gold.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('duplicate IDs within one NPC never authorize contradictory notes', () {
    final campaign = _campaign(
      notes: [
        _note('collision', 'mira', 'Erfundene Belohnung bestätigt.'),
        _note('collision', 'mira', 'Der Schlüssel wurde zerstört.'),
        _note('safe', 'mira', 'Mira bewahrt den Brief.', hoursAgo: 1),
      ],
    );
    final original = jsonEncode(campaign.toJson());
    final selected = NpcNarratorMemory.merge(
      campaign,
      'Ich frage Mira nach dem Brief.',
      ['Das Hafentor ist verschlossen.'],
      limit: 3,
      npcNoteLimit: 2,
    );

    expect(selected, hasLength(2));
    expect(selected.first, contains('Mira bewahrt den Brief.'));
    expect(selected.last, 'Das Hafentor ist verschlossen.');
    expect(selected.join(' '), isNot(contains('Erfundene Belohnung')));
    expect(selected.join(' '), isNot(contains('Schlüssel wurde zerstört')));
    expect(selected.join(' '), isNot(contains('9999 Gold')));
    expect(() => selected.add('Erfunden'), throwsUnsupportedError);
    expect(
      () => Campaign.fromJson(jsonDecode(original) as Map<String, dynamic>),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('duplicate note ID across NPCs is excluded before ranking', () {
    final campaign = _campaign(
      notes: [
        _note('shared', 'mira', 'Mira behauptet ein altes Siegel.'),
        _note('shared', 'tarek', 'Tarek widerspricht ihr.'),
        _note('mira-safe', 'mira', 'Mira kennt den Brunnen.', hoursAgo: 1),
        _note('tarek-safe', 'tarek', 'Tarek kennt den Hafen.', hoursAgo: 2),
      ],
    );
    final selected = NpcNarratorMemory.merge(
      campaign,
      'Ich frage Mira und Tarek.',
      ['Ein allgemeiner bestätigter Ort.'],
      limit: 3,
      npcNoteLimit: 2,
    );

    expect(selected, hasLength(3));
    expect(selected.first, contains('Mira kennt den Brunnen.'));
    expect(selected[1], contains('Tarek kennt den Hafen.'));
    expect(selected.last, 'Ein allgemeiner bestätigter Ort.');
    expect(selected.join(' '), isNot(contains('altes Siegel')));
    expect(selected.join(' '), isNot(contains('widerspricht ihr')));
  });

  test('unsafe legacy note and NPC IDs are never promoted to memory', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'unsafe npc', name: 'Sera'),
        WorldNpc(id: 'newline\n', name: 'Sela'),
      ],
      notes: [
        _note('bad id', 'mira', 'Falsche Goldbelohnung.'),
        _note('linebreak\n', 'mira', 'Trügerisches Zeilenende.'),
        _note('hidden\u202e', 'mira', 'Täuschung durch Bidi.'),
        _note('über', 'mira', 'Ungültige Unicode-ID.'),
        _note(List.filled(65, 'x').join(), 'mira', 'Zu lange ID.'),
        _note('safe-for-unsafe', 'unsafe npc', 'Sera kennt ein Geheimnis.'),
        _note('safe-for-newline', 'newline\n', 'Sela kennt den Tempel.'),
        _note('safe-1', 'mira', 'Mira besitzt die Karte.', hoursAgo: 3),
      ],
    );
    final rawJson = jsonEncode(campaign.toJson());
    final loaded = Campaign.fromJson(
      jsonDecode(rawJson) as Map<String, dynamic>,
    );
    final selected = NpcNarratorMemory.merge(
      loaded,
      'Ich spreche mit Mira, Sera und Sela.',
      ['Das Stadttor ist offen.'],
      limit: 3,
      npcNoteLimit: 2,
    );

    expect(selected, hasLength(2));
    expect(selected.first, contains('Mira besitzt die Karte.'));
    expect(selected.last, 'Das Stadttor ist offen.');
    for (final forbidden in [
      'Goldbelohnung',
      'Bidi',
      'Unicode-ID',
      'Zu lange ID',
      'Sera kennt ein Geheimnis',
      'Sela kennt den Tempel',
      'Trügerisches Zeilenende',
      '9999 Gold',
    ]) {
      expect(selected.join(' '), isNot(contains(forbidden)));
    }
    expect(selected.every((entry) => entry.length <= 400), isTrue);
    expect(jsonEncode(loaded.toJson()), rawJson);
    expect(loaded.hero.hitPoints, 17);
  });

  test('SQLite restart retains raw notes and safe memories', () async {
    final folder = await Directory.systemTemp.createTemp('npc-note-ids-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = _campaign(
        notes: [
          _note('bad id', 'mira', 'Unbestätigte Schatzkammer.'),
          _note('safe', 'mira', 'Mira fand das Archiv.', hoursAgo: 1),
          _note('other', 'tarek', 'Tarek bewacht den Eingang.', hoursAgo: 2),
        ],
      );
      final rawJson = jsonEncode(campaign.toJson());
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(campaign.id))!;
      final before = jsonEncode(restored.toJson());
      final memories = NpcNarratorMemory.merge(
        restored,
        'Ich frage Mira.',
        ['Bekannter Weg über die Brücke.'],
        limit: 2,
        npcNoteLimit: 1,
      );

      expect(memories, hasLength(2));
      expect(memories.first, contains('Mira fand das Archiv.'));
      expect(memories.last, 'Bekannter Weg über die Brücke.');
      expect(memories.join(' '), isNot(contains('Schatzkammer')));
      expect(memories.join(' '), isNot(contains('bewacht den Eingang')));
      expect(restored.npcRelationshipNotes.first.id, 'bad id');
      expect(restored.hero.toJson(), campaign.hero.toJson());
      expect(restored.revision, campaign.revision);
      expect(jsonEncode(restored.toJson()), rawJson);
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(campaign.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
