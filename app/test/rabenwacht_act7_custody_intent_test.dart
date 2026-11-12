import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/fourteenth_voice_act7.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _atLedger({bool pageFound = true}) => Campaign(
  id: 'act7-custody-choice',
  name: 'Das vierzehnte Blatt',
  world: 'Rabenwacht',
  sessionId: 'act7-session',
  scene: 'Der Name ist nur als beschädigte Abschrift gesichert.',
  hero: HeroCharacter(id: 'hero', name: 'Valen', hitPoints: 17),
  storyBible: const {'mode': 'rabenwacht-voice-v1', 'stage': 'voice-ledger'},
  facts: {
    'voice:chronistChoice': 'refused',
    if (pageFound) 'voice:oathPageFound': 'true',
  },
  quests: const [
    Quest(id: 'voice-main', title: 'Die vierzehnte Stimme'),
    Quest(
      id: 'voice-chronist',
      title: 'Ein unmögliches Angebot',
      status: 'completed',
    ),
  ],
);

void main() {
  sqfliteFfiInit();

  test('questions and hypotheticals cannot choose name custody', () {
    final original = _atLedger();
    final before = jsonEncode(original.toJson());
    for (final input in [
      'Kann ich Liora den Namen anvertrauen?',
      'Ich frage, ob ich Liora den Namen anvertrauen soll.',
      'Vielleicht vertraue ich Liora den Namen später an.',
      'Ich möchte Liora den Namen anvertrauen, aber ich bin unsicher.',
      'Liora den Namen anvertrauen – wäre das richtig?',
      'Ich würde den Namen selbst bewahren.',
      'Ich frage, ob ich den Namen selbst bewahren soll.',
      'Ich behalte den Namen selbst?',
      'Ich will den Namen nicht selbst bewahren.',
      'Ich vertraue Liora den Namen nicht an.',
    ]) {
      final result = FourteenthVoiceAct7.advance(original, input);
      expect(identical(result.campaign, original), isTrue, reason: input);
      expect(result.campaign.storyBible['stage'], 'voice-ledger');
      expect(result.campaign.facts['voice:nameCustody'], isNull);
      expect(result.campaign.facts['voice:act7Reached'], isNull);
      expect(jsonEncode(original.toJson()), before);
    }
  });

  test('explicit transfer to Liora unlocks only the intended story path', () {
    final original = _atLedger();
    final before = jsonEncode(original.toJson());
    for (final input in [
      'Ich vertraue Liora den Namen an.',
      'Ich will Liora den Namen anvertrauen.',
      'Ich möchte Liora den Namen anvertrauen.',
      'Liora den Namen anvertrauen.',
    ]) {
      final next = FourteenthVoiceAct7.advance(original, input).campaign;
      expect(next.storyBible['stage'], 'voice-threshold', reason: input);
      expect(next.facts['voice:nameCustody'], 'liora');
      expect(next.facts['voice:act7Reached'], 'true');
      expect(next.facts['voice:oathPageFound'], 'true');
      expect(next.hero.toJson(), original.hero.toJson());
      expect(next.revision, original.revision);
      expect(
        next.quests.map((q) => q.toJson()).toList(),
        original.quests.map((q) => q.toJson()).toList(),
      );
    }
    expect(jsonEncode(original.toJson()), before);
  });

  test('explicit self-custody does not assign the name to Liora', () {
    final original = _atLedger();
    for (final input in [
      'Ich will den Namen selbst bewahren.',
      'Ich möchte den Namen selbst bewahren.',
      'Ich behalte den Namen.',
      'Ich verwahre den Namen selbst.',
      'Den Namen selbst bewahren.',
    ]) {
      final next = FourteenthVoiceAct7.advance(original, input).campaign;
      expect(next.storyBible['stage'], 'voice-threshold', reason: input);
      expect(next.facts['voice:nameCustody'], 'hero');
      expect(next.facts['voice:act7Reached'], 'true');
      expect(next.facts['voice:chronistChoice'], 'refused');
      expect(next.hero.toJson(), original.hero.toJson());
    }
  });

  test('missing confirmed oath page blocks both custody decisions', () {
    final original = _atLedger(pageFound: false);
    final before = jsonEncode(original.toJson());
    for (final input in [
      'Ich vertraue Liora den Namen an.',
      'Ich will den Namen selbst bewahren.',
    ]) {
      final result = FourteenthVoiceAct7.advance(original, input);
      expect(identical(result.campaign, original), isTrue, reason: input);
      expect(original.facts['voice:nameCustody'], isNull);
      expect(original.facts['voice:act7Reached'], isNull);
      expect(jsonEncode(original.toJson()), before);
    }
  });

  test('JSON roundtrip keeps questions separate from confirmed choices', () {
    final original = _atLedger();
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());

    final question = FourteenthVoiceAct7.advance(
      restored,
      'Ich frage, ob Liora den Namen anvertrauen sinnvoll wäre.',
    );
    expect(identical(question.campaign, restored), isTrue);

    final chosen = FourteenthVoiceAct7.advance(
      restored,
      'Ich will den Namen selbst bewahren.',
    ).campaign;
    final decoded = Campaign.fromJson(chosen.toJson());
    expect(decoded.storyBible['stage'], 'voice-threshold');
    expect(decoded.facts['voice:nameCustody'], 'hero');
    expect(decoded.hero.toJson(), restored.hero.toJson());
    expect(jsonEncode(restored.toJson()), before);
  });

  test('SQLite restart retains the actual decision and journal', () async {
    final directory = await Directory.systemTemp.createTemp('act7-custody-');
    final dbPath = paths.join(directory.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: dbPath,
    );
    try {
      final original = _atLedger();
      final chosen = FourteenthVoiceAct7.advance(
        original,
        'Ich vertraue Liora den Namen an.',
      ).campaign;
      await repository.saveCampaign(chosen);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      final restored = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(restored.toJson());
      expect(restored.storyBible['stage'], 'voice-threshold');
      expect(restored.facts['voice:nameCustody'], 'liora');
      expect(restored.facts['voice:act7Reached'], 'true');
      expect(restored.facts['voice:oathPageFound'], 'true');
      expect(restored.hero.toJson(), original.hero.toJson());
      expect(
        (await repository.reconstructCampaign(restored.id))!.toJson(),
        restored.toJson(),
      );
      expect(jsonEncode(restored.toJson()), before);
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
