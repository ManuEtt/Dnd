import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart' as story;

Campaign _campaign() => Campaign(
  id: 'chat-b-recall',
  name: 'Würfelraunen',
  world: 'Valdorn',
  sessionId: 'session-recall',
  hero: HeroCharacter(id: 'hero', name: 'Aria'),
  scene: 'Am Stadttor',
  facts: const {'Mira': 'Mira bewacht das Stadttor.'},
);

void main() {
  test('explicit German recap requests still trigger confirmed recall', () {
    for (final request in [
      'Was weißt du über Mira?',
      'Erinnere dich an Mira.',
      'Erinnerst du dich an Mira?',
      'Kannst du dich an Mira erinnern?',
      'Rückblick',
      'Zeig mir das Tagebuch.',
      'Fasse unsere bisherige Geschichte zusammen.',
      'Was ist bisher geschehen?',
      'Erzähl mir von Mira.',
      'Ich möchte eine Zusammenfassung.',
      'Bitte erinnere dich an Mira.',
    ]) {
      expect(
        story.MemoryEngine.isRecallRequest(request),
        isTrue,
        reason: request,
      );
    }
  });

  test('player actions and quoted questions do not trigger recall', () {
    for (final action in [
      'Ich erinnere mich an Mira und gehe weiter.',
      'Ich lese das Tagebuch am Feuer.',
      'Ich nehme das Tagebuch aus der Truhe.',
      'Mira erinnert sich an unsere bisherige Geschichte.',
      'Ich erzähle Mira von unserem letzten Abenteuer.',
      'Ich fasse den Brief für Mira zusammen.',
      'Wir gehen zum Tagebuch.',
      'Mira fragt: Was weißt du über mich?',
      'Ich suche eine Zusammenfassung in der Bibliothek.',
      'Die bisherige Geschichte ist voller Rätsel.',
    ]) {
      expect(
        story.MemoryEngine.isRecallRequest(action),
        isFalse,
        reason: action,
      );
    }
  });

  test('a diary interaction remains a player turn, not a recalled memory', () {
    final campaign = _campaign();
    final original = jsonEncode(campaign.toJson());
    final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 25));
    final update = engine.act(campaign, 'Ich lese das Tagebuch am Feuer.');

    expect(update.events, hasLength(1));
    expect(update.events.single.type, isNot('memory.recalled'));
    expect(update.campaign.hero.toJson(), campaign.hero.toJson());
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('explicit memory question still uses confirmed facts', () {
    final campaign = _campaign();
    final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 25));
    final update = engine.act(campaign, 'Was weißt du über Mira?');

    expect(update.events.single.type, 'memory.recalled');
    expect(update.narration, contains('Mira bewacht das Stadttor.'));
    expect(update.campaign.hero.toJson(), campaign.hero.toJson());
  });
}
