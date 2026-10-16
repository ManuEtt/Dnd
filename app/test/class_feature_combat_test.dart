import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_feature_resources.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class LowRandom implements Random {
  @override int nextInt(int max) => 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

GameEngine gm() => GameEngine(dice: DiceEngine(random: LowRandom()),
    clock: () => DateTime.utc(2026, 10, 16));

Campaign encounter(GameEngine engine, int level) {
  var c = engine.createDemo();
  c = c.copyWith(hero: c.hero.copyWith(className: 'Kämpfer', level: level,
      hitPoints: 10, maxHitPoints: 22));
  return engine.act(c, 'Ich gehe zum Waldschrein.').campaign;
}

Campaign miss(GameEngine engine, Campaign c) {
  final requested = engine.act(c, 'Ich greife den Wächter an.').campaign;
  expect(requested.pendingRoll?.type, 'attack');
  return engine.resolveRoll(requested, natural: 1).campaign;
}

void main() {
  test('Second Wind uses a bonus action once per combat round', () {
    final engine = gm();
    var c = encounter(engine, 5);
    final first = engine.act(c, 'Second Wind');
    expect(first.events.single.type, 'class.secondWind');
    c = first.campaign;
    expect(c.encounter!.bonusActionUsed, true);
    expect(c.encounter!.actionUsed, false);
    expect(c.hero.hitPoints, 16); // 1 (d10) + 5 Fighter levels
    expect(c.hero.spentSecondWind, 1);
    final refused = engine.act(c, 'zweite Luft');
    expect(refused.events.single.type, 'rules.blocked');
    expect(refused.campaign.hero.spentSecondWind, 1);
    c = miss(engine, c);
    c = miss(engine, c);
    expect(c.encounter!.bonusActionUsed, false);
    final again = engine.act(c, 'Zweite Luft');
    expect(again.events.single.type, 'class.secondWind');
    expect(again.campaign.hero.spentSecondWind, 2);
  });

  test('Action Surge reserves a second Attack action, no extra foe turn', () {
    final engine = gm();
    var c = encounter(engine, 5);
    final first = engine.act(c, 'Aktionsschub');
    expect(first.events.single.type, 'class.actionSurge');
    c = first.campaign;
    expect(c.encounter!.surgeReserved, true);
    expect(c.hero.spentActionSurge, 1);
    final duplicate = engine.act(c, 'Action Surge');
    expect(duplicate.events.single.type, 'rules.blocked');
    c = Campaign.fromJson(c.toJson());
    c = miss(engine, c);
    expect(c.encounter!.attacksRemaining, 1);
    c = miss(engine, c);
    expect(c.encounter!.round, 1); // no enemy turn yet
    expect(c.encounter!.surgeReserved, false);
    expect(c.encounter!.surgeUsedThisTurn, true);
    expect(c.encounter!.actionUsed, false);
    c = miss(engine, c);
    expect(c.encounter!.attacksRemaining, 1);
    c = miss(engine, c);
    expect(c.encounter!.round, 2); // exactly one enemy turn
    expect(c.encounter!.surgeUsedThisTurn, false);
    expect(ClassFeatureResources.remainingActionSurge(c.hero), 0);
  });

  test('Action Surge cannot be activated twice in one turn at Fighter 17', () {
    final engine = gm();
    var c = encounter(engine, 17);
    c = engine.act(c, 'Action Surge').campaign;
    expect(c.hero.spentActionSurge, 1);
    expect(engine.act(c, 'Action Surge').events.single.type, 'rules.blocked');
    expect(c.encounter!.surgeReserved, true);
    final altered = c.toJson();
    final e = Map<String, dynamic>.from(altered['encounter'] as Map);
    e['surgeReserved'] = true;
    e['surgeUsedThisTurn'] = false;
    altered['encounter'] = e;
    expect(() => Campaign.fromJson(altered), throwsFormatException);
  });

  test('Full-HP short rest regenerates class resources without hit die', () {
    final engine = gm();
    var c = engine.createDemo();
    final hp = c.hero.maxHitPoints!;
    c = c.copyWith(hero: c.hero.copyWith(
      className: 'Kämpfer', level: 5, hitPoints: hp,
      spentSecondWind: 2, spentActionSurge: 1));
    final rest = engine.act(c, 'Ich mache eine kurze Rast.');
    expect(rest.events.single.type, 'character.shortRest');
    expect(rest.campaign.hero.spentSecondWind, 1);
    expect(rest.campaign.hero.spentActionSurge, 0);
    expect(rest.campaign.hero.hitPoints, hp);
  });
}
