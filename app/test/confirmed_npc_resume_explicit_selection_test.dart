import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_resume_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _time = DateTime.utc(2026, 11, 13);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String text, {
  DateTime? recordedAt,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'bestätigt',
  note: text,
  recordedAt: recordedAt ?? _time,
);

Campaign _campaign({
  String sessionId = 'session-memory',
  int revision = 0,
  List<WorldNpc> npcs = const [
    WorldNpc(id: 'mira-1', name: 'Mira', relationship: 'freundlich'),
    WorldNpc(id: 'mira-2', name: 'Mira', relationship: 'misstrauisch'),
    WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
    WorldNpc(id: 'elin', name: 'Elin', relationship: 'freundlich'),
  ],
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'explicit-npc-resume',
  name: 'Eine alte Begegnung',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Mira besitzt alle Schätze.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('explicit NPC ID resumes old relationships beyond the top-three', () {
    final original = _campaign(
      notes: [
        _note(
          'mira-old',
          'mira-1',
          'Die alte Mira kennt die Nordbrücke.',
          recordedAt: DateTime.utc(2026, 10, 1),
        ),
        _note(
          'mira-new',
          'mira-1',
          'Die alte Mira bewacht die Karte.',
          recordedAt: DateTime.utc(2026, 10, 2),
        ),
        _note('mira-2-note', 'mira-2', 'Die andere Mira kennt den Hafen.'),
        _note('tarek-note', 'tarek', 'Tarek kennt das Nordtor.'),
        _note('elin-note', 'elin', 'Elin bewacht den Turm.'),
      ],
    );
    final before = jsonEncode(original.toJson());
    final overview = ConfirmedNpcResumeSelector.read(
      original,
      expectedRevision: 0,
    );
    expect(overview.entries.map((entry) => entry.npcId), isNot(contains('mira-1')));

    final selected = ConfirmedNpcResumeSelector.readSelected(
      original,
      expectedRevision: 0,
      npcId: 'mira-1',
      maxNotesPerNpc: 2,
    );
    expect(selected.entries, hasLength(1));
    expect(selected.entries.single.npcId, 'mira-1');
    expect(selected.entries.single.name, 'Mira');
    expect(selected.entries.single.recentNotes, hasLength(2));
    expect(selected.entries.single.recentNotes.first, contains('bewacht die Karte'));
    expect(selected.entries.single.recentNotes.last, contains('Nordbrücke'));
    expect(selected.playerOverview, contains('NPC-ID: mira-1'));
    expect(selected.playerOverview, isNot(contains('kennt den Hafen')));
    expect(selected.playerOverview, isNot(contains('alle Schätze')));
    expect(() => selected.entries.clear(), throwsUnsupportedError);
    expect(
      () => selected.entries.single.recentNotes.add('Erfundener Hinweis'),
      throwsUnsupportedError,
    );
    selected.requireCurrent(original);
    expect(jsonEncode(original.toJson()), before);
    expect(original.hero.hitPoints, 17);
  });

  test('a saved NPC without notes is selectable without invented claims', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(
          id: 'silent',
          name: 'Sil\u200bvia',
          alive: false,
          relationship: '',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedNpcResumeSelector.readSelected(
      campaign,
      expectedRevision: 0,
      npcId: 'silent',
    );

    expect(
      ConfirmedNpcResumeSelector.read(campaign, expectedRevision: 0).entries,
      isEmpty,
    );
    expect(selected.entries.single.npcId, 'silent');
    expect(selected.entries.single.name, 'Silvia');
    expect(selected.entries.single.alive, isFalse);
    expect(selected.entries.single.relationship, 'unbekannt');
    expect(selected.entries.single.recentNotes, isEmpty);
    expect(selected.playerOverview, contains('NPC-ID: silent'));
    expect(selected.playerOverview, isNot(contains('Bestätigte Notiz:')));
    expect(selected.playerOverview, isNot(contains('alle Schätze')));
    selected.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('missing, unsafe and duplicate NPC identities fail closed', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'valid', name: 'Mira'),
        WorldNpc(id: 'double', name: 'Mira'),
        WorldNpc(id: 'double', name: 'Eine andere Mira'),
        WorldNpc(id: 'blank', name: '\u200b'),
        WorldNpc(id: 'unsafe\n', name: 'Zeilenende'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final good = ConfirmedNpcResumeSelector.readSelected(
      campaign,
      expectedRevision: 0,
      npcId: 'valid',
    );
    expect(good.entries.single.npcId, 'valid');

    for (final id in [
      '',
      'missing',
      'double',
      'blank',
      'unsafe\n',
      'bad id',
      'bad\u202e',
      List.filled(65, 'x').join(),
    ]) {
      expect(
        () => ConfirmedNpcResumeSelector.readSelected(
          campaign,
          expectedRevision: 0,
          npcId: id,
        ),
        throwsFormatException,
      );
    }
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('duplicate and unsafe note IDs do not become confirmed evidence', () {
    final campaign = _campaign(
      notes: [
        _note('shared', 'mira-1', 'Uneindeutiger erster Eintrag.'),
        _note('shared', 'mira-2', 'Uneindeutiger zweiter Eintrag.'),
        _note('bad\n', 'mira-1', 'Nicht-kanonische Notiz.'),
        _note('safe', 'mira-1', 'Der sichere Weg\u202e\nführt zum Tor.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final chosen = ConfirmedNpcResumeSelector.readSelected(
      campaign,
      expectedRevision: 0,
      npcId: 'mira-1',
      maxNotesPerNpc: 1,
    );
    expect(chosen.entries.single.recentNotes, hasLength(1));
    expect(chosen.playerOverview, contains('Der sichere Weg'));
    expect(chosen.playerOverview, isNot(contains('Uneindeutiger')));
    expect(chosen.playerOverview, isNot(contains('Nicht-kanonische')));
    expect(chosen.playerOverview, isNot(contains('\u202e')));
    expect(chosen.playerOverview, isNot(contains('alle Schätze')));
    chosen.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('stale raw histories, session changes and invalid limits are rejected', () {
    final campaign = _campaign(
      notes: [
        _note('new', 'mira-1', 'Neuer Hinweis.'),
        _note(
          'old',
          'mira-1',
          'Älterer Hinweis.',
          recordedAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedNpcResumeSelector.readSelected(
      campaign,
      expectedRevision: 0,
      npcId: 'mira-1',
      maxNotesPerNpc: 1,
    );
    expect(selected.entries.single.recentNotes, hasLength(1));
    selected.requireCurrent(campaign);

    final mutated = campaign.copyWith(
      npcRelationshipNotes: [
        campaign.npcRelationshipNotes.first,
        _note(
          'old',
          'mira-1',
          'Erfundene abweichende Erinnerung.',
          recordedAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );
    expect(() => selected.requireCurrent(mutated), throwsFormatException);
    expect(
      () => selected.requireCurrent(campaign.copyWith(revision: 1)),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(
        Campaign.fromJson({
          ...campaign.toJson(),
          'sessionId': 'another-session',
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(
        campaign.copyWith(hero: campaign.hero.copyWith(hitPoints: 9)),
      ),
      returnsNormally,
    );
    for (final limit in [-1, 0, 4]) {
      expect(
        () => ConfirmedNpcResumeSelector.readSelected(
          campaign,
          expectedRevision: 0,
          npcId: 'mira-1',
          maxNotesPerNpc: limit,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedNpcResumeSelector.readSelected(
        campaign,
        expectedRevision: 1,
        npcId: 'mira-1',
      ),
      throwsFormatException,
    );
    expect(
      () => ConfirmedNpcResumeSelector.readSelected(
        _campaign(sessionId: ' '),
        expectedRevision: 0,
        npcId: 'mira-1',
      ),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 17);
  });

  test('explicit NPC survives JSON and SQLite restart without save changes', () async {
    final campaign = _campaign(
      notes: [
        _note('map', 'mira-1', 'Mira kennt die Brücke.'),
        _note('guard', 'mira-2', 'Die andere Mira bewacht den Turm.'),
      ],
    );
    final restoredJson = Campaign.fromJson(
      jsonDecode(jsonEncode(campaign.toJson())) as Map<String, dynamic>,
    );
    final directory = await Directory.systemTemp.createTemp('npc-choice-');
    final file = paths.join(directory.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: file,
    );
    try {
      await repository.saveCampaign(restoredJson);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: file,
      );
      final restored = (await repository.getCampaign(campaign.id))!;
      final before = jsonEncode(restored.toJson());
      final selected = ConfirmedNpcResumeSelector.readSelected(
        restored,
        expectedRevision: restored.revision,
        npcId: 'mira-1',
      );

      expect(selected.entries.single.npcId, 'mira-1');
      expect(selected.entries.single.recentNotes.single, contains('Brücke'));
      expect(selected.playerOverview, isNot(contains('bewacht den Turm')));
      selected.requireCurrent(restored);
      expect(jsonEncode(restored.toJson()), before);
      expect(restored.hero.toJson(), campaign.hero.toJson());
      expect(
        (await repository.reconstructCampaign(restored.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
