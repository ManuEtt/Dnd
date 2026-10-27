import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart' as story;

Campaign _seed() => Campaign(
  id: 'story-replay-campaign',
  name: 'Rabenwacht',
  world: 'Valdorn',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'hero', name: 'Aria'),
  scene: 'Vor dem Tor.',
);

GameEvent _eventLike(
  GameEvent original, {
  String? id,
  String? sessionId,
  Map<String, dynamic>? payload,
}) => GameEvent(
  id: id ?? original.id,
  campaignId: original.campaignId,
  sessionId: sessionId ?? original.sessionId,
  timestamp: original.timestamp,
  type: original.type,
  entities: original.entities,
  payload: payload ?? original.payload,
);

void main() {
  final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 27));

  test('a confirmed same-session journal replays without changing rules', () {
    final seed = _seed();
    final update = engine.act(seed, 'Ich frage nach dem Weg.');
    final replayed = story.MemoryEngine.replay(seed, update.events);

    expect(replayed.toJson(), update.campaign.toJson());
    expect(replayed.hero.toJson(), seed.hero.toJson());
    expect(replayed.sessionId, seed.sessionId);
  });

  test('new event from another session is rejected without side effects', () {
    final seed = _seed();
    final update = engine.act(seed, 'Ich gehe zum Stadttor.');
    final before = jsonEncode(seed.toJson());
    final source = update.events.single;
    final foreign = _eventLike(source, sessionId: 'session-foreign');

    expect(
      () => story.MemoryEngine.replay(seed, [foreign]),
      throwsFormatException,
    );
    expect(jsonEncode(seed.toJson()), before);

    // Older event formats without checkpoints must not bypass identity checks.
    final noCheckpoint = _eventLike(
      source,
      id: 'legacy-unrelated-event',
      sessionId: 'session-foreign',
      payload: const {},
    );
    expect(
      () => story.MemoryEngine.replay(seed, [noCheckpoint]),
      throwsFormatException,
    );
  });

  test('checkpoint cannot silently switch the confirmed session', () {
    final seed = _seed();
    final source = engine.act(seed, 'Ich lese den Aushang.').events.single;
    final checkpoint = Map<String, dynamic>.from(
      source.payload['stateAfter'] as Map<String, dynamic>,
    )..['sessionId'] = 'session-forged';
    final forged = _eventLike(
      source,
      payload: {...source.payload, 'stateAfter': checkpoint},
    );

    expect(
      () => story.MemoryEngine.replay(seed, [forged]),
      throwsFormatException,
    );
    expect(seed.sessionId, 'session-one');
  });

  test('identical prior-session event remains idempotent after session change', () {
    final seed = _seed();
    final update = engine.act(seed, 'Ich bleibe beim Brunnen.');
    final later = update.campaign.copyWith(sessionId: 'session-two');
    final before = jsonEncode(later.toJson());

    // This is already in the saved history: replay must not reject it merely
    // because the campaign now continues in a later session.
    final replayed = story.MemoryEngine.replay(later, [update.events.single]);
    expect(replayed.toJson(), later.toJson());
    expect(jsonEncode(later.toJson()), before);
  });
}
