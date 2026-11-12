import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/fourteenth_voice_epilogue.dart';

Campaign _future({int witnesses = 2, String? savedLegacy}) => Campaign(
  id: 'epilogue-legacy-choices',
  name: 'Rabenwacht',
  world: 'Rabenwacht',
  sessionId: 'session-epilogue',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Das Dorf wartet auf eine bewusste Wahl.',
  storyBible: const {
    'mode': 'rabenwacht-voice-v1',
    'stage': 'voice-epilogue-future',
  },
  facts: {
    'voice:ending': 'end-oath',
    'voice:witnessChain': 'true',
    'voice:epilogueStarted': 'true',
    if (witnesses >= 1) 'voice:epilogue:elda': 'true',
    if (witnesses >= 2) 'voice:epilogue:tarek': 'true',
    if (savedLegacy != null) 'voice:legacy': savedLegacy,
  },
  quests: const [
    Quest(id: 'voice-main', title: 'Vierzehnte Stimme', status: 'completed'),
    Quest(id: 'voice-epilogue', title: 'Was Rabenwacht bewahrt'),
  ],
);

void main() {
  test('only an explicit single legacy choice completes the epilogue', () {
    final initial = _future();
    final original = jsonEncode(initial.toJson());
    const choices = {
      'Gedenkbuch anlegen.': 'memorial',
      'Ich möchte ein Gedenkbuch anlegen.': 'memorial',
      'Zeugnisse veröffentlichen.': 'testimonies',
      'Wir wollen Zeugnisse veroeffentlichen!': 'testimonies',
      'Dorffest veranstalten.': 'festival',
      'Ich will ein Dorffest veranstalten.': 'festival',
      'Fest veranstalten.': 'festival',
    };
    for (final entry in choices.entries) {
      final completed = FourteenthVoiceEpilogue.advance(
        initial,
        entry.key,
      ).campaign;
      expect(
        completed.storyBible['stage'],
        'voice-epilogue-complete',
        reason: entry.key,
      );
      expect(completed.facts['voice:legacy'], entry.value, reason: entry.key);
      expect(
        completed.quests.singleWhere((q) => q.id == 'voice-epilogue').status,
        'completed',
        reason: entry.key,
      );
      expect(completed.hero.toJson(), initial.hero.toJson());
      expect(completed.revision, initial.revision);
      expect(
        completed.events.map((e) => e.toJson()).toList(),
        initial.events.map((e) => e.toJson()).toList(),
      );
    }
    expect(jsonEncode(initial.toJson()), original);
  });

  test('quotes, questions and competing alternatives do not finalize', () {
    final campaign = _future();
    final before = jsonEncode(campaign.toJson());
    for (final input in [
      'Ich lese den Abschnitt Gedenkbuch anlegen.',
      'Ich spreche über „Gedenkbuch anlegen“.',
      'Kann ich Zeugnisse veröffentlichen?',
      'Zeugnisse veröffentlichen oder Dorffest veranstalten?',
      'Ich möchte Gedenkbuch anlegen oder Zeugnisse veröffentlichen.',
      'Ich kann Zeugnisse veröffentlichen.',
      'Gedenkbuch anlegen?',
      'Ich möchte kein Gedenkbuch anlegen.',
      'Wir diskutieren, ob ein Dorffest veranstalten sinnvoll ist.',
      'Ich notiere Dorffest veranstalten in meinem Tagebuch.',
    ]) {
      final turn = FourteenthVoiceEpilogue.advance(campaign, input);
      expect(identical(turn.campaign, campaign), isTrue, reason: input);
      expect(turn.campaign.storyBible['stage'], 'voice-epilogue-future');
      expect(turn.campaign.facts['voice:legacy'], isNull);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('JSON resume keeps open choices open until confirmed', () {
    final initial = _future();
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(initial.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    final asked = FourteenthVoiceEpilogue.advance(
      restored,
      'Sollten wir Zeugnisse veröffentlichen?',
    );
    expect(identical(asked.campaign, restored), isTrue);
    expect(jsonEncode(restored.toJson()), before);

    final confirmed = FourteenthVoiceEpilogue.advance(
      restored,
      'Wir wollen Zeugnisse veröffentlichen.',
    ).campaign;
    expect(confirmed.facts['voice:legacy'], 'testimonies');
    expect(confirmed.storyBible['stage'], 'voice-epilogue-complete');
    final saved = Campaign.fromJson(
      jsonDecode(jsonEncode(confirmed.toJson())) as Map<String, dynamic>,
    );
    final replay = FourteenthVoiceEpilogue.advance(
      saved,
      'Gedenkbuch anlegen.',
    );
    expect(identical(replay.campaign, saved), isTrue);
    expect(saved.facts['voice:legacy'], 'testimonies');
    expect(saved.hero.toJson(), initial.hero.toJson());
    expect(jsonEncode(restored.toJson()), before);
  });

  test('missing witnesses or existing legacy cannot be overwritten', () {
    for (final campaign in [
      _future(witnesses: 1),
      _future(savedLegacy: 'festival'),
    ]) {
      final before = jsonEncode(campaign.toJson());
      final rejected = FourteenthVoiceEpilogue.advance(
        campaign,
        'Gedenkbuch anlegen.',
      );
      expect(identical(rejected.campaign, campaign), isTrue);
      expect(rejected.campaign.storyBible['stage'], 'voice-epilogue-future');
      expect(jsonEncode(campaign.toJson()), before);
    }
  });
}
