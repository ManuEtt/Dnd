import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/fourteenth_voice_act7.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign(String stage, {bool pageFound = false}) => Campaign(
  id: 'act7-explicit-decisions',
  name: 'Vierzehnte Stimme',
  world: 'Valdorn',
  sessionId: 'act7-session',
  hero: HeroCharacter(
    id: 'hero',
    name: 'Valen',
    hitPoints: 18,
    maxHitPoints: 18,
  ),
  scene: 'Du entscheidest selbst.',
  storyBible: {'mode': 'rabenwacht-voice-v1', 'stage': stage},
  facts: {if (pageFound) 'voice:oathPageFound': 'true'},
  quests: const [
    Quest(
      id: 'voice-chronist',
      title: 'Ein unmögliches Angebot',
      description: 'Entscheide dich bewusst.',
    ),
  ],
);

void main() {
  sqfliteFfiInit();

  test('questions and reported possibilities cannot settle the trade', () {
    final original = _campaign('voice-library');
    final before = jsonEncode(original.toJson());

    for (final phrase in [
      'Was passiert, wenn ich das Angebot ablehne?',
      'Ich überlege, ob ich das Angebot ablehne.',
      'Ich erwähne, dass ich das Angebot ablehne.',
      'Ich lehne das Angebot nicht ab.',
      'Sollte ich Zustimmung vortäuschen?',
      'Ich würde Zustimmung vortäuschen.',
      'Ich erzähle Liora, dass ich Zustimmung vortäusche.',
    ]) {
      final result = FourteenthVoiceAct7.advance(original, phrase).campaign;
      expect(result.facts['voice:chronistChoice'], isNull, reason: phrase);
      expect(result.facts['voice:chronistSuspicious'], isNull, reason: phrase);
      expect(result.storyBible['stage'], 'voice-library', reason: phrase);
      expect(
        result.quests.single.status,
        original.quests.single.status,
        reason: phrase,
      );
      expect(result.hero.toJson(), original.hero.toJson(), reason: phrase);
    }
    expect(jsonEncode(original.toJson()), before);
  });

  test('explicit refusal and feigned consent remain distinct and final', () {
    for (final choice in [
      ('Ich lehne das Angebot ab.', 'refused', false),
      ('Ich verweigere den Handel.', 'refused', false),
      ('Ich täusche Zustimmung vor.', 'feigned', true),
      ('Ich spiele Zustimmung vor.', 'feigned', true),
    ]) {
      final before = _campaign('voice-library');
      final selected = FourteenthVoiceAct7.advance(before, choice.$1).campaign;
      expect(selected.facts['voice:chronistChoice'], choice.$2);
      expect(
        selected.facts['voice:chronistSuspicious'],
        choice.$3 ? 'true' : isNull,
      );
      expect(selected.quests.single.status, 'completed');
      expect(selected.hero.toJson(), before.hero.toJson());
      expect(Campaign.fromJson(selected.toJson()).toJson(), selected.toJson());

      final repeated = FourteenthVoiceAct7.advance(
        selected,
        'Ich lehne das Angebot ab.',
      ).campaign;
      expect(repeated.facts, selected.facts);
      expect(repeated.quests.single.status, 'completed');
    }
  });

  test('hypothetical or negated custody does not reach Act VIII', () {
    final original = _campaign('voice-ledger', pageFound: true);
    final before = jsonEncode(original.toJson());

    for (final phrase in [
      'Was wäre, wenn ich Liora den Namen anvertraue?',
      'Ich frage, ob ich Liora den Namen anvertrauen sollte.',
      'Ich vertraue Liora den Namen nicht an.',
      'Ich bespreche, ob ich den Namen selbst bewahren sollte.',
      'Ich erzähle Liora, dass ich den Namen selbst bewahren will.',
      'Ich würde den Namen selbst bewahren.',
    ]) {
      final result = FourteenthVoiceAct7.advance(original, phrase).campaign;
      expect(result.storyBible['stage'], 'voice-ledger', reason: phrase);
      expect(result.facts['voice:nameCustody'], isNull, reason: phrase);
      expect(result.facts['voice:act7Reached'], isNull, reason: phrase);
      expect(result.hero.toJson(), original.hero.toJson(), reason: phrase);
    }
    expect(jsonEncode(original.toJson()), before);
  });

  test('custody requires discovered page and explicit first-person action', () {
    for (final choice in [
      ('Ich vertraue Liora den Namen an.', 'liora'),
      ('Ich will Liora den Namen anvertrauen.', 'liora'),
      ('Ich will den Namen selbst bewahren.', 'hero'),
      ('Ich behalte den Namen.', 'hero'),
    ]) {
      final missing = _campaign('voice-ledger');
      final blocked = FourteenthVoiceAct7.advance(missing, choice.$1).campaign;
      expect(blocked.storyBible['stage'], 'voice-ledger');
      expect(blocked.facts['voice:nameCustody'], isNull);

      final before = _campaign('voice-ledger', pageFound: true);
      final selected = FourteenthVoiceAct7.advance(before, choice.$1).campaign;
      expect(selected.storyBible['stage'], 'voice-threshold');
      expect(selected.facts['voice:nameCustody'], choice.$2);
      expect(selected.facts['voice:act7Reached'], 'true');
      expect(selected.hero.toJson(), before.hero.toJson());
      expect(Campaign.fromJson(selected.toJson()).toJson(), selected.toJson());
    }
  });

  test(
    'confirmed custody survives SQLite restart without rule changes',
    () async {
      final folder = await Directory.systemTemp.createTemp('act7-explicit-');
      final dbPath = paths.join(folder.path, 'campaign.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      try {
        final before = _campaign('voice-ledger', pageFound: true);
        final confirmed = FourteenthVoiceAct7.advance(
          before,
          'Ich vertraue Liora den Namen an.',
        ).campaign;
        await repository.saveCampaign(confirmed);
        await repository.close();

        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: dbPath,
        );
        final restored = (await repository.getCampaign(before.id))!;
        expect(restored.facts['voice:nameCustody'], 'liora');
        expect(restored.storyBible['stage'], 'voice-threshold');
        expect(restored.hero.toJson(), before.hero.toJson());
        expect(
          (await repository.reconstructCampaign(restored.id))!.toJson(),
          restored.toJson(),
        );
      } finally {
        await repository.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
