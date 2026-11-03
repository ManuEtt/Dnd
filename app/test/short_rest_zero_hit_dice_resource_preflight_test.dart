import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';

class _CountingRandom implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

void main() {
  GameEngine newEngine(_CountingRandom random) => GameEngine(
    dice: DiceEngine(random: random),
    clock: () => DateTime.utc(2026, 11, 2),
  );

  test('zero-die rest rejects forged Fighter Pact Magic at full HP', () {
    final random = _CountingRandom();
    final engine = newEngine(random);
    final base = engine.createDemo();
    final forgedHero = base.hero.copyWith(spentPactSlots: 1);
    final forged = base.copyWith(hero: forgedHero);
    final original = jsonEncode(forged.hero.toJson());
    final beforeRolls = random.calls;

    expect(
      () => RestRules.validateShortRestResources(forged.hero),
      throwsFormatException,
    );
    // Invalid persisted source data cannot produce a serialized blocked
    // event. _commit validates every resulting campaign and rejects it.
    // The caller must not treat the thrown FormatException as a saved turn.
    expect(
      () => engine.act(forged, 'Ich mache eine kurze Rast.'),
      throwsFormatException,
    );
    expect(jsonEncode(forged.hero.toJson()), original);
    expect(forged.events, isEmpty);
    expect(update.campaign.hero.spentPactSlots, 1);
    expect(random.calls, beforeRolls);
  });

  test('zero-die rest rejects forged Pact Magic after all Hit Dice spent', () {
    final random = _CountingRandom();
    final engine = newEngine(random);
    final base = engine.createDemo();
    final forged = base.copyWith(
      hero: base.hero.copyWith(
        hitPoints: 3,
        spentHitDice: const {'d10': 1},
        spentPactSlots: 1,
      ),
    );
    final original = jsonEncode(forged.hero.toJson());
    final beforeRolls = random.calls;

    // Invalid persisted source data cannot produce a serialized blocked
    // event. _commit validates every resulting campaign and rejects it.
    // The caller must not treat the thrown FormatException as a saved turn.
    expect(
      () => engine.act(forged, 'Ich mache eine kurze Rast.'),
      throwsFormatException,
    );
    expect(jsonEncode(forged.hero.toJson()), original);
    expect(forged.events, isEmpty);
    expect(random.calls, beforeRolls);
  });

  test('invalid zero-die class resources are not silently restored', () {
    final random = _CountingRandom();
    final engine = newEngine(random);
    final base = engine.createDemo();
    final forgedHero = base.hero.copyWith(
      spentClassResources: const {'rage': 1},
    );
    final forged = base.copyWith(hero: forgedHero);
    final original = jsonEncode(forged.hero.toJson());

    // Invalid persisted source data cannot produce a serialized blocked
    // event. _commit validates every resulting campaign and rejects it.
    // The caller must not treat the thrown FormatException as a saved turn.
    expect(
      () => engine.act(forged, 'Ich mache eine kurze Rast.'),
      throwsFormatException,
    );
    expect(jsonEncode(forged.hero.toJson()), original);
    expect(forged.events, isEmpty);
    expect(random.calls, 0);
  });

  test('valid full-HP Fighter recovers one Second Wind without rolling', () {
    final random = _CountingRandom();
    final engine = newEngine(random);
    final base = engine.createDemo();
    final hero = base.hero.copyWith(spentSecondWind: 1);
    expect(RestRules.validateShortRestResources(hero), {'d10': 1});
    final before = jsonEncode(hero.toJson());

    final campaign = base.copyWith(hero: hero);
    final update = engine.act(campaign, 'Ich mache eine kurze Rast.');
    expect(update.events.single.type, 'character.shortRest');
    expect(update.events.single.payload['count'], 0);
    expect(update.events.single.payload['rolls'], isEmpty);
    expect(update.campaign.hero.spentSecondWind, 0);
    expect(update.campaign.hero.spentHitDice, isEmpty);
    expect(random.calls, 0);
    expect(jsonEncode(hero.toJson()), before);
  });

  test('valid depleted Warlock recovers Pact Magic with no Hit Dice', () {
    final random = _CountingRandom();
    final engine = newEngine(random);
    final base = engine.createDemo();
    final hero = base.hero.copyWith(
      className: 'Hexenmeister',
      hitPoints: 3,
      spentHitDice: const {'d8': 1},
      spentPactSlots: 1,
    );
    expect(RestRules.validateShortRestResources(hero), {'d8': 0});
    final before = jsonEncode(hero.toJson());

    final campaign = base.copyWith(hero: hero);
    final update = engine.act(campaign, 'Ich mache eine kurze Rast.');
    expect(update.events.single.type, 'character.shortRest');
    expect(update.events.single.payload['count'], 0);
    expect(update.events.single.payload['rolls'], isEmpty);
    expect(update.campaign.hero.hitPoints, 3);
    expect(update.campaign.hero.spentPactSlots, 0);
    expect(update.campaign.hero.spentHitDice, {'d8': 1});
    expect(random.calls, 0);
    expect(jsonEncode(hero.toJson()), before);
    final resumed = Campaign.fromJson(update.campaign.toJson());
    expect(resumed.hero.spentPactSlots, 0);
    expect(resumed.hero.spentHitDice, {'d8': 1});
  });
}
