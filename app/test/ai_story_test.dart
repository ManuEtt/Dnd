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
}
