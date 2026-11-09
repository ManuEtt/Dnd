import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_continuity_excerpt.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _time = DateTime.utc(2026, 11, 9, 12);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String text, {
  DateTime? at,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'bekannt',
  note: text,
  recordedAt: at ?? _time,
);

Campaign _campaign(List<NpcRelationshipNote> notes) => Campaign(
  id: 'npc-excerpt-note-identity',
  name: 'Die Chronik',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Mira hat den Schatz verteilt.',
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
    WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'vorsichtig'),
  ],
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('duplicate note IDs for one NPC never become confirmed history', () {
    final campaign = _campaign([
      _note('duplicate', 'mira', 'Ungeprüfte Aussage A.'),
      _note('duplicate', 'mira', 'Widersprüchliche Aussage B.'),
      _note('verified', 'mira', 'Der Turm ist im Osten.'),
    ]);
    final before = jsonEncode(campaign.toJson());

    final excerpt = ConfirmedNpcContinuityExcerpt.read(
      campaign,
      npcId: 'mira',
      maxNotes: 2,
    );

    expect(excerpt, contains('Der Turm ist im Osten.'));
    expect(excerpt, isNot(contains('Ungeprüfte Aussage')));
    expect(excerpt, isNot(contains('Widersprüchliche Aussage')));
    expect(RegExp('Bestätigte Notiz').allMatches(excerpt), hasLength(1));
    expect(excerpt, isNot(contains('Schatz verteilt')));
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 17);
  });

  test('cross-NPC collisions and unsafe IDs cannot occupy note slots', () {
    final campaign = _campaign([
      _note('shared', 'mira', 'Falsche Zuordnung.'),
      _note('shared', 'tarek', 'Gleiche Notiz-ID.'),
      _note('bad id', 'mira', 'Leerzeichen in ID.'),
      _note('hidden\u200bmark', 'mira', 'Unsichtbare ID.'),
      _note('valid', 'mira', 'Mira kennt den Brunnenschlüssel.'),
    ]);

    final excerpt = ConfirmedNpcContinuityExcerpt.read(
      campaign,
      npcId: 'mira',
      maxNotes: 1,
    );

    expect(excerpt, contains('Mira kennt den Brunnenschlüssel.'));
    expect(excerpt, isNot(contains('Falsche Zuordnung')));
    expect(excerpt, isNot(contains('Gleiche Notiz-ID')));
    expect(excerpt, isNot(contains('Leerzeichen in ID')));
    expect(excerpt, isNot(contains('Unsichtbare ID')));
    expect(RegExp('Bestätigte Notiz').allMatches(excerpt), hasLength(1));
  });

  test('blank notes are skipped and equal timestamps keep saved order', () {
    final campaign = _campaign([
      _note('earlier', 'mira', 'Zuerst gespeichert.'),
      _note('later', 'mira', 'Danach gespeichert.'),
      _note('blank', 'mira', '\u202e\n\t'),
      _note('foreign', 'tarek', 'Fremde Erinnerung.'),
    ]);

    final excerpt = ConfirmedNpcContinuityExcerpt.read(
      campaign,
      npcId: 'mira',
      maxNotes: 2,
    );

    expect(excerpt, contains('Zuerst gespeichert.'));
    expect(excerpt, contains('Danach gespeichert.'));
    expect(
      excerpt.indexOf('Danach gespeichert.'),
      lessThan(excerpt.indexOf('Zuerst gespeichert.')),
    );
    expect(excerpt, isNot(contains('Fremde Erinnerung')));
    expect(RegExp('Bestätigte Notiz').allMatches(excerpt), hasLength(2));
  });

  test('only ambiguous notes give an explicit empty-confirmation result', () {
    final campaign = _campaign([
      _note('clash', 'mira', 'Behauptung eins.'),
      _note('clash', 'mira', 'Behauptung zwei.'),
      _note('', 'mira', 'Ohne ID.'),
    ]);

    final excerpt = ConfirmedNpcContinuityExcerpt.read(campaign, npcId: 'mira');

    expect(excerpt, contains('Keine bestätigten Beziehungsnotizen.'));
    expect(excerpt, isNot(contains('Behauptung')));
    expect(excerpt, isNot(contains('Ohne ID')));
  });

  test(
    'more than twenty invisible notes cannot hide older visible evidence',
    () {
      final campaign = _campaign([
        _note(
          'confirmed',
          'mira',
          'Die alte Karte liegt sicher im Archiv.',
          at: _time.subtract(const Duration(days: 1)),
        ),
        for (var i = 0; i < 24; i++)
          _note(
            'hidden-$i',
            'mira',
            '\u200b\u202e\n\t',
            at: _time.add(Duration(minutes: i + 1)),
          ),
      ]);
      final before = jsonEncode(campaign.toJson());

      final excerpt = ConfirmedNpcContinuityExcerpt.read(
        campaign,
        npcId: 'mira',
        maxNotes: 1,
      );

      expect(excerpt, contains('Die alte Karte liegt sicher im Archiv.'));
      expect(RegExp('Bestätigte Notiz').allMatches(excerpt), hasLength(1));
      expect(excerpt, isNot(contains('Keine bestätigten Beziehungsnotizen.')));
      expect(excerpt, isNot(contains('\u202e')));
      expect(jsonEncode(campaign.toJson()), before);
    },
  );

  test(
    'unique confirmed notes survive legacy JSON and SQLite restart',
    () async {
      final original = _campaign([
        _note('first', 'mira', 'Die Archivarin bewahrt die Karte.'),
        _note(
          'second',
          'mira',
          'Mira hat die Karte abgegeben.',
          at: _time.subtract(const Duration(days: 1)),
        ),
      ]);
      final encoded = jsonEncode(original.toJson());
      final imported = Campaign.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      final folder = await Directory.systemTemp.createTemp(
        'npc-note-identity-',
      );
      final path = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        await repository.saveCampaign(imported);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = (await repository.getCampaign(imported.id))!;
        final before = jsonEncode(restored.toJson());
        final excerpt = ConfirmedNpcContinuityExcerpt.read(
          restored,
          npcId: 'mira',
        );

        expect(excerpt, contains('Die Archivarin bewahrt die Karte.'));
        expect(excerpt, contains('Mira hat die Karte abgegeben.'));
        expect(RegExp('Bestätigte Notiz').allMatches(excerpt), hasLength(2));
        expect(excerpt, isNot(contains('Schatz verteilt')));
        expect(restored.hero.hitPoints, 17);
        expect(restored.revision, 0);
        expect(jsonEncode(restored.toJson()), before);
        expect(
          (await repository.reconstructCampaign(imported.id))!.toJson(),
          restored.toJson(),
        );
      } finally {
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
