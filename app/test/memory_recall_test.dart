import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

GameEngine demoEngine() => GameEngine(clock: () => DateTime.utc(2026, 10, 15));

Campaign memoryCampaign({Map<String, String> facts = const {}}) => Campaign(
  id: 'confirmed',
  name: 'Silberhain',
  world: 'Aetheria',
  sessionId: 'session',
  hero: HeroCharacter(id: 'arescan', name: 'Arescan'),
  scene: 'Eine unbestätigte Erzählung über einen Drachen.',
  facts: facts,
  quests: const [
    Quest(id: 'signal', title: 'Das Signal entzünden', status: 'completed'),
    Quest(id: 'lost', title: 'Den Boten suchen', status: 'failed'),
  ],
  npcs: const [
    WorldNpc(id: 'mira', name: 'Mira', description: 'Hüterin des Dorfes.'),
    WorldNpc(id: 'knight', name: 'Schattenritter', alive: false),
  ],
  places: const [Place(id: 'shrine', name: 'Waldschrein')],
);

void main() {
  test('topical recall excludes unrelated high-priority memories', () {
    final campaign = memoryCampaign(facts: {
      for (var i = 0; i < 130; i++) 'Wetter $i': 'Nebel am Meer $i',
      'Mira Warnung': 'Mira bewacht den alten Brunnen.',
    });
    final memories = MemoryEngine.retrieve(
      campaign,
      'Was weißt du über Mira?',
      matchingOnly: true,
      limit: 4,
    );
    expect(memories, isNotEmpty);
    expect(memories.join(' '), contains('Mira'));
    expect(memories.join(' '), isNot(contains('Wetter')));
    expect(memories.join(' '), isNot(contains('Schattenritter')));
    expect(memories.join(' '), isNot(contains('Quest abgeschlossen')));
  });

  test('unknown topic never substitutes unrelated quest facts or scene', () {
    final campaign = memoryCampaign();
    expect(MemoryEngine.retrieve(
      campaign, 'Erinnere dich an den Drachen.', matchingOnly: true,
    ), isEmpty);
    final update = demoEngine().act(campaign, 'Erinnere dich an den Drachen.');
    expect(update.narration, contains('keine passende Erinnerung'));
    expect(update.narration, isNot(contains('Drachen')));
    expect(update.narration, isNot(contains('Schattenritter')));
    expect(update.events.single.type, 'memory.recalled');
  });

  test('general recap uses confirmed quest and NPC statuses', () {
    final update = demoEngine().act(
      memoryCampaign(), 'Fasse unsere bisherige Geschichte zusammen.',
    );
    expect(update.narration, contains('Schattenritter'));
    expect(update.narration, contains('tot'));
    expect(update.narration, contains('Quest abgeschlossen'));
    expect(update.narration, isNot(contains('unbestätigte Erzählung')));
    expect(update.narration.length, lessThan(4000));
  });

  test('recall event preserves confirmed rules and pending roll', () {
    final engine = demoEngine();
    final seed = engine.createDemo();
    final pending = engine.act(
      engine.act(seed, 'Ich gehe zum Schrein.').campaign,
      'Ich greife an.',
    ).campaign;
    expect(pending.pendingRoll, isNotNull);
    final oldRevision = pending.revision;
    final oldHero = jsonEncode(pending.hero.toJson());
    final oldQuest = jsonEncode(pending.quests.map((e) => e.toJson()).toList());
    final oldEncounter = jsonEncode(pending.encounter?.toJson());
    final oldPending = jsonEncode(pending.pendingRoll?.toJson());
    final update = engine.act(pending, 'Was weißt du über Mira?');
    expect(update.events.single.type, 'memory.recalled');
    expect(update.campaign.revision, oldRevision + 1);
    expect(jsonEncode(update.campaign.hero.toJson()), oldHero);
    expect(jsonEncode(update.campaign.quests.map((e) => e.toJson()).toList()), oldQuest);
    expect(jsonEncode(update.campaign.encounter?.toJson()), oldEncounter);
    expect(jsonEncode(update.campaign.pendingRoll?.toJson()), oldPending);
    expect(update.narration, contains('Mira'));
    expect(Campaign.fromJson(update.campaign.toJson()).toJson(), update.campaign.toJson());
    expect(update.events.single.payload['stateAfter'],
        update.campaign.copyWith(events: const []).toJson());
  });

  test('recalled facts are limited to confirmed sources and remain immutable', () {
    final campaign = memoryCampaign(facts: const {
      'Amulett': 'Die Wirkung des Amuletts ist unbekannt.',
    });
    final before = jsonEncode(campaign.toJson());
    final update = demoEngine().act(
      campaign, 'Was weißt du über das Amulett?',
    );
    expect(update.narration, contains('Wirkung des Amuletts ist unbekannt'));
    expect(update.campaign.hero.hitPoints, isNull);
    expect(update.campaign.hero.abilities.values.every((e) => e == null), isTrue);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('Mira responds to confirmed quest stages without resetting progress', () {
    final gm = demoEngine();
    final seed = gm.createDemo();
    final newKey = gm.act(seed, 'Ich untersuche den Brunnen.').campaign;
    final withKey = gm.act(newKey, 'Ich spreche mit Mira.');
    expect(withKey.narration, contains('bereits gefunden'));
    expect(withKey.narration, isNot(contains('Suche den Messingschlüssel')));
    expect(withKey.campaign.hero.inventory.length,
        newKey.hero.inventory.length);

    final guardianDown = newKey.copyWith(
      facts: {...newKey.facts, 'guardianDefeated': 'true'},
    );
    final afterGuardian = gm.act(guardianDown, 'Ich frage Mira.');
    expect(afterGuardian.narration, contains('besiegt'));
    expect(afterGuardian.narration, contains('gefundenen Messingschlüssel'));

    final finished = newKey.copyWith(
      facts: {...newKey.facts, 'questCompleted': 'true'},
      quests: [for (final quest in newKey.quests)
        quest.copyWith(status: 'completed')],
    );
    final afterQuest = gm.act(finished, 'Ich spreche mit Mira.');
    expect(afterQuest.narration, contains('Auftrag erfüllt'));
    expect(afterQuest.narration, isNot(contains('Suche den Messingschlüssel')));
    expect(afterQuest.campaign.quests.single.status, 'completed');
    expect(afterQuest.campaign.hero.toJson(), finished.hero.toJson());
  });

  test('explicit memory question detection does not intercept ordinary actions', () {
    expect(MemoryEngine.isRecallRequest('Was weißt du über Mira?'), isTrue);
    expect(MemoryEngine.isRecallRequest('Erinnere dich an Mira.'), isTrue);
    expect(MemoryEngine.isRecallRequest('Rückblick'), isTrue);
    expect(MemoryEngine.isRecallRequest('Fasse unsere bisherige Geschichte zusammen.'), isTrue);
    expect(MemoryEngine.isRecallRequest('Ich lese eine alte Geschichte.'), isFalse);
    expect(MemoryEngine.isRecallRequest('Ich rede mit Mira.'), isFalse);
  });
}
