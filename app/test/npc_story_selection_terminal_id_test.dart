import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_story_payload.dart';
import 'package:lebendiger_spielleiter/story/npc_story_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _time = DateTime.utc(2026, 11, 6, 9);

NpcRelationshipNote _note(String id, String npcId, String text) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'freundlich',
      note: text,
      recordedAt: _time,
    );

Campaign _campaign({
  String sessionId = 'session-two',
  List<WorldNpc> npcs = const [],
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'npc-identity-newline',
  name: 'Die Chronik von Valdorn',
  world: 'Valdorn',
  sessionId: sessionId,
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 16),
  scene: 'Unbestätigt: Ein Erzähler schenkt 999 Gold.',
  npcs: npcs,
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('line breaks and controls never become explicitly selected IDs', () {
    const unsafeIds = [
      'mira\n',
      'mira\r',
      'mira\r\n',
      'mira\u2028',
      'mira\u2029',
      'mira\u200b',
      'mira ',
      ' mira',
    ];
    final campaign = _campaign(
      npcs: [
        const WorldNpc(id: 'mira', name: 'Mira'),
        for (final id in unsafeIds) WorldNpc(id: id, name: 'Mira'),
      ],
    );
    final before = jsonEncode(campaign.toJson());

    for (final id in unsafeIds) {
      expect(
        () => NpcStorySelection.choose(campaign, id),
        throwsFormatException,
      );
    }
    final safe = NpcStorySelection.choose(campaign, 'mira');
    expect(safe.npcId, 'mira');
    safe.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('blank or whitespace-only session never authorizes an NPC pick', () {
    for (final session in ['', '   ', '\n\t']) {
      final campaign = _campaign(
        sessionId: session,
        npcs: const [WorldNpc(id: 'mira', name: 'Mira')],
      );
      final original = jsonEncode(campaign.toJson());

      expect(
        () => NpcStorySelection.choose(campaign, 'mira'),
        throwsFormatException,
      );
      expect(jsonEncode(campaign.toJson()), original);
    }

    final valid = _campaign(npcs: const [WorldNpc(id: 'mira', name: 'Mira')]);
    expect(NpcStorySelection.choose(valid, 'mira').sessionId, 'session-two');
  });

  test('legacy JSON retains raw IDs but cannot select trailing newline', () {
    final original = _campaign(
      npcs: const [
        WorldNpc(id: 'mira\n', name: 'Mira'),
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'tarek', name: 'Tarek'),
      ],
      notes: [_note('safe-note', 'mira', 'Mira kennt den Schlüssel.')],
    );
    final raw = jsonEncode(original.toJson());
    final restored = Campaign.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(restored.npcs.first.id, 'mira\n');
    expect(
      () => NpcStorySelection.choose(restored, 'mira\n'),
      throwsFormatException,
    );
    final selected = NpcStorySelection.choose(restored, 'mira');
    final payload = NpcIdentityStoryPayload.prepare(
      restored,
      'Ich frage Mira nach dem Schlüssel.',
      selectedNpc: selected,
    );

    expect(payload, isNotNull);
    expect(payload!.selectedNpcId, 'mira');
    expect(payload.npcContexts.single['npcId'], 'mira');
    expect(payload.npcContexts.toString(), contains('kennt den Schlüssel'));
    payload.requireCurrent(restored);
    expect(restored.hero.hitPoints, 16);
    expect(jsonEncode(restored.toJson()), raw);
  });

  test('same-name NPCs remain distinct and stale picks fail closed', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-two', name: 'Mira', relationship: 'misstrauisch'),
      ],
      notes: [
        _note('note-first', 'mira-one', 'Nur die erste Mira kennt den Turm.'),
        _note('note-second', 'mira-two', 'Nur die zweite Mira hat die Karte.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final choice = NpcStorySelection.choose(campaign, 'mira-two');
    final payload = NpcIdentityStoryPayload.prepare(
      campaign,
      'Ich frage Mira nach der Karte.',
      selectedNpc: choice,
    )!;

    expect(choice.npcId, 'mira-two');
    expect(payload.npcContexts, hasLength(1));
    expect(payload.npcContexts.single['npcId'], 'mira-two');
    expect(payload.npcContexts.toString(), contains('zweite Mira'));
    expect(payload.npcContexts.toString(), isNot(contains('erste Mira')));
    choice.requireCurrent(campaign);
    payload.requireCurrent(campaign);

    expect(
      () => choice.requireCurrent(campaign.copyWith(revision: 1)),
      throwsFormatException,
    );
    final changed = campaign.copyWith(
      npcs: const [
        WorldNpc(id: 'mira-one', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-two', name: 'Mira', relationship: 'feindlich'),
      ],
    );
    expect(() => choice.requireCurrent(changed), throwsFormatException);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('SQLite restart preserves raw legacy ID and valid selection', () async {
    final dir = await Directory.systemTemp.createTemp('npc-id-terminal-');
    final dbPath = paths.join(dir.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: dbPath,
    );
    try {
      final original = _campaign(
        npcs: const [
          WorldNpc(id: 'mira\n', name: 'Mira'),
          WorldNpc(id: 'mira', name: 'Mira'),
        ],
        notes: [_note('safe-note', 'mira', 'Mira kennt den Weg.')],
      );
      final raw = jsonEncode(original.toJson());
      await repository.saveCampaign(original);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      final restored = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(restored.toJson());

      expect(
        () => NpcStorySelection.choose(restored, 'mira\n'),
        throwsFormatException,
      );
      final selected = NpcStorySelection.choose(restored, 'mira');
      final payload = NpcIdentityStoryPayload.prepare(
        restored,
        'Ich frage Mira nach dem Weg.',
        selectedNpc: selected,
      )!;
      expect(payload.selectedNpcId, 'mira');
      expect(payload.npcContexts.single['npcId'], 'mira');
      expect(payload.npcContexts.toString(), contains('kennt den Weg'));
      selected.requireCurrent(restored);
      payload.requireCurrent(restored);
      expect(restored.hero.toJson(), original.hero.toJson());
      expect(restored.npcs.first.id, 'mira\n');
      expect(jsonEncode(restored.toJson()), raw);
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(original.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await dir.delete(recursive: true);
    }
  });
}
