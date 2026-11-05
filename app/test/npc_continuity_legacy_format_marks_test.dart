import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_continuity_reader.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  required List<WorldNpc> npcs,
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'npc-legacy-format-marks',
  name: 'Die Chronik der Nebelstadt',
  world: 'Valdorn',
  sessionId: 'session-legacy',
  hero: HeroCharacter(
    id: 'aria',
    name: 'Aria',
    hitPoints: 17,
    maxHitPoints: 20,
  ),
  scene: 'Eine unbestätigte Erzählung über Mira.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

NpcRelationshipNote _note(String id, String npcId, String text) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'vorsichtig',
      note: text,
      recordedAt: DateTime.utc(2026, 11, 5),
    );

void main() {
  sqfliteFfiInit();

  test('legacy invisible marks cannot hide equal displayed NPC names', () {
    const marks = [
      '\u00ad',
      '\u034f',
      '\u180e',
      '\u206a',
      '\u206b',
      '\u206c',
      '\u206d',
      '\u206e',
      '\u206f',
    ];
    for (final mark in marks) {
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira-one', name: 'Mira'),
          WorldNpc(id: 'mira-two', name: 'Mi${mark}ra'),
        ],
        notes: [
          _note('one', 'mira-one', 'Nur die erste Mira kennt das Tor.'),
          _note('two', 'mira-two', 'Nur die zweite Mira kennt den Brunnen.'),
        ],
      );
      final before = jsonEncode(campaign.toJson());
      final first = NpcContinuityReader.read(campaign, npcId: 'mira-one');
      final second = NpcContinuityReader.read(campaign, npcId: 'mira-two');

      expect(first.disambiguateName, isTrue);
      expect(second.disambiguateName, isTrue);
      expect(first.confirmedContext, contains('NPC: Mira (NPC-ID: mira-one)'));
      expect(second.confirmedContext, contains('NPC: Mira (NPC-ID: mira-two)'));
      expect(first.confirmedContext, contains('erste Mira kennt das Tor'));
      expect(first.confirmedContext, isNot(contains('Brunnen')));
      expect(
        second.confirmedContext,
        contains('zweite Mira kennt den Brunnen'),
      );
      expect(second.confirmedContext, isNot(contains('das Tor')));
      expect(second.confirmedContext, isNot(contains(mark)));
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test(
    'relationships and saved notes render without legacy format controls',
    () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(
          id: 'mira',
          name: 'Mi\u034fra',
          relationship: 'ver\u00adtraut',
        ),
      ],
      notes: [_note('first', 'mira', 'Das\u180e Geheimnis\u206a bleibt.')],
    );
    final before = jsonEncode(campaign.toJson());
    final snapshot = NpcContinuityReader.read(campaign, npcId: 'mira');
    final context = snapshot.confirmedContext;

    expect(snapshot.name, 'Mi\u034fra');
    expect(snapshot.disambiguateName, isFalse);
    expect(context, startsWith('NPC: Mira\nStatus: lebendig\n'));
    expect(context, contains('Aktuelle Beziehung: ver traut'));
    expect(context, contains('Das Geheimnis bleibt.'));
    expect(context.split('\n'), hasLength(4));
    for (final mark in ['\u00ad', '\u034f', '\u180e', '\u206a']) {
      expect(context, isNot(contains(mark)));
    }
    expect(jsonEncode(campaign.toJson()), before);
    },
  );

  test('unsafe ambiguous IDs are rejected; distinct names stay distinct', () {
    final ambiguous = _campaign(
      npcs: const [
        WorldNpc(id: 'unsafe id', name: 'Mi\u00adra'),
        WorldNpc(id: 'mira-two', name: 'Mira'),
      ],
    );
    expect(
      () => NpcContinuityReader.read(ambiguous, npcId: 'unsafe id'),
      throwsFormatException,
    );
    expect(
      NpcContinuityReader.read(ambiguous, npcId: 'mira-two').confirmedContext,
      contains('(NPC-ID: mira-two)'),
    );

    final ordinary = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'miranda', name: 'Miranda'),
        WorldNpc(id: 'elin', name: 'Älin ✨'),
      ],
    );
    for (final id in ['mira', 'miranda', 'elin']) {
      expect(
        NpcContinuityReader.read(ordinary, npcId: id).disambiguateName,
        isFalse,
      );
    }
    expect(
      NpcContinuityReader.read(ordinary, npcId: 'elin').confirmedContext,
      startsWith('NPC: Älin ✨\n'),
    );
  });

  test(
    'SQLite restart keeps raw legacy names and confirmed NPC identities',
    () async {
    final folder = await Directory.systemTemp.createTemp('npc-legacy-format-');
    final file = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: file,
    );
    try {
      final campaign = _campaign(
        npcs: const [
          WorldNpc(id: 'mira-one', name: 'Mira'),
          WorldNpc(id: 'mira-two', name: 'Mi\u00adra'),
        ],
        notes: [
          _note('one', 'mira-one', 'Die erste Chronik.'),
          _note('two', 'mira-two', 'Die zweite Chronik.'),
        ],
      );
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: file,
      );
      final restored = (await repository.getCampaign(campaign.id))!;
      final before = jsonEncode(restored.toJson());
      final snapshot = NpcContinuityReader.read(restored, npcId: 'mira-two');

      expect(snapshot.disambiguateName, isTrue);
      expect(snapshot.confirmedContext, contains('(NPC-ID: mira-two)'));
      expect(snapshot.confirmedContext, contains('zweite Chronik'));
      expect(snapshot.confirmedContext, isNot(contains('erste Chronik')));
      expect(restored.npcs[1].name, 'Mi\u00adra');
      expect(restored.hero.toJson(), campaign.hero.toJson());
      expect(restored.revision, campaign.revision);
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(campaign.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
    },
  );
}
