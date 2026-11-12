import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

final _now = DateTime.utc(2026, 11, 12, 12);

Campaign _campaign() => Campaign(
  id: 'diary-intent',
  name: 'Das Nebelarchiv',
  world: 'Valdorn',
  sessionId: 'session-diary',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 12),
  scene: 'Vor der Bibliothek.',
  facts: const {'archiv': 'Die Bibliothek ist geöffnet.'},
  revision: 3,
);

void main() {
  test('bare recall nouns and deliberate read commands remain available', () {
    for (final request in [
      'Rückblick',
      'Tagebuch',
      'Zusammenfassung',
      'Erinnerungen',
      'Tagebuch anzeigen.',
      'Tagebuch öffnen!',
      'Rückblick bitte.',
      'Bitte Tagebuch, bitte!',
      'Zeig mir das Tagebuch.',
      'Öffne das Tagebuch.',
      'Öffne mir das Tagebuch, bitte.',
      'Erinnere dich an die Bibliothek.',
      'Was weißt du über die Bibliothek?',
    ]) {
      expect(MemoryEngine.isRecallRequest(request), isTrue, reason: request);
    }
  });

  test('diary and memory actions are not silently converted to recall', () {
    for (final action in [
      'Tagebuch verbrennen.',
      'Tagebuch verstecken.',
      'Tagebuch wegwerfen.',
      'Tagebuch an Mira übergeben.',
      'Tagebuch verkaufen.',
      'Rückblick verlassen.',
      'Rückblick ändern.',
      'Zusammenfassung zerreißen.',
      'Erinnerungen löschen.',
      'Erinnerungen fälschen.',
      'Öffne das Tagebuch nicht.',
      'Zeige das Tagebuch nur Mira.',
      'Erinnere dich nicht an die Bibliothek.',
    ]) {
      expect(MemoryEngine.isRecallRequest(action), isFalse, reason: action);
    }
  });

  test('normal game turns keep diary action distinct from memory recall', () {
    final original = _campaign();
    final snapshot = jsonEncode(original.toJson());
    final engine = GameEngine(clock: () => _now);
    for (final action in [
      'Tagebuch verbrennen.',
      'Erinnerungen löschen.',
      'Öffne das Tagebuch nicht.',
    ]) {
      final update = engine.act(original, action);
      expect(update.events, hasLength(1), reason: action);
      expect(update.events.single.type, isNot('memory.recalled'));
      expect(update.campaign.revision, original.revision + 1);
      expect(update.campaign.hero.toJson(), original.hero.toJson());
      expect(update.campaign.facts, original.facts);
    }
    expect(jsonEncode(original.toJson()), snapshot);
  });

  test('explicit diary request uses only confirmed persisted memory', () {
    final saved = Campaign.fromJson(
      jsonDecode(jsonEncode(_campaign().toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(saved.toJson());
    final engine = GameEngine(clock: () => _now);
    for (final request in [
      'Tagebuch anzeigen.',
      'Rückblick bitte.',
      'Zeig mir das Tagebuch.',
      'Öffne mir das Tagebuch, bitte.',
    ]) {
      final update = engine.act(saved, request);
      expect(update.events.single.type, 'memory.recalled', reason: request);
      expect(
        update.narration,
        contains('Die Bibliothek ist geöffnet.'),
        reason: request,
      );
      expect(update.campaign.hero.toJson(), saved.hero.toJson());
      expect(update.campaign.facts, saved.facts);
    }
    final unrelated = engine.act(saved, 'Was weißt du über die Drachenhöhle?');
    expect(unrelated.events.single.type, 'memory.recalled');
    expect(unrelated.narration, contains('keine passende Erinnerung'));
    expect(jsonEncode(saved.toJson()), before);
  });
}
