import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_continuity_reader.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _at = DateTime.utc(2026, 11, 2, 8);

NpcRelationshipNote _note(String id, String npcId, String value) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'freundlich',
      note: value,
      recordedAt: _at,
    );

Campaign _campaign({
  List<WorldNpc> npcs = const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
  ],
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'npc-continuity-zero-width',
  name: 'Die Stadt der Zeichen',
  world: 'Valdorn',
  sessionId: 'session-two',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Die KI behauptet, Mira habe einen Schatz gefunden.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('visually equal NPC names must include their distinct saved IDs', () {
    const hiddenMarks = [
      '\u200b',
      '\u200c',
      '\u200d',
      '\u2060',
      '\ufeff',
      '\u202e',
    ];
    for (final mark in hiddenMarks) {
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira-one', name: 'Mira'),
          WorldNpc(id: 'mira-two', name: 'Mi${mark}ra'),
        ],
        notes: [
          _note('one', 'mira-one', 'Nur Mira Eins kennt das Tor.'),
          _note('two', 'mira-two', 'Nur Mira Zwei kennt den Brunnen.'),
        ],
      );
      final original = jsonEncode(campaign.toJson());
      final one = NpcContinuityReader.read(campaign, npcId: 'mira-one');
      final two = NpcContinuityReader.read(campaign, npcId: 'mira-two');

      expect(one.disambiguateName, isTrue);
      expect(two.disambiguateName, isTrue);
      expect(one.confirmedContext, contains('NPC: Mira (NPC-ID: mira-one)'));
      expect(two.confirmedContext, contains('NPC: Mira (NPC-ID: mira-two)'));
      expect(one.confirmedContext, contains('Nur Mira Eins kennt das Tor.'));
      expect(two.confirmedContext, contains('Nur Mira Zwei kennt den Brunnen.'));
      expect(one.confirmedContext, isNot(contains('Brunnen.')));
      expect(two.confirmedContext, isNot(contains('Tor.')));
      expect(two.confirmedContext, isNot(contains(mark)));
      expect(jsonEncode(campaign.toJson()), original);
    }
  });

  test('one legacy NPC shows its visible name, with line-safe notes', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(
          id: 'mira',
          name: 'Mi\u200bra',
          relationship: 'freu\u2060ndlich',
        ),
      ],
      notes: [_note('legacy', 'mira', 'Der\u200b Schlüssel\u2060 ist hier.\n') ],
    );
    final before = jsonEncode(campaign.toJson());
    final snapshot = NpcContinuityReader.read(campaign, npcId: 'mira');
    final context = snapshot.confirmedContext;

    expect(snapshot.name, 'Mi\u200bra');
    expect(snapshot.disambiguateName, isFalse);
    expect(context, startsWith('NPC: Mira\nStatus: lebendig\n'));
    expect(context, contains('Aktuelle Beziehung: freu ndlich'));
    expect(context, contains('Der Schlüssel ist hier.'));
    expect(context.split('\n'), hasLength(4));
    for (final mark in ['\u200b', '\u2060', '\ufeff']) {
      expect(context, isNot(contains(mark)));
    }
    expect(jsonEncode(campaign.toJson()), before);
    expect(() => snapshot.recentNotes.add(_note('faked', 'mira', 'falsch')),
        throwsUnsupportedError);
  });

  test('unsafe identity cannot be rendered when visible names collide', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'unsafe id', name: 'Mi\u200bra'),
        WorldNpc(id: 'safe-id', name: 'Mira'),
      ],
    );
    expect(
      () => NpcContinuityReader.read(campaign, npcId: 'unsafe id'),
      throwsFormatException,
    );
    expect(
      NpcContinuityReader.read(campaign, npcId: 'safe-id').confirmedContext,
      contains('(NPC-ID: safe-id)'),
    );
    final duplicateId = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'mira', name: 'Mi\u200bra'),
      ],
    );
    expect(
      () => NpcContinuityReader.read(duplicateId, npcId: 'mira'),
      throwsFormatException,
    );
    expect(
      () => NpcContinuityReader.read(campaign, npcId: 'safe-id', limit: 0),
      throwsFormatException,
    );
  });

  test('legacy JSON without optional NPC notes remains readable', () {
    final oldJson = _campaign(
      npcs: const [WorldNpc(id: 'mira', name: 'Mi\u200dra')],
    ).toJson()
      ..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(oldJson)) as Map<String, dynamic>,
    );
    final original = jsonEncode(restored.toJson());
    final snapshot = NpcContinuityReader.read(restored, npcId: 'mira');

    expect(snapshot.disambiguateName, isFalse);
    expect(snapshot.recentNotes, isEmpty);
    expect(snapshot.confirmedContext, contains('NPC: Mira'));
    expect(snapshot.confirmedContext, contains('Keine bestätigten'));
    expect(snapshot.confirmedContext, isNot(contains('Schatz')));
    expect(jsonEncode(restored.toJson()), original);
  });

  test('SQLite restart and replay preserve identities and confirmed history',
      () async {
    final folder = await Directory.systemTemp.createTemp('npc-continuity-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = _campaign(
        npcs: const [
          WorldNpc(id: 'mira-one', name: 'Mira'),
          WorldNpc(id: 'mira-two', name: 'Mi\u2060ra'),
          WorldNpc(id: 'tarek', name: 'Tarek'),
        ],
        notes: [
          _note('one', 'mira-one', 'Erste Mira kennt die Karte.'),
          _note('two', 'mira-two', 'Zweite Mira kennt die Truhe.'),
          _note('three', 'tarek', 'Tarek kennt den Hafen.'),
        ],
      );
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final loaded = (await repository.getCampaign(campaign.id))!;
      final before = jsonEncode(loaded.toJson());
      final second = NpcContinuityReader.read(loaded, npcId: 'mira-two');
      final third = NpcContinuityReader.read(loaded, npcId: 'tarek');

      expect(second.disambiguateName, isTrue);
      expect(second.confirmedContext, contains('(NPC-ID: mira-two)'));
      expect(second.confirmedContext, contains('Zweite Mira kennt die Truhe.'));
      expect(second.confirmedContext, isNot(contains('Karte.')));
      expect(third.disambiguateName, isFalse);
      expect(third.confirmedContext, startsWith('NPC: Tarek\n'));
      expect(third.confirmedContext, contains('Hafen.'));
      expect(loaded.revision, 0);
      expect(loaded.hero.toJson(), campaign.hero.toJson());
      expect(jsonEncode(loaded.toJson()), before);
      expect(
        (await repository.reconstructCampaign(campaign.id))!.toJson(),
        loaded.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
