import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/npc_continuity_reader.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _now = DateTime.utc(2026, 11, 13);

NpcRelationshipNote _note(String text) => NpcRelationshipNote(
  id: 'note-one',
  npcId: 'mira',
  relationship: 'vorsichtig',
  note: text,
  recordedAt: _now,
);

Campaign _campaign({
  List<WorldNpc>? npcs,
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'bounded-npc-context',
  name: 'Der Nebelhafen',
  world: 'Valdorn',
  sessionId: 'session-one',
  revision: 0,
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Eine unbestätigte Szene über gestohlenes Gold.',
  npcs:
      npcs ??
      const [WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich')],
  npcRelationshipNotes: notes,
);

String _after(String text, String marker) =>
    text.split(marker).last.split('\n').first;

void main() {
  sqfliteFfiInit();

  test('oversized old memory is bounded only in its visible projection', () {
    final name = 'Mira ${'Hüterin ' * 100}';
    final relationship = 'verbündet ' * 200;
    final note = '🐉' * 700;
    final campaign = _campaign(
      npcs: [WorldNpc(id: 'mira', name: name, relationship: relationship)],
      notes: [_note(note)],
    );
    final savedBefore = jsonEncode(campaign.toJson());
    final snapshot = NpcContinuityReader.read(campaign, npcId: 'mira');
    final context = snapshot.confirmedContext;

    expect(context.split('\n'), hasLength(4));
    expect(context.split('\n').first, startsWith('NPC: Mira Hüterin'));
    expect(context.split('\n').first.length, lessThanOrEqualTo(85));
    expect(context.split('\n').first, endsWith('…'));
    final relation = _after(context, 'Aktuelle Beziehung: ');
    final noteExcerpt = _after(context, '): ');
    expect(relation.length, lessThanOrEqualTo(80));
    expect(noteExcerpt.length, lessThanOrEqualTo(500));
    expect(relation, endsWith('…'));
    expect(noteExcerpt, endsWith('…'));
    expect(noteExcerpt.runes.any((r) => r >= 0xd800 && r <= 0xdfff), isFalse);
    expect(snapshot.name, name);
    expect(snapshot.currentRelationship, relationship);
    expect(snapshot.recentNotes.single.note, note);
    expect(jsonEncode(campaign.toJson()), savedBefore);
    expect(context, isNot(contains('gestohlenes Gold')));
  });

  test('colliding shortened names must show safe confirmed NPC IDs', () {
    final prefix = 'Mira ${'🐉' * 50}';
    final campaign = _campaign(
      npcs: [
        WorldNpc(id: 'mira', name: '${prefix}Nord'),
        WorldNpc(id: 'mira-two', name: '${prefix}Süd'),
      ],
      notes: [_note('Die echte Mira kennt den Hafen.')],
    );
    final first = NpcContinuityReader.read(campaign, npcId: 'mira');
    final second = NpcContinuityReader.read(campaign, npcId: 'mira-two');

    expect(first.disambiguateName, isTrue);
    expect(second.disambiguateName, isTrue);
    expect(first.confirmedContext, contains('(NPC-ID: mira)'));
    expect(second.confirmedContext, contains('(NPC-ID: mira-two)'));
    expect(first.confirmedContext.split('\n').first, isNot(contains('Nord')));
    expect(second.confirmedContext.split('\n').first, isNot(contains('Süd')));
    expect(first.confirmedContext, contains('echte Mira kennt den Hafen'));
    expect(second.confirmedContext, isNot(contains('echte Mira kennt')));
  });

  test('unsafe identity cannot be used to disambiguate shortened names', () {
    final prefix = 'Mira ${'🐉' * 50}';
    final campaign = _campaign(
      npcs: [
        WorldNpc(id: 'unsafe id', name: '${prefix}Nord'),
        WorldNpc(id: 'mira-two', name: '${prefix}Süd'),
      ],
    );

    expect(
      () => NpcContinuityReader.read(campaign, npcId: 'unsafe id'),
      throwsFormatException,
    );
    expect(
      NpcContinuityReader.read(campaign, npcId: 'mira-two').confirmedContext,
      contains('(NPC-ID: mira-two)'),
    );
  });

  test('short names and original German memories stay unchanged', () {
    final campaign = _campaign(
      npcs: const [
        WorldNpc(
          id: 'mira',
          name: 'Mira – Hüterin',
          relationship: 'wohlgesinnt',
        ),
      ],
      notes: [_note('Mira öffnete das versiegelte Stadttor.')],
    );
    final context = NpcContinuityReader.read(
      campaign,
      npcId: 'mira',
    ).confirmedContext;

    expect(context, startsWith('NPC: Mira – Hüterin\nStatus: lebendig\n'));
    expect(context, contains('Aktuelle Beziehung: wohlgesinnt'));
    expect(context, contains('Mira öffnete das versiegelte Stadttor.'));
    expect(context, isNot(contains('…')));
  });

  test(
    'valid long legacy data keeps full values after SQLite restart',
    () async {
      final name = 'Mira ${'Hüterin ' * 20}';
      final relationship = 'freundlich ' * 20;
      final note = '🐉' * 200;
      final source = _campaign(
        npcs: [WorldNpc(id: 'mira', name: name, relationship: relationship)],
        notes: [_note(note)],
      );
      final folder = await Directory.systemTemp.createTemp(
        'npc-bounded-context-',
      );
      final path = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        await repository.saveCampaign(source);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = (await repository.getCampaign(source.id))!;
        final saved = jsonEncode(restored.toJson());
        final snapshot = NpcContinuityReader.read(restored, npcId: 'mira');

        expect(restored.npcs.single.name, name);
        expect(restored.npcs.single.relationship, relationship);
        expect(restored.npcRelationshipNotes.single.note, note);
        expect(snapshot.name, name);
        expect(snapshot.recentNotes.single.note, note);
        expect(
          snapshot.confirmedContext.split('\n').first.length,
          lessThanOrEqualTo(85),
        );
        expect(
          _after(snapshot.confirmedContext, 'Aktuelle Beziehung: ').length,
          lessThanOrEqualTo(80),
        );
        expect(snapshot.confirmedContext, contains(note));
        expect(restored.hero.toJson(), source.hero.toJson());
        expect(restored.revision, source.revision);
        expect(jsonEncode(restored.toJson()), saved);
        expect(
          (await repository.reconstructCampaign(source.id))!.toJson(),
          restored.toJson(),
        );
      } finally {
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
