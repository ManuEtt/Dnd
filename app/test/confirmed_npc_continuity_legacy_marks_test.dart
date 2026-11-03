import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_continuity_excerpt.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _time = DateTime.utc(2026, 11, 3, 20);

Campaign _campaign({
  required String name,
  required String relationship,
  required String note,
  String noteRelationship = 'bestätigt',
}) => Campaign(
  id: 'continuity-legacy-marks',
  name: 'Die Chronik',
  world: 'Valdorn',
  sessionId: 'session-continued',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: 999 Gold und sofortige Questbelohnung.',
  npcs: [
    const WorldNpc(id: 'mira', name: 'Mira', relationship: 'unbekannt'),
    WorldNpc(id: 'mira-two', name: name, relationship: relationship),
  ],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'other-note',
      npcId: 'mira',
      relationship: 'neutral',
      note: 'Nur Mira Eins weiß von der Karte.',
      recordedAt: _time,
    ),
    NpcRelationshipNote(
      id: 'selected-note',
      npcId: 'mira-two',
      relationship: noteRelationship,
      note: note,
      recordedAt: _time,
    ),
  ],
);

void main() {
  sqfliteFfiInit();

  test('all legacy invisible marks are absent from confirmed NPC excerpt', () {
    const legacyMarks = [
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

    for (final mark in legacyMarks) {
      final hidden = String.fromCharCode(mark);
      final campaign = _campaign(
        name: 'Mi${hidden}ra',
        relationship: 'vertrau${hidden}t',
        note: 'Schlüs${hidden}sel im Turm.',
        noteRelationship: 'freund${hidden}lich',
      );
      final before = jsonEncode(campaign.toJson());

      final excerpt = ConfirmedNpcContinuityExcerpt.read(
        campaign,
        npcId: 'mira-two',
      );

      expect(excerpt, startsWith('Bestätigter NPC (ID: mira-two): Mira'));
      expect(excerpt, contains('Aktuelle Beziehung: vertrau t'));
      expect(excerpt, contains('(freund lich): Schlüs sel im Turm.'));
      expect(excerpt.contains(hidden), isFalse, reason: 'U+$mark');
      expect(excerpt.split('\n'), hasLength(4));
      expect(excerpt, isNot(contains('999 Gold')));
      expect(excerpt, isNot(contains('Nur Mira Eins')));
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('accented text and emoji variation selectors are kept verbatim', () {
    final campaign = _campaign(
      name: 'Élise ✨️',
      relationship: 'freundlich in der Straße',
      note: 'Über den Fluss ✨️ führt die Brücke.',
    );

    final excerpt = ConfirmedNpcContinuityExcerpt.read(
      campaign,
      npcId: 'mira-two',
    );

    expect(excerpt, contains('Élise ✨️'));
    expect(excerpt, contains('freundlich in der Straße'));
    expect(excerpt, contains('Über den Fluss ✨️ führt die Brücke.'));
    expect(excerpt, contains('ID: mira-two'));
    expect(excerpt, isNot(contains('999 Gold')));
  });

  test('SQLite resume keeps raw notes and sanitizes the excerpt', () async {
    final folder = await Directory.systemTemp.createTemp('npc-legacy-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    final original = _campaign(
      name: 'Mi\u00adra',
      relationship: 'vertrau\u034ft',
      note: 'Schlüs\u180esel \u206aim Turm.',
      noteRelationship: 'freund\u206flich',
    );
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );

    try {
      await repository.saveCampaign(original);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(restored.toJson());
      final excerpt = ConfirmedNpcContinuityExcerpt.read(
        restored,
        npcId: 'mira-two',
      );

      expect(excerpt, startsWith('Bestätigter NPC (ID: mira-two): Mira'));
      expect(excerpt, contains('Schlüs sel im Turm.'));
      expect(excerpt, isNot(contains('\u00ad')));
      expect(excerpt, isNot(contains('\u034f')));
      expect(excerpt, isNot(contains('\u180e')));
      expect(excerpt, isNot(contains('\u206a')));
      expect(excerpt, isNot(contains('\u206f')));
      expect(restored.hero.hitPoints, 17);
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
}
