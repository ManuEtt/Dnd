import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/ai_story.dart';

Map<String, dynamic> _plan() => {
  'title': 'Das Licht von Valdorn',
  'world': 'Valdorn',
  'opening': 'Eine Stimme ruft aus dem Wald.',
  'premise': 'Ein altes Geheimnis.',
  'secret': 'Das Licht ruht im Turm.',
  'goal': 'Den Weg selbst wählen.',
  'threads': [
    {'id': 'licht', 'title': 'Das Licht', 'description': 'Suche den Turm.'},
    {'id': 'wald', 'title': 'Der Wald', 'description': 'Erforsche die Spuren.'},
  ],
  'npcs': [
    {
      'id': 'mira',
      'name': 'Mira',
      'description': 'Eine Kartografin.',
      'relationship': 'neutral',
    },
  ],
  'places': [
    {'id': 'turm', 'name': 'Der Turm', 'description': 'Ein verlassener Turm.'},
  ],
};

Map<String, dynamic> _changedEntry(
  String collection,
  String field,
  String value,
) {
  final plan = _plan();
  final entries = (plan[collection] as List)
      .map((entry) => Map<String, dynamic>.from(entry as Map))
      .toList();
  entries.first[field] = value;
  plan[collection] = entries;
  return plan;
}

Campaign _campaign() => Campaign(
  id: 'campaign-1',
  name: 'Valdorn',
  world: 'Valdorn',
  sessionId: 'session-1',
  hero: HeroCharacter(id: 'hero', name: 'Eila'),
  scene: 'Vor dem Turm',
  storyThreads: const [
    StoryThread(id: 'licht', title: 'Das Licht', description: 'Eine Spur.'),
  ],
  npcs: const [WorldNpc(id: 'mira', name: 'Mira')],
);

Map<String, dynamic> _step() => {
  'narration': 'Mira deutet auf den Turm.',
  'threadUpdates': [
    {'id': 'licht', 'status': 'open', 'description': 'Die Spur führt weiter.'},
  ],
  'newThreads': [
    {'id': 'bruecke', 'title': 'Die Brücke', 'description': 'Ein neuer Weg.'},
  ],
  'npcUpdates': [
    {'id': 'mira', 'relationship': 'freundlich', 'note': 'Sie kennt den Weg.'},
  ],
};

void main() {
  test('German, multiline prose and ordinary RTL letters remain valid', () {
    final plan = AiStoryPlan.fromJson({
      ..._plan(),
      'opening': 'Äste rauschen.\nEine Tür öffnet sich. שלום',
    });
    expect(plan.opening, contains('\n'));
    expect(plan.opening, contains('שלום'));
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    final step = AiStoryStep.fromJson({
      ..._step(),
      'narration': 'Mira flüstert.\nWas tust du als Nächstes?',
    }, campaign);
    expect(step.narration, contains('\n'));
    expect(step.npcUpdates.single.id, 'mira');
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('all provider plan scalar fields reject invisible formatting', () {
    for (final field in [
      'title',
      'world',
      'opening',
      'premise',
      'secret',
      'goal',
    ]) {
      for (final control in ['\u202e', '\x00', '\u200b']) {
        final plan = _plan();
        plan[field] = (plan[field] as String) + control;
        expect(
          () => AiStoryPlan.fromJson(plan),
          throwsFormatException,
          reason: '$field contains an invisible control',
        );
      }
    }
  });

  test('NPC, place and thread labels reject deceptive identities', () {
    for (final item in [
      _changedEntry('npcs', 'name', 'Mira\u202e'),
      _changedEntry('npcs', 'relationship', 'freundlich\u2066'),
      _changedEntry('places', 'description', 'Ort\u2029'),
      _changedEntry('threads', 'title', 'Die Spur\u200b'),
      _changedEntry('threads', 'description', 'Notiz\x7f'),
    ]) {
      expect(() => AiStoryPlan.fromJson(item), throwsFormatException);
    }
  });

  test('narration and stored story changes reject invisible controls', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    expect(
      () => AiStoryStep.fromJson({
        ..._step(),
        'narration': 'Die Reise\u202e beginnt.',
      }, campaign),
      throwsFormatException,
    );
    expect(
      () => AiStoryStep.fromJson({
        ..._step(),
        'threadUpdates': [
          {'id': 'licht', 'status': 'open', 'description': 'Die Spur\u2069'},
        ],
      }, campaign),
      throwsFormatException,
    );
    expect(
      () => AiStoryStep.fromJson({
        ..._step(),
        'npcUpdates': [
          {'id': 'mira', 'relationship': 'neutral', 'note': 'Hinweis\u200b'},
        ],
      }, campaign),
      throwsFormatException,
    );
    expect(
      () => AiStoryStep.fromJson({
        ..._step(),
        'newThreads': [
          {'id': 'bruecke', 'title': 'Brücke\x1b', 'description': 'Ein Weg.'},
        ],
      }, campaign),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
  });
}
