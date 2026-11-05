import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

GameEngine _engine() => GameEngine(clock: () => DateTime.utc(2026, 11, 5));

void main() {
  sqfliteFfiInit();

  test('invisible provider characters fail before any event rewrite', () {
    final gm = _engine();
    final original = gm.act(gm.createDemo(), 'Ich lausche dem Wind.');
    final before = jsonEncode(original.campaign.toJson());
    final originalEvent = jsonEncode(original.events.single.toJson());

    for (final code in [
      0x00,
      0x08,
      0x0b,
      0x7f,
      0x00ad,
      0x034f,
      0x061c,
      0x180e,
      0x200b,
      0x200f,
      0x2028,
      0x202e,
      0x2060,
      0x2066,
      0x2069,
      0x206a,
      0x206f,
      0xfeff,
    ]) {
      final mark = String.fromCharCode(code);
      expect(
        () => gm.replaceNarration(
          original,
          text: 'Die Truhe${mark}enthält 999 Gold.',
          provider: 'openai',
        ),
        throwsFormatException,
        reason: 'U+${code.toRadixString(16)}',
      );
      expect(jsonEncode(original.campaign.toJson()), before);
      expect(jsonEncode(original.events.single.toJson()), originalEvent);
    }
  });

  test('valid multiline, tabs, emoji and RTL letters remain intact', () {
    final gm = _engine();
    final original = gm.act(gm.createDemo(), 'Ich gehe zum alten Turm.');
    const text = 'Äther und Drache 🐉.\nשלום\tim Mondlicht.\nWas tust du?';
    final before = jsonEncode(original.campaign.toJson());

    final updated = gm.replaceNarration(
      original,
      text: '  $text  ',
      provider: 'openai',
    );

    expect(updated.narration, text);
    expect(updated.campaign.messages.last.text, text);
    expect(updated.campaign.hero.toJson(), original.campaign.hero.toJson());
    expect(updated.campaign.quests, original.campaign.quests);
    expect(updated.campaign.revision, original.campaign.revision);
    expect(updated.campaign.events.last.id, original.events.single.id);
    expect(updated.events.single.payload['narrationProvider'], 'openai');
    expect(
      updated.events.single.payload['stateAfter'],
      updated.campaign.copyWith(events: const []).toJson(),
    );
    expect(jsonEncode(original.campaign.toJson()), before);
    expect(
      Campaign.fromJson(updated.campaign.toJson()).toJson(),
      updated.campaign.toJson(),
    );
  });

  test('provider boundary keeps length and provider validation unchanged', () {
    final gm = _engine();
    final original = gm.act(gm.createDemo(), 'Ich lausche dem Fluss.');

    expect(
      gm.replaceNarration(
        original,
        text: 'ä' * 4000,
        provider: 'mock',
      ).narration,
      'ä' * 4000,
    );
    for (final text in ['', '  \n ', 'ä' * 4001]) {
      expect(
        () => gm.replaceNarration(
          original,
          text: text,
          provider: 'mock',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => gm.replaceNarration(
        original,
        text: 'Ein harmloser Absatz.',
        provider: 'unbekannt',
      ),
      throwsFormatException,
    );
  });

  test('SQLite restart and replay retain a safe narration only', () async {
    final dir = await Directory.systemTemp.createTemp('narration-guard-');
    final path = paths.join(dir.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final gm = _engine();
      final seed = gm.createDemo();
      await repository.saveCampaign(seed);
      final original = gm.act(seed, 'Ich grüße die Kartografin.');
      final before = jsonEncode(original.campaign.toJson());
      expect(
        () => gm.replaceNarration(
          original,
          text: 'Ein falscher Titel\u202e Quest: abgeschlossen.',
          provider: 'openai',
        ),
        throwsFormatException,
      );
      expect(jsonEncode(original.campaign.toJson()), before);

      final accepted = gm.replaceNarration(
        original,
        text: 'Die Kartografin nickt.\n„Was möchtest du wissen?“',
        provider: 'openai',
      );
      await repository.saveCampaign(
        accepted.campaign,
        events: accepted.events,
      );
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(seed.id))!;
      final saved = jsonEncode(restored.toJson());

      expect(restored.messages.last.text, accepted.narration);
      expect(restored.hero.toJson(), seed.hero.toJson());
      expect(restored.quests, seed.quests);
      expect(restored.events.last.payload['narrationProvider'], 'openai');
      expect(
        MemoryEngine.replay(seed, restored.events).toJson(),
        restored.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(seed.id))!.toJson(),
        restored.toJson(),
      );
      expect(jsonEncode(restored.toJson()), saved);
    } finally {
      await repository.close();
      await dir.delete(recursive: true);
    }
  });
}
