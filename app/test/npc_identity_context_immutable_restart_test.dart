import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_memory.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign() => Campaign(
  id: 'story-immutable',
  name: 'Die zwei Miras',
  world: 'Valdorn',
  sessionId: 'session-immutable',
  hero: HeroCharacter(id: 'hero', name: 'Eila'),
  scene: 'Die Hafenstadt',
  npcs: const [
    WorldNpc(
      id: 'mira-one',
      name: 'Mira',
      description: 'Kartografin',
      relationship: 'freundlich',
    ),
    WorldNpc(
      id: 'mira-two',
      name: 'Mira',
      description: 'Wächterin',
      relationship: 'vorsichtig',
    ),
  ],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'note-old',
      npcId: 'mira-one',
      relationship: 'freundlich',
      note: 'Die erste Mira besitzt eine Seekarte.',
      recordedAt: DateTime.utc(2026, 10, 25),
    ),
    NpcRelationshipNote(
      id: 'note-new',
      npcId: 'mira-one',
      relationship: 'freundlich',
      note: 'Die erste Mira kennt den Nordpfad.',
      recordedAt: DateTime.utc(2026, 10, 26),
    ),
    NpcRelationshipNote(
      id: 'note-other',
      npcId: 'mira-two',
      relationship: 'vorsichtig',
      note: 'Die zweite Mira bewacht das Nordtor.',
      recordedAt: DateTime.utc(2026, 10, 27),
    ),
  ],
);

void _expectDeepReadOnly(Map<String, Object> context) {
  final before = jsonEncode(context);
  expect(() => context['npcName'] = 'Erfundener Name', throwsUnsupportedError);
  final notes = context['notes'] as List;
  expect(() => notes.clear(), throwsUnsupportedError);
  final first = notes.first as Map;
  expect(
    () => first['note'] = 'Unbestätigte KI-Behauptung.',
    throwsUnsupportedError,
  );
  expect(() => first['npcId'] = 'mira-two', throwsUnsupportedError);
  expect(jsonEncode(context), before);
}

void main() {
  test(
    'confirmed NPC snapshot and nested notes are read-only and JSON-safe',
    () {
      final campaign = _campaign();
      final original = jsonEncode(campaign.toJson());
      final snapshot = NpcIdentityMemory.read(
        campaign,
        npcId: 'mira-one',
        expectedRevision: campaign.revision,
        maxNotes: 2,
      );

      final context = snapshot.toContextMap();
      _expectDeepReadOnly(context);
      expect(context['npcId'], 'mira-one');
      expect(context['notes'], hasLength(2));
      expect(context.toString(), contains('Nordpfad'));
      expect(context.toString(), isNot(contains('Nordtor')));
      expect(jsonDecode(jsonEncode(context))['npcId'], 'mira-one');
      NpcIdentityMemory.requireCurrent(campaign, snapshot);
      expect(jsonEncode(campaign.toJson()), original);
    },
  );

  test(
    'selected NPC payload cannot be modified through exposed nested maps',
    () {
      final campaign = _campaign();
      final selected = NpcStorySelection.choose(campaign, 'mira-one');
      final payload = NpcIdentityStoryPayload.prepare(
        campaign,
        'Ich frage Mira nach der Seekarte.',
        selectedNpc: selected,
        maxNotes: 2,
      )!;

      expect(payload.npcContexts, hasLength(1));
      expect(payload.npcContexts.single['npcId'], 'mira-one');
      expect(payload.npcContexts.toString(), isNot(contains('Nordtor')));
      _expectDeepReadOnly(payload.npcContexts.single);
      expect(() => payload.npcContexts.clear(), throwsUnsupportedError);
      payload.requireCurrent(campaign);
    },
  );

  test(
    'confirmed NPC context survives SQLite restart but rejects stale edits',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp('npc-immutable-');
      final path = paths.join(directory.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final original = _campaign();
        await repository.saveCampaign(original);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );

        final loaded = (await repository.getCampaign(original.id))!;
        final savedBytes = jsonEncode(loaded.toJson());
        final snapshot = NpcIdentityMemory.read(
          loaded,
          npcId: 'mira-one',
          expectedRevision: loaded.revision,
          maxNotes: 2,
        );
        final selection = NpcStorySelection.choose(loaded, 'mira-one');
        final payload = NpcIdentityStoryPayload.prepare(
          loaded,
          'Ich spreche die erste Mira an.',
          selectedNpc: selection,
          maxNotes: 2,
        )!;

        _expectDeepReadOnly(snapshot.toContextMap());
        _expectDeepReadOnly(payload.npcContexts.single);
        NpcIdentityMemory.requireCurrent(loaded, snapshot);
        payload.requireCurrent(loaded);
        expect(loaded.hero.toJson(), original.hero.toJson());
        expect(jsonEncode(loaded.toJson()), savedBytes);

        final changed = loaded.copyWith(
          npcRelationshipNotes: [
            ...loaded.npcRelationshipNotes,
            NpcRelationshipNote(
              id: 'uncommitted-note',
              npcId: 'mira-one',
              relationship: 'misstrauisch',
              note: 'Eine fremde Geschichte.',
              recordedAt: DateTime.utc(2026, 10, 28),
            ),
          ],
        );
        expect(
          () => NpcIdentityMemory.requireCurrent(changed, snapshot),
          throwsFormatException,
        );
        expect(() => payload.requireCurrent(changed), throwsFormatException);
        expect(
          jsonEncode((await repository.getCampaign(original.id))!.toJson()),
          savedBytes,
        );
      } finally {
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
