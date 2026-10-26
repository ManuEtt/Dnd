import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Map<String, dynamic> samplePlan() => {
  'title': 'Das Sternenmeer',
  'world': 'Ymera',
  'opening': 'Eila, am Hafen erscheint ein schwarzes Segel. Was tust du?',
  'premise': 'Ein altes Bündnis droht zu zerbrechen.',
  'secret': 'Die Königin bewahrt das letzte Licht.',
  'goal': 'Finde deinen eigenen Weg, den Frieden zu wahren.',
  'threads': [
    {
      'id': 'hafen',
      'title': 'Die Hafenspuren',
      'description': 'Ergründe das Geheimnis der Schiffe.',
    },
    {
      'id': 'bund',
      'title': 'Das alte Bündnis',
      'description': 'Entscheide zwischen zwei rivalisierenden Gruppen.',
    },
  ],
  'npcs': [
    {
      'id': 'tela',
      'name': 'Tela',
      'description': 'Unruhige Kapitänin.',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {'id': 'eiland', 'name': 'Eiland', 'description': 'Sturmgeschützte Stadt.'},
  ],
};

void main() {
  final hero = HeroCharacter(
    id: 'hero-1',
    name: 'Eila',
    className: 'Waldläufer',
  );

  test('generative opening preserves hero rules and persists hidden bible', () {
    final engine = GameEngine();
    final campaign = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    expect(campaign.name, 'Das Sternenmeer');
    expect(campaign.storyThreads, hasLength(2));
    expect(
      campaign.storyBible['secret'],
      'Die Königin bewahrt das letzte Licht.',
    );
    expect(campaign.hero.hitPoints, isNull);
    expect(campaign.quests, isEmpty);
    expect(campaign.hero.inventory, isEmpty);
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    final data = campaign.toJson()..remove('storyBible');
    expect(Campaign.fromJson(data).storyBible, isEmpty);
  });

  test('decision rewrites only narrative world and keeps a single event', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    final local = engine.act(created, 'Ich folge Tela zum Hafen.');
    final next = AiStoryStep.fromJson({
      'narration': 'Tela vertraut dir die Karte an. Wie reagierst du?',
      'threadUpdates': [
        {
          'id': 'hafen',
          'status': 'resolved',
          'description': 'Die Spur führt zur Kapitänin.',
        },
      ],
      'newThreads': [
        {
          'id': 'karte',
          'title': 'Die Karte der Sturmwinde',
          'description': 'Ein Weg führt zur Nebelinsel.',
        },
      ],
      'npcUpdates': [
        {
          'id': 'tela',
          'relationship': 'vertraut',
          'note': 'Eila hörte Tela zu.',
        },
      ],
    }, local.campaign);
    final update = engine.applyAiStoryStep(
      local,
      next,
      provider: 'mock',
      decision: 'Ich folge Tela zum Hafen.',
    );
    expect(update.events, hasLength(1));
    expect(update.campaign.revision, created.revision + 1);
    expect(update.campaign.hero.toJson(), created.hero.toJson());
    expect(update.campaign.quests, isEmpty);
    expect(update.campaign.storyThreads, hasLength(3));
    expect(update.campaign.storyThreads.first.status, 'resolved');
    expect(update.campaign.npcs.first.relationship, 'vertraut');
    expect(
      update.campaign.npcRelationshipNotes.single.note,
      'Eila hörte Tela zu.',
    );
    expect(update.campaign.storyBible['turnCount'], '1');
    expect(
      update.campaign.events.last.payload['playerDecision'],
      'Ich folge Tela zum Hafen.',
    );
    final saved = Campaign.fromJson(update.campaign.toJson());
    expect(saved.toJson(), update.campaign.toJson());
    expect(
      update.events.single.payload['stateAfter'],
      update.campaign.copyWith(events: const []).toJson(),
    );
  });

  test('AI campaign cannot accidentally execute Mooswacht demo rules', () {
    final engine = GameEngine();
    final campaign = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    final next = engine.act(
      campaign,
      'Ich suche den Messingschlüssel im Brunnen.',
    );
    expect(next.events.single.type, 'narrative.turn');
    expect(next.campaign.hero.inventory, isEmpty);
    expect(next.campaign.facts.containsKey('keyFound'), false);
  });

  test('provider cannot invent IDs, duplicate threads or modify the hero', () {
    final engine = GameEngine();
    final campaign = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    expect(
      () => AiStoryStep.fromJson({
        'narration': 'Etwas passiert.',
        'threadUpdates': [
          {'id': 'unknown', 'status': 'resolved', 'description': 'Unbekannt'},
        ],
        'newThreads': [],
        'npcUpdates': [],
      }, campaign),
      throwsFormatException,
    );
    expect(
      () => AiStoryStep.fromJson({
        'narration': 'Etwas passiert.',
        'threadUpdates': [],
        'newThreads': [
          {
            'id': 'hafen',
            'title': 'Doppelter Auftrag',
            'description': 'Ein doppelter Faden',
          },
        ],
        'npcUpdates': [],
      }, campaign),
      throwsFormatException,
    );
    expect(
      () => AiStoryPlan.fromJson({...samplePlan(), 'secret': 'x' * 1001}),
      throwsFormatException,
    );
  });
  test('confirmed ending cannot be reopened by a local AI reply', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    for (final terminal in ['resolved', 'abandoned']) {
      final saved = engine
          .saveStoryThread(
            created,
            threadId: 'hafen',
            title: 'Die Hafenspuren',
            description: 'Diese Entscheidung ist abgeschlossen.',
            status: terminal,
          )
          .campaign;
      final roundtrip = Campaign.fromJson(saved.toJson());
      expect(roundtrip.storyThreads.first.status, terminal);
      for (final forbidden in [
        'open',
        terminal == 'resolved' ? 'abandoned' : 'resolved',
      ]) {
        expect(
          () => AiStoryStep.fromJson({
            'narration': 'Der alte Handlungsstrang kehrt zurück.',
            'threadUpdates': [
              {
                'id': 'hafen',
                'status': forbidden,
                'description': 'Ein unbestätigter Rückschritt.',
              },
            ],
            'newThreads': [],
            'npcUpdates': [],
          }, roundtrip),
          throwsFormatException,
        );
      }
      final unchanged = {
        'narration': 'Eine alte Erinnerung bleibt erhalten.',
        'threadUpdates': [
          {
            'id': 'hafen',
            'status': terminal,
            'description': roundtrip.storyThreads.first.description,
          },
        ],
        'newThreads': [],
        'npcUpdates': [],
      };
      final safe = AiStoryStep.fromJson(unchanged, roundtrip);
      expect(safe.threadUpdates.single.status, terminal);
      expect(
        safe.threadUpdates.single.description,
        'Diese Entscheidung ist abgeschlossen.',
      );

      // The narrator may not silently rewrite an already confirmed ending.
      final changed = {
        ...unchanged,
        'threadUpdates': [
          {
            'id': 'hafen',
            'status': terminal,
            'description': 'Eine erfundene spätere Auflösung.',
          },
        ],
      };
      expect(
        () => AiStoryStep.fromJson(changed, roundtrip),
        throwsFormatException,
      );

      // An explicit journal edit, unlike provider text, may change history.
      final edited = engine
          .saveStoryThread(
            roundtrip,
            threadId: 'hafen',
            title: roundtrip.storyThreads.first.title,
            description: 'Spieler hat den Abschluss berichtigt.',
            status: terminal,
          )
          .campaign;
      expect(edited.storyThreads.first.status, terminal);
      expect(
        edited.storyThreads.first.description,
        'Spieler hat den Abschluss berichtigt.',
      );
      expect(edited.events.last.type, 'memory.storyThreadSaved');
      expect(
        AiStoryStep.fromJson({
          ...unchanged,
          'threadUpdates': [
            {
              'id': 'hafen',
              'status': terminal,
              'description': edited.storyThreads.first.description,
            },
          ],
        }, edited).threadUpdates.single.description,
        'Spieler hat den Abschluss berichtigt.',
      );
      expect(roundtrip.hero.toJson(), created.hero.toJson());
      expect(roundtrip.quests, created.quests);
      expect(edited.hero.toJson(), created.hero.toJson());
    }
  });

  test('explicitly reopening the thread allows a new narrative conclusion', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    final closed = engine
        .saveStoryThread(
          created,
          threadId: 'hafen',
          title: 'Die Hafenspuren',
          description: 'Die Suche ist beendet.',
          status: 'abandoned',
        )
        .campaign;
    final reopened = engine
        .saveStoryThread(
          Campaign.fromJson(closed.toJson()),
          threadId: 'hafen',
          title: 'Die Hafenspuren',
          description: 'Spieler entscheidet sich zur Rückkehr.',
          status: 'open',
        )
        .campaign;
    expect(reopened.storyThreads.first.status, 'open');
    expect(reopened.events.last.type, 'memory.storyThreadSaved');
    final action = engine.act(reopened, 'Ich verfolge die Spur erneut.');
    final proposed = AiStoryStep.fromJson({
      'narration': 'Eine neue Fährte erscheint. Was tust du?',
      'threadUpdates': [
        {
          'id': 'hafen',
          'status': 'resolved',
          'description': 'Die Spur wurde nach der Rückkehr aufgeklärt.',
        },
      ],
      'newThreads': [],
      'npcUpdates': [],
    }, action.campaign);
    final applied = engine.applyAiStoryStep(
      action,
      proposed,
      provider: 'mock',
      decision: 'Ich verfolge die Spur erneut.',
    );
    expect(applied.campaign.storyThreads.first.status, 'resolved');
    expect(applied.campaign.hero.toJson(), reopened.hero.toJson());
    expect(applied.campaign.quests, reopened.quests);
    expect(applied.events, hasLength(1));
    expect(
      applied.events.single.payload['stateAfter'],
      applied.campaign.copyWith(events: const []).toJson(),
    );
    expect(
      Campaign.fromJson(applied.campaign.toJson()).toJson(),
      applied.campaign.toJson(),
    );
  });

  test('AI reply parsed before a player closes the thread fails on apply', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    final local = engine.act(created, 'Ich gehe den alten Weg entlang.');
    final originallyValid = AiStoryStep.fromJson({
      'narration': 'Die alte Spur wird wieder aktuell.',
      'threadUpdates': [
        {'id': 'hafen', 'status': 'open', 'description': 'Noch ein Hinweis.'},
      ],
      'newThreads': [],
      'npcUpdates': [],
    }, local.campaign);
    final closed = local.campaign.copyWith(
      storyThreads: [
        for (final thread in local.campaign.storyThreads)
          thread.id == 'hafen' ? thread.copyWith(status: 'resolved') : thread,
      ],
    );
    final changed = GameUpdate(campaign: closed, events: local.events);
    final before = changed.campaign.toJson();
    expect(
      () => engine.applyAiStoryStep(
        changed,
        originallyValid,
        provider: 'mock',
        decision: 'Ich gehe den alten Weg entlang.',
      ),
      throwsFormatException,
    );
    expect(changed.campaign.toJson(), before);
  });

  test(
    'duplicate confirmed NPC IDs cannot fan out one AI relationship update',
    () {
      final engine = GameEngine();
      final created = engine.createAiCampaign(
        hero,
        AiStoryPlan.fromJson(samplePlan()),
        provider: 'mock',
      );
      final turn = engine.act(created, 'Ich spreche mit Tela.');
      final response = {
        'narration': 'Tela berichtet vom Hafen.',
        'threadUpdates': [],
        'newThreads': [],
        'npcUpdates': [
          {
            'id': 'tela',
            'relationship': 'freundlich',
            'note': 'Ein bestätigtes Gespräch.',
          },
        ],
      };
      final valid = AiStoryStep.fromJson(response, turn.campaign);
      expect(valid.npcUpdates.single.id, 'tela');

      final ambiguous = turn.campaign.copyWith(
        npcs: [
          ...turn.campaign.npcs,
          turn.campaign.npcs.first.copyWith(relationship: 'misstrauisch'),
        ],
      );
      final before = ambiguous.toJson();
      expect(
        () => AiStoryStep.fromJson(response, ambiguous),
        throwsFormatException,
      );
      // Even a formerly valid response is rechecked before story commit.
      expect(
        () => engine.applyAiStoryStep(
          GameUpdate(campaign: ambiguous, events: turn.events),
          valid,
          provider: 'mock',
          decision: 'Ich spreche mit Tela.',
        ),
        throwsFormatException,
      );
      expect(ambiguous.toJson(), before);
      expect(ambiguous.hero.toJson(), turn.campaign.hero.toJson());
    },
  );

  test('conflicting saved thread IDs cannot be silently collapsed', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    final response = {
      'narration': 'Die Hafenspur setzt sich fort.',
      'threadUpdates': [
        {
          'id': 'hafen',
          'status': 'open',
          'description': 'Der nächste Hinweis.',
        },
      ],
      'newThreads': [],
      'npcUpdates': [],
    };
    expect(AiStoryStep.fromJson(response, created).threadUpdates, hasLength(1));
    final ambiguous = created.copyWith(
      storyThreads: [
        ...created.storyThreads,
        created.storyThreads.first.copyWith(status: 'resolved'),
      ],
    );
    expect(
      () => AiStoryStep.fromJson(response, ambiguous),
      throwsFormatException,
    );
    expect(ambiguous.storyThreads.last.status, 'resolved');
    expect(ambiguous.hero.toJson(), created.hero.toJson());
  });

  test('thread and NPC IDs remain independent namespaces', () {
    final engine = GameEngine();
    final created = engine.createAiCampaign(
      hero,
      AiStoryPlan.fromJson(samplePlan()),
      provider: 'mock',
    );
    final separateNamespaces = created.copyWith(
      npcs: const [
        WorldNpc(
          id: 'hafen',
          name: 'Tela',
          description: 'Kapitänin am Hafen.',
          relationship: 'neutral',
        ),
      ],
    );
    final step = AiStoryStep.fromJson({
      'narration': 'Die Kapitänin weist auf die Hafenspur.',
      'threadUpdates': [
        {'id': 'hafen', 'status': 'open', 'description': 'Noch ungelöst.'},
      ],
      'newThreads': [],
      'npcUpdates': [
        {
          'id': 'hafen',
          'relationship': 'vorsichtig',
          'note': 'Das Gespräch war freundlich.',
        },
      ],
    }, separateNamespaces);
    expect(step.threadUpdates.single.id, 'hafen');
    expect(step.npcUpdates.single.id, 'hafen');
    expect(separateNamespaces.hero.toJson(), created.hero.toJson());
  });
}
