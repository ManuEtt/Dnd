import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

GameEngine engine() => GameEngine(clock: () => DateTime.utc(2026, 10, 13));

Map<String, dynamic> stateFields(Campaign campaign) =>
    Map<String, dynamic>.from(campaign.toJson())
      ..remove('messages')
      ..remove('events');

GameEvent eventLike(
  GameEvent event, {
  String? id,
  String? campaignId,
  String? sessionId,
  String? type,
  Map<String, dynamic>? payload,
}) => GameEvent(
  id: id ?? event.id,
  campaignId: campaignId ?? event.campaignId,
  sessionId: sessionId ?? event.sessionId,
  timestamp: event.timestamp,
  type: type ?? event.type,
  entities: event.entities,
  payload: payload ?? event.payload,
);

Object? reverseObjectKeys(Object? value) {
  if (value is Map) {
    final keys = value.keys.cast<String>().toList()..sort();
    return {
      for (final key in keys.reversed) key: reverseObjectKeys(value[key]),
    };
  }
  if (value is List) return value.map(reverseObjectKeys).toList();
  return value;
}

void main() {
  test('free narration preserves game state, message and event identities', () {
    final gm = engine();
    final first = gm.act(gm.createDemo(), 'Ich winke den Dorfbewohnern.');
    final original = gm.act(first.campaign, 'Ich lausche dem Wind.');
    final before = jsonEncode(original.campaign.toJson());
    final updated = gm.replaceNarration(
      original,
      text:
          '  Liora, der Wind streicht durch die Bäume. Was möchtest du tun?  ',
      provider: 'openai',
    );
    expect(
      updated.narration,
      'Liora, der Wind streicht durch die Bäume. Was möchtest du tun?',
    );
    expect(stateFields(updated.campaign), stateFields(original.campaign));
    expect(updated.campaign.revision, original.campaign.revision);
    expect(updated.campaign.messages.length, original.campaign.messages.length);
    final oldMessage = original.campaign.messages.last;
    final newMessage = updated.campaign.messages.last;
    expect(newMessage.id, oldMessage.id);
    expect(newMessage.role, oldMessage.role);
    expect(newMessage.timestamp, oldMessage.timestamp);
    expect(
      updated.campaign.messages
          .take(updated.campaign.messages.length - 1)
          .map((message) => message.toJson()),
      original.campaign.messages
          .take(original.campaign.messages.length - 1)
          .map((message) => message.toJson()),
    );
    expect(
      updated.campaign.events
          .take(updated.campaign.events.length - 1)
          .map((event) => event.toJson()),
      original.campaign.events
          .take(original.campaign.events.length - 1)
          .map((event) => event.toJson()),
    );
    final oldEvent = original.events.single.toJson()..remove('payload');
    final newEvent = updated.events.single.toJson()..remove('payload');
    expect(newEvent, oldEvent);
    expect(updated.events.single, same(updated.campaign.events.last));
    expect(updated.events.single.payload['narrationProvider'], 'openai');
    expect(
      updated.events.single.payload['stateAfter'],
      updated.campaign.copyWith(events: const []).toJson(),
    );
    expect(jsonEncode(original.campaign.toJson()), before);
    expect(
      Campaign.fromJson(updated.campaign.toJson()).toJson(),
      updated.campaign.toJson(),
    );
  });

  test(
    'historical Arescan values stay unknown and new facts stay confirmed',
    () {
      final gm = engine();
      final seed = gm.createArescan();
      final original = gm.act(seed, 'Ich befrage die Elfenmagierin.');
      expect(original.campaign.facts['elfenwarnung'], isNotNull);
      final updated = gm.replaceNarration(
        original,
        text: 'Arescan, die Elfin warnt dich vor dem Amulett. Was fragst du?',
        provider: 'mock',
      );
      expect(stateFields(updated.campaign), stateFields(original.campaign));
      expect(
        updated.campaign.hero.abilities.values.every((e) => e == null),
        true,
      );
      expect(updated.campaign.hero.hitPoints, isNull);
      expect(updated.campaign.hero.armorClass, isNull);
      expect(updated.campaign.hero.gold, isNull);
      expect(updated.campaign.hero.experience, isNull);
      expect(updated.campaign.hero.inventory, isEmpty);
      expect(
        updated.campaign.events.first.toJson(),
        seed.events.first.toJson(),
      );
      expect(updated.campaign.events.first.payload['attackTotal'], 19);
      expect(updated.campaign.events.first.payload['narratedDamage'], 14);
      expect(
        updated.campaign.events.first.payload['unverifiedDexterityModifier'],
        7,
      );
    },
  );

  test('replacing a free turn preserves an existing roll and combat state', () {
    final gm = engine();
    final combat = gm.act(gm.createDemo(), 'Ich gehe zum Schrein.').campaign;
    final pending = gm.act(combat, 'Ich greife mit dem Schwert an.').campaign;
    final original = gm.act(pending, 'Was ist in meinem Inventar?');
    expect(original.events.single.type, 'narrative.turn');
    final updated = gm.replaceNarration(
      original,
      text: 'Dein Inventar ist unverändert. Deine Angriffsprobe wartet noch.',
      provider: 'mock',
    );
    expect(stateFields(updated.campaign), stateFields(original.campaign));
    expect(
      updated.campaign.pendingRoll!.toJson(),
      pending.pendingRoll!.toJson(),
    );
    expect(updated.campaign.encounter!.toJson(), pending.encounter!.toJson());
  });

  test('rule, roll, combat, quest and item events cannot be rewritten', () {
    final gm = engine();
    final demo = gm.createDemo();
    final combat = gm.act(demo, 'Ich gehe zum Schrein.').campaign;
    final roll = gm.act(combat, 'Ich greife mit dem Schwert an.');
    final updates = [
      gm.act(gm.createArescan(), 'Ich greife an.'),
      gm.rollDice(demo, '1d20'),
      gm.act(demo, 'Ich gehe zum Schrein.'),
      roll,
      gm.resolveRoll(roll.campaign, natural: 16),
      gm.act(demo, 'Ich untersuche den Brunnen.'),
      gm.act(gm.createArescan(), 'Ich nehme das Amulett.'),
    ];
    for (final update in updates) {
      expect(update.events.single.type, isNot('narrative.turn'));
      final before = jsonEncode(update.campaign.toJson());
      expect(
        () =>
            gm.replaceNarration(update, text: 'Neue Worte.', provider: 'mock'),
        throwsFormatException,
        reason: update.events.single.type,
      );
      expect(jsonEncode(update.campaign.toJson()), before);
    }
    // All unsupported event types are rejected even with an otherwise valid
    // checkpoint; creative narration must not reinterpret a quest outcome.
    final free = gm.act(demo, 'Ich winke.');
    for (final type in ['quest.completed', 'combat.ended', 'hero.updated']) {
      final event = eventLike(free.events.single, type: type);
      final update = GameUpdate(
        campaign: free.campaign.copyWith(events: [event]),
        events: [event],
      );
      expect(
        () =>
            gm.replaceNarration(update, text: 'Neue Worte.', provider: 'mock'),
        throwsFormatException,
      );
    }
  });

  test('missing, multiple and outdated event updates are rejected', () {
    final gm = engine();
    final first = gm.act(gm.createDemo(), 'Ich winke.');
    final second = gm.act(first.campaign, 'Ich lausche dem Wind.');
    final updates = [
      GameUpdate(campaign: first.campaign, events: const []),
      GameUpdate(
        campaign: first.campaign.copyWith(events: const []),
        events: first.events,
      ),
      GameUpdate(campaign: second.campaign, events: first.events),
      GameUpdate(
        campaign: second.campaign,
        events: [...first.events, ...second.events],
      ),
    ];
    for (final update in updates) {
      expect(
        () =>
            gm.replaceNarration(update, text: 'Neue Worte.', provider: 'mock'),
        throwsFormatException,
      );
    }
  });

  test('event identity and checkpoint tampering are rejected', () {
    final gm = engine();
    final free = gm.act(gm.createDemo(), 'Ich winke.');
    final originalEvent = free.events.single;
    final wrongEvents = [
      eventLike(originalEvent, campaignId: 'foreign-campaign'),
      eventLike(originalEvent, sessionId: 'foreign-session'),
      eventLike(originalEvent, payload: const {}),
      eventLike(
        originalEvent,
        payload: {
          ...originalEvent.payload,
          'stateAfter': free.campaign
              .copyWith(hero: free.campaign.hero.copyWith(gold: 999))
              .copyWith(events: const [])
              .toJson(),
        },
      ),
    ];
    for (final event in wrongEvents) {
      final update = GameUpdate(
        campaign: free.campaign.copyWith(events: [event]),
        events: [event],
      );
      expect(
        () =>
            gm.replaceNarration(update, text: 'Neue Worte.', provider: 'mock'),
        throwsFormatException,
      );
    }
    final changedEvent = eventLike(
      originalEvent,
      payload: const {'wrong': true},
    );
    expect(
      () => gm.replaceNarration(
        GameUpdate(campaign: free.campaign, events: [changedEvent]),
        text: 'Neue Worte.',
        provider: 'mock',
      ),
      throwsFormatException,
    );
  });

  test('only a last GM message can be replaced', () {
    final gm = engine();
    final free = gm.act(gm.createDemo(), 'Ich winke.');
    for (final messages in <List<NarrativeMessage>>[
      [],
      [
        NarrativeMessage(
          id: 'player-message',
          role: 'player',
          text: 'Meine Handlung',
          timestamp: DateTime.utc(2026, 10, 13),
        ),
      ],
    ]) {
      final state = free.campaign.copyWith(messages: messages);
      final event = eventLike(
        free.events.single,
        payload: {
          ...free.events.single.payload,
          'stateAfter': state.copyWith(events: const []).toJson(),
        },
      );
      expect(
        () => gm.replaceNarration(
          GameUpdate(
            campaign: state.copyWith(events: [event]),
            events: [event],
          ),
          text: 'Neue Worte.',
          provider: 'mock',
        ),
        throwsFormatException,
      );
    }
  });

  test('original nested event payload remains isolated', () {
    final gm = engine();
    final free = gm.act(gm.createDemo(), 'Ich winke.');
    final event = eventLike(
      free.events.single,
      payload: {
        ...free.events.single.payload,
        'confirmedDetails': {
          'source': [
            {'name': 'Mira', 'confirmed': true},
          ],
        },
      },
    );
    final original = GameUpdate(
      campaign: free.campaign.copyWith(events: [event]),
      events: [event],
    );
    final before = jsonEncode(original.campaign.toJson());
    final updated = gm.replaceNarration(
      original,
      text: 'Mira winkt dir zu. Was möchtest du tun?',
      provider: 'mock',
    );
    expect(
      updated.events.single.payload['confirmedDetails'],
      original.events.single.payload['confirmedDetails'],
    );
    final details = updated.events.single.payload['confirmedDetails'] as Map;
    (details['source'] as List).first['name'] = 'Veränderte Kopie';
    expect(jsonEncode(original.campaign.toJson()), before);
  });

  test(
    'Unicode plain text is trimmed and retained without markup conversion',
    () {
      final gm = engine();
      final seed = gm.createDemo();
      final free = gm.act(seed, 'Ich winke.');
      const text = 'Äther, Grüße und Zauber ✨ 🐉.\n„Was möchtest du tun?“';
      final updated = gm.replaceNarration(
        free,
        text: '\n  $text \t',
        provider: 'mock',
      );
      expect(updated.narration, text);
      expect(updated.campaign.scene, free.campaign.scene);
      expect(
        MemoryEngine.replay(seed, updated.events).messages.last.text,
        text,
      );
    },
  );

  test('narration length and provider are strictly bounded', () {
    final gm = engine();
    final free = gm.act(gm.createDemo(), 'Ich winke.');
    for (final text in ['', '  \n\t', 'ä' * 4001]) {
      expect(
        () => gm.replaceNarration(free, text: text, provider: 'mock'),
        throwsFormatException,
      );
    }
    expect(
      gm.replaceNarration(free, text: 'ä' * 4000, provider: 'mock').narration,
      'ä' * 4000,
    );
    for (final provider in ['', 'unknown', 'OpenAI', 'openai ', 'realtime']) {
      expect(
        () =>
            gm.replaceNarration(free, text: 'Neue Worte.', provider: provider),
        throwsFormatException,
      );
    }
  });

  test(
    'replay deduplicates equal JSON objects regardless of nested key order',
    () {
      final gm = engine();
      final seed = gm.createArescan();
      final original = gm.act(seed, 'Ich befrage die Elfenmagierin.');
      final reordered = Campaign.fromJson(
        reverseObjectKeys(original.campaign.toJson()) as Map<String, dynamic>,
      );
      expect(
        MemoryEngine.replay(seed, [
          ...reordered.events,
          ...original.events,
        ]).toJson(),
        original.campaign.toJson(),
      );
      final replacement = gm.replaceNarration(
        GameUpdate(campaign: reordered, events: [reordered.events.last]),
        text:
            'Arescan, die Elfin bittet dich um Vorsicht. Was möchtest du tun?',
        provider: 'mock',
      );
      expect(stateFields(replacement.campaign), stateFields(original.campaign));
    },
  );

  test(
    'replay still rejects changed values, list order and numeric JSON types',
    () {
      final gm = engine();
      final seed = gm.createArescan();
      final history = seed.events.single;
      for (final payload in [
        {...history.payload, 'narratedDamage': 15},
        {...history.payload, 'narratedDamage': 14.0},
        {
          ...history.payload,
          'history': (history.payload['history'] as List).reversed.toList(),
        },
      ]) {
        final changed = eventLike(history, payload: payload);
        expect(
          () => MemoryEngine.replay(seed, [changed]),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'persisted snapshot and replay restore exactly the replacement text',
    () async {
      sqfliteFfiInit();
      final directory = await Directory.systemTemp.createTemp(
        'narration-replay-',
      );
      final path = paths.join(directory.path, 'test.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final gm = engine();
        final seed = gm.createArescan();
        final original = gm.act(seed, 'Ich befrage die Elfenmagierin.');
        final updated = gm.replaceNarration(
          original,
          text:
              'Arescan, die Elfin warnt vor der Magie. Was möchtest du fragen?',
          provider: 'mock',
        );
        await repository.saveCampaign(seed);
        await repository.saveCampaign(updated.campaign, events: updated.events);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = (await repository.getCampaign(seed.id))!;
        expect(restored.toJson(), updated.campaign.toJson());
        expect(
          MemoryEngine.replay(seed, restored.events).toJson(),
          restored.toJson(),
        );
        expect(
          (await repository.reconstructCampaign(seed.id))!.toJson(),
          restored.toJson(),
        );
        expect(restored.messages.last.text, updated.narration);
        expect(restored.messages.last.text, isNot(original.narration));
        expect(restored.events.last.payload['narrationProvider'], 'mock');
      } finally {
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
