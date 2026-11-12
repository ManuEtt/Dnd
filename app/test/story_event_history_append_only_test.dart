import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_campaign_engine.dart';

final _now = DateTime.utc(2026, 11, 12, 8);

GameEvent _event(
  String id, {
  Map<String, dynamic> payload = const {},
  String campaignId = 'story-history',
  String sessionId = 'session-1',
}) => GameEvent(
  id: id,
  campaignId: campaignId,
  sessionId: sessionId,
  timestamp: _now,
  type: 'memory.sessionRecapSaved',
  payload: payload,
);

Campaign _campaign() => Campaign(
  id: 'story-history',
  name: 'Der Nebelhafen',
  world: 'Valdorn',
  sessionId: 'session-1',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 12,
    maxHitPoints: 12,
  ),
  scene: 'Vor dem Hafen.',
  facts: const {'location': 'harbor'},
  events: [
    _event('old-one', payload: {
      'details': {'a': 'one', 'b': 'two'},
    }),
    _event('old-two', payload: {'confirmed': true}),
  ],
  revision: 4,
);

StoryCampaignEngine _engine(
  GameUpdate Function(GameUpdate) transform,
) => StoryCampaignEngine(
  nextId: (prefix) => '$prefix-new',
  clock: () => _now,
  commit:
      (
        before,
        next,
        narration, {
        required String type,
        required Map<String, dynamic> payload,
      }) {
        final committed = next.copyWith(revision: before.revision + 1);
        final event = GameEvent(
          id: 'new-story-event',
          campaignId: before.id,
          sessionId: before.sessionId,
          timestamp: _now,
          type: type,
          payload: {
            ...payload,
            'revision': committed.revision,
            'stateAfter': committed.copyWith(events: const []).toJson(),
          },
        );
        return transform(
          GameUpdate(
            campaign: committed.copyWith(events: [...before.events, event]),
            events: [event],
          ),
        );
      },
);

GameUpdate _withJournal(
  GameUpdate update,
  List<GameEvent> events, {
  List<GameEvent>? reported,
}) => GameUpdate(
  campaign: update.campaign.copyWith(events: events),
  events: reported ?? update.events,
);

void main() {
  test('confirmed history survives one story event and JSON roundtrip', () {
    final before = _campaign();
    final savedBytes = jsonEncode(before.toJson());
    final update = _engine((result) => result).saveSessionRecap(before);

    expect(update.events, hasLength(1));
    expect(update.campaign.events, hasLength(3));
    expect(
      update.campaign.events.take(2).map((e) => e.toJson()).toList(),
      before.events.map((e) => e.toJson()).toList(),
    );
    expect(update.campaign.events.last.toJson(), update.events.single.toJson());
    expect(update.campaign.sessionRecaps, hasLength(1));
    expect(update.campaign.revision, 5);
    expect(update.campaign.hero.toJson(), before.hero.toJson());
    expect(update.campaign.facts, before.facts);
    expect(jsonEncode(before.toJson()), savedBytes);
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(update.campaign.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), update.campaign.toJson());
  });

  test('truncation, rewrite, reorder and extra event are rejected', () {
    final before = _campaign();
    final originalBytes = jsonEncode(before.toJson());
    final good = _engine((result) => result).saveSessionRecap(before);
    final oldOne = before.events.first;
    final oldTwo = before.events.last;
    final added = good.events.single;
    final modified = _event('old-one', payload: {
      'details': {'a': 'changed', 'b': 'two'},
    });
    final variants = <List<GameEvent>>[
      [oldOne, added],
      [modified, oldTwo, added],
      [oldTwo, oldOne, added],
      [oldOne, oldTwo, added, _event('unrelated-new')],
    ];
    for (final journal in variants) {
      expect(
        () => _engine((result) => _withJournal(result, journal))
            .saveSessionRecap(before),
        throwsFormatException,
      );
    }
    expect(jsonEncode(before.toJson()), originalBytes);
  });

  test('new story event must match reported event and saved checkpoint', () {
    final before = _campaign();
    final good = _engine((result) => result).saveSessionRecap(before);
    final added = good.events.single;
    final prefix = before.events;
    final invalid = <GameUpdate>[
      _withJournal(good, [...prefix, _event('old-one')]),
      _withJournal(good, [...prefix, added], reported: []),
      _withJournal(good, [...prefix, added], reported: [prefix.first]),
      _withJournal(good, [...prefix, added], reported: [added, added]),
      _withJournal(good, prefix, reported: [added]),
      _withJournal(good, [
        ...prefix,
        _event(
          added.id,
          campaignId: 'another-campaign',
          payload: added.payload,
        ),
      ]),
      _withJournal(good, [
        ...prefix,
        _event(
          added.id,
          sessionId: 'another-session',
          payload: added.payload,
        ),
      ]),
      _withJournal(good, [
        ...prefix,
        _event(added.id, payload: {
          ...added.payload,
          'stateAfter': {'forged': true},
        }),
      ]),
    ];
    for (final candidate in invalid) {
      expect(
        () => _engine((result) => candidate).saveSessionRecap(before),
        throwsFormatException,
      );
    }
  });

  test('canonical JSON key order does not change confirmed event history', () {
    final before = _campaign();
    final originalBytes = jsonEncode(before.toJson());
    final reordered = _event('old-one', payload: {
      'details': {'b': 'two', 'a': 'one'},
    });
    final result = _engine(
      (update) => _withJournal(update, [
        reordered,
        before.events.last,
        update.events.single,
      ]),
    ).saveSessionRecap(before);
    expect(result.campaign.events, hasLength(3));
    expect(result.campaign.revision, 5);
    expect(jsonEncode(before.toJson()), originalBytes);
  });

  test(
    'journal-free legacy callback remains valid if history is unchanged',
    () {
      final before = Campaign.fromJson(
        jsonDecode(jsonEncode(_campaign().toJson())) as Map<String, dynamic>,
      );
      final result = _engine(
        (update) => _withJournal(update, before.events, reported: []),
      ).saveSessionRecap(before);
      expect(
        result.campaign.events.map((e) => e.toJson()).toList(),
        before.events.map((e) => e.toJson()).toList(),
      );
      expect(result.events, isEmpty);
      expect(result.campaign.sessionRecaps, hasLength(1));
    },
  );
}
