import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

GameEngine engine() => GameEngine(
  dice: DiceEngine(random: MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 13),
);

Campaign attack(
  GameEngine gm,
  Campaign campaign, {
  int? natural = 20,
  int? total,
}) {
  final pending = gm
      .act(campaign, 'Ich greife mit meinem Schwert an.')
      .campaign;
  expect(pending.pendingRoll?.type, 'attack');
  return gm.resolveRoll(pending, natural: natural, total: total).campaign;
}

void main() {
  test(
    'New campaigns have independent identities and selected hero narration',
    () {
      final gm = engine();
      final first = gm.createDemo();
      final second = gm.createDemo(
        hero: first.hero.copyWith(name: 'Elya'),
        name: 'Meine Reise',
      );
      expect(first.id, isNot(second.id));
      expect(second.name, 'Meine Reise');
      expect(second.scene, contains('Elya'));
      expect(gm.createArescan().id, isNot(gm.createArescan().id));
    },
  );

  test(
    'Playable demo persists key, resolves full combat, consumes key and completes quest',
    () {
      final gm = engine();
      var game = gm.createDemo();
      expect(game.hero.isComplete, isTrue);
      game = gm.act(game, 'Ich untersuche den Brunnen.').campaign;
      expect(game.hero.inventory.where((e) => e.id == 'brass-key').length, 1);
      game = gm.act(game, 'Ich untersuche den Brunnen erneut.').campaign;
      expect(game.hero.inventory.where((e) => e.id == 'brass-key').length, 1);
      game = Campaign.fromJson(
        jsonDecode(jsonEncode(game.toJson())) as Map<String, dynamic>,
      );
      game = gm.act(game, 'Ich gehe zum Waldschrein.').campaign;
      expect(game.encounter?.round, 1);
      expect(game.encounter?.enemyHitPoints, 10);
      game = attack(gm, game);
      expect(game.encounter?.enemyHitPoints, 5);
      expect(
        game.hero.hitPoints,
        12,
      ); // The deterministic enemy rolled a natural 1.
      game = attack(gm, game);
      expect(game.encounter?.isFinished, isTrue);
      game = gm.act(game, 'Ich öffne den Schrein.').campaign;
      expect(game.quests.single.status, 'completed');
      expect(game.hero.inventory.any((e) => e.id == 'brass-key'), isFalse);
      final remembered = Campaign.fromJson(game.toJson());
      game = gm.act(remembered, 'Ich öffne das Tor erneut.').campaign;
      expect(game.quests.single.status, 'completed');
      expect(game.hero.inventory.any((e) => e.id == 'brass-key'), isFalse);
      final memory = MemoryEngine.context(game);
      expect((memory['longTerm'] as Map)['facts']['questCompleted'], 'true');
    },
  );

  test(
    'Arescan import preserves historical numbers without inventing abilities',
    () {
      final gm = engine();
      var game = Campaign.fromJson(gm.createArescan().toJson());
      expect(game.hero.abilities.values.every((e) => e == null), isTrue);
      expect(game.hero.hitPoints, isNull);
      expect(game.hero.armorClass, isNull);
      expect(game.hero.gold, isNull);
      expect(game.hero.experience, isNull);
      expect(game.hero.inventory, isEmpty);
      final history = game.events.single.payload;
      expect(history['attackTotal'], 19);
      expect(history['narratedDamage'], 14);
      expect(history['naturalRoll'], isNull);
      expect(history['unverifiedDexterityModifier'], 7);
      expect(history['mechanicallyVerified'], isFalse);
      game = gm.act(game, 'Ich greife den Schattenritter an.').campaign;
      expect(game.events.last.type, 'rules.blocked');
      expect(game.pendingRoll, isNull);
      expect(game.hero.hitPoints, isNull);
      game = gm.act(game, 'Ich befrage die Elfenmagierin.').campaign;
      expect(game.messages.last.text, contains('Elfenmagierin'));
      expect(game.hero.isComplete, isFalse);
    },
  );

  test(
    'Taking Arescan amulet is idempotent and the narration remembers its location',
    () {
      final gm = engine();
      var game = gm.createArescan();
      game = gm.act(game, 'Ich nehme das Amulett.').campaign;
      expect(game.hero.inventory.single.id, 'red-amulet');
      expect(game.scene, contains('Arescan trägt das rote Amulett'));
      game = gm.act(game, 'Ich nehme das Amulett erneut.').campaign;
      expect(game.hero.inventory.length, 1);
      game = gm.act(game, 'Ich untersuche den Schattenritter.').campaign;
      expect(game.messages.last.text, contains('deiner Tasche'));
      expect(
        game.messages.last.text,
        isNot(contains('überstrahlt seine Brust')),
      );
    },
  );

  test(
    'Manual total never gains a second attack bonus or fabricated critical',
    () {
      final gm = engine();
      var game = gm.act(gm.createDemo(), 'Ich gehe zum Schrein.').campaign;
      game = attack(gm, game, natural: null, total: 20);
      final event = game.events.last.payload;
      expect(event['roll']['total'], 20);
      expect(event['roll']['natural'], isNull);
      expect(event['damage'], 4); // 1d8=1 plus Strength=3, no critical.
      expect(game.encounter?.enemyHitPoints, 6);
    },
  );

  test('Manual German voice result accepts natural and explicit total', () {
    final gm = engine();
    var game = gm.act(gm.createDemo(), 'Ich gehe zum Schrein.').campaign;
    game = gm.act(game, 'Ich greife an.').campaign;
    game = gm.act(game, 'Ich habe sechzehn gewürfelt.').campaign;
    expect(game.events.last.payload['roll']['natural'], 16);
    expect(game.events.last.payload['roll']['total'], 21);
    game = gm.act(game, 'Ich greife an.').campaign;
    game = gm.act(game, 'Gesamt 19.').campaign;
    expect(game.events.last.payload['roll']['total'], 19);
    expect(game.events.last.payload['roll']['natural'], isNull);
  });

  test('Confirmed hero edit clears stale cached roll modifiers', () {
    final gm = engine();
    var game = gm.act(gm.createDemo(), 'Ich gehe zum Schrein.').campaign;
    game = gm.act(game, 'Ich greife an.').campaign;
    expect(game.pendingRoll?.modifier, 5);
    game = gm
        .updateHero(
          game,
          game.hero.copyWith(
            abilities: {...game.hero.abilities, 'strength': 12},
          ),
        )
        .campaign;
    expect(game.pendingRoll, isNull);
    game = gm.act(game, 'Ich greife an.').campaign;
    expect(game.pendingRoll?.modifier, 3);
  });

  test(
    'Fleeing and returning does not resurrect or fully heal damaged enemy',
    () {
      final gm = engine();
      var game = gm.act(gm.createDemo(), 'Ich gehe zum Schrein.').campaign;
      game = attack(gm, game, natural: 19);
      expect(game.encounter?.enemyHitPoints, 6);
      game = gm.act(game, 'Ich fliehe.').campaign;
      expect(game.pendingRoll?.type, 'escape');
      game = gm.resolveRoll(game, natural: 20).campaign;
      expect(game.encounter, isNull);
      game = gm.act(game, 'Ich gehe zum Schrein zurück.').campaign;
      expect(game.encounter?.enemyHitPoints, 6);
    },
  );

  test('Healing consumes exactly one potion and safe rest restores HP', () {
    final gm = engine();
    var game = gm.createDemo();
    game = game.copyWith(hero: game.hero.copyWith(hitPoints: 2));
    game = gm.act(game, 'Ich trinke einen Heiltrank.').campaign;
    expect(game.hero.hitPoints, 6);
    expect(game.hero.inventory.any((e) => e.id == 'potion'), isFalse);
    game = gm.act(game, 'Ich trinke einen Heiltrank.').campaign;
    expect(game.hero.hitPoints, 6);
    game = gm.act(game, 'Ich mache eine lange Rast.').campaign;
    expect(game.hero.hitPoints, 12);
  });

  test('Death saves require natural result and can restore one HP', () {
    final gm = engine();
    var game = gm.createDemo();
    game = game.copyWith(
      hero: game.hero.copyWith(hitPoints: 0, conditions: ['bewusstlos']),
    );
    game = gm.act(game, 'Todesrettungswurf').campaign;
    expect(game.pendingRoll?.type, 'death');
    expect(() => gm.resolveRoll(game, total: 20), throwsArgumentError);
    game = gm.resolveRoll(game, natural: 20).campaign;
    expect(game.hero.hitPoints, 1);
    expect(game.hero.conditions, isNot(contains('bewusstlos')));
  });

  test(
    'Event checkpoints reconstruct confirmed world state and deduplicate replay',
    () {
      final gm = engine();
      final seed = gm.createDemo();
      final one = gm.act(seed, 'Ich untersuche den Brunnen.');
      final two = gm.act(one.campaign, 'Ich befrage Mira.');
      final restored = MemoryEngine.replay(seed, [
        ...one.events,
        ...one.events,
        ...two.events,
      ]);
      expect(restored.toJson(), two.campaign.toJson());
      expect(
        () => MemoryEngine.replay(seed, two.events),
        throwsFormatException,
      );
      final original = one.events.single;
      final changed = GameEvent(
        id: original.id,
        campaignId: original.campaignId,
        sessionId: original.sessionId,
        timestamp: original.timestamp,
        type: 'modified',
        payload: original.payload,
      );
      expect(
        () => MemoryEngine.replay(seed, [original, changed]),
        throwsFormatException,
      );
    },
  );

  test(
    'All supported free dice are journaled without changing mechanical values',
    () {
      final gm = engine();
      var game = gm.createArescan();
      final original = game.hero.toJson();
      for (final die in DiceEngine.supportedSides) {
        game = gm.rollDice(game, '1d$die').campaign;
        expect(game.hero.toJson(), original);
        expect(game.events.last.type, 'dice.freeRoll');
        expect(game.events.last.payload['roll']['total'], 1);
      }
    },
  );

  test(
    'Strict versioned import rejects unsupported or corrupt mechanical values',
    () {
      final gm = engine();
      final game = gm.createDemo();
      expect(
        () => Campaign.fromJson({...game.toJson(), 'schemaVersion': 9}),
        throwsFormatException,
      );
      final hero = game.hero.toJson();
      expect(
        () => HeroCharacter.fromJson({...hero, 'hitPoints': 100}),
        throwsFormatException,
      );
      expect(
        () => HeroCharacter.fromJson({...hero, 'weaponDamage': 'd6'}),
        throwsFormatException,
      );
      expect(
        () => HeroCharacter.fromJson({...hero, 'level': 21}),
        throwsFormatException,
      );
      expect(
        () => PendingRoll.fromJson({
          'id': 'x',
          'type': 'arbitrary-sql',
          'modifier': 0,
          'difficulty': 10,
        }),
        throwsFormatException,
      );
      final pending = gm
          .act(gm.act(game, 'Ich gehe zum Schrein.').campaign, 'Ich greife an.')
          .campaign;
      final raw = pending.toJson();
      raw['pendingRoll']['modifier'] = 20;
      expect(() => Campaign.fromJson(raw), throwsFormatException);
    },
  );

  test(
    'Both packaged saves import and preserve historical and demo identity',
    () {
      final demo = Campaign.fromJson(
        jsonDecode(File('assets/demo.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      final arescan = Campaign.fromJson(
        jsonDecode(File('assets/arescan.json').readAsStringSync())
            as Map<String, dynamic>,
      );
      expect(demo.hero.isComplete, isTrue);
      expect(arescan.hero.name, 'Arescan');
      expect(arescan.hero.isComplete, isFalse);
      expect(arescan.events.single.payload['attackTotal'], 19);
    },
  );
}
