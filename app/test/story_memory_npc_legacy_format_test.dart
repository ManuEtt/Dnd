import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart' as story;
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _recorded = DateTime.utc(2026, 11, 6);

NpcRelationshipNote _note(String id, String npcId, String content) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'freundlich',
      note: content,
      recordedAt: _recorded,
    );

Campaign _campaign({
  required List<WorldNpc> npcs,
  List<NpcRelationshipNote> notes = const [],
  int revision = 0,
}) => Campaign(
  id: 'legacy-name-memory',
  name: 'Stadt der Spiegel',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Alle Miras sind dieselbe Person.',
  revision: revision,
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('nine invisible marks never merge two saved NPC identities', () {
    const marks = [
      0x00ad,
      0x034f,
      0x061c,
      0x180e,
      0x200b,
      0x202e,
      0x206a,
      0x206d,
      0x206f,
    ];
    for (final point in marks) {
      final mark = String.fromCharCode(point);
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira-a', name: 'Mira'),
          WorldNpc(id: 'mira-b', name: 'Mi${mark}ra'),
        ],
        notes: [
          _note('north', 'mira-a', 'Die erste Mira kennt das Nordtor.'),
          _note('south', 'mira-b', 'Die zweite Mira kennt das Südtor.'),
        ],
      );
      final before = jsonEncode(campaign.toJson());
      final summary = story.MemoryEngine.buildSessionSummary(campaign);
      final recall = story.MemoryEngine.retrieve(
        campaign,
        'Was weißt du über Mira?',
        matchingOnly: true,
      ).join('\n');

      for (final rendered in [summary, recall]) {
        expect(rendered, contains('Mira (NPC-ID: mira-a)'), reason: '$point');
        expect(rendered, contains('Mira (NPC-ID: mira-b)'), reason: '$point');
        expect(rendered, isNot(contains(mark)), reason: '$point');
        expect(rendered, isNot(contains('Unbestätigt:')), reason: '$point');
      }
      expect(recall, contains('Nordtor'), reason: '$point');
      expect(recall, contains('Südtor'), reason: '$point');
      expect(
        story.MemoryEngine.retrieve(
          campaign,
          'Was weißt du über Mi${mark}ra?',
          matchingOnly: true,
        ).join('\n'),
        contains('NPC-ID: mira-b'),
        reason: '$point',
      );
      expect(jsonEncode(campaign.toJson()), before);
      expect(campaign.hero.hitPoints, 17);
    }
  });

  test('unsafe duplicate ID and name made solely of marks are excluded', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'bad\nid', name: 'Mira', relationship: 'feindlich'),
        WorldNpc(id: 'safe', name: 'Mi\u206ara', relationship: 'freundlich'),
        WorldNpc(id: 'hidden', name: '\u00ad\u034f\u206d'),
      ],
      notes: [
        _note('bad', 'bad\nid', 'Unzuordenbarer Geheimplan.'),
        _note('safe-note', 'safe', 'Der bestätigte Hafenschlüssel.'),
        _note('hidden-note', 'hidden', 'Ein unsichtbarer Geist.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final recap = story.MemoryEngine.buildSessionSummary(campaign);
    final recall = story.MemoryEngine.retrieve(
      campaign,
      'Mira',
      matchingOnly: true,
    ).join('\n');

    for (final rendered in [recap, recall]) {
      expect(rendered, contains('Mira (NPC-ID: safe)'));
      expect(rendered, isNot(contains('bad\nid')));
      expect(rendered, isNot(contains('Unzuordenbarer Geheimplan')));
      expect(rendered, isNot(contains('Ein unsichtbarer Geist')));
      expect(rendered, isNot(contains('\u206a')));
    }
    expect(recall, contains('Hafenschlüssel'));
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('valid German names and old JSON preserve confirmed recaps', () {
    final campaign = _campaign(
      revision: 7,
      npcs: const [
        WorldNpc(
          id: 'keeper-a',
          name: 'Große Hüterin ✨',
          relationship: 'verbündet',
        ),
        WorldNpc(
          id: 'keeper-b',
          name: 'GROSSE HUETERIN ✨',
          relationship: 'neutral',
        ),
      ],
      notes: [
        _note('one', 'keeper-a', 'Der erste Schlüssel ist bestätigt.'),
        _note('two', 'keeper-b', 'Der zweite Schlüssel ist bestätigt.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final summary = story.MemoryEngine.buildSessionSummary(campaign);
    final recall = story.MemoryEngine.retrieve(
      campaign,
      'Was weißt du über die GROSSE HUETERIN?',
      matchingOnly: true,
    ).join('\n');

    for (final rendered in [summary, recall]) {
      expect(rendered, contains('Große Hüterin ✨ (NPC-ID: keeper-a)'));
      expect(rendered, contains('GROSSE HUETERIN ✨ (NPC-ID: keeper-b)'));
    }
    final saved = GameEngine(clock: () => _recorded).saveSessionRecap(campaign);
    expect(saved.events.single.type, 'memory.sessionRecapSaved');
    expect(saved.campaign.sessionRecaps.single.summary, summary);
    expect(saved.campaign.hero.toJson(), campaign.hero.toJson());
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(saved.campaign.toJson())) as Map<String, dynamic>,
    );
    expect(restored.sessionRecaps.single.summary, summary);
    expect(restored.hero.toJson(), campaign.hero.toJson());
    expect(jsonEncode(campaign.toJson()), before);

    final oldJson = campaign.toJson()..remove('npcRelationshipNotes');
    final old = Campaign.fromJson(oldJson);
    expect(old.npcRelationshipNotes, isEmpty);
    expect(
      story.MemoryEngine.buildSessionSummary(old),
      contains('NPC-ID: keeper-a'),
    );
    expect(
      story.MemoryEngine.retrieve(old, 'Schlüssel', matchingOnly: true),
      isEmpty,
    );
  });

  test(
    'SQLite restart keeps raw legacy names but renders safe identities',
    () async {
      final folder = await Directory.systemTemp.createTemp('memory-npc-mark-');
      final path = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final campaign = _campaign(
          npcs: const [
            WorldNpc(id: 'mira-a', name: 'Mira'),
            WorldNpc(id: 'mira-b', name: 'Mi\u180era'),
          ],
          notes: [
            _note('north', 'mira-a', 'Die Karte liegt im Norden.'),
            _note('south', 'mira-b', 'Die Karte liegt im Süden.'),
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
        final recap = story.MemoryEngine.buildSessionSummary(loaded);
        final recalled = story.MemoryEngine.retrieve(
          loaded,
          'Mira',
          matchingOnly: true,
        ).join('\n');

        expect(recap, contains('Mira (NPC-ID: mira-a)'));
        expect(recap, contains('Mira (NPC-ID: mira-b)'));
        expect(recalled, contains('NPC-ID: mira-a'));
        expect(recalled, contains('NPC-ID: mira-b'));
        expect(loaded.npcs.last.name, 'Mi\u180era');
        expect(loaded.hero.toJson(), campaign.hero.toJson());
        expect(loaded.revision, campaign.revision);
        expect(jsonEncode(loaded.toJson()), before);
        expect(
          (await repository.reconstructCampaign(campaign.id))!.toJson(),
          loaded.toJson(),
        );
      } finally {
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
