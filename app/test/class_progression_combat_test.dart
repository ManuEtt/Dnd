import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class LowRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

GameEngine gameMaster() => GameEngine(
  dice: DiceEngine(random: LowRandom()),
  clock: () => DateTime.utc(2026, 10, 16),
);

Campaign beginFight(GameEngine gm, int level, {String className = 'Kämpfer'}) {
  var game = gm.createDemo();
  game = game.copyWith(hero: game.hero.copyWith(
    className: className, level: level,
  ));
  return gm.act(game, 'Ich gehe zum Waldschrein.').campaign;
}

Campaign miss(GameEngine gm, Campaign game) {
  final rolled = gm.act(game, 'Ich greife den Wächter an.').campaign;
  expect(rolled.pendingRoll?.type, 'attack');
  return gm.resolveRoll(rolled, natural: 1).campaign;
}

void main() {
  test('Kämpfer Stufe 5: zwei Angriffe, ein einziger gegnerischer Zug', () {
    final gm = gameMaster();
    var game = beginFight(gm, 5);
    final round = game.encounter!.round;
    game = miss(gm, game);
    expect(game.encounter!.attacksRemaining, 1);
    expect(game.encounter!.round, round);
    expect(game.encounter!.actionUsed, isTrue);
    expect(game.events.last.payload.containsKey('enemyTurn'), isFalse);
    // Serialize/deserialize in the middle of the Attack action.
    game = Campaign.fromJson(game.toJson());
    expect(game.encounter!.attacksRemaining, 1);
    game = miss(gm, game);
    expect(game.encounter!.attacksRemaining, 0);
    expect(game.encounter!.round, round + 1);
    expect(game.events.last.payload.containsKey('enemyTurn'), isTrue);
  });

  test('Kämpfer Stufe 11: drei Angriffe, Runde erst danach beendet', () {
    final gm = gameMaster();
    var game = beginFight(gm, 11);
    final round = game.encounter!.round;
    game = miss(gm, game);
    expect(game.encounter!.attacksRemaining, 2);
    game = miss(gm, game);
    expect(game.encounter!.attacksRemaining, 1);
    expect(game.encounter!.round, round);
    game = miss(gm, game);
    expect(game.encounter!.attacksRemaining, 0);
    expect(game.encounter!.round, round + 1);
  });

  test('Bei laufender Angriffsaktion ist keine zweite volle Aktion möglich', () {
    final gm = gameMaster();
    var game = beginFight(gm, 5);
    game = miss(gm, game);
    final round = game.encounter!.round;
    for (final input in ['Ich weiche aus.', 'Ich fliehe.',
        'Ich trinke einen Heiltrank.']) {
      final attempt = gm.act(game, input);
      expect(attempt.events.single.type, 'rules.blocked');
      expect(attempt.campaign.encounter!.round, round);
      expect(attempt.campaign.encounter!.attacksRemaining, 1);
      game = attempt.campaign;
    }
    game = miss(gm, game);
    expect(game.encounter!.round, round + 1);
  });

  test('Restliche Angriffe freiwillig aufgeben beendet den Zug', () {
    final gm = gameMaster();
    var game = beginFight(gm, 11);
    game = miss(gm, game);
    expect(game.encounter!.attacksRemaining, 2);
    game = gm.act(game, 'Ich beende meinen Zug.').campaign;
    expect(game.encounter!.attacksRemaining, 0);
    expect(game.encounter!.actionUsed, isFalse);
  });

  test('Charakter ohne Extra Attack löst sofort Gegnerzug aus', () {
    final gm = gameMaster();
    var game = beginFight(gm, 5, className: 'Magier');
    final round = game.encounter!.round;
    game = miss(gm, game);
    expect(game.encounter!.round, round + 1);
    expect(game.encounter!.attacksRemaining, 0);
  });

  test('Alte Encounter-Speicherstände ohne Feld laden ohne Zusatzangriffe', () {
    final gm = gameMaster();
    final campaign = beginFight(gm, 5);
    final old = campaign.toJson();
    final encounter = Map<String, dynamic>.from(old['encounter'] as Map);
    encounter.remove('attacksRemaining');
    old['encounter'] = encounter;
    expect(Campaign.fromJson(old).encounter!.attacksRemaining, 0);
    encounter['attacksRemaining'] = 99;
    expect(() => Campaign.fromJson(old), throwsFormatException);
  });
}
