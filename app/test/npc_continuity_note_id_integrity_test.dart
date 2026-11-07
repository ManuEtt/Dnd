import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_continuity_reader.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _at = DateTime.utc(2026, 11, 7, 6);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String text, {
  DateTime? at,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'freundlich',
  note: text,
  recordedAt: at ?? _at,
);

Campaign _campaign({List<NpcRelationshipNote> notes = const []}) => Campaign(
  id: 'npc-note-id-integrity',
  name: 'Die Brunnenchronik',
  world: 'Valdorn',
  sessionId: 'session-saved',
  revision: 4,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Ein unbestätigter Erzähler behauptet, Mira habe 999 Gold.',
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
    WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
  ],
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('duplicate and unsafe note IDs never displace confirmed history', () {
    final original = _campaign(
      notes: [
        _note(
          'old',
          'mira',
          'Bestätigt: Mira kennt den Brunnen.',
          at: _at.subtract(const Duration(days: 1)),
        ),
        _note('shared', 'mira', 'Gefälschte fremde Erinnerung.'),
        _note('shared', 'tarek', 'Doppelte Identität bei Tarek.'),
        _note('same-owner', 'mira', 'Erste kollidierende Notiz.'),
        _note('same-owner', 'mira', 'Zweite kollidierende Notiz.'),
        _note('bad id', 'mira', 'Ungültiges Leerzeichen.'),
        _note('bad\n', 'mira', 'Ungültiger Zeilenumbruch.'),
        _note('bad\u200b', 'mira', 'Unsichtbare ID.'),
        _note('new', 'mira', 'Bestätigt: Mira bewahrt die Karte.'),
        _note('other', 'tarek', 'Tarek bewacht das Tor.'),
      ],
    );
    final before = jsonEncode(original.toJson());

    final snapshot = NpcContinuityReader.read(original, npcId: 'mira');
    expect(snapshot.recentNotes.map((n) => n.id).toList(), ['new', 'old']);
    expect(snapshot.confirmedContext, contains('Mira bewahrt die Karte'));
    expect(snapshot.confirmedContext, contains('Mira kennt den Brunnen'));
    expect(snapshot.confirmedContext, isNot(contains('Gefälschte')));
    expect(snapshot.confirmedContext, isNot(contains('kollidierende')));
    expect(snapshot.confirmedContext, isNot(contains('Ungültig')));
    expect(snapshot.confirmedContext, isNot(contains('Tarek bewacht')));
    expect(snapshot.confirmedContext, isNot(contains('999 Gold')));
    expect(jsonEncode(original.toJson()), before);
  });

  test(
    'invalid most recent note cannot occupy the limit or change tie order',
    () {
      final campaign = _campaign(
        notes: [
          _note('first', 'mira', 'Erste bestätigte Nachricht.'),
          _note(
            'unsafe\n',
            'mira',
            'Nicht als neueste Notiz verwenden.',
            at: _at.add(const Duration(days: 2)),
          ),
          _note('second', 'mira', 'Zweite bestätigte Nachricht.'),
        ],
      );
      final snapshot = NpcContinuityReader.read(
        campaign,
        npcId: 'mira',
        limit: 1,
      );
      expect(snapshot.recentNotes.single.id, 'second');
      expect(snapshot.confirmedContext, contains('Zweite bestätigte'));
      expect(snapshot.confirmedContext, isNot(contains('Nicht als neueste')));
      expect(() => snapshot.recentNotes.clear(), throwsUnsupportedError);
    },
  );

  test(
    'legacy JSON and valid confirmed notes survive read-only round trips',
    () {
      final legacy = _campaign().toJson()..remove('npcRelationshipNotes');
      final old = Campaign.fromJson(legacy);
      expect(NpcContinuityReader.read(old, npcId: 'mira').recentNotes, isEmpty);

      final saved = _campaign(
        notes: [
          _note('confirmed-one', 'mira', 'Mira bleibt am Brunnen.'),
          _note('other-one', 'tarek', 'Tarek ist in der Stadt.'),
        ],
      );
      final recovered = Campaign.fromJson(
        jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
      );
      final before = jsonEncode(recovered.toJson());
      final snapshot = NpcContinuityReader.read(recovered, npcId: 'mira');

      expect(snapshot.recentNotes.single.id, 'confirmed-one');
      expect(snapshot.confirmedContext, contains('Mira bleibt am Brunnen.'));
      expect(snapshot.confirmedContext, isNot(contains('Tarek ist')));
      expect(recovered.hero.toJson(), saved.hero.toJson());
      expect(jsonEncode(recovered.toJson()), before);
    },
  );

  test(
    'SQLite restart preserves valid NPC history and untouched hero',
    () async {
      final folder = await Directory.systemTemp.createTemp('npc-note-id-');
      final file = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: file,
      );
      try {
        final saved = _campaign(
          notes: [
            _note('first', 'mira', 'Mira kennt den Hafen.'),
            _note('second', 'mira', 'Mira kennt den Turm.'),
          ],
        );
        await repository.saveCampaign(saved);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: file,
        );
        final restored = (await repository.getCampaign(saved.id))!;
        final before = jsonEncode(restored.toJson());
        final snapshot = NpcContinuityReader.read(restored, npcId: 'mira');

        expect(snapshot.recentNotes.map((n) => n.id).toList(), [
          'second',
          'first',
        ]);
        expect(snapshot.confirmedContext, contains('Mira kennt den Hafen.'));
        expect(snapshot.confirmedContext, contains('Mira kennt den Turm.'));
        expect(restored.hero.toJson(), saved.hero.toJson());
        expect(jsonEncode(restored.toJson()), before);
        expect(
          (await repository.reconstructCampaign(saved.id))!.toJson(),
          restored.toJson(),
        );
      } finally {
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
