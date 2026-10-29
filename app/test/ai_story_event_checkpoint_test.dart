import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/ai_story.dart';

AiStoryPlan _plan() => AiStoryPlan.fromJson({
  'title': 'Der Nebelhafen',
  'world': 'Ymera',
  'opening': 'Tela wartet am Kai. Was tust du?',
  'premise': 'Ein verborgenes Schiff kehrt zurück.',
  'secret': 'Der Hafenmeister kennt den Kurs.',
  'goal': 'Finde das Schiff.',
  'threads': [
    {
      'id': 'spur',
      'title': 'Die Schiffsspur',
      'description': 'Finde den Kurs.',
    },
    {
      'id': 'bund',
      'title': 'Das Hafenbündnis',
      'description': 'Suche Verbündete.',
    },
  ],
  'npcs': [
    {
      'id': 'tela',
      'name': 'Tela',
      'description': 'Kapitänin am Hafen.',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {'id': 'kai', 'name': 'Kai', 'description': 'Am Meer.'},
  ],
});

AiStoryStep _step(Campaign campaign) => AiStoryStep.fromJson({
  'narration': 'Tela zeigt den Weg zum Schiff.',
  'threadUpdates': [],
  'newThreads': [],
  'npcUpdates': [],
}, campaign);

GameEvent _eventWith(GameEvent event, Map<String, dynamic> fields) =>
    GameEvent.fromJson({...event.toJson(), ...fields});

void main() {
  test('current AI turn replaces only its own event and survives JSON', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 12),
      _plan(),
      provider: 'mock',
    );
    final local = engine.act(created, 'Ich frage Tela nach dem Schiff.');
    final result = engine.applyAiStoryStep(
      local,
      _step(local.campaign),
      provider: 'mock',
      decision: 'Ich frage Tela nach dem Schiff.',
    );

    expect(result.events, hasLength(1));
    expect(result.campaign.events, hasLength(local.campaign.events.length));
    expect(result.events.single.id, local.events.single.id);
    expect(result.campaign.scene, 'Tela zeigt den Weg zum Schiff.');
    expect(result.campaign.hero.toJson(), created.hero.toJson());
    expect(result.campaign.quests, created.quests);
    expect(
      result.events.single.payload['stateAfter'],
      result.campaign.copyWith(events: const []).toJson(),
    );
    expect(
      Campaign.fromJson(
        jsonDecode(jsonEncode(result.campaign.toJson()))
            as Map<String, dynamic>,
      ).toJson(),
      result.campaign.toJson(),
    );
  });

  test('forged events, sessions and checkpoints are rejected untouched', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 12),
      _plan(),
      provider: 'mock',
    );
    final local = engine.act(created, 'Ich spreche mit Tela.');
    final event = local.events.single;
    final invalid = <GameUpdate>[
      GameUpdate(
        campaign: local.campaign,
        events: [_eventWith(event, {'id': 'wrong-event'})],
      ),
      GameUpdate(
        campaign: local.campaign,
        events: [_eventWith(event, {'campaignId': 'another-campaign'})],
      ),
      GameUpdate(
        campaign: local.campaign,
        events: [_eventWith(event, {'sessionId': 'another-session'})],
      ),
      GameUpdate(
        campaign: local.campaign,
        events: [
          _eventWith(event, {
            'payload': {...event.payload, 'stateAfter': <String, dynamic>{}},
          }),
        ],
      ),
      GameUpdate(
        campaign: local.campaign.copyWith(events: const []),
        events: local.events,
      ),
      GameUpdate(
        campaign: local.campaign.copyWith(scene: 'Manipulierte Szene'),
        events: local.events,
      ),
      GameUpdate(
        campaign: local.campaign.copyWith(
          events: [_eventWith(event, {'id': 'different-journal-event'})],
        ),
        events: local.events,
      ),
    ];
    for (final candidate in invalid) {
      final before = jsonEncode(candidate.campaign.toJson());
      expect(
        () => engine.applyAiStoryStep(
          candidate,
          _step(candidate.campaign),
          provider: 'mock',
          decision: 'Ich spreche mit Tela.',
        ),
        throwsFormatException,
      );
      expect(jsonEncode(candidate.campaign.toJson()), before);
      expect(candidate.campaign.hero.toJson(), created.hero.toJson());
    }
  });

  test('previous turn cannot replace newer confirmed journal event', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      HeroCharacter(id: 'hero', name: 'Aria'),
      _plan(),
      provider: 'mock',
    );
    final first = engine.act(created, 'Ich schaue zum Schiff.');
    final second = engine.act(first.campaign, 'Ich folge der Spur.');
    final stale = GameUpdate(
      campaign: second.campaign,
      events: first.events,
    );
    final before = jsonEncode(second.campaign.toJson());
    expect(
      () => engine.applyAiStoryStep(
        stale,
        _step(second.campaign),
        provider: 'mock',
        decision: 'Ich schaue zum Schiff.',
      ),
      throwsFormatException,
    );
    expect(jsonEncode(second.campaign.toJson()), before);
  });
}
