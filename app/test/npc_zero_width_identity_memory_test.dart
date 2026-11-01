import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_narrator_memory.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _now = DateTime.utc(2026, 11, 1);

NpcRelationshipNote _note(String id, String npcId, String text) =>
    NpcRelationshipNote(
      id: id,
      npcId: npcId,
      relationship: 'freundlich',
      note: text,
      recordedAt: _now,
    );

Campaign _campaign({
  List<WorldNpc>? npcs,
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'zero-width-npc',
  name: 'Die Stadt der Spiegel',
  world: 'Valdorn',
  sessionId: 'session-two',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 14),
  scene: 'Die KI behauptet, Mira kenne den geheimen Schatz.',
  npcs: npcs ?? const [WorldNpc(id: 'mira', name: 'Mira')],
  npcRelationshipNotes: notes,
);

void main() {
  sqfliteFfiInit();

  test('zero-width lookalikes never authorize one NPC by visible name', () {
    final markers = [
      '\u200b', // zero-width space
      '\u200c', // zero-width non-joiner
      '\u200d', // zero-width joiner
      '\u2060', // word joiner
      '\ufeff', // zero-width no-break space / BOM
    ];

    for (final marker in markers) {
      final campaign = _campaign(
        npcs: [
          const WorldNpc(id: 'mira-original', name: 'Mira'),
          WorldNpc(id: 'mira-hidden', name: 'Mi${marker}ra'),
        ],
        notes: [
          _note(
            'original',
            'mira-original',
            'Nur die erste Mira kennt das Tor.',
          ),
          _note('hidden', 'mira-hidden', 'Nur die zweite Mira kennt den Turm.'),
        ],
      );
      final before = jsonEncode(campaign.toJson());

      for (final action in [
        'Ich spreche mit Mira.',
        'Ich spreche mit Mi${marker}ra.',
      ]) {
        final context = NpcNarratorMemory.merge(campaign, action, [
          'Der Hafen ist bestätigt.',
        ]);
        expect(context, ['Der Hafen ist bestätigt.']);
      }
      expect(jsonEncode(campaign.toJson()), before);
      expect(campaign.hero.hitPoints, 14);
    }
  });

  test('unique legacy name remains selectable without invisible glyphs', () {
    final campaign = _campaign(
      npcs: const [WorldNpc(id: 'mira', name: 'Mi\u200bra')],
      notes: [
        _note('mira-note', 'mira', 'Der\u2060 Schlüssel\u200b liegt im Turm.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = NpcNarratorMemory.merge(
      campaign,
      'Ich frage Mira nach dem Schlüssel.',
      [],
    );

    expect(selected, hasLength(1));
    expect(selected.single, contains('Bestätigte NPC-Beziehungsnotiz zu Mira'));
    expect(selected.single, contains('Der Schlüssel liegt im Turm.'));
    expect(selected.single, isNot(contains('\u200b')));
    expect(selected.single, isNot(contains('\u2060')));
    expect(jsonEncode(campaign.toJson()), before);
    expect(() => selected.add('Erfundener Fakt'), throwsUnsupportedError);
  });

  test('legacy JSON with no confirmed notes invents no history', () {
    final oldJson = _campaign(
      npcs: const [WorldNpc(id: 'mira', name: 'Mi\u200dra')],
    ).toJson()..remove('npcRelationshipNotes');
    final loaded = Campaign.fromJson(oldJson);
    final before = jsonEncode(loaded.toJson());

    expect(NpcNarratorMemory.merge(loaded, 'Ich frage Mira.', []), isEmpty);
    expect(loaded.npcRelationshipNotes, isEmpty);
    expect(jsonEncode(loaded.toJson()), before);
  });

  test(
    'SQLite restart keeps zero-width identities distinct and read-only',
    () async {
      final folder = await Directory.systemTemp.createTemp('npc-name-fold-');
      final path = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final campaign = _campaign(
          npcs: const [
            WorldNpc(id: 'first', name: 'Mira'),
            WorldNpc(id: 'second', name: 'Mi\u200bra'),
            WorldNpc(id: 'tarek', name: 'Tarek'),
          ],
          notes: [
            _note('a', 'first', 'Die erste Mira kennt die Karte.'),
            _note('b', 'second', 'Die zweite Mira bewacht das Archiv.'),
            _note('c', 'tarek', 'Tarek kennt den verborgenen Kai.'),
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
        final ambiguous = NpcNarratorMemory.merge(restored, 'Ich frage Mira.', [
          'Bestätigter allgemeiner Fakt',
        ]);
        final distinct = NpcNarratorMemory.merge(
          restored,
          'Ich frage Tarek.',
          [],
        );

        expect(ambiguous, ['Bestätigter allgemeiner Fakt']);
        expect(distinct, hasLength(1));
        expect(distinct.single, contains('verborgenen Kai'));
        expect(distinct.single, isNot(contains('Archiv')));
        expect(jsonEncode(restored.toJson()), before);
        expect(restored.revision, 0);
        expect(restored.hero.toJson(), campaign.hero.toJson());
        expect(
          (await repository.reconstructCampaign(campaign.id))!.toJson(),
          restored.toJson(),
        );
      } finally {
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
