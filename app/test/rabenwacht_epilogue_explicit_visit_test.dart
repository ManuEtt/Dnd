import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/fourteenth_voice_epilogue.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({String stage = 'voice-epilogue-square'}) => Campaign(
  id: 'epilogue-visits',
  name: 'Rabenwacht',
  world: 'Rabenwacht',
  sessionId: 'session-epilogue',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Der Dorfplatz wartet auf die eigene Entscheidung.',
  storyBible: {'mode': 'rabenwacht-voice-v1', 'stage': stage},
  facts: const {
    'voice:ending': 'end-oath',
    'voice:witnessChain': 'true',
    'voice:epilogueStarted': 'true',
    'voice:originEnding': 'end-seal',
  },
  quests: const [
    Quest(id: 'voice-main', title: 'Vierzehnte Stimme', status: 'completed'),
    Quest(id: 'voice-epilogue', title: 'Was Rabenwacht bewahrt'),
  ],
);

void main() {
  sqfliteFfiInit();

  test('NPCs and their places may be discussed without a confirmed visit', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    for (final decision in [
      'Ich frage nach Elda.',
      'Was denkt Tarek über den Brief?',
      'Liora soll selbst entscheiden, was sie erzählt.',
      'Ich untersuche die Zeichnung.',
      'Ich vergleiche die Teller.',
      'Der Brief erwähnt das Gasthaus.',
      'Ich erinnere mich an den Brunnen.',
      'Die Fremde hat Liora getroffen.',
      'Ich besuche Elda oder Tarek?',
      'Ich möchte Elda erst morgen besuchen.',
      'Ich besuche Liora nicht.',
    ]) {
      final turn = FourteenthVoiceEpilogue.advance(campaign, decision);
      expect(identical(turn.campaign, campaign), isTrue, reason: decision);
      expect(turn.campaign.storyBible['stage'], 'voice-epilogue-square');
      expect(FourteenthVoiceEpilogue.witnessCount(turn.campaign), 0);
      expect(turn.campaign.facts['voice:epilogue:elda'], isNull);
      expect(turn.campaign.facts['voice:epilogue:tarek'], isNull);
      expect(turn.campaign.facts['voice:epilogue:liora'], isNull);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('explicit visits record exactly the intended NPC testimony', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    const decisions = {
      'Ich besuche Elda.': 'elda',
      'Ich möchte Elda besuchen.': 'elda',
      'Ich suche Tarek.': 'tarek',
      'Besuche Tarek.': 'tarek',
      'Ich gehe zum Gasthaus.': 'tarek',
      'Ich besuche Liora.': 'liora',
      'Ich spreche mit Liora.': 'liora',
      'Ich gehe zum Brunnen.': 'liora',
    };
    for (final choice in decisions.entries) {
      final turn = FourteenthVoiceEpilogue.advance(campaign, choice.key);
      final changed = turn.campaign;
      expect(
        changed.storyBible['stage'],
        'voice-epilogue-${choice.value}',
        reason: choice.key,
      );
      expect(changed.facts['voice:epilogue:${choice.value}'], 'true');
      expect(FourteenthVoiceEpilogue.witnessCount(changed), 1);
      expect(changed.hero.toJson(), campaign.hero.toJson());
      expect(changed.revision, campaign.revision);
      expect(
        changed.quests.map((q) => q.toJson()).toList(),
        campaign.quests.map((q) => q.toJson()).toList(),
      );
    }
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('return requires action, not an incidental mention of Dorfplatz', () {
    final before = _campaign(stage: 'voice-epilogue-tarek');
    final saved = jsonEncode(before.toJson());
    for (final input in [
      'Ich erinnere mich an den Dorfplatz.',
      'Die Leute auf dem Platz sprechen über den Brief.',
      'Kann ich irgendwann zurück zum Dorfplatz?',
      'Ich möchte den Platz nicht verlassen.',
    ]) {
      final turn = FourteenthVoiceEpilogue.advance(before, input);
      expect(identical(turn.campaign, before), isTrue, reason: input);
      expect(turn.campaign.storyBible['stage'], 'voice-epilogue-tarek');
    }
    for (final input in [
      'Zurück zum Dorfplatz.',
      'Ich gehe zurück.',
      'Ich kehre zum Dorfplatz zurück.',
    ]) {
      final turn = FourteenthVoiceEpilogue.advance(before, input);
      expect(turn.campaign.storyBible['stage'], 'voice-epilogue-square');
      expect(turn.campaign.hero.toJson(), before.hero.toJson());
    }
    expect(jsonEncode(before.toJson()), saved);
  });

  test('JSON reloading never turns a mention into saved testimony', () {
    final campaign = _campaign();
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(campaign.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    final ignored = FourteenthVoiceEpilogue.advance(
      restored,
      'Ich spreche über Tarek und Liora.',
    );
    expect(identical(ignored.campaign, restored), isTrue);
    expect(FourteenthVoiceEpilogue.witnessCount(restored), 0);

    final visited = FourteenthVoiceEpilogue.advance(
      restored,
      'Ich besuche Tarek.',
    ).campaign;
    expect(visited.storyBible['stage'], 'voice-epilogue-tarek');
    expect(visited.facts['voice:epilogue:tarek'], 'true');
    expect(visited.hero.toJson(), restored.hero.toJson());
    expect(jsonEncode(restored.toJson()), before);
  });

  test(
    'SQLite restart preserves only genuinely confirmed NPC visits',
    () async {
      final dir = await Directory.systemTemp.createTemp('epilogue-visits-');
      final dbPath = paths.join(dir.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      try {
        final original = _campaign();
        final ignored = FourteenthVoiceEpilogue.advance(
          original,
          'Ist Elda heute am Brunnen?',
        );
        expect(identical(ignored.campaign, original), isTrue);
        final confirmed = FourteenthVoiceEpilogue.advance(
          original,
          'Ich besuche Liora.',
        ).campaign;
        await repository.saveCampaign(confirmed);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: dbPath,
        );
        final restored = (await repository.getCampaign(original.id))!;
        final before = jsonEncode(restored.toJson());
        expect(restored.storyBible['stage'], 'voice-epilogue-liora');
        expect(FourteenthVoiceEpilogue.witnessCount(restored), 1);
        expect(restored.facts['voice:epilogue:elda'], isNull);
        expect(restored.facts['voice:epilogue:liora'], 'true');
        expect(restored.hero.toJson(), original.hero.toJson());
        expect(
          (await repository.reconstructCampaign(restored.id))!.toJson(),
          restored.toJson(),
        );
        expect(jsonEncode(restored.toJson()), before);
      } finally {
        await repository.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
