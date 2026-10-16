import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_flurry_rules.dart';

class FixedRandom implements Random {
  FixedRandom(this.middle);
  final bool middle;
  @override int nextInt(int max) => middle ? max ~/ 2 : 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

HeroCharacter monk({int monkLevel = 2, int focusSpent = 0,
    bool multiclass = false}) => HeroCharacter(
  id: 'monk', name: 'Liora',
  className: multiclass ? 'Kämpfer' : 'Mönch',
  level: multiclass ? monkLevel + 3 : monkLevel,
  secondaryClassName: multiclass ? 'Mönch' : '',
  secondaryClassLevel: multiclass ? monkLevel : 0,
  abilities: const {'strength': 12, 'dexterity': 16,
    'constitution': 12, 'intelligence': 10, 'wisdom': 14, 'charisma': 10},
  hitPoints: 30, maxHitPoints: 30, armorClass: 15, speed: 9,
  weaponDamage: '1d6', weaponProficient: true,
  spentClassResources: {'focusPoints': focusSpent},
);

Encounter enemy() => const Encounter(id: 'foe', enemyName: 'Wache',
    enemyHitPoints: 90, enemyMaxHitPoints: 90,
    enemyArmorClass: 12, movementRemaining: 12);

class MaximumRandom implements Random {
  @override int nextInt(int max) => max - 1;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

GameEngine gameMaster() => GameEngine(
  dice: DiceEngine(random: FixedRandom(false)),
  clock: () => DateTime.utc(2026, 10, 16),
);

Campaign beginFight(GameEngine gm, HeroCharacter hero) {
  var game = gm.createDemo();
  game = game.copyWith(hero: hero.copyWith(id: game.hero.id));
  return gm.act(game, 'Ich gehe zum Waldschrein.').campaign;
}

void main() {
  test('Monk 2: two independent strikes, one Focus, bonus action only', () {
    final result = MonkFlurryRules.use(monk(), enemy(),
        DiceEngine(random: FixedRandom(true)));
    expect(result.strikes, hasLength(2));
    expect(result.strikes.every((s) => s.hit), isTrue);
    expect(result.strikes.every((s) => s.damageRoll!.expression == '1d6'), isTrue);
    expect(result.damageTotal, 14);
    expect(result.encounter.enemyHitPoints, 76);
    expect(result.encounter.bonusActionUsed, isTrue);
    expect(result.encounter.actionUsed, isFalse);
    expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 1);
    expect(() => MonkFlurryRules.use(result.hero, result.encounter,
        DiceEngine(random: FixedRandom(true))), throwsStateError);
    final saved = Encounter.fromJson(result.encounter.toJson());
    expect(saved.bonusActionUsed, isTrue);
  });

  test('Monk 10: three strikes use D8, not total multiclass level', () {
    final mono = MonkFlurryRules.use(monk(monkLevel: 10), enemy(),
        DiceEngine(random: FixedRandom(true)));
    expect(mono.strikes, hasLength(3));
    expect(mono.strikes.every((s) => s.damageRoll!.expression == '1d8'), isTrue);
    final multi = monk(monkLevel: 2, multiclass: true);
    expect(MonkFlurryRules.strikeCount(multi), 2);
    expect(MonkFlurryRules.use(multi, enemy(),
        DiceEngine(random: FixedRandom(true))).strikes, hasLength(2));
  });

  test('critical dice double, ability modifier is not doubled', () {
    final strikes = MonkFlurryRules.use(monk(), enemy(),
        DiceEngine(random: MaximumRandom())).strikes;
    expect(strikes, hasLength(2));
    expect(strikes.first.damage, 15);
  });

  test('Only one confirmed attack ability is enough for Martial Arts', () {
    final both = monk();
    final onlyStrength = both.copyWith(abilities: {
      ...both.abilities, 'dexterity': null,
    });
    final onlyDexterity = both.copyWith(abilities: {
      ...both.abilities, 'strength': null,
    });
    expect(MonkFlurryRules.use(onlyStrength, enemy(),
        DiceEngine(random: FixedRandom(false))).strikes, hasLength(2));
    expect(MonkFlurryRules.use(onlyDexterity, enemy(),
        DiceEngine(random: FixedRandom(false))).strikes, hasLength(2));
    final neither = both.copyWith(abilities: {
      ...both.abilities, 'strength': null, 'dexterity': null,
    });
    expect(() => MonkFlurryRules.use(neither, enemy(),
        DiceEngine(random: FixedRandom(false))), throwsStateError);
  });

  test('focus, class level, armor, conditions, turn ownership fail closed', () {
    final dice = DiceEngine(random: FixedRandom(false));
    expect(() => MonkFlurryRules.use(monk(monkLevel: 1), enemy(), dice),
        throwsStateError);
    expect(() => MonkFlurryRules.use(monk(focusSpent: 2), enemy(), dice),
        throwsStateError);
    expect(() => MonkFlurryRules.use(monk(),
        enemy().copyWith(bonusActionUsed: true), dice), throwsStateError);
    expect(() => MonkFlurryRules.use(monk(),
        enemy().copyWith(activeParticipant: 'enemy'), dice), throwsStateError);
    expect(() => MonkFlurryRules.use(monk().copyWith(
        conditions: ['bewusstlos']), enemy(), dice), throwsStateError);
    expect(() => MonkFlurryRules.use(monk().copyWith(
        equippedArmorId: 'unverified'), enemy(), dice), throwsStateError);
  });

  test('GameEngine supports Flurry before Attack action, journals results', () {
    final gm = gameMaster();
    var game = beginFight(gm, monk());
    final round = game.encounter!.round;
    final flurry = gm.act(game, 'Schlaghagel');
    expect(flurry.events.single.type, 'class.flurryOfBlows');
    expect(flurry.events.single.payload['strikes'], hasLength(2));
    game = flurry.campaign;
    expect(game.encounter!.round, round);
    expect(game.encounter!.actionUsed, isFalse);
    expect(game.encounter!.bonusActionUsed, isTrue);
    expect(game.hero.spentClassResources['focusPoints'], 1);
    expect(gm.act(game, 'Schlaghagel').events.single.type, 'rules.blocked');
    game = Campaign.fromJson(game.toJson());
    expect(game.encounter!.bonusActionUsed, isTrue);
    final attack = gm.act(game, 'Ich greife an.');
    expect(attack.campaign.pendingRoll?.type, 'attack');
  });

  test('GameEngine offers Flurry after Attack, resolves enemy once', () {
    final gm = gameMaster();
    var game = beginFight(gm, monk(monkLevel: 5));
    final round = game.encounter!.round;
    for (var i = 0; i < 2; i++) {
      game = gm.act(game, 'Ich greife an.').campaign;
      game = gm.resolveRoll(game, natural: 1).campaign;
    }
    expect(game.encounter!.actionUsed, isTrue);
    expect(game.encounter!.attacksRemaining, 0);
    expect(game.encounter!.round, round);
    expect(gm.act(game, 'Schlaghagel').events.single.type,
        'class.flurryOfBlows');
    final flurry = gm.act(game, 'Schlaghagel');
    expect(flurry.events.single.payload.containsKey('enemyTurn'), isTrue);
    expect(flurry.campaign.encounter!.round, round + 1);
    expect(flurry.campaign.encounter!.bonusActionUsed, isFalse);
    expect(flurry.campaign.hero.spentClassResources['focusPoints'], 1);
  });

  test('Victory from Flurry does not trigger an enemy turn', () {
    final gm = GameEngine(dice: DiceEngine(random: FixedRandom(true)),
      clock: () => DateTime.utc(2026, 10, 16));
    var game = beginFight(gm, monk());
    game = game.copyWith(encounter: game.encounter!.copyWith(enemyHitPoints: 1));
    final flurry = gm.act(game, 'Schlaghagel');
    expect(flurry.events.single.type, 'class.flurryOfBlows');
    expect(flurry.events.single.payload['strikes'], hasLength(1));
    expect(flurry.events.single.payload.containsKey('enemyTurn'), isFalse);
    expect(flurry.campaign.encounter!.enemyHitPoints, 0);
    expect(flurry.campaign.facts['guardianDefeated'], 'true');
  });

  test('No second full action after Attack while Flurry remains available', () {
    final gm = gameMaster();
    var game = beginFight(gm, monk(monkLevel: 5));
    for (var i = 0; i < 2; i++) {
      game = gm.act(game, 'Ich greife an.').campaign;
      game = gm.resolveRoll(game, natural: 1).campaign;
    }
    expect(game.encounter!.attacksRemaining, 0);
    expect(gm.act(game, 'Ich weiche aus.').events.single.type,
        'rules.blocked');
    expect(gm.act(game, 'Ich trinke einen Heiltrank.').events.single.type,
        'rules.blocked');
    expect(gm.act(game, 'Schlaghagel').events.single.type,
        'class.flurryOfBlows');
  });

  test('Strike misses do not deal damage or consume the Attack action', () {
    final result = MonkFlurryRules.use(monk(), enemy(),
        DiceEngine(random: FixedRandom(false)));
    expect(result.strikes, hasLength(2));
    expect(result.strikes.every((s) => !s.hit && s.damage == 0), isTrue);
    expect(result.encounter.enemyHitPoints, 90);
    expect(result.encounter.actionUsed, isFalse);
  });
}
