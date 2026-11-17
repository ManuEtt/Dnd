import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_note_history_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _at = DateTime.utc(2026, 11, 10, 14, 30);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String relationship,
  String note, {
  DateTime? at,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: relationship,
  note: note,
  recordedAt: at ?? _at,
);

Campaign _campaign({
  String id = 'npc-note-history',
  String sessionId = 'session-two',
  int revision = 5,
  List<WorldNpc> npcs = const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'neutral'),
    WorldNpc(id: 'tarek', name: 'Tarek'),
  ],
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: id,
  name: 'Das Hafenarchiv',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Die KI behauptet unbestätigt 999 Gold.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

bool _validUtf16(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      i++;
      if (i >= text.length) return false;
      if (text.codeUnitAt(i) < 0xdc00 || text.codeUnitAt(i) > 0xdfff) {
        return false;
      }
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      return false;
    }
  }
  return true;
}

void main() {
  sqfliteFfiInit();

  test('old relationship note is selectable beyond recent notes', () {
    final campaign = _campaign(
      notes: [
        _note('old', 'mira', 'vertraut', 'Mira bewahrte die Karte auf.'),
        for (var i = 0; i < 26; i++)
          _note(
            'recent-$i',
            'mira',
            'neutral',
            'Neuer Eintrag $i',
            at: _at.add(Duration(days: i + 1)),
          ),
        _note('foreign', 'tarek', 'vorsichtig', 'Andere Erinnerung.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selection = ConfirmedNpcNoteHistorySelector.readSelected(
      campaign,
      expectedRevision: 5,
      noteId: 'old',
    );

    expect(selection.noteId, 'old');
    expect(selection.npcId, 'mira');
    expect(selection.relationship, 'vertraut');
    expect(selection.recordedAt, _at);
    expect(selection.playerOverview, contains('Mira bewahrte die Karte auf.'));
    expect(selection.playerOverview, contains('Notizdatum:'));
    expect(selection.playerOverview, contains('NPC-ID: mira'));
    expect(selection.playerOverview, contains('Kein Nachweis für den aktuellen'));
    expect(selection.playerOverview, isNot(contains('999 Gold')));
    expect(selection.playerOverview, isNot(contains('Andere Erinnerung')));
    expect(selection.playerOverview, isNot(contains('Neuer Eintrag')));
    selection.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 17);
  });

  test('invalid IDs and cross-NPC duplicate note IDs fail closed', () {
    final campaign = _campaign(
      notes: [_note('old', 'mira', 'vertraut', 'Gespeicherte Notiz.')],
    );
    for (final badId in [
      '',
      'old\n',
      'old\r',
      'old\r\n',
      'old\u2028',
      'old\u200b',
      'bad id',
      List.filled(65, 'x').join(),
      'missing',
    ]) {
      expect(
        () => ConfirmedNpcNoteHistorySelector.readSelected(
          campaign,
          expectedRevision: 5,
          noteId: badId,
        ),
        throwsFormatException,
      );
    }
    final duplicate = _campaign(
      notes: [
        _note('old', 'mira', 'neutral', 'Erste Aussage.'),
        _note('old', 'tarek', 'neutral', 'Widersprüchliche Aussage.'),
      ],
    );
    expect(
      () => ConfirmedNpcNoteHistorySelector.readSelected(
        duplicate,
        expectedRevision: 5,
        noteId: 'old',
      ),
      throwsFormatException,
    );
    expect(duplicate.npcRelationshipNotes, hasLength(2));
  });

  test('missing or ambiguous NPC and invalid session fail closed', () {
    final selectedNote = _note(
      'old',
      'mira',
      'bekannt',
      'Gespeicherte Notiz.',
    );
    for (final npcs in [
      <WorldNpc>[],
      <WorldNpc>[
        const WorldNpc(id: 'mira', name: 'Mira'),
        const WorldNpc(id: 'mira', name: 'Andere Mira'),
      ],
      <WorldNpc>[const WorldNpc(id: 'mira', name: '\u200b')],
    ]) {
      expect(
        () => ConfirmedNpcNoteHistorySelector.readSelected(
          _campaign(npcs: npcs, notes: [selectedNote]),
          expectedRevision: 5,
          noteId: 'old',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedNpcNoteHistorySelector.readSelected(
        _campaign(
          notes: [_note('old', 'mira\n', 'bekannt', 'Gefälschter NPC.')],
        ),
        expectedRevision: 5,
        noteId: 'old',
      ),
      throwsFormatException,
    );
    for (final revision in [-1, 4, 2147483648]) {
      expect(
        () => ConfirmedNpcNoteHistorySelector.readSelected(
          _campaign(notes: [selectedNote]),
          expectedRevision: revision,
          noteId: 'old',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedNpcNoteHistorySelector.readSelected(
        _campaign(sessionId: ' ', notes: [selectedNote]),
        expectedRevision: 5,
        noteId: 'old',
      ),
      throwsFormatException,
    );
  });

  test('unicode control marks and long emoji stay line-safe', () {
    final dragons = List.filled(350, '🐉').join();
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mi\u200bra\nStatus: tot\u202e'),
      ],
      notes: [
        _note(
          'old',
          'mira',
          'vertrau\u206at',
          'Hinweis:\n$dragons\u202e Aktueller Status: tot',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final chosen = ConfirmedNpcNoteHistorySelector.readSelected(
      campaign,
      expectedRevision: 5,
      noteId: 'old',
    );
    final overview = chosen.playerOverview;

    expect(overview.split('\n'), hasLength(6));
    expect(overview, contains('Mira Status: tot'));
    expect(overview, contains('Damals gespeicherte Beziehung:'));
    expect(overview, contains('…'));
    expect(overview, isNot(contains('\u200b')));
    expect(overview, isNot(contains('\u206a')));
    expect(overview, isNot(contains('\u202e')));
    expect(overview.length, lessThanOrEqualTo(1000));
    expect(_validUtf16(overview), isTrue);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('same-revision hidden and foreign edits invalidate selection', () {
    final text = List.filled(490, 'A').join();
    final campaign = _campaign(
      notes: [
        _note('old', 'mira', 'bekannt', text),
        _note('other', 'tarek', 'neutral', 'Andere Notiz.'),
      ],
    );
    final original = jsonEncode(campaign.toJson());
    final chosen = ConfirmedNpcNoteHistorySelector.readSelected(
      campaign,
      expectedRevision: 5,
      noteId: 'old',
    );
    chosen.requireCurrent(campaign);

    final changedOld = campaign.copyWith(
      npcRelationshipNotes: [
        _note('old', 'mira', 'bekannt', '${text.substring(0, 489)}B'),
        _note('other', 'tarek', 'neutral', 'Andere Notiz.'),
      ],
    );
    final changedOther = campaign.copyWith(
      npcRelationshipNotes: [
        _note('old', 'mira', 'bekannt', text),
        _note('other', 'tarek', 'neutral', 'Anders gespeichert.'),
      ],
    );
    final changedNpc = campaign.copyWith(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'tarek', name: 'Tarek'),
      ],
    );
    for (final stale in [
      changedOld,
      changedOther,
      changedNpc,
      campaign.copyWith(revision: 6),
      _campaign(sessionId: 'changed', notes: campaign.npcRelationshipNotes),
      _campaign(id: 'changed', notes: campaign.npcRelationshipNotes),
    ]) {
      expect(() => chosen.requireCurrent(stale), throwsFormatException);
    }
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('JSON and SQLite restart preserve exact historical note', () async {
    final original = _campaign(
      revision: 0,
      notes: [
        _note('old', 'mira', 'bekannt', 'Die Karte lag im Archiv.'),
        _note('new', 'mira', 'neutral', 'Die Karte wurde später abgeholt.'),
      ],
    );
    final encoded = jsonEncode(original.toJson());
    final restoredJson = Campaign.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('npc-note-resume-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      await repository.saveCampaign(restoredJson);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(restored.toJson());
      final chosen = ConfirmedNpcNoteHistorySelector.readSelected(
        restored,
        expectedRevision: 0,
        noteId: 'old',
      );

      expect(chosen.playerOverview, contains('Die Karte lag im Archiv.'));
      expect(
        chosen.playerOverview,
        isNot(contains('später abgeholt')),
      );
      expect(chosen.recordedAt, _at);
      chosen.requireCurrent(restored);
      expect(restored.hero.toJson(), original.hero.toJson());
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(restored.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });

  test('legacy save without note history has no invented evidence', () {
    final json = _campaign().toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(json);
    final before = jsonEncode(restored.toJson());

    expect(
      () => ConfirmedNpcNoteHistorySelector.readSelected(
        restored,
        expectedRevision: 5,
        noteId: 'old',
      ),
      throwsFormatException,
    );
    expect(jsonEncode(restored.toJson()), before);
  });
}
