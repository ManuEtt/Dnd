import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

NpcRelationshipNote _note(
  String id,
  String npcId,
  String text, {
  String relationship = 'freundlich',
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: relationship,
  note: text,
  recordedAt: DateTime.utc(2026, 11, 2),
);

Campaign _campaign({
  List<WorldNpc> npcs = const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
  ],
  List<NpcRelationshipNote>? notes,
}) => Campaign(
  id: 'npc-story-zero-width',
  name: 'Das Stadttor',
  world: 'Valdorn',
  sessionId: 'session-2',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 14),
  scene: 'Die KI behauptet, Mira habe einen Schatz gefunden.',
  storyBible: const {'secret': 'Der König ist der Drache.'},
  npcs: npcs,
  npcRelationshipNotes:
      notes ?? [_note('mira-note', 'mira', 'Mira kennt den Hafen.')],
);

void main() {
  sqfliteFfiInit();

  test('invisible name duplicates never select a guessed NPC ID', () {
    const markers = ['\u200b', '\u200c', '\u200d', '\u2060', '\ufeff'];
    for (final marker in markers) {
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira', name: 'Mira'),
          WorldNpc(id: 'mira-hidden', name: 'Mi${marker}ra'),
        ],
        notes: [
          _note('one', 'mira', 'Mira besitzt die Karte.'),
          _note('two', 'mira-hidden', 'Die andere Mira besitzt das Buch.'),
        ],
      );
      final before = jsonEncode(campaign.toJson());
      for (final action in [
        'Ich frage Mira nach dem Buch.',
        'Ich frage Mi${marker}ra nach dem Buch.',
      ]) {
        expect(NpcIdentityStoryPayload.prepare(campaign, action), isNull);
      }
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('explicit safe ID can select one of two visually equal NPCs', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'other', name: 'Mi\u200bra'),
      ],
      notes: [
        _note('one', 'mira', 'Nur Mira kennt die Karte.'),
        _note('two', 'other', 'Andere Mira kennt das Geheimnis.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selection = NpcStorySelection.choose(campaign, 'mira');
    final result = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich spreche mit Mira.',
      selectedNpc: selection,
    );

    expect(result, isNotNull);
    expect(result!.selectedNpcId, 'mira');
    expect(result.npcContexts, hasLength(1));
    expect(result.npcContexts.single['npcId'], 'mira');
    final notes = result.npcContexts.single['notes'] as List;
    expect(notes, hasLength(1));
    expect((notes.single as Map)['note'], 'Nur Mira kennt die Karte.');
    result.requireCurrent(campaign);
    expect(
      () => result.requireCurrent(campaign.copyWith(revision: 1)),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('unsafe zero-width name or relationship is not sent to Story API', () {
    const markers = ['\u200b', '\u200c', '\u200d', '\u2060', '\ufeff'];
    for (final marker in markers) {
      final name = _campaign(
        npcs: [WorldNpc(id: 'mira', name: 'Mi${marker}ra')],
      );
      final relationship = _campaign(
        npcs: [
          WorldNpc(
            id: 'mira',
            name: 'Mira',
            relationship: 'freu${marker}ndlich',
          ),
        ],
      );

      expect(NpcIdentityStoryPayload.prepare(name, 'Ich frage Mira.'), isNull);
      expect(
        NpcIdentityStoryPayload.prepare(relationship, 'Ich frage Mira.'),
        isNull,
      );
    }
  });

  test('invisible markers in confirmed notes do not reach transport', () {
    const markers = ['\u200b', '\u200c', '\u200d', '\u2060', '\ufeff'];
    for (final marker in markers) {
      final note = _campaign(
        notes: [_note('hidden', 'mira', 'Die ${marker}e Karte ist echt.')],
      );
      final relation = _campaign(
        notes: [
          _note(
            'relation',
            'mira',
            'Das Tor ist bestätigt.',
            relationship: 'neutral$marker',
          ),
        ],
      );
      expect(NpcIdentityStoryPayload.prepare(note, 'Ich frage Mira.'), isNull);
      expect(
        NpcIdentityStoryPayload.prepare(relation, 'Ich frage Mira.'),
        isNull,
      );
    }
  });

  test('safe legacy JSON stays readable without inventing a note', () {
    final original = _campaign().toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(original);
    final before = jsonEncode(restored.toJson());

    expect(
      NpcIdentityStoryPayload.prepare(restored, 'Ich frage Mira.'),
      isNull,
    );
    expect(restored.npcRelationshipNotes, isEmpty);
    expect(jsonEncode(restored.toJson()), before);
  });

  test(
    'SQLite restart preserves rejection and safe selected context',
    () async {
      final folder = await Directory.systemTemp.createTemp('npc-wire-zero-');
      final path = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final campaign = _campaign(
          npcs: const [
            WorldNpc(id: 'mira', name: 'Mira'),
            WorldNpc(id: 'hidden', name: 'Mi\u2060ra'),
            WorldNpc(id: 'tarek', name: 'Tarek'),
          ],
          notes: [
            _note('one', 'mira', 'Mira kennt den Schlüssel.'),
            _note('two', 'hidden', 'Andere Mira kennt die Truhe.'),
            _note('three', 'tarek', 'Tarek öffnet die Tür.'),
          ],
        );
        await repository.saveCampaign(campaign);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );

        final restored = (await repository.getCampaign(campaign.id))!;
        final before = jsonEncode(restored.toJson());
        expect(
          NpcIdentityStoryPayload.prepare(restored, 'Ich frage Mira.'),
          isNull,
        );
        final safe = NpcIdentityStoryPayload.prepare(
          restored,
          'Ich frage Tarek.',
        );
        expect(safe, isNotNull);
        expect(safe!.npcContexts.single['npcId'], 'tarek');
        safe.requireCurrent(restored);
        expect(restored.hero.toJson(), campaign.hero.toJson());
        expect(restored.revision, 0);
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
