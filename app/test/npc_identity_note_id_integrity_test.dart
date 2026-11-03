import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_memory.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _now = DateTime.utc(2026, 11, 3, 9);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String description, {
  int daysAgo = 0,
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: 'freundlich',
  note: description,
  recordedAt: _now.subtract(Duration(days: daysAgo)),
);

Campaign _campaign({
  List<NpcRelationshipNote> notes = const [],
  int revision = 3,
}) => Campaign(
  id: 'npc-note-integrity',
  name: 'Der verlorene Pfad',
  world: 'Valdorn',
  sessionId: 'session-a',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 14),
  scene: 'Der geheime Wald',
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
    WorldNpc(id: 'tarek', name: 'Tarek', relationship: 'neutral'),
  ],
  npcRelationshipNotes: notes,
  revision: revision,
);

NpcIdentityContext _read(Campaign campaign, {int maxNotes = 1}) =>
    NpcIdentityMemory.read(
      campaign,
      npcId: 'mira',
      expectedRevision: campaign.revision,
      maxNotes: maxNotes,
    );

void main() {
  sqfliteFfiInit();

  test('duplicate legacy note IDs are rejected even behind preview limit', () {
    final raw = _campaign(
      notes: [
        _note('shared', 'mira', 'Der aktuelle Weg.'),
        _note('older', 'mira', 'Ein Zwischenziel.', daysAgo: 1),
        _note('shared', 'mira', 'Alte widersprüchliche Notiz.', daysAgo: 20),
      ],
    ).toJson();
    final originalJson = jsonEncode(raw);
    final restored = Campaign.fromJson(
      jsonDecode(originalJson) as Map<String, dynamic>,
    );

    expect(() => _read(restored, maxNotes: 1), throwsFormatException);
    expect(() => _read(restored, maxNotes: 3), throwsFormatException);
    expect(jsonEncode(restored.toJson()), originalJson);
    expect(restored.hero.hitPoints, 14);
    expect(restored.revision, 3);
  });

  test('malformed IDs in hidden history fail closed without data changes', () {
    final invalidIds = [
      '',
      'white space',
      'newline\nid',
      'invisible\u200bid',
      'reverse\u202eid',
      'x' * 65,
    ];
    for (final badId in invalidIds) {
      final campaign = _campaign(
        notes: [
          _note('fresh', 'mira', 'Mira kennt das Ziel.'),
          _note(badId, 'mira', 'Eine alte unklare Erinnerung.', daysAgo: 12),
        ],
      );
      final before = jsonEncode(campaign.toJson());
      expect(() => _read(campaign), throwsFormatException, reason: badId);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('a stale same-revision snapshot rejects newly duplicated history', () {
    final original = _campaign(
      notes: [
        _note('one', 'mira', 'Der Weg beginnt am Brunnen.'),
        _note('two', 'mira', 'Mira kennt den Geheimgang.', daysAgo: 3),
      ],
    );
    final before = jsonEncode(original.toJson());
    final selected = _read(original);
    expect(selected.notes.single.id, 'one');
    NpcIdentityMemory.requireCurrent(original, selected);

    final altered = original.copyWith(
      npcRelationshipNotes: [
        ...original.npcRelationshipNotes,
        _note('one', 'mira', 'Uneindeutige ältere Kopie.', daysAgo: 30),
      ],
    );
    expect(altered.revision, selected.revision);
    expect(
      () => NpcIdentityMemory.requireCurrent(altered, selected),
      throwsFormatException,
    );
    expect(jsonEncode(original.toJson()), before);
  });

  test('unrelated NPC note identities stay independent', () {
    final campaign = _campaign(
      notes: [
        _note('shared', 'mira', 'Mira kennt den Weg.'),
        _note('shared', 'tarek', 'Tarek bewacht das Tor.'),
        _note('shared', 'tarek', 'Zweite Tarek-Notiz.', daysAgo: 1),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selection = _read(campaign);
    expect(selection.notes.single.note, contains('Mira kennt'));
    expect(selection.toContextMap().toString(), isNot(contains('Tor')));
    NpcIdentityMemory.requireCurrent(campaign, selection);
    expect(
      () => NpcIdentityMemory.read(
        campaign,
        npcId: 'tarek',
        expectedRevision: 3,
      ),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('legacy records survive SQLite restart, invalid identity is not sent', () async {
    final directory = await Directory.systemTemp.createTemp('npc-id-');
    final dbPath = paths.join(directory.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: dbPath,
    );
    try {
      final original = _campaign(
        revision: 0,
        notes: [
          _note('same', 'mira', 'Neue Notiz.'),
          _note('same', 'mira', 'Alte Notiz.', daysAgo: 4),
        ],
      );
      await repository.saveCampaign(original);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      final saved = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(saved.toJson());
      expect(saved.npcRelationshipNotes, hasLength(2));
      expect(() => _read(saved), throwsFormatException);
      expect(saved.hero.toJson(), original.hero.toJson());
      expect(saved.revision, 0);
      expect(jsonEncode(saved.toJson()), before);
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });

  test('valid stable IDs work after JSON restore with hidden unique notes', () {
    final original = _campaign(
      notes: [
        _note('new', 'mira', 'Die Brücke ist offen.'),
        _note('old', 'mira', 'Der Tunnel ist geschlossen.', daysAgo: 2),
        _note('foreign', 'tarek', 'Tarek bleibt in der Stadt.'),
      ],
    );
    final saved = jsonEncode(original.toJson());
    final restored = Campaign.fromJson(
      jsonDecode(saved) as Map<String, dynamic>,
    );
    final context = _read(restored);
    expect(context.notes.single.id, 'new');
    expect(context.toContextMap().toString(), isNot(contains('Tunnel')));
    NpcIdentityMemory.requireCurrent(restored, context);
    expect(restored.toJson(), original.toJson());
  });
}
