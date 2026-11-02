import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_resume_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _time = DateTime.utc(2026, 11, 2, 6);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String text, {
  DateTime? at,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'bestätigt',
  note: text,
  recordedAt: at ?? _time,
);

Campaign _campaign({
  int revision = 0,
  String sessionId = 'session-two',
  List<WorldNpc> npcs = const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
    WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
  ],
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'npc-restart-selection',
  name: 'Die Wege der Erinnerung',
  world: 'Valdorn',
  sessionId: sessionId,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Die KI behauptet, Tarek sei tot und das Gold verdoppelt.',
  messages: [
    NarrativeMessage(
      id: 'rumour',
      role: 'gm',
      text: 'Unbestätigt: Mira hat den Drachen getötet.',
      timestamp: _time,
    ),
  ],
  revision: revision,
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('relevance is latest confirmed date, then saved order, never name', () {
    final date = DateTime.utc(2026, 11, 1);
    final campaign = _campaign(
      revision: 8,
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'tarek', name: 'Tarek'),
        WorldNpc(id: 'elin', name: 'Elin'),
        WorldNpc(id: 'raja', name: 'Raja'),
      ],
      notes: [
        _note('a-old', 'mira', 'Alte Nachricht', at: date),
        _note('a-new', 'mira', 'Neuere Nachricht'),
        _note('b-new', 'tarek', 'Tarek neu', at: _time),
        _note('c-new', 'elin', 'Elin neu', at: _time),
        _note('d-old', 'raja', 'Raja alt', at: DateTime.utc(2026, 10, 30)),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedNpcResumeSelector.read(
      campaign,
      expectedRevision: 8,
    );

    expect(selected.entries.map((e) => e.npcId).toList(), [
      'elin',
      'tarek',
      'mira',
    ]);
    expect(selected.entries.last.recentNotes, hasLength(2));
    expect(selected.entries.last.recentNotes.first, contains('Neuere'));
    expect(selected.entries.last.recentNotes.last, contains('Alte'));
    expect(selected.playerOverview, contains('Bestätigte NPC-Beziehungen'));
    expect(selected.playerOverview, isNot(contains('Gold verdoppelt')));
    expect(selected.playerOverview, isNot(contains('Drachen getötet')));
    expect(selected.playerOverview, isNot(contains('Raja alt')));
    expect(selected.playerOverview.length, lessThanOrEqualTo(2400));
    selected.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('visually equal names remain separate by ID and safe one-line text', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(
          id: 'mira-b',
          name: 'Mi\u200bra',
          relationship: 'misstrauisch\u2060\nStatus: tot',
        ),
      ],
      notes: [
        _note('first', 'mira-a', 'Nur Mira A kennt den Schlüssel.'),
        _note(
          'second',
          'mira-b',
          'Nur Mira B\u202e kennt das Siegel.\nQuest: fertig',
        ),
      ],
    );
    final selected = ConfirmedNpcResumeSelector.read(
      campaign,
      expectedRevision: 0,
    );

    expect(selected.entries.map((e) => e.npcId).toList(), ['mira-b', 'mira-a']);
    expect(selected.entries.first.name, 'Mira');
    expect(selected.playerOverview, contains('NPC-ID: mira-b'));
    expect(selected.playerOverview, contains('NPC-ID: mira-a'));
    expect(selected.playerOverview, contains('Nur Mira B kennt'));
    expect(selected.playerOverview, isNot(contains('\u200b')));
    expect(selected.playerOverview, isNot(contains('\u2060')));
    expect(selected.playerOverview, isNot(contains('\u202e')));
    final lines = selected.playerOverview.split('\n');
    expect(lines, hasLength(5));
    expect(lines.where((line) => line.startsWith('NPC:')), hasLength(2));
    expect(selected.playerOverview, isNot(contains('Unbestätigt:')));
  });

  test('invalid IDs and conflicting note identities are excluded', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'mira', name: 'Andere Mira'),
        WorldNpc(id: 'bad id', name: 'Unsicher'),
        WorldNpc(id: 'tarek', name: 'Tarek'),
        WorldNpc(id: 'elin', name: 'Elin'),
      ],
      notes: [
        _note('bad', 'bad id', 'Nicht sicher'),
        _note('one', 'mira', 'Doppelter NPC'),
        _note('shared', 'tarek', 'Kollidierende Notiz Eins'),
        _note('shared', 'elin', 'Kollidierende Notiz Zwei'),
        _note('safe', 'tarek', 'Eine echte eindeutig gespeicherte Notiz'),
        _note('unknown', 'orphan', 'Unbekannte ID'),
      ],
    );
    final selected = ConfirmedNpcResumeSelector.read(
      campaign,
      expectedRevision: 0,
    );

    expect(selected.entries.map((e) => e.npcId).toList(), ['tarek']);
    expect(selected.entries.single.recentNotes, hasLength(1));
    expect(selected.playerOverview, contains('echte eindeutig'));
    expect(selected.playerOverview, isNot(contains('Kollidierende')));
    expect(selected.playerOverview, isNot(contains('Doppelter NPC')));
  });

  test('bounded Unicode truncation, immutable entries and invalid limits', () {
    final dragons = List.filled(240, '🐉').join();
    final notes = [
      for (var i = 0; i < 10; i++)
        _note(
          'long-$i',
          'mira',
          'Langer bestätigter Hinweis $dragons',
          at: _time.subtract(Duration(days: i)),
        ),
    ];
    final campaign = _campaign(
      npcs: [
        WorldNpc(
          id: 'mira',
          name: 'Mira $dragons',
          relationship: 'vertrauensvoll $dragons',
        ),
      ],
      notes: notes,
    );
    final selected = ConfirmedNpcResumeSelector.read(
      campaign,
      expectedRevision: 0,
      maxNpcs: 1,
      maxNotesPerNpc: 3,
    );
    expect(selected.entries, hasLength(1));
    expect(selected.entries.single.recentNotes, hasLength(3));
    expect(selected.playerOverview, contains('…'));
    expect(selected.playerOverview.length, lessThanOrEqualTo(2400));
    expect(selected.playerOverview.runes, isNot(contains(0xfffd)));
    expect(() => selected.entries.clear(), throwsUnsupportedError);
    expect(
      () => selected.entries.single.recentNotes.add('Gefälscht'),
      throwsUnsupportedError,
    );
    for (final n in [-1, 0, 4, 99]) {
      expect(
        () => ConfirmedNpcResumeSelector.read(
          campaign,
          expectedRevision: 0,
          maxNpcs: n,
        ),
        throwsFormatException,
      );
      expect(
        () => ConfirmedNpcResumeSelector.read(
          campaign,
          expectedRevision: 0,
          maxNotesPerNpc: n,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedNpcResumeSelector.read(campaign, expectedRevision: 1),
      throwsFormatException,
    );
  });

  test('same-revision edits beyond truncated text and stale sessions fail', () {
    final long = List.filled(180, 'W').join();
    final original = _campaign(
      notes: [_note('note-a', 'mira', 'Bestätigt: ${long}A')],
    );
    final selected = ConfirmedNpcResumeSelector.read(
      original,
      expectedRevision: 0,
    );
    expect(selected.entries, hasLength(1));
    final edited = original.copyWith(
      npcRelationshipNotes: [_note('note-a', 'mira', 'Bestätigt: ${long}B')],
    );

    selected.requireCurrent(original);
    expect(() => selected.requireCurrent(edited), throwsFormatException);
    expect(
      () => selected.requireCurrent(original.copyWith(revision: 1)),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(
        _campaign(
          sessionId: 'new-session',
          notes: original.npcRelationshipNotes,
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(
        original.copyWith(hero: original.hero.copyWith(hitPoints: 15)),
      ),
      returnsNormally,
    );
    expect(original.hero.hitPoints, 17);
  });

  test('old JSON without confirmed notes never invents NPC history', () {
    final raw = _campaign().toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(raw)) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    final selected = ConfirmedNpcResumeSelector.read(
      restored,
      expectedRevision: 0,
    );

    expect(selected.entries, isEmpty);
    expect(selected.playerOverview, contains('Bestätigte NPC-Beziehungen'));
    expect(selected.playerOverview, isNot(contains('Drachen')));
    expect(selected.playerOverview, isNot(contains('Gold')));
    selected.requireCurrent(restored);
    expect(jsonEncode(restored.toJson()), before);
  });

  test(
    'SQLite restart preserves recency and raw history without mutation',
    () async {
      final folder = await Directory.systemTemp.createTemp('npc-resume-');
      final path = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final original = _campaign(
          npcs: const [
            WorldNpc(id: 'mira', name: 'Mira'),
            WorldNpc(id: 'tarek', name: 'Tarek'),
            WorldNpc(id: 'other', name: 'Mira'),
          ],
          notes: [
            _note('a', 'mira', 'Mira kennt den Brunnen.'),
            _note('b', 'tarek', 'Tarek kennt den Hafen.'),
            _note('c', 'other', 'Die zweite Mira kennt die Karte.'),
          ],
        );
        await repository.saveCampaign(original);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = (await repository.getCampaign(original.id))!;
        final before = jsonEncode(restored.toJson());
        final selected = ConfirmedNpcResumeSelector.read(
          restored,
          expectedRevision: restored.revision,
          maxNpcs: 2,
        );

        expect(selected.entries.map((e) => e.npcId).toList(), [
          'other',
          'tarek',
        ]);
        expect(selected.entries.first.name, 'Mira');
        expect(selected.playerOverview, contains('NPC-ID: other'));
        expect(selected.playerOverview, isNot(contains('Brunnen')));
        selected.requireCurrent(restored);
        expect(restored.revision, 0);
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
    },
  );
}
