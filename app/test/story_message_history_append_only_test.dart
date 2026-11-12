import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_campaign_engine.dart';

final _now = DateTime.utc(2026, 11, 12, 12);

NarrativeMessage _message(String id, String role, String text) =>
    NarrativeMessage(id: id, role: role, text: text, timestamp: _now);

Campaign _campaign() => Campaign(
  id: 'message-history',
  name: 'Der Nebelhafen',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Aria',
    hitPoints: 12,
    maxHitPoints: 12,
  ),
  scene: 'Vor dem alten Hafen.',
  facts: const {'location': 'harbor'},
  messages: [
    _message('player-one', 'player', 'Ich frage nach dem Hafen.'),
    _message('gm-one', 'gm', 'Der Nebel löst sich langsam.'),
  ],
  revision: 4,
);

StoryCampaignEngine _preview(
  List<NarrativeMessage> Function(Campaign, String) messages,
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
      }) => GameUpdate(
        campaign: next.copyWith(
          revision: before.revision + 1,
          messages: messages(before, narration),
        ),
        events: const [],
      ),
);

StoryCampaignEngine _committed() => StoryCampaignEngine(
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
        final committed = next.copyWith(
          revision: before.revision + 1,
          messages: [...before.messages, _message('gm-new', 'gm', narration)],
        );
        final event = GameEvent(
          id: 'event-new',
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
        return GameUpdate(
          campaign: committed.copyWith(events: [...before.events, event]),
          events: [event],
        );
      },
);

void main() {
  test('confirmed story commit appends one matching GM message and event', () {
    final before = _campaign();
    final saved = jsonEncode(before.toJson());
    final result = _committed().saveSessionRecap(before);
    final messages = result.campaign.messages;

    expect(messages, hasLength(before.messages.length + 1));
    expect(
      messages.take(before.messages.length).map((m) => m.toJson()).toList(),
      before.messages.map((m) => m.toJson()).toList(),
    );
    expect(messages.last.role, 'gm');
    expect(messages.last.text, result.narration);
    expect(messages.last.id, 'gm-new');
    expect(result.campaign.events, hasLength(1));
    expect(result.events, hasLength(1));
    expect(result.campaign.revision, 5);
    expect(result.campaign.hero.toJson(), before.hero.toJson());
    expect(result.campaign.facts, before.facts);
    expect(jsonEncode(before.toJson()), saved);
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(result.campaign.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), result.campaign.toJson());
  });

  test('old dialogue cannot be deleted, reordered or silently rewritten', () {
    final before = _campaign();
    final original = jsonEncode(before.toJson());
    final old = before.messages;
    final altered = [
      [old.first],
      [old.last, old.first],
      [
        _message('player-one', 'player', 'Eine geänderte Spielerentscheidung.'),
        old.last,
      ],
      [old.first, _message('gm-one', 'gm', 'Eine erfundene frühere Antwort.')],
      [
        old.first,
        _message('injected', 'system', 'Eine manipulierte Systemnotiz.'),
        old.last,
      ],
      [
        ...old,
        _message('gm-a', 'gm', 'Extra A'),
        _message('gm-b', 'gm', 'Extra B'),
      ],
    ];
    for (final messages in altered) {
      expect(
        () => _preview((_, __) => messages).saveSessionRecap(before),
        throwsFormatException,
      );
    }
    expect(jsonEncode(before.toJson()), original);
  });

  test(
    'a newly appended answer requires a fresh ID, GM role and exact text',
    () {
      final before = _campaign();
      final original = jsonEncode(before.toJson());
      for (final response in [
        _message('gm-one', 'gm', 'Belegtes Ende.'),
        _message('player-new', 'player', 'Belegtes Ende.'),
        _message('system-new', 'system', 'Belegtes Ende.'),
        _message('gm-new', 'gm', 'Eine andere Erzählung.'),
      ]) {
        expect(
          () => _preview(
            (campaign, _) => [...campaign.messages, response],
          ).saveSessionRecap(before),
          throwsFormatException,
        );
      }
      expect(jsonEncode(before.toJson()), original);
    },
  );

  test('journal-free preview keeps legacy unchanged-message behavior', () {
    final before = _campaign();
    final original = jsonEncode(before.toJson());
    final unchanged = _preview(
      (campaign, _) => campaign.messages,
    ).saveSessionRecap(before);
    expect(unchanged.campaign.messages, before.messages);
    expect(unchanged.events, isEmpty);
    expect(unchanged.campaign.sessionRecaps, hasLength(1));

    final withMessage = _preview(
      (campaign, narration) => [
        ...campaign.messages,
        _message('fresh-gm', 'gm', narration),
      ],
    ).saveSessionRecap(before);
    expect(withMessage.campaign.messages, hasLength(3));
    expect(withMessage.campaign.messages.last.role, 'gm');
    expect(withMessage.campaign.messages.last.text, withMessage.narration);
    expect(jsonEncode(before.toJson()), original);
  });

  test(
    'unconfirmed free-turn narration can still replace only its last GM',
    () {
      final engine = GameEngine(clock: () => _now);
      final local = engine.act(engine.createDemo(), 'Ich winke den Wachen.');
      expect(local.events.single.type, 'narrative.turn');
      final original = jsonEncode(local.campaign.toJson());
      final updated = engine.replaceNarration(
        local,
        text: 'Die Wachen grüßen zurück.',
        provider: 'mock',
      );
      expect(updated.campaign.revision, local.campaign.revision);
      expect(
        updated.campaign.messages,
        hasLength(local.campaign.messages.length),
      );
      expect(updated.campaign.messages.last.text, 'Die Wachen grüßen zurück.');
      expect(
        updated.campaign.messages.last.id,
        local.campaign.messages.last.id,
      );
      expect(
        updated.campaign.messages
            .take(local.campaign.messages.length - 1)
            .map((message) => message.toJson())
            .toList(),
        local.campaign.messages
            .take(local.campaign.messages.length - 1)
            .map((message) => message.toJson())
            .toList(),
      );
      expect(jsonEncode(local.campaign.toJson()), original);
    },
  );
}
