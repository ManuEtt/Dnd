import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/fourteenth_voice_act8.dart';

Campaign _readyCampaign() => Campaign(
  id: 'council-intent',
  name: 'Rabenwacht',
  world: 'Rabenwacht',
  scene: 'Das vierzehnte Blatt liegt sicher verwahrt.',
  sessionId: 'session-8',
  hero: HeroCharacter(id: 'hero', name: 'Valen', hitPoints: 17),
  storyBible: const {'mode': 'rabenwacht-voice-v1', 'stage': 'voice-threshold'},
  facts: const {
    'voice:oathPageFound': 'true',
    'voice:nameCustody': 'hero',
    'voice:memorySketch': 'true',
    'voice:splitInkLetter': 'true',
    'voice:chronistChoice': 'refused',
  },
);

void main() {
  test('mentions of the council or square do not convene the witnesses', () {
    final campaign = _readyCampaign();
    final before = jsonEncode(campaign.toJson());
    for (final decision in [
      'Ich verrate Liora meine Zweifel.',
      'Ich errate den Namen auf dem Blatt.',
      'Ich gehe zum Dorfplatz und suche Tarek.',
      'Ich spreche mit dem Rat über die Warnung.',
      'Ich beschreibe die Versammlung der Zeugen.',
      'Ich lade Elda zum Mittagessen ein.',
      'Ich berufe den Rat nicht ein.',
    ]) {
      final turn = FourteenthVoiceAct8.advance(campaign, decision);
      expect(identical(turn.campaign, campaign), isTrue, reason: decision);
      expect(turn.campaign.storyBible['stage'], 'voice-threshold');
      expect(turn.campaign.facts['voice:visited:council'], isNull);
      expect(turn.campaign.facts['location'], isNull);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('explicitly convening the council keeps confirmed evidence intact', () {
    final campaign = _readyCampaign();
    final before = jsonEncode(campaign.toJson());
    for (final decision in [
      'Ich berufe den Rat der Zeugen ein.',
      'Ich versammle die Zeugen auf dem Dorfplatz.',
      'Rat einberufen.',
      'Ich rufe die Versammlung zusammen.',
    ]) {
      final turn = FourteenthVoiceAct8.advance(campaign, decision);
      final next = turn.campaign;
      expect(next.storyBible['stage'], 'voice-council', reason: decision);
      expect(next.facts['voice:visited:council'], 'true');
      expect(next.facts['location'], 'Rat der Zeugen');
      expect(next.facts['voice:memorySketch'], 'true');
      expect(next.facts['voice:splitInkLetter'], 'true');
      expect(next.hero.toJson(), campaign.hero.toJson());
      expect(next.revision, campaign.revision);
      expect(next.pendingRoll, isNull);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('missing custody or evidence still blocks explicit summoning', () {
    final campaign = _readyCampaign();
    for (final facts in [
      {...campaign.facts, 'voice:oathPageFound': 'false'},
      {...campaign.facts, 'voice:nameCustody': 'chronist'},
      {...campaign.facts, 'voice:splitInkLetter': 'false'},
    ]) {
      final blocked = campaign.copyWith(facts: facts);
      final before = jsonEncode(blocked.toJson());
      final turn = FourteenthVoiceAct8.advance(
        blocked,
        'Ich berufe den Rat der Zeugen ein.',
      );
      expect(identical(turn.campaign, blocked), isTrue);
      expect(turn.campaign.storyBible['stage'], 'voice-threshold');
      expect(turn.campaign.facts['voice:visited:council'], isNull);
      expect(jsonEncode(blocked.toJson()), before);
    }
  });

  test('restored campaign does not infer a council from dialogue', () {
    final campaign = _readyCampaign();
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(campaign.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());

    final dialogue = FourteenthVoiceAct8.advance(
      restored,
      'Ich verrate Liora, dass ich den Rat fürchte.',
    );
    expect(identical(dialogue.campaign, restored), isTrue);
    expect(dialogue.campaign.storyBible['stage'], 'voice-threshold');

    final summoned = FourteenthVoiceAct8.advance(
      restored,
      'Ich berufe den Rat ein.',
    );
    expect(summoned.campaign.storyBible['stage'], 'voice-council');
    expect(summoned.campaign.hero.toJson(), restored.hero.toJson());
    expect(jsonEncode(restored.toJson()), before);
  });
}
