import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/ai_story.dart';

const _hiddenMarks = <String>[
  '\u00ad',
  '\u034f',
  '\u180e',
  '\u206a',
  '\u206b',
  '\u206c',
  '\u206d',
  '\u206e',
  '\u206f',
];

Map<String, dynamic> _plan() => {
  'title': 'Die Nebelinsel',
  'world': 'Valdorn',
  'opening': 'Eine Glocke ertönt.',
  'premise': 'Der Hafen ist bedroht.',
  'secret': 'Eine alte Karte hilft.',
  'goal': 'Finde den sicheren Weg.',
  'threads': [
    {'id': 'weg', 'title': 'Der Weg', 'description': 'Suche die Karte.'},
    {'id': 'hafen', 'title': 'Der Hafen', 'description': 'Warnung an alle.'},
  ],
  'npcs': [
    {
      'id': 'mira',
      'name': 'Mira',
      'description': 'Eine Botin.',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {'id': 'turm', 'name': 'Turm', 'description': 'Ein alter Wachturm.'},
  ],
};

Campaign _campaign() => Campaign(
  id: 'safe-story',
  name: 'Nebelinsel',
  world: 'Valdorn',
  sessionId: 'session-1',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Die alte Straße',
  storyThreads: const [
    StoryThread(id: 'weg', title: 'Der Weg', description: 'Suche die Karte.'),
  ],
  npcs: const [WorldNpc(id: 'mira', name: 'Mira')],
);

Map<String, dynamic> _turn() => {
  'narration': 'Mira deutet auf die Karte.',
  'threadUpdates': [
    {'id': 'weg', 'status': 'open', 'description': 'Eine neue Spur.'},
  ],
  'newThreads': [
    {'id': 'ufer', 'title': 'Das Ufer', 'description': 'Eine Brücke.'},
  ],
  'npcUpdates': [
    {
      'id': 'mira',
      'relationship': 'freundlich',
      'note': 'Mira hat den Weg bestätigt.',
    },
  ],
};

void main() {
  test('valid multiline Unicode narration and emoji remain supported', () {
    final story = _plan();
    story['opening'] = 'Äste rauschen.\n🐉 reist weiter\tund kehrt zurück ❤️';
    expect(AiStoryPlan.fromJson(story).opening, contains('kehrt zurück'));

    final parsed = AiStoryStep.fromJson({
      ..._turn(),
      'narration': 'Die Tür öffnet sich.\nWas tust du? 🐉',
    }, _campaign());
    expect(parsed.narration, contains('Was tust du?'));
    expect(parsed.npcUpdates.single.id, 'mira');
  });

  test('all top-level plan fields reject invisible legacy marks', () {
    for (final mark in _hiddenMarks) {
      for (final field in [
        'title',
        'world',
        'opening',
        'premise',
        'secret',
        'goal',
      ]) {
        final plan = _plan()..[field] = 'Vor${mark}Nach';
        expect(
          () => AiStoryPlan.fromJson(plan),
          throwsFormatException,
          reason: field,
        );
      }
    }
  });

  test('nested thread, NPC and place prose reject invisible marks', () {
    for (final mark in _hiddenMarks) {
      for (final field in ['title', 'description']) {
        final plan = _plan();
        final thread = (plan['threads'] as List).first as Map<String, dynamic>;
        thread[field] = 'Vor${mark}Nach';
        expect(() => AiStoryPlan.fromJson(plan), throwsFormatException);
      }
      for (final field in ['name', 'description', 'relationship']) {
        final plan = _plan();
        final npc = (plan['npcs'] as List).first as Map<String, dynamic>;
        npc[field] = 'Vor${mark}Nach';
        expect(() => AiStoryPlan.fromJson(plan), throwsFormatException);
      }
      for (final field in ['name', 'description']) {
        final plan = _plan();
        final place = (plan['places'] as List).first as Map<String, dynamic>;
        place[field] = 'Vor${mark}Nach';
        expect(() => AiStoryPlan.fromJson(plan), throwsFormatException);
      }
    }
  });

  test('all turn prose rejects marks without changing saved state', () {
    final campaign = _campaign();
    final saved = jsonEncode(campaign.toJson());
    for (final mark in _hiddenMarks) {
      final narration = _turn()..['narration'] = 'Vor${mark}Nach';
      expect(
        () => AiStoryStep.fromJson(narration, campaign),
        throwsFormatException,
      );
      for (final field in ['description']) {
        final turn = _turn();
        final thread =
            (turn['threadUpdates'] as List).first as Map<String, dynamic>;
        thread[field] = 'Vor${mark}Nach';
        expect(
          () => AiStoryStep.fromJson(turn, campaign),
          throwsFormatException,
        );
      }
      for (final field in ['title', 'description']) {
        final turn = _turn();
        final thread =
            (turn['newThreads'] as List).first as Map<String, dynamic>;
        thread[field] = 'Vor${mark}Nach';
        expect(
          () => AiStoryStep.fromJson(turn, campaign),
          throwsFormatException,
        );
      }
      for (final field in ['relationship', 'note']) {
        final turn = _turn();
        final npc = (turn['npcUpdates'] as List).first as Map<String, dynamic>;
        npc[field] = 'Vor${mark}Nach';
        expect(
          () => AiStoryStep.fromJson(turn, campaign),
          throwsFormatException,
        );
      }
    }
    expect(jsonEncode(campaign.toJson()), saved);
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });
}
