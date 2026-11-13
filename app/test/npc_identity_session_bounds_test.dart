import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_memory.dart';

Campaign _campaign({
  String sessionId = 'session-verified',
  int revision = 4,
}) => Campaign(
  id: 'identity-session-bounds',
  name: 'Der Weg zum Turm',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Ein unbestätigter Erzählerbericht.',
  npcs: const [WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich')],
  npcRelationshipNotes: [
    NpcRelationshipNote(
      id: 'note-1',
      npcId: 'mira',
      relationship: 'freundlich',
      note: 'Mira kennt den Weg zum Turm.',
      recordedAt: DateTime.utc(2026, 11, 13),
    ),
  ],
);

NpcIdentityContext _read(Campaign campaign) => NpcIdentityMemory.read(
  campaign,
  npcId: 'mira',
  expectedRevision: campaign.revision,
);

void main() {
  test('confirmed NPC context requires a nonblank saved session identity', () {
    for (final sessionId in ['', ' ', '\t\n', '\u2003']) {
      final campaign = _campaign(sessionId: sessionId);
      final original = jsonEncode(campaign.toJson());

      expect(() => _read(campaign), throwsFormatException);
      expect(jsonEncode(campaign.toJson()), original);
      expect(campaign.hero.hitPoints, 17);
    }
  });

  test(
    'valid session still supports JSON restart and a stale-session guard',
    () {
      final original = _campaign();
      final originalJson = jsonEncode(original.toJson());
      final restored = Campaign.fromJson(
        jsonDecode(originalJson) as Map<String, dynamic>,
      );
      final snapshot = _read(restored);
      final context = snapshot.toContextMap();

      expect(snapshot.sessionId, 'session-verified');
      expect(context['npcId'], 'mira');
      expect(context['notes'], hasLength(1));
      expect(context.toString(), contains('Weg zum Turm'));
      NpcIdentityMemory.requireCurrent(restored, snapshot);
      final changedSession = Campaign.fromJson({
        ...restored.toJson(),
        'sessionId': 'session-new',
      });
      expect(
        () => NpcIdentityMemory.requireCurrent(changedSession, snapshot),
        throwsFormatException,
      );
      expect(jsonEncode(restored.toJson()), originalJson);
    },
  );

  test('unbounded revisions never create confirmed NPC identity contexts', () {
    for (final invalidRevision in [-1, 2147483648]) {
      final campaign = _campaign(revision: invalidRevision);
      final before = jsonEncode(campaign.toJson());

      expect(() => _read(campaign), throwsFormatException);
      expect(jsonEncode(campaign.toJson()), before);
    }

    final atBoundary = _campaign(revision: 2147483647);
    final context = _read(atBoundary);
    expect(context.revision, 2147483647);
    NpcIdentityMemory.requireCurrent(atBoundary, context);
    expect(atBoundary.hero.hitPoints, 17);
  });
}
