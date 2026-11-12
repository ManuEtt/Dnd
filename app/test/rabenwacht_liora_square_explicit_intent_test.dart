import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final engine = GameEngine();

  Campaign continued() {
    final original = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(name: 'Valen', experience: 900),
    );
    final finished = original.copyWith(
      storyBible: {...original.storyBible, 'stage': 'end-seal'},
      facts: {...original.facts, 'ending': 'end-seal'},
    );
    return engine.act(finished, 'Fortsetzung beginnen').campaign;
  }

  test('hypotheses and reported words do not change Liora or her quest', () {
    final before = continued();
    final encoded = jsonEncode(before.toJson());
    final relationship = before.npcs.singleWhere((npc) => npc.id == 'liora');
    final quest = before.quests.singleWhere((q) => q.id == 'voice-liora');

    for (final phrase in [
      'Was wäre, wenn ich Liora beschütze?',
      'Ich frage, ob ich Liora beschuldigen soll.',
      'Ich will Liora nicht beschuldigen.',
      'Ich erzähle, dass ich Liora beschütze.',
      'Ich würde zuerst Beweise suchen.',
      'Ich frage, ob ich zuerst Belege suchen sollte.',
    ]) {
      final result = engine.act(before, phrase).campaign;
      expect(result.storyBible['stage'], 'voice-square', reason: phrase);
      expect(result.facts['voice:lioraChoice'], isNull, reason: phrase);
      expect(
        result.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
        relationship.relationship,
        reason: phrase,
      );
      expect(
        result.quests.singleWhere((q) => q.id == 'voice-liora').status,
        quest.status,
        reason: phrase,
      );
      expect(result.hero.toJson(), before.hero.toJson(), reason: phrase);
    }
    expect(jsonEncode(before.toJson()), encoded);
  });

  test('clear protection, accusation and investigation remain selectable', () {
    for (final choice in [
      ('Ich schütze Liora.', 'protect', 'vertrauensvoll'),
      ('Ich beschütze die Fremde.', 'protect', 'vertrauensvoll'),
      ('Ich beschuldige Liora.', 'accuse', 'misstrauisch'),
      ('Ich klage Liora an.', 'accuse', 'misstrauisch'),
      ('Ich will erst Belege suchen.', 'evidence', 'unbekannt'),
      ('Ich suche zuerst Beweise.', 'evidence', 'unbekannt'),
    ]) {
      final before = continued();
      final after = engine.act(before, choice.$1).campaign;
      expect(after.facts['voice:lioraChoice'], choice.$2);
      expect(after.storyBible['stage'], 'voice-square');
      expect(
        after.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
        choice.$3,
      );
      expect(
        after.quests.singleWhere((q) => q.id == 'voice-liora').status,
        'completed',
      );
      expect(after.hero.toJson(), before.hero.toJson());
      expect(Campaign.fromJson(after.toJson()).toJson(), after.toJson());
    }
  });

  test('a confirmed first choice cannot be rewritten by another response', () {
    final original = continued();
    final protected = engine.act(original, 'Ich schütze Liora.').campaign;
    for (final attempt in [
      'Ich beschuldige Liora.',
      'Ich will erst Belege suchen.',
      'Ich verteidige Liora.',
    ]) {
      final repeated = engine.act(protected, attempt).campaign;
      expect(repeated.facts, protected.facts, reason: attempt);
      expect(
        repeated.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
        'vertrauensvoll',
        reason: attempt,
      );
      expect(repeated.hero.toJson(), protected.hero.toJson());
      expect(
        repeated.quests.singleWhere((q) => q.id == 'voice-liora').status,
        'completed',
      );
    }
  });

  test('after a decision the other witnesses remain accessible', () {
    final chosen = engine.act(continued(), 'Ich beschuldige Liora.').campaign;
    final moved = engine.act(chosen, 'Ich besuche Elda.').campaign;
    expect(moved.storyBible['stage'], 'voice-elda');
    expect(moved.facts['voice:lioraChoice'], 'accuse');
    expect(
      moved.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
      'misstrauisch',
    );
    expect(moved.hero.toJson(), chosen.hero.toJson());
  });

  test('confirmed choice survives JSON and SQLite reopening', () async {
    final folder = await Directory.systemTemp.createTemp('liora-choice-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final before = continued();
      final confirmed = engine.act(before, 'Ich schütze Liora.').campaign;
      expect(
        Campaign.fromJson(
          jsonDecode(jsonEncode(confirmed.toJson())) as Map<String, dynamic>,
        ).toJson(),
        confirmed.toJson(),
      );
      await repository.saveCampaign(confirmed);
      await repository.close();

      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(confirmed.id))!;
      expect(restored.facts['voice:lioraChoice'], 'protect');
      expect(
        restored.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
        'vertrauensvoll',
      );
      expect(restored.hero.toJson(), before.hero.toJson());
      expect(
        (await repository.reconstructCampaign(restored.id))!.toJson(),
        restored.toJson(),
      );
      final rejected = engine.act(restored, 'Ich beschuldige Liora.').campaign;
      expect(rejected.facts['voice:lioraChoice'], 'protect');
      expect(
        rejected.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
        'vertrauensvoll',
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
