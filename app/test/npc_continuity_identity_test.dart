import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_api.dart';

Campaign _campaign({
  required List<WorldNpc> npcs,
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'continuity-ids',
  name: 'Stadt der Spiegel',
  world: 'Valdorn',
  sessionId: 'second-session',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 17,
    maxHitPoints: 20,
  ),
  scene: 'Eine unbestätigte Erzählung',
  revision: 3,
  npcs: npcs,
  npcRelationshipNotes: notes,
);

NpcRelationshipNote _note(String id, String npcId, String text) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'freundlich',
      note: text,
      recordedAt: DateTime.utc(2026, 10, 28),
    );

void main() {
  test('same-name NPC continuity uses confirmed IDs after JSON restore', () {
    final original = _campaign(
      npcs: const [
        WorldNpc(id: 'mira-a', name: 'Mira', relationship: 'freundlich'),
        WorldNpc(id: 'mira-b', name: 'Mira', relationship: 'misstrauisch'),
      ],
      notes: [
        _note('note-a', 'mira-a', 'Die erste Mira kennt die Karte.'),
        _note('note-b', 'mira-b', 'Die zweite Mira bewacht das Tor.'),
      ],
    );
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());

    final a = NpcContinuityReader.read(restored, npcId: 'mira-a');
    final b = NpcContinuityReader.read(restored, npcId: 'mira-b');
    expect(a.disambiguateName, isTrue);
    expect(b.disambiguateName, isTrue);
    expect(a.confirmedContext, startsWith('NPC: Mira (NPC-ID: mira-a)'));
    expect(b.confirmedContext, startsWith('NPC: Mira (NPC-ID: mira-b)'));
    expect(a.confirmedContext, contains('erste Mira'));
    expect(a.confirmedContext, isNot(contains('zweite Mira')));
    expect(b.confirmedContext, contains('zweite Mira'));
    expect(b.confirmedContext, isNot(contains('erste Mira')));
    expect(a.recentNotes.single.npcId, 'mira-a');
    expect(b.recentNotes.single.npcId, 'mira-b');
    expect(restored.hero.hitPoints, 17);
    expect(jsonEncode(restored.toJson()), before);
  });

  test('German case, umlauts and whitespace also disambiguate names', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(id: 'north', name: 'Große  Hüterin'),
        WorldNpc(id: 'south', name: 'GROSSE HUETERIN'),
      ],
    );
    final north = NpcContinuityReader.read(campaign, npcId: 'north');
    final south = NpcContinuityReader.read(campaign, npcId: 'south');

    expect(
      north.confirmedContext,
      startsWith('NPC: Große Hüterin (NPC-ID: north)'),
    );
    expect(
      south.confirmedContext,
      startsWith('NPC: GROSSE HUETERIN (NPC-ID: south)'),
    );
    expect(north.confirmedContext, contains('Keine bestätigten'));
  });

  test('unsafe IDs and duplicated stored IDs never give ambiguous context', () {
    final malformed = _campaign(
      npcs: const [
        WorldNpc(id: 'unsafe\nid', name: 'Mira'),
        WorldNpc(id: 'safe', name: 'Mira'),
      ],
    );
    expect(
      () => NpcContinuityReader.read(malformed, npcId: 'unsafe\nid'),
      throwsFormatException,
    );
    expect(
      NpcContinuityReader.read(malformed, npcId: 'safe').confirmedContext,
      startsWith('NPC: Mira (NPC-ID: safe)'),
    );

    final duplicates = _campaign(
      npcs: const [
        WorldNpc(id: 'same', name: 'Mira'),
        WorldNpc(id: 'same', name: 'Andere Mira'),
      ],
    );
    expect(
      () => NpcContinuityReader.read(duplicates, npcId: 'same'),
      throwsFormatException,
    );
  });

  test(
    'unique legacy name retains exact old context text and read-only data',
    () {
      final legacy = _campaign(
        npcs: const [
          WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
        ],
      ).toJson()..remove('npcRelationshipNotes');
      final recovered = Campaign.fromJson(legacy);
      final before = jsonEncode(recovered.toJson());

      final snapshot = NpcContinuityReader.read(recovered, npcId: 'mira');
      expect(snapshot.disambiguateName, isFalse);
      expect(
        snapshot.confirmedContext,
        'NPC: Mira\n'
        'Status: lebendig\n'
        'Aktuelle Beziehung: freundlich\n'
        'Keine bestätigten Beziehungsnotizen.',
      );
      expect(snapshot.recentNotes, isEmpty);
      expect(jsonEncode(recovered.toJson()), before);
      expect(
        () => snapshot.recentNotes.add(
          _note('invented', 'mira', 'Unbestätigtes Gerücht'),
        ),
        throwsUnsupportedError,
      );
    },
  );
}
