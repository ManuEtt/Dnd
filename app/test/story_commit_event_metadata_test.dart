import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_campaign_engine.dart';

final _now = DateTime.utc(2026, 11, 12);

Campaign _campaign() => Campaign(
  id: 'event-contract',
  name: 'Die Nebelbrücke',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 16,
    maxHitPoints: 16,
  ),
  scene: 'Die Brücke liegt im Nebel.',
  revision: 4,
);

GameEvent _withFields(
  GameEvent event, {
  String? type,
  Map<String, dynamic>? payload,
}) => GameEvent(
  id: event.id,
  campaignId: event.campaignId,
  sessionId: event.sessionId,
  timestamp: event.timestamp,
  type: type ?? event.type,
  entities: event.entities,
  payload: payload ?? event.payload,
);

GameUpdate _replaceEvent(GameUpdate update, GameEvent event) => GameUpdate(
  campaign: update.campaign.copyWith(events: [event]),
  events: [event],
);

StoryCampaignEngine _engine(GameUpdate Function(GameUpdate) change) =>
    StoryCampaignEngine(
      nextId: (prefix) => '$prefix-test',
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
              id: 'new-event',
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
            return change(
              GameUpdate(
                campaign: committed.copyWith(events: [event]),
                events: [event],
              ),
            );
          },
    );

void main() {
  test('confirmed story audit matches action, revision and saved state', () {
    final engine = GameEngine(clock: () => _now);
    final before = engine.createDemo();
    final original = jsonEncode(before.toJson());
    final recap = engine.saveSessionRecap(before);
    final event = recap.events.single;

    expect(event.type, 'memory.sessionRecapSaved');
    expect(event.payload.keys.toSet(), {
      'recapId',
      'revision',
      'stateAfter',
    });
    expect(event.payload['recapId'], recap.campaign.sessionRecaps.single.id);
    expect(event.payload['revision'], recap.campaign.revision);
    expect(
      event.payload['stateAfter'],
      recap.campaign.copyWith(events: const []).toJson(),
    );
    expect(recap.campaign.hero.toJson(), before.hero.toJson());
    expect(jsonEncode(before.toJson()), original);

    final thread = engine.saveStoryThread(
      recap.campaign,
      title: 'Der Hinweis',
      description: 'Das Tor finden.',
      status: 'open',
    );
    expect(thread.events.single.type, 'memory.storyThreadSaved');
    expect(
      thread.events.single.payload['threadId'],
      thread.campaign.storyThreads.single.id,
    );
    expect(thread.events.single.payload['status'], 'open');
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(thread.campaign.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), thread.campaign.toJson());
  });

  test('a callback cannot forge another event type', () {
    final before = _campaign();
    final original = jsonEncode(before.toJson());
    expect(
      () => _engine(
        (update) => _replaceEvent(
          update,
          _withFields(update.events.single, type: 'xp.reward.confirmed'),
        ),
      ).saveSessionRecap(before),
      throwsFormatException,
    );
    expect(jsonEncode(before.toJson()), original);
  });

  test('a callback cannot change, omit or invent confirmed audit fields', () {
    final before = _campaign();
    final original = jsonEncode(before.toJson());
    final good = _engine((update) => update).saveSessionRecap(before);
    final payload = good.events.single.payload;
    final invalid = <Map<String, dynamic>>[
      {...payload, 'recapId': 'forged-id'},
      {
        'revision': payload['revision'],
        'stateAfter': payload['stateAfter'],
      },
      {...payload, 'surpriseReward': 1000},
      {...payload, 'revision': before.revision},
    ];

    for (final fields in invalid) {
      expect(
        () => _engine(
          (update) => _replaceEvent(
            update,
            _withFields(update.events.single, payload: fields),
          ),
        ).saveSessionRecap(before),
        throwsFormatException,
      );
    }
    expect(jsonEncode(before.toJson()), original);
  });

  test('new confirmed event cannot keep a stale campaign revision', () {
    final before = _campaign();
    final saved = jsonEncode(before.toJson());
    expect(
      () => _engine((update) {
        final rewound = update.campaign.copyWith(revision: before.revision);
        final added = _withFields(
          update.events.single,
          payload: {
            ...update.events.single.payload,
            'revision': rewound.revision,
            'stateAfter': rewound.copyWith(events: const []).toJson(),
          },
        );
        return GameUpdate(
          campaign: rewound.copyWith(events: [added]),
          events: [added],
        );
      }).saveSessionRecap(before),
      throwsFormatException,
    );
    expect(jsonEncode(before.toJson()), saved);
  });

  test('canonical payload key order and journal-free previews still work', () {
    final before = _campaign();
    final saved = jsonEncode(before.toJson());
    final accepted = _engine((update) {
      final event = update.events.single;
      final payload = event.payload;
      return _replaceEvent(
        update,
        _withFields(
          event,
          payload: {
            'stateAfter': payload['stateAfter'],
            'revision': payload['revision'],
            'recapId': payload['recapId'],
          },
        ),
      );
    }).saveSessionRecap(before);
    expect(accepted.events.single.payload['recapId'], 'recap-test');
    expect(accepted.campaign.revision, 5);

    final preview = StoryCampaignEngine(
      nextId: (prefix) => '$prefix-test',
      clock: () => _now,
      commit:
          (
            old,
            next,
            narration, {
            required String type,
            required Map<String, dynamic> payload,
          }) => GameUpdate(
            campaign: next.copyWith(revision: old.revision + 1),
            events: const [],
          ),
    ).saveSessionRecap(before);
    expect(preview.events, isEmpty);
    expect(preview.campaign.sessionRecaps, hasLength(1));
    expect(jsonEncode(before.toJson()), saved);
  });
}
