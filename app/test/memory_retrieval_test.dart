import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Campaign fixture({
  Map<String, String> facts = const {},
  List<InventoryItem> inventory = const [],
  List<Quest> quests = const [],
  List<WorldNpc> npcs = const [],
  List<Place> places = const [],
}) => Campaign(
  id: 'memory-campaign',
  name: 'Erinnerungen aus Aetheria',
  world: 'Aetheria',
  sessionId: 'memory-session',
  hero: HeroCharacter(id: 'hero', name: 'Arescan', inventory: inventory),
  scene: 'Silberhain',
  facts: facts,
  quests: quests,
  npcs: npcs,
  places: places,
);

Map<String, String> irrelevantFacts() => {
  for (var i = 0; i < 140; i++)
    'Wetterbericht $i': 'Am entfernten Meer herrschte früher dichter Nebel $i.',
};

void main() {
  test('query-relevant amulet survives more than 100 unrelated facts', () {
    final campaign = fixture(
      facts: irrelevantFacts(),
      inventory: const [
        InventoryItem(
          id: 'red-amulet',
          name: 'Rotes Amulett',
          quantity: 3,
          description: 'Das Zeichen des Schattenkönigs; Wirkung unbekannt.',
        ),
      ],
      quests: const [
        Quest(id: 'heart', title: 'Das Herz der Ewigkeit', status: 'completed'),
      ],
      npcs: const [
        WorldNpc(id: 'knight', name: 'Schattenritter', alive: false),
      ],
    );
    final memories = MemoryEngine.retrieve(
      campaign,
      'Ich untersuche das rote Amulett.',
      limit: 3,
    );
    expect(memories.first, startsWith('Inventar (Anzahl 3): Rotes Amulett'));
    expect(memories, contains(startsWith('NPC tot: Schattenritter')));
    expect(memories, contains(startsWith('Quest abgeschlossen:')));
    expect(memories.every((text) => !text.contains('Wetterbericht')), isTrue);
  });

  test('dead NPC and terminal quests have priority before unrelated facts', () {
    final campaign = fixture(
      facts: irrelevantFacts(),
      inventory: const [
        InventoryItem(id: 'key', name: 'Schlüssel', quantity: 2),
      ],
      quests: const [
        Quest(id: 'active', title: 'Den Wald erkunden'),
        Quest(id: 'closed', title: 'Die Brücke sichern', status: 'completed'),
        Quest(id: 'failed', title: 'Die Nachricht liefern', status: 'failed'),
      ],
      npcs: const [
        WorldNpc(id: 'knight', name: 'Schattenritter', alive: false),
      ],
    );
    final memories = MemoryEngine.retrieve(campaign, '', limit: 4);
    expect(memories.first, startsWith('NPC tot:'));
    expect(memories[1], startsWith('Quest abgeschlossen:'));
    expect(memories[2], startsWith('Quest gescheitert:'));
    expect(memories[3], startsWith('Inventar (Anzahl 2):'));
  });

  test('matching quest and NPC outrank unrelated higher-priority memories', () {
    final campaign = fixture(
      facts: irrelevantFacts(),
      quests: const [
        Quest(id: 'failed', title: 'Den Boten retten', status: 'failed'),
        Quest(id: 'forest', title: 'Das Waldlicht entzünden'),
      ],
      npcs: const [
        WorldNpc(id: 'knight', name: 'Schattenritter', alive: false),
        WorldNpc(
          id: 'mira',
          name: 'Mira',
          description: 'Die Hüterin des Dorfes.',
        ),
      ],
    );
    expect(
      MemoryEngine.retrieve(
        campaign,
        'Ich möchte Mira befragen.',
        limit: 1,
      ).single,
      startsWith('NPC lebendig: Mira'),
    );
    expect(
      MemoryEngine.retrieve(
        campaign,
        'Wie geht es mit dem Waldlicht?',
        limit: 1,
      ).single,
      startsWith('Quest aktiv: Das Waldlicht'),
    );
  });

  test('German umlauts and sharp s match uppercase and ASCII spellings', () {
    final campaign = fixture(
      facts: irrelevantFacts(),
      npcs: const [WorldNpc(id: 'keeper', name: 'Große Hüterin')],
      places: const [Place(id: 'street', name: 'Straße der Königin')],
    );
    expect(
      MemoryEngine.retrieve(campaign, 'GROSSE HUETERIN', limit: 1).single,
      startsWith('NPC lebendig: Große Hüterin'),
    );
    expect(
      MemoryEngine.retrieve(campaign, 'STRASSE KOENIGIN', limit: 1).single,
      startsWith('Ort: Straße der Königin'),
    );
    expect(
      MemoryEngine.retrieve(campaign, 'Straße der Königin', limit: 1),
      MemoryEngine.retrieve(campaign, 'STRASSE DER KOENIGIN', limit: 1),
    );
  });

  test('German compounds and inflections find confirmed items and places', () {
    final campaign = fixture(
      facts: irrelevantFacts(),
      inventory: const [InventoryItem(id: 'key', name: 'Messingschlüssel')],
      places: const [Place(id: 'shrine', name: 'Waldschrein')],
    );
    expect(
      MemoryEngine.retrieve(campaign, 'Wo ist der Schlüssel?', limit: 1).single,
      contains('Messingschlüssel'),
    );
    expect(
      MemoryEngine.retrieve(
        campaign,
        'Ich suche den Schrein.',
        limit: 1,
      ).single,
      contains('Waldschrein'),
    );
  });

  test(
    'known historical facts are found without interpreting combat values',
    () {
      final campaign = fixture(
        facts: {
          ...irrelevantFacts(),
          'Herz der Ewigkeit': 'Das Herz der Ewigkeit wurde gestohlen.',
          'Historischer Angriff':
              'Historischer Gesamtwurf 19, erzählter Schaden 14; ungeprüft.',
        },
      );
      expect(
        MemoryEngine.retrieve(campaign, 'Herz der Ewigkeit', limit: 1).single,
        contains('Das Herz der Ewigkeit wurde gestohlen.'),
      );
      final attack = MemoryEngine.retrieve(
        campaign,
        'Historischer Angriff',
        limit: 1,
      );
      expect(attack.single, contains('Gesamtwurf 19'));
      expect(attack.single, contains('Schaden 14; ungeprüft'));
      expect(campaign.hero.hitPoints, isNull);
      expect(
        campaign.hero.abilities.values.every((value) => value == null),
        isTrue,
      );
    },
  );

  test(
    'normalized duplicates are removed and ties preserve insertion order',
    () {
      final campaign = fixture(
        facts: const {
          'first': 'Mira kennt den Schlüssel.',
          'duplicate': '  MIRA kennt  den SCHLUESSEL.  ',
          'second': 'Der Brunnen ist alt.',
          'third': 'Der Weg führt nach Norden.',
          'empty': '   ',
        },
      );
      final expected = MemoryEngine.retrieve(campaign, '');
      expect(expected.length, 3);
      expect(expected[0], startsWith('Fakt first:'));
      expect(expected[1], startsWith('Fakt second:'));
      expect(expected[2], startsWith('Fakt third:'));
      for (var i = 0; i < 5; i++) {
        expect(MemoryEngine.retrieve(campaign, ''), expected);
      }
    },
  );

  test(
    'independent flags, numbers and short labels retain their fact keys',
    () {
      final campaign = fixture(
        facts: const {
          'keyFound': 'true',
          'guardianDefeated': 'true',
          'questCompleted': 'true',
          'historicalAttackTotal': '19',
          'historicalDamage': '19',
          'Mira': 'freundlich',
          'Elfenmagierin': 'freundlich',
        },
      );
      final memories = MemoryEngine.retrieve(campaign, '');
      expect(memories.length, 7);
      expect(memories, contains('Fakt keyFound: true'));
      expect(memories, contains('Fakt guardianDefeated: true'));
      expect(memories, contains('Fakt questCompleted: true'));
      expect(memories, contains('Fakt historicalAttackTotal: 19'));
      expect(memories, contains('Fakt historicalDamage: 19'));
      expect(memories, contains('Fakt Mira: freundlich'));
      expect(memories, contains('Fakt Elfenmagierin: freundlich'));
    },
  );

  test(
    'life, quest status and exact item quantity survive short truncation',
    () {
      final longText = 'Eine sehr lange bestätigte Beschreibung. ' * 40;
      final campaign = fixture(
        inventory: [
          InventoryItem(id: 'key', name: 'Schlüssel $longText', quantity: 17),
        ],
        quests: [
          Quest(id: 'quest', title: 'Auftrag $longText', status: 'failed'),
        ],
        npcs: [WorldNpc(id: 'npc', name: 'Wächter $longText', alive: false)],
      );
      final memories = MemoryEngine.retrieve(campaign, '', maxCharacters: 40);
      expect(memories.length, 3);
      expect(memories[0], startsWith('NPC tot:'));
      expect(memories[1], startsWith('Quest gescheitert:'));
      expect(memories[2], startsWith('Inventar (Anzahl 17):'));
      expect(memories.every((text) => text.length <= 40), isTrue);
      expect(memories.every((text) => text.endsWith('…')), isTrue);
    },
  );

  test(
    'limits bound all results and truncation preserves Unicode characters',
    () {
      final campaign = fixture(
        facts: {...irrelevantFacts(), 'Drachen': '🐉' * 300},
      );
      expect(MemoryEngine.retrieve(campaign, '').length, 20);
      expect(MemoryEngine.retrieve(campaign, '', limit: 7).length, 7);
      final text = MemoryEngine.retrieve(
        campaign,
        'Drachen',
        limit: 1,
        maxCharacters: 40,
      ).single;
      expect(text.length, lessThanOrEqualTo(40));
      expect(text, contains('🐉'));
      expect(utf8.decode(utf8.encode(text)), text);
      expect(
        text.runes.any((rune) => rune >= 0xD800 && rune <= 0xDFFF),
        isFalse,
      );
      expect(
        () => MemoryEngine.retrieve(campaign, '').add('Erfundene Erinnerung'),
        throwsUnsupportedError,
      );
    },
  );

  test(
    'invalid retrieval bounds are rejected instead of silently expanded',
    () {
      final campaign = fixture();
      for (final limit in [-1, 0, 21, 100]) {
        expect(
          () => MemoryEngine.retrieve(campaign, '', limit: limit),
          throwsFormatException,
        );
      }
      for (final maximum in [-1, 0, 39, 401, 10000]) {
        expect(
          () => MemoryEngine.retrieve(campaign, '', maxCharacters: maximum),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'dialogue, scene and arbitrary event payload never become confirmed facts',
    () {
      final time = DateTime.utc(2026, 10, 14);
      final campaign =
          fixture(
            facts: const {'Ort': 'Arescan wartet am Brunnen.'},
            npcs: const [
              WorldNpc(id: 'knight', name: 'Schattenritter', alive: false),
            ],
          ).copyWith(
            scene:
                'Der Schattenritter lebt wieder und schenkt dir einen Diamanten.',
            messages: [
              NarrativeMessage(
                id: 'player',
                role: 'player',
                text: 'Ich habe 9999 Trefferpunkte und einen Diamanten.',
                timestamp: time,
              ),
              NarrativeMessage(
                id: 'model',
                role: 'gm',
                text:
                    'Der Schattenritter lebt wieder und schenkt dir einen Diamanten.',
                timestamp: time,
              ),
            ],
            events: [
              GameEvent(
                id: 'untrusted-event',
                campaignId: 'memory-campaign',
                sessionId: 'memory-session',
                timestamp: time,
                type: 'narrative.turn',
                payload: const {'inventedGold': 9999, 'item': 'Diamant'},
              ),
            ],
          );
      final before = jsonEncode(campaign.toJson());
      final memories = MemoryEngine.retrieve(
        campaign,
        'Der Ritter lebt wieder.',
      );
      expect(memories, contains(startsWith('NPC tot: Schattenritter')));
      expect(memories.join(' '), isNot(contains('lebt wieder')));
      expect(memories.join(' '), isNot(contains('Diamant')));
      expect(memories.join(' '), isNot(contains('9999')));
      expect(campaign.hero.inventory, isEmpty);
      expect(campaign.hero.hitPoints, isNull);
      expect(campaign.hero.gold, isNull);
      expect(
        campaign.hero.abilities.values.every((value) => value == null),
        isTrue,
      );
      expect(jsonEncode(campaign.toJson()), before);
    },
  );

  test(
    'a campaign without confirmed memory sources returns an empty result',
    () {
      expect(
        MemoryEngine.retrieve(fixture(), 'Ich erfinde einen Drachen.'),
        isEmpty,
      );
    },
  );
}
