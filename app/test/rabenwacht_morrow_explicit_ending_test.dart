import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/fourteenth_voice_morrow.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign() => Campaign(
  id: 'morrow-choice',
  name: 'Der Brief von Morgen',
  world: 'Rabenwacht',
  scene: 'Der Rat prüft zwei gesicherte Spuren.',
  sessionId: 'morrow-session',
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  storyBible: const {
    'mode': 'rabenwacht-voice-v1',
    'stage': 'voice-morrow-council',
  },
  facts: const {
    'voice:ending': 'end-accord',
    'voice:legacy': 'memorial',
    'voice:witnessChain': 'true',
    'voice:morrow:started': 'true',
    'voice:morrow:letterRead': 'true',
    'voice:morrow:elda': 'true',
    'voice:morrow:tarek': 'true',
  },
  quests: const [
    Quest(
      id: 'voice-epilogue',
      title: 'Was Rabenwacht bewahrt',
      status: 'completed',
    ),
    Quest(id: 'voice-morrow', title: 'Der Brief von Morgen'),
  ],
  storyThreads: const [
    StoryThread(id: 'voice-morrow-truth', title: 'Der neue Morgen'),
  ],
);

void main() {
  sqfliteFfiInit();

  test('questions and hypothetical endings never finalize the story', () {
    final original = _campaign();
    final before = jsonEncode(original.toJson());
    for (final input in [
      'Sollten wir den Brief versiegelt verwahren?',
      'Ich frage, ob wir den Brief mit Quellen veröffentlichen sollen.',
      'Was wäre, wenn wir Liora selbst entscheiden lassen?',
      'Der Rat sagt: Brief versiegelt verwahren.',
      'Ich möchte wissen, ob wir Liora selbst entscheiden lassen.',
      'Bitte erkläre: Brief mit Quellen veröffentlichen.',
      'Ich zitiere „Brief versiegelt verwahren“ nur.',
    ]) {
      final turn = FourteenthVoiceMorrow.advance(original, input);
      expect(identical(turn.campaign, original), isTrue, reason: input);
      expect(
        turn.campaign.storyBible['stage'],
        'voice-morrow-council',
        reason: input,
      );
      expect(turn.campaign.facts['voice:morrow:outcome'], isNull);
      expect(turn.campaign.quests.last.status, 'active', reason: input);
      expect(jsonEncode(original.toJson()), before);
    }
  });

  test('all direct choices remain available and final exactly once', () {
    const choices = {
      'Brief versiegelt verwahren.': 'sealed',
      'Brief mit Quellen veröffentlichen.': 'published',
      'Brief mit Quellen veroeffentlichen.': 'published',
      'Liora selbst entscheiden lassen.': 'liora',
      'Ich möchte den Brief versiegelt verwahren.': 'sealed',
      'Wir möchten den Brief mit Quellen veröffentlichen.': 'published',
      'Ich will Liora selbst entscheiden lassen.': 'liora',
    };
    final original = _campaign();
    final before = jsonEncode(original.toJson());
    for (final entry in choices.entries) {
      final result = FourteenthVoiceMorrow.advance(original, entry.key);
      final finished = result.campaign;
      expect(
        finished.storyBible['stage'],
        'voice-morrow-end-${entry.value}',
        reason: entry.key,
      );
      expect(finished.facts['voice:morrow:outcome'], entry.value);
      expect(finished.quests.last.status, 'completed');
      expect(finished.storyThreads.single.status, 'resolved');
      expect(finished.hero.toJson(), original.hero.toJson());
      expect(finished.revision, original.revision);
      expect(finished.facts['voice:witnessChain'], 'true');
      final repeated = FourteenthVoiceMorrow.advance(
        finished,
        'Brief mit Quellen veröffentlichen.',
      );
      expect(identical(repeated.campaign, finished), isTrue);
    }
    expect(jsonEncode(original.toJson()), before);
  });

  test('insufficient evidence blocks even an explicit final choice', () {
    final original = _campaign();
    final incomplete = [
      original.copyWith(
        facts: {...original.facts, 'voice:morrow:tarek': 'false'},
      ),
      original.copyWith(
        facts: {...original.facts, 'voice:morrow:letterRead': 'false'},
      ),
    ];
    for (final campaign in incomplete) {
      final before = jsonEncode(campaign.toJson());
      final turn = FourteenthVoiceMorrow.advance(
        campaign,
        'Ich will den Brief versiegelt verwahren.',
      );
      expect(identical(turn.campaign, campaign), isTrue);
      expect(campaign.facts['voice:morrow:outcome'], isNull);
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('JSON restart preserves explicit choices and refuses speculation', () {
    final saved = _campaign();
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(saved.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    final question = FourteenthVoiceMorrow.advance(
      restored,
      'Sollen wir Liora selbst entscheiden lassen?',
    );
    expect(identical(question.campaign, restored), isTrue);

    final confirmed = FourteenthVoiceMorrow.advance(
      restored,
      'Wir wollen Liora selbst entscheiden lassen.',
    );
    expect(confirmed.campaign.facts['voice:morrow:outcome'], 'liora');
    expect(confirmed.campaign.quests.last.status, 'completed');
    expect(confirmed.campaign.hero.toJson(), restored.hero.toJson());
    expect(jsonEncode(restored.toJson()), before);
  });

  test(
    'SQLite reopening retains a confirmed ending and read-only inputs',
    () async {
      final directory = await Directory.systemTemp.createTemp('morrow-choice-');
      final path = paths.join(directory.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final original = _campaign();
        final decided = FourteenthVoiceMorrow.advance(
          original,
          'Brief mit Quellen veröffentlichen.',
        ).campaign;
        await repository.saveCampaign(decided);
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = (await repository.getCampaign(decided.id))!;
        final before = jsonEncode(restored.toJson());
        expect(restored.storyBible['stage'], 'voice-morrow-end-published');
        expect(restored.facts['voice:morrow:outcome'], 'published');
        expect(restored.quests.last.status, 'completed');
        final next = FourteenthVoiceMorrow.advance(
          restored,
          'Liora selbst entscheiden lassen.',
        );
        expect(identical(next.campaign, restored), isTrue);
        expect(jsonEncode(restored.toJson()), before);
        expect(restored.hero.toJson(), original.hero.toJson());
        expect(
          (await repository.reconstructCampaign(restored.id))!.toJson(),
          restored.toJson(),
        );
      } finally {
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
