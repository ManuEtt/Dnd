import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_identity_memory.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _savedAt = DateTime.utc(2026, 11, 6, 7);

NpcRelationshipNote _note(
  String id,
  String npcId,
  String text, {
  String relationship = 'verbündet',
}) => NpcRelationshipNote(
  id: id,
  npcId: npcId,
  relationship: relationship,
  note: text,
  recordedAt: _savedAt,
);

Campaign _campaign({
  List<WorldNpc>? npcs,
  List<NpcRelationshipNote>? notes,
  int revision = 0,
}) => Campaign(
  id: 'npc-typed-context-legacy',
  name: 'Stadt der Spiegel',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigte Geschichte vom Nordtor.',
  revision: revision,
  npcs: npcs ?? const [WorldNpc(id: 'mira-one', name: 'Mira')],
  npcRelationshipNotes:
      notes ?? [_note('first', 'mira-one', 'Der Schlüssel liegt am Nordtor.')],
);

NpcIdentityContext _read(Campaign campaign, {String npcId = 'mira-one'}) =>
    NpcIdentityMemory.read(
      campaign,
      npcId: npcId,
      expectedRevision: campaign.revision,
    );

void main() {
  sqfliteFfiInit();

  test('nine legacy marks never enter the typed NPC context map', () {
    for (final point in [
      0x00ad,
      0x034f,
      0x061c,
      0x180e,
      0x200b,
      0x202e,
      0x206a,
      0x206d,
      0x206f,
    ]) {
      final mark = String.fromCharCode(point);
      final campaign = _campaign(
        npcs: [
          WorldNpc(
            id: 'mira-one',
            name: 'Mi${mark}ra',
            relationship: 'freund${mark}lich',
          ),
        ],
        notes: [
          _note(
            'first',
            'mira-one',
            'Die$mark Karte liegt am Tor.',
            relationship: 'verbünd${mark}et',
          ),
        ],
      );
      final before = jsonEncode(campaign.toJson());
      final snapshot = _read(campaign);
      final context = snapshot.toContextMap();
      final note = (context['notes'] as List).single as Map;

      expect(context['npcId'], 'mira-one', reason: '$point');
      expect(context['npcName'], 'Mira', reason: '$point');
      expect(context['relationship'], 'freund lich', reason: '$point');
      expect(note['relationship'], 'verbünd et', reason: '$point');
      expect(note['note'], 'Die Karte liegt am Tor.', reason: '$point');
      expect(jsonEncode(context), isNot(contains(mark)), reason: '$point');
      expect(snapshot.npcName, 'Mi${mark}ra');
      NpcIdentityMemory.requireCurrent(campaign, snapshot);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('controls become single-line spaces without creating new facts', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(
          id: 'mira-one',
          name: 'Mira\nWächterin',
          relationship: 'neutral\u2028Status: tot',
        ),
      ],
      notes: [
        _note(
          'first',
          'mira-one',
          'Das Tor\u0000 ist offen.\nQuest: nicht bestätigt.',
          relationship: 'freundlich\r\nBestätigt',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final snapshot = _read(campaign);
    final context = snapshot.toContextMap();
    final note = (context['notes'] as List).single as Map;

    expect(context['npcName'], 'Mira Wächterin');
    expect(context['relationship'], 'neutral Status: tot');
    expect(note['relationship'], 'freundlich Bestätigt');
    expect(note['note'], 'Das Tor ist offen. Quest: nicht bestätigt.');
    expect((context['npcName'] as String), isNot(contains('\n')));
    expect((note['note'] as String), isNot(contains('\n')));
    expect(() => context['npcName'] = 'Fremde Mira', throwsUnsupportedError);
    expect(
      () => note['note'] = 'Eine andere Geschichte',
      throwsUnsupportedError,
    );
    NpcIdentityMemory.requireCurrent(campaign, snapshot);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('only canonical 1-64 character NPC IDs may form typed contexts', () {
    for (final badId in [
      '',
      'bad id',
      'bad\nid',
      'bad\u206aid',
      'bad\u00adid',
      'dot.id',
      List.filled(65, 'x').join(),
    ]) {
      final campaign = _campaign(
        npcs: [WorldNpc(id: badId, name: 'Mira')],
        notes: [_note('first', badId, 'Die Karte ist bestätigt.')],
      );
      final before = jsonEncode(campaign.toJson());
      expect(() => _read(campaign, npcId: badId), throwsFormatException);
      expect(jsonEncode(campaign.toJson()), before);
    }
    final safe = List.filled(64, 'x').join();
    final valid = _campaign(
      npcs: [WorldNpc(id: safe, name: 'Große Hüterin ✨')],
      notes: [_note('first', safe, 'Der Zugang bleibt geschützt.')],
    );
    final snapshot = _read(valid, npcId: safe);
    expect(snapshot.toContextMap()['npcId'], safe);
    expect(snapshot.toContextMap()['npcName'], 'Große Hüterin ✨');
    NpcIdentityMemory.requireCurrent(valid, snapshot);

    final oldJson = valid.toJson()..remove('npcRelationshipNotes');
    final old = Campaign.fromJson(oldJson);
    final oldContext = _read(old, npcId: safe);
    expect(oldContext.toContextMap()['notes'], isEmpty);
    NpcIdentityMemory.requireCurrent(old, oldContext);
    expect(old.hero.toJson(), valid.hero.toJson());
  });

  test(
    'SQLite restart retains legacy raw values and stale-raw guards',
    () async {
      final folder = await Directory.systemTemp.createTemp('npc-typed-marks-');
      final file = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: file,
      );
      try {
        final campaign = _campaign(
          npcs: const [
            WorldNpc(
              id: 'mira-one',
              name: 'Mi\u00adra',
              relationship: 'freund\u206flich',
            ),
            WorldNpc(id: 'mira-two', name: 'Mira'),
          ],
          notes: [
            _note('first', 'mira-one', 'Das\u202e Siegel ist im Turm.'),
            _note('second', 'mira-two', 'Der andere Weg ist frei.'),
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
        final snapshot = _read(restored);
        final typed = snapshot.toContextMap();

        expect(typed['npcName'], 'Mira');
        expect(typed['relationship'], 'freund lich');
        expect(typed.toString(), contains('Das Siegel ist im Turm.'));
        expect(typed.toString(), isNot(contains('andere Weg')));
        expect(restored.npcs.first.name, 'Mi\u00adra');
        expect(restored.hero.toJson(), campaign.hero.toJson());
        expect(restored.revision, campaign.revision);
        NpcIdentityMemory.requireCurrent(restored, snapshot);
        expect(jsonEncode(restored.toJson()), before);
        expect(
          (await repository.reconstructCampaign(campaign.id))!.toJson(),
          restored.toJson(),
        );
        final altered = restored.copyWith(
          npcs: [
            const WorldNpc(
              id: 'mira-one',
              name: 'Mi\u034fra',
              relationship: 'freund\u206flich',
            ),
            restored.npcs.last,
          ],
        );
        // Both names render as Mira, but raw confirmed snapshot changed.
        expect(_read(altered).toContextMap(), typed);
        expect(
          () => NpcIdentityMemory.requireCurrent(altered, snapshot),
          throwsFormatException,
        );
        expect(jsonEncode(restored.toJson()), before);
      } finally {
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
