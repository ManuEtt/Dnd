import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/ai_story.dart';

Campaign _campaign() => Campaign(
  id: 'offer-test',
  name: 'Weg der Sterne',
  world: 'Ymera',
  sessionId: 'session-one',
  hero: HeroCharacter(id: 'hero', name: 'Eila', hitPoints: 12),
  scene: 'Die Gruppe erreicht das Dorf.',
  revision: 4,
);

Map<String, dynamic> _step(Map<String, dynamic>? offer) => {
  'narration': 'Ein Bote bittet um Hilfe.',
  'threadUpdates': [],
  'newThreads': [],
  'npcUpdates': [],
  'adventure': offer,
};

Map<String, dynamic> _offer() => {
  'id': 'old-tower',
  'title': 'Der alte Turm',
  'description': 'Eine Spur führt zu einem alten Turm.',
  'archetype': 'investigation',
  'questTitle': 'Suche den Turm',
  'questDescription': 'Finde die verborgene Treppe.',
};

void main() {
  test('valid AI adventure offer stays available without changing rules', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    final offer = AiStoryStep.fromJson(_step(_offer()), campaign).adventure;

    expect(offer, isNotNull);
    expect(offer!.id, 'old-tower');
    expect(offer.title, 'Der alte Turm');
    expect(offer.questTitle, 'Suche den Turm');
    expect(campaign.hero.hitPoints, 12);
    expect(campaign.quests, isEmpty);
    expect(campaign.revision, 4);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('provider offer rejects invisible marks in every player-facing field', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    for (final field in [
      'title',
      'description',
      'questTitle',
      'questDescription',
    ]) {
      for (final mark in ['\u202e', '\u2066', '\u00ad', '\u034f', '\u180e']) {
        final candidate = _offer();
        candidate[field] = 'Vor$mark schlag';
        expect(
          () => AiStoryStep.fromJson(_step(candidate), campaign),
          throwsFormatException,
          reason: field,
        );
      }
    }
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('ordinary Unicode and multiline text remain valid for an AI offer', () {
    final campaign = _campaign();
    final offer = _offer();
    offer['title'] = 'Über den Wolken 🐉';
    offer['description'] = 'Erster Hinweis.\nZweiter Hinweis.';
    offer['questTitle'] = 'Élises Prüfung';
    offer['questDescription'] = 'Finde die Tür im alten Gemäuer.';
    final parsed = AiStoryStep.fromJson(_step(offer), campaign).adventure;

    expect(parsed!.title, 'Über den Wolken 🐉');
    expect(parsed.description, 'Erster Hinweis.\nZweiter Hinweis.');
    expect(parsed.questTitle, 'Élises Prüfung');
  });

  test('blocked offers remain ignored without touching saved campaign state', () {
    final original = _campaign();
    final existing = AdventureOffer.fromJson(_offer());
    final campaign = original.copyWith(adventureOffer: existing);
    final before = jsonEncode(campaign.toJson());
    final malformed = _offer()..['title'] = 'Versteckt\u202eTitel';

    final step = AiStoryStep.fromJson(_step(malformed), campaign);
    expect(step.adventure, isNull);
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.adventureOffer!.title, 'Der alte Turm');
  });
}
