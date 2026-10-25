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
      final note = AiStoryStep.fromJson({
        'narration': 'Eine alte Erinnerung bleibt erhalten.',
        'threadUpdates': [
          {
            'id': 'hafen',
            'status': terminal,
            'description': 'Eine ergänzende Notiz ohne Statusänderung.',
          },
        ],
        'newThreads': [],
        'npcUpdates': [],
      }, roundtrip);
      expect(note.threadUpdates.single.status, terminal);
      expect(roundtrip.hero.toJson(), created.hero.toJson());
      expect(roundtrip.quests, created.quests);
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
}
