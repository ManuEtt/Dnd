import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/ai_story.dart';

// U+2061..U+2064 are invisible mathematical operators, not ordinary spaces.
const _operators = <String>['\u2061', '\u2062', '\u2063', '\u2064'];

Map<String, dynamic> _plan() => {
  'title': 'Die Nebelinsel',
  'world': 'Valdorn',
  'opening': 'Eine Glocke ertönt.',
  'premise': 'Der Hafen ist bedroht.',
  'secret': 'Eine alte Karte hilft.',
  'goal': 'Finde den sicheren Weg.',
  'threads': [
    {'id': 'weg', 'title': 'Der Weg', 'description': 'Suche die Karte.'},
    {'id': 'hafen', 'title': 'Der Hafen', 'description': 'Warne die Bewohner.'},
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
  id: 'ai-text-guard',
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

Map<String, dynamic> _offer() => {
  'id': 'tower-quest',
  'title': 'Der alte Turm',
  'description': 'Eine Spur führt zum Turm.',
  'archetype': 'investigation',
  'questTitle': 'Suche den Turm',
  'questDescription': 'Finde die versteckte Treppe.',
};

Map<String, dynamic> _step() => {
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
  test('AI plan rejects invisible operators in all story text fields', () {
    for (final mark in _operators) {
      for (final field in [
        'title',
        'world',
        'opening',
        'premise',
        'secret',
        'goal',
      ]) {
        final plan = _plan()..[field] = 'Vor$mark Nach';
        expect(
          () => AiStoryPlan.fromJson(plan),
          throwsFormatException,
          reason: field,
        );
      }
      for (final field in ['title', 'description']) {
        final plan = _plan();
        final thread = (plan['threads'] as List).first as Map<String, dynamic>;
        thread[field] = 'Vor$mark Nach';
        expect(() => AiStoryPlan.fromJson(plan), throwsFormatException);
      }
      for (final field in ['name', 'description', 'relationship']) {
        final plan = _plan();
        final npc = (plan['npcs'] as List).first as Map<String, dynamic>;
        npc[field] = 'Vor$mark Nach';
        expect(() => AiStoryPlan.fromJson(plan), throwsFormatException);
      }
      for (final field in ['name', 'description']) {
        final plan = _plan();
        final place = (plan['places'] as List).first as Map<String, dynamic>;
        place[field] = 'Vor$mark Nach';
        expect(() => AiStoryPlan.fromJson(plan), throwsFormatException);
      }
    }
  });

  test('AI turn rejects invisible operators in narration and updates', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    for (final mark in _operators) {
      final narration = _step()..['narration'] = 'Vor$mark Nach';
      expect(
        () => AiStoryStep.fromJson(narration, campaign),
        throwsFormatException,
      );
      final threadUpdate = _step();
      final existing =
          (threadUpdate['threadUpdates'] as List).first as Map<String, dynamic>;
      existing['description'] = 'Vor$mark Nach';
      expect(
        () => AiStoryStep.fromJson(threadUpdate, campaign),
        throwsFormatException,
      );
      for (final field in ['title', 'description']) {
        final turn = _step();
        final added = (turn['newThreads'] as List).first as Map<String, dynamic>;
        added[field] = 'Vor$mark Nach';
        expect(
          () => AiStoryStep.fromJson(turn, campaign),
          throwsFormatException,
        );
      }
      for (final field in ['relationship', 'note']) {
        final turn = _step();
        final npc = (turn['npcUpdates'] as List).first as Map<String, dynamic>;
        npc[field] = 'Vor$mark Nach';
        expect(
          () => AiStoryStep.fromJson(turn, campaign),
          throwsFormatException,
        );
      }
    }
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('AI adventure offers reject invisible operators in all prose', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    for (final mark in _operators) {
      for (final field in [
        'title',
        'description',
        'questTitle',
        'questDescription',
      ]) {
        final offer = _offer()..[field] = 'Vor$mark Nach';
        final turn = {..._step(), 'adventure': offer};
        expect(
          () => AiStoryStep.fromJson(turn, campaign),
          throwsFormatException,
          reason: field,
        );
      }
    }
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('normal Unicode, multiline narration and JSON remain valid', () {
    final campaign = _campaign();
    final saved = jsonEncode(campaign.toJson());
    final plan = _plan()..['opening'] = 'Äste rauschen.\nEin 🐉 wacht auf.';
    expect(AiStoryPlan.fromJson(plan).opening, contains('Ein 🐉'));

    final parsed = AiStoryStep.fromJson({
      ..._step(),
      'narration': 'Mira grüßt Élise.\nWas tust du? 🐉',
      'adventure': _offer(),
    }, campaign);
    expect(parsed.narration, contains('Was tust du?'));
    expect(parsed.npcUpdates.single.id, 'mira');
    expect(parsed.adventure!.id, 'tower-quest');
    expect(jsonEncode(campaign.toJson()), saved);
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });
}
