import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _now = DateTime.utc(2026, 11, 5);

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
  recordedAt: _now,
);

Campaign _campaign({
  required List<WorldNpc> npcs,
  List<NpcRelationshipNote>? notes,
}) => Campaign(
  id: 'structured-npc-legacy',
  name: 'Spiegelstadt',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Eine unbestätigte Erzählung über Mira.',
  revision: 3,
  npcs: npcs,
  npcRelationshipNotes:
      notes ?? [_note('first', 'mira-a', 'Mira kennt das Nordtor.')],
);

void main() {
  sqfliteFfiInit();

  test('nine legacy hidden markers never disambiguate identical NPCs', () {
    const codePoints = [
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
    for (final point in codePoints) {
      final mark = String.fromCharCode(point);
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira-a', name: 'Mira'),
          WorldNpc(id: 'mira-b', name: 'Mi${mark}ra'),
        ],
        notes: [
          _note('north', 'mira-a', 'Nur die erste Mira kennt das Nordtor.'),
          _note('south', 'mira-b', 'Nur die zweite Mira kennt das Südtor.'),
        ],
      );
      final original = jsonEncode(campaign.toJson());

      expect(
        NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira.'),
        isNull,
      );
      expect(
        NpcIdentityStoryPayload.prepare(
          campaign,
          'Ich frage Mi${mark}ra.',
        ),
        isNull,
      );
      // Explicitly selecting the clean stored identity is still permitted.
      final safe = NpcStorySelection.choose(campaign, 'mira-a');
      final payload = NpcIdentityStoryPayload.prepare(
        campaign,
        'Ich frage Mira.',
        selectedNpc: safe,
      )!;
      expect(payload.selectedNpcId, 'mira-a');
      expect(payload.npcContexts.single['npcId'], 'mira-a');
      expect(payload.npcContexts.toString(), contains('Nordtor'));
      expect(payload.npcContexts.toString(), isNot(contains('Südtor')));
      payload.requireCurrent(campaign);

      // Explicit selection cannot send unsafe legacy provider text.
      final unsafe = NpcStorySelection.choose(campaign, 'mira-b');
      expect(
        NpcIdentityStoryPayload.prepare(
          campaign,
          'Ich frage Mira.',
          selectedNpc: unsafe,
        ),
        isNull,
      );
      expect(jsonEncode(campaign.toJson()), original);
    }
  });

  test('structured name, relationship and notes reject hidden formats', () {
    for (final point in [
      0x00ad,
      0x034f,
      0x180e,
      0x206a,
      0x206b,
      0x206c,
      0x206d,
      0x206e,
      0x206f,
    ]) {
      final mark = String.fromCharCode(point);
      final cases = [
        _campaign(
          npcs: [WorldNpc(id: 'mira-a', name: 'Mi${mark}ra')],
        ),
        _campaign(
          npcs: [
            WorldNpc(
              id: 'mira-a',
              name: 'Mira',
              relationship: 'freund${mark}lich',
            ),
          ],
        ),
        _campaign(
          npcs: const [WorldNpc(id: 'mira-a', name: 'Mira')],
          notes: [
            _note('first', 'mira-a', 'Das${mark} geheime Tor.'),
          ],
        ),
        _campaign(
          npcs: const [WorldNpc(id: 'mira-a', name: 'Mira')],
          notes: [
            _note(
              'first',
              'mira-a',
              'Das geheime Tor.',
              relationship: 'freund${mark}lich',
            ),
          ],
        ),
      ];
      for (final campaign in cases) {
        final before = jsonEncode(campaign.toJson());
        expect(
          NpcIdentityStoryPayload.prepare(campaign, 'Ich frage Mira.'),
          isNull,
        );
        final selection = NpcStorySelection.choose(campaign, 'mira-a');
        expect(
          NpcIdentityStoryPayload.prepare(
            campaign,
            'Ich frage Mira.',
            selectedNpc: selection,
          ),
          isNull,
        );
        expect(jsonEncode(campaign.toJson()), before);
      }
    }
  });

  test('valid German names and old JSON remain revision-bound', () {
    final initial = _campaign(
      npcs: const [
        WorldNpc(
          id: 'keeper',
          name: 'Große Hüterin ✨',
          relationship: 'verbündet',
        ),
      ],
      notes: [_note('keeper-note', 'keeper', 'Das Südtor ist geöffnet.')],
    );
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(initial.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    final payload = NpcIdentityStoryPayload.prepare(
      restored,
      'Ich frage die GROSSE HUETERIN ✨ nach dem Tor.',
    )!;

    expect(payload.npcContexts, hasLength(1));
    expect(payload.npcContexts.single['npcId'], 'keeper');
    expect(payload.npcContexts.single['npcName'], 'Große Hüterin ✨');
    expect(payload.npcContexts.toString(), contains('Südtor'));
    payload.requireCurrent(restored);
    expect(
      () => payload.requireCurrent(restored.copyWith(revision: 4)),
      throwsFormatException,
    );
    final changed = restored.copyWith(
      npcRelationshipNotes: [
        _note('keeper-note', 'keeper', 'Ein anderer, unbestätigter Weg.'),
      ],
    );
    expect(() => payload.requireCurrent(changed), throwsFormatException);
    expect(jsonEncode(restored.toJson()), before);

    final oldJson = initial.toJson()..remove('npcRelationshipNotes');
    final old = Campaign.fromJson(oldJson);
    expect(
      NpcIdentityStoryPayload.prepare(old, 'Ich frage die Hüterin.'),
      isNull,
    );
    expect(old.npcRelationshipNotes, isEmpty);
  });

  test('SQLite restart retains raw marks and authoritative selection', () async {
    final folder = await Directory.systemTemp.createTemp('npc-structured-');
    final file = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: file,
    );
    try {
      final campaign = _campaign(
        npcs: const [
          WorldNpc(id: 'mira-a', name: 'Mira'),
          WorldNpc(id: 'mira-b', name: 'Mi\u00adra'),
        ],
        notes: [
          _note('north', 'mira-a', 'Nur Mira Eins kennt den Weg.'),
          _note('south', 'mira-b', 'Nur Mira Zwei kennt das Tor.'),
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
      expect(
        NpcIdentityStoryPayload.prepare(restored, 'Ich frage Mira.'),
        isNull,
      );
      final choice = NpcStorySelection.choose(restored, 'mira-a');
      final selected = NpcIdentityStoryPayload.prepare(
        restored,
        'Ich frage Mira.',
        selectedNpc: choice,
      )!;
      expect(selected.npcContexts.single['npcId'], 'mira-a');
      expect(selected.npcContexts.toString(), contains('Mira Eins'));
      expect(selected.npcContexts.toString(), isNot(contains('Mira Zwei')));
      selected.requireCurrent(restored);
      final badChoice = NpcStorySelection.choose(restored, 'mira-b');
      expect(
        NpcIdentityStoryPayload.prepare(
          restored,
          'Ich frage Mira.',
          selectedNpc: badChoice,
        ),
        isNull,
      );
      expect(restored.npcs.last.name, 'Mi\u00adra');
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
  });
}
