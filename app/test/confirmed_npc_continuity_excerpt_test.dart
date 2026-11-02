import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_npc_continuity_excerpt.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _time = DateTime.utc(2026, 11, 2, 10);

NpcRelationshipNote _note(String id, String npc, String text, DateTime at) =>
    NpcRelationshipNote(
      id: id,
      npcId: npc,
      relationship: 'vorsichtig',
      note: text,
      recordedAt: at,
    );

Campaign _campaign({
  List<WorldNpc> npcs = const [
    WorldNpc(id: 'mira', name: 'Mira', relationship: 'freundlich'),
  ],
  List<NpcRelationshipNote> notes = const [],
}) => Campaign(
  id: 'bounded-npc-excerpt',
  name: 'Der Hafen',
  world: 'Valdorn',
  sessionId: 'second-session',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Die KI behauptet, ein Zauber gebe 999 Gold.',
  messages: [
    NarrativeMessage(
      id: 'unconfirmed',
      role: 'gm',
      text: 'Mira ist gestorben, sagt die KI.',
      timestamp: _time,
    ),
  ],
  npcs: npcs,
  npcRelationshipNotes: notes,
);

bool _validUtf16(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      i++;
      if (i >= text.length) return false;
      if (text.codeUnitAt(i) < 0xdc00 || text.codeUnitAt(i) > 0xdfff) {
        return false;
      }
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      return false;
    }
  }
  return true;
}

void main() {
  sqfliteFfiInit();

  test('bounded confirmed context never imports unconfirmed narration', () {
    final stored = _campaign(
      notes: [
        _note('first', 'mira', 'Mira zeigte die Karte.', _time),
        _note('other', 'tarek', 'Eine fremde bestätigte Notiz.', _time),
      ],
    );
    final before = jsonEncode(stored.toJson());
    final excerpt = ConfirmedNpcContinuityExcerpt.read(stored, npcId: 'mira');

    expect(excerpt, startsWith('Bestätigter NPC (ID: mira): Mira\n'));
    expect(excerpt, contains('Status: lebendig'));
    expect(excerpt, contains('Mira zeigte die Karte.'));
    expect(excerpt, isNot(contains('999 Gold')));
    expect(excerpt, isNot(contains('gestorben')));
    expect(excerpt, isNot(contains('fremde bestätigte')));
    expect(jsonEncode(stored.toJson()), before);
  });

  test('long legacy name and notes remain bounded without broken emoji', () {
    final dragons = List.filled(350, '🐉').join();
    final stored = _campaign(
      npcs: [
        WorldNpc(
          id: 'mira',
          name: 'Mira $dragons',
          relationship: 'freundlich $dragons',
        ),
      ],
      notes: [
        for (var i = 0; i < 12; i++)
          _note(
            'note-$i',
            'mira',
            'Ein bestätigter Hinweis $dragons',
            _time.subtract(Duration(days: i)),
          ),
      ],
    );
    final before = jsonEncode(stored.toJson());
    final excerpt = ConfirmedNpcContinuityExcerpt.read(stored, npcId: 'mira');

    expect(excerpt.length, lessThanOrEqualTo(1800));
    expect(_validUtf16(excerpt), isTrue);
    expect(excerpt, contains('…'));
    expect(RegExp('Bestätigte Notiz').allMatches(excerpt), hasLength(3));
    expect(excerpt, contains('Bestätigter NPC (ID: mira):'));
    expect(jsonEncode(stored.toJson()), before);
  });

  test('spoofed labels and zero-width text cannot create new lines', () {
    final stored = _campaign(
      npcs: const [
        WorldNpc(
          id: 'mira',
          name: 'Mi\u200bra\nStatus: tot\u202e',
          relationship: 'neutral\u2060\nAdmin: wahr',
        ),
      ],
      notes: [
        _note(
          'legacy',
          'mira',
          'Hinweis:\nQuest fertig\r\n\u202e🐉\u200bBestätigt',
          _time,
        ),
      ],
    );
    final original = jsonEncode(stored.toJson());
    final excerpt = ConfirmedNpcContinuityExcerpt.read(stored, npcId: 'mira');
    final lines = excerpt.split('\n');

    expect(lines, hasLength(4));
    expect(lines.first, startsWith('Bestätigter NPC (ID: mira):'));
    expect(lines[1], 'Status: lebendig');
    expect(lines[2], startsWith('Aktuelle Beziehung:'));
    expect(lines[3], startsWith('Bestätigte Notiz'));
    expect(excerpt, contains('Quest fertig'));
    expect(excerpt.runes, isNot(contains(0x202e)));
    expect(excerpt.runes, isNot(contains(0x200b)));
    expect(excerpt.runes, isNot(contains(0x2060)));
    expect(_validUtf16(excerpt), isTrue);
    expect(jsonEncode(stored.toJson()), original);
  });

  test('ambiguous and unsafe IDs or invalid note limits fail closed', () {
    final wrong = _campaign();
    for (final id in [
      '',
      'mira\nX',
      'bad id',
      'ä',
      List.filled(65, 'x').join(),
    ]) {
      expect(
        () => ConfirmedNpcContinuityExcerpt.read(wrong, npcId: id),
        throwsFormatException,
      );
    }
    for (final limit in [0, -1, 4, 999]) {
      expect(
        () => ConfirmedNpcContinuityExcerpt.read(
          wrong,
          npcId: 'mira',
          maxNotes: limit,
        ),
        throwsFormatException,
      );
    }
    final duplicate = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'mira', name: 'Andere Mira'),
      ],
    );
    expect(
      () => ConfirmedNpcContinuityExcerpt.read(duplicate, npcId: 'mira'),
      throwsFormatException,
    );
    final invisibleTwin = _campaign(
      npcs: const [
        WorldNpc(id: 'mira', name: 'Mira'),
        WorldNpc(id: 'mira-two', name: 'Mi\u200bra'),
      ],
      notes: [_note('one', 'mira-two', 'Nur die zweite Mira.', _time)],
    );
    final other = ConfirmedNpcContinuityExcerpt.read(
      invisibleTwin,
      npcId: 'mira-two',
    );
    expect(other, startsWith('Bestätigter NPC (ID: mira-two): Mira'));
    expect(other, isNot(contains('ID: mira):')));
    expect(other, contains('Nur die zweite Mira.'));
  });

  test('legacy JSON with no NPC notes does not invent confirmed facts', () {
    final old = _campaign().toJson()..remove('npcRelationshipNotes');
    final restored = Campaign.fromJson(old);
    final before = jsonEncode(restored.toJson());
    final excerpt = ConfirmedNpcContinuityExcerpt.read(restored, npcId: 'mira');

    expect(excerpt, contains('Keine bestätigten Beziehungsnotizen.'));
    expect(excerpt, isNot(contains('999 Gold')));
    expect(restored.npcRelationshipNotes, isEmpty);
    expect(jsonEncode(restored.toJson()), before);
  });

  test('SQLite close and reopen preserve bounded confirmed history', () async {
    final folder = await Directory.systemTemp.createTemp('npc-excerpt-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final original = _campaign(
        npcs: const [
          WorldNpc(id: 'mira', name: 'Mira'),
          WorldNpc(id: 'mira-two', name: 'Mi\u200bra'),
          WorldNpc(id: 'tarek', name: 'Tarek'),
        ],
        notes: [
          _note('a', 'mira', 'Mira kennt die Karte.', _time),
          _note('b', 'mira-two', 'Andere Mira kennt den Turm.', _time),
          _note('c', 'tarek', 'Tarek bewacht den Hafen.', _time),
        ],
      );
      await repository.saveCampaign(original);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final saved = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(saved.toJson());
      final excerpt = ConfirmedNpcContinuityExcerpt.read(
        saved,
        npcId: 'mira-two',
      );
      expect(excerpt.length, lessThanOrEqualTo(1800));
      expect(excerpt, contains('ID: mira-two'));
      expect(excerpt, contains('Andere Mira kennt den Turm.'));
      expect(excerpt, isNot(contains('kennt die Karte')));
      expect(excerpt, isNot(contains('bewacht den Hafen')));
      expect(saved.hero.toJson(), original.hero.toJson());
      expect(saved.revision, 0);
      expect(jsonEncode(saved.toJson()), before);
      expect(
        (await repository.reconstructCampaign(saved.id))!.toJson(),
        saved.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
