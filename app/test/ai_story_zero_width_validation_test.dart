import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/ai_story.dart';

Map<String, dynamic> _plan() => {
  'title': 'Die Sturminsel',
  'world': 'Valdorn',
  'opening': 'Am Hafen beginnt ein neues Abenteuer.',
  'premise': 'Ein Handelsschiff ist verschwunden.',
  'secret': 'Eine versiegelte Karte liegt im Turm.',
  'goal': 'Finde die Spur des Schiffes.',
  'threads': [
    {
      'id': 'hafen',
      'title': 'Die Hafenspur',
      'description': 'Untersuche die Anleger.',
    },
    {
      'id': 'turm',
      'title': 'Der Turm',
      'description': 'Suche die alte Karte.',
    },
  ],
  'npcs': [
    {
      'id': 'tela',
      'name': 'Tela',
      'description': 'Kapitänin des Handelsschiffs.',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {
      'id': 'hafenstadt',
      'name': 'Hafenstadt',
      'description': 'Eine Stadt an der Küste.',
    },
  ],
};

Campaign _campaign() => Campaign(
  id: 'campaign-1',
  name: 'Die Sturminsel',
  world: 'Valdorn',
  sessionId: 'session-1',
  hero: HeroCharacter(id: 'hero-1', name: 'Eila'),
  scene: 'Du stehst am Hafen.',
  storyThreads: const [
    StoryThread(
      id: 'hafen',
      title: 'Die Hafenspur',
      description: 'Untersuche die Anleger.',
    ),
  ],
  npcs: const [WorldNpc(id: 'tela', name: 'Tela', relationship: 'neutral')],
);

Map<String, dynamic> _step() => {
  'narration': 'Tela erzählt vom Schiff.',
  'threadUpdates': [
    {
      'id': 'hafen',
      'status': 'open',
      'description': 'Die Fährte führt zur Küste.',
    },
  ],
  'newThreads': [
    {
      'id': 'insel',
      'title': 'Die Insel',
      'description': 'Eine neue Spur.',
    },
  ],
  'npcUpdates': [
    {
      'id': 'tela',
      'relationship': 'freundlich',
      'note': 'Tela hat freiwillig gesprochen.',
    },
  ],
};

void main() {
  test('clean multilingual prose, tabs and line breaks remain accepted', () {
    final plan = _plan();
    plan['opening'] = 'Über dem Hafen:\n\t„Willkommen, Eila!“';
    final parsedPlan = AiStoryPlan.fromJson(plan);
    expect(parsedPlan.opening, plan['opening']);
    expect(parsedPlan.npcs.single.name, 'Tela');

    final campaign = _campaign();
    final before = campaign.toJson();
    final step = _step();
    step['narration'] = 'Tela lächelt.\n\tWas tust du?';
    final parsedStep = AiStoryStep.fromJson(step, campaign);
    expect(parsedStep.narration, step['narration']);
    expect(parsedStep.npcUpdates.single.id, 'tela');
    expect(campaign.toJson(), before);
    expect(Campaign.fromJson(before).toJson(), before);
  });

  for (final marker in <String>['\u200c', '\u200d']) {
    test('AI plan rejects hidden joiner in every top-level field', () {
      for (final field in [
        'title',
        'world',
        'opening',
        'premise',
        'secret',
        'goal',
      ]) {
        final plan = _plan();
        plan[field] = 'Hafen' + marker + 'stadt';
        expect(
          () => AiStoryPlan.fromJson(plan),
          throwsFormatException,
          reason: 'Field ' + field + ' must reject invisible joiner',
        );
      }
    });

    test('AI plan rejects hidden joiner in entity prose', () {
      const fields = <String, List<String>>{
        'threads': ['title', 'description'],
        'npcs': ['name', 'description', 'relationship'],
        'places': ['name', 'description'],
      };
      for (final entry in fields.entries) {
        for (final field in entry.value) {
          final plan = _plan();
          final items = plan[entry.key] as List;
          final changed = Map<String, dynamic>.from(items.first as Map);
          changed[field] = 'Mira' + marker + 'Name';
          plan[entry.key] = [changed, ...items.skip(1)];
          expect(
            () => AiStoryPlan.fromJson(plan),
            throwsFormatException,
            reason: 'Field ' + entry.key + '.' + field + ' must be safe',
          );
        }
      }
    });

    test('AI step rejects hidden joiner in narration and updates', () {
      final campaign = _campaign();
      final before = campaign.toJson();
      final invalidNarration = _step();
      invalidNarration['narration'] = 'Die' + marker + 'Fährte';
      expect(
        () => AiStoryStep.fromJson(invalidNarration, campaign),
        throwsFormatException,
      );

      const fields = <String, List<String>>{
        'threadUpdates': ['description'],
        'newThreads': ['title', 'description'],
        'npcUpdates': ['relationship', 'note'],
      };
      for (final entry in fields.entries) {
        for (final field in entry.value) {
          final step = _step();
          final items = step[entry.key] as List;
          final changed = Map<String, dynamic>.from(items.first as Map);
          changed[field] = 'Küste' + marker + 'Hafen';
          step[entry.key] = [changed];
          expect(
            () => AiStoryStep.fromJson(step, campaign),
            throwsFormatException,
            reason: 'Field ' + entry.key + '.' + field + ' must be safe',
          );
        }
      }
      expect(campaign.toJson(), before);
      expect(campaign.hero.toJson(), _campaign().hero.toJson());
    });
  }
}
