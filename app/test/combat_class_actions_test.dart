import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/combat_class_actions.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class LowestRandom implements Random {
  @override int nextInt(int max) => 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

GameEngine gm() => GameEngine(dice: DiceEngine(random: LowestRandom()),
  clock: () => DateTime.utc(2026, 10, 16));

Campaign fight(GameEngine engine, String characterClass, int level, {
  String? weaponId,
  bool concentration = false,
}) {
  var c = engine.createDemo();
  c = c.copyWith(hero: c.hero.copyWith(
    className: characterClass, level: level,
    equippedWeaponId: weaponId == null ? '' : 'main',
    inventory: weaponId == null ? c.hero.inventory : [
      ...c.hero.inventory,
      InventoryItem(id: 'main', name: weaponId, catalogId: weaponId),
    ],
    concentratingOn: concentration ? 'Schutzzauber' : '',
  ));
  return engine.act(c, 'Ich gehe zum Waldschrein.').campaign;
}

Campaign miss(GameEngine engine, Campaign c) {
  final pending = engine.act(c, 'Ich greife den Wächter an.').campaign;
  expect(pending.pendingRoll?.type, 'attack');
  return engine.resolveRoll(pending, natural: 1).campaign;
}

void main() {
  test('Rage uses a bonus action, spends a Barbarian resource and breaks concentration', () {
    final engine = gm();
    var c = fight(engine, 'Barbar', 5, weaponId: 'weapon-longsword',
        concentration: true);
    final rage = engine.act(c, 'Kampfrausch');
    expect(rage.events.single.type, 'class.rage');
    c = rage.campaign;
    expect(c.hero.spentClassResources['rage'], 1);
    expect(c.hero.concentratingOn, isEmpty);
    expect(c.encounter!.bonusActionUsed, true);
    expect(c.encounter!.rageUntilRound, c.encounter!.round + 1);
    expect(CombatClassActions.rageDamageBonus(c.hero, c.encounter!), 2);
    expect(engine.act(c, 'Kampfrausch').events.single.type, 'rules.blocked');
    final saved = Campaign.fromJson(c.toJson());
    expect(saved.encounter!.rageUntilRound, c.encounter!.rageUntilRound);
    expect(saved.hero.spentClassResources['rage'], 1);
  });

  test('Rage expires without another attack and extends after a miss', () {
    final engine = gm();
    var c = fight(engine, 'Barbar', 1, weaponId: 'weapon-longsword');
    c = engine.act(c, 'Kampfrausch').campaign;
    final initialRound = c.encounter!.round;
    c = engine.act(c, 'Ich beende meinen Zug.').campaign;
    expect(c.encounter!.round, initialRound + 1);
    expect(CombatClassActions.rageActive(c.encounter!), true);
    c = engine.act(c, 'Ich beende meinen Zug.').campaign;
    expect(c.encounter!.rageUntilRound, 0);
    expect(CombatClassActions.rageActive(c.encounter!), false);
    final rageAgain = engine.act(c, 'Kampfrausch').campaign;
    expect(rageAgain.hero.spentClassResources['rage'], 2);
    final next = miss(engine, rageAgain);
    expect(CombatClassActions.rageActive(next.encounter!), true);
    expect(engine.act(next, 'Kampfrausch').events.single.type, 'rules.blocked');
  });

  test('Rage on a hit adds class damage, but not to unconfirmed ranged attacks', () {
    final engine = gm();
    var c = fight(engine, 'Barbar', 5, weaponId: 'weapon-longsword');
    c = engine.act(c, 'Kampfrausch').campaign;
    c = engine.act(c, 'Ich greife an.').campaign;
    final result = engine.resolveRoll(c, natural: 15);
    expect(result.events.single.payload['rageDamageBonus'], 2);
    final bow = c.hero.copyWith(equippedWeaponId: 'bow', inventory: [
      ...c.hero.inventory,
      const InventoryItem(id: 'bow', name: 'Kurzbogen', catalogId: 'weapon-shortbow'),
    ]);
    expect(CombatClassActions.rageDamageBonus(bow, c.encounter!), 0);
  });

  test('Heavy armor blocks Rage without spending uses', () {
    final engine = gm();
    var c = fight(engine, 'Barbar', 3, weaponId: 'weapon-longsword');
    c = c.copyWith(hero: c.hero.copyWith(
      equippedArmorId: 'plate', inventory: [
        ...c.hero.inventory,
        const InventoryItem(id: 'plate', name: 'Plattenrüstung',
          catalogId: 'armor-plate-armor'),
      ],
    ));
    final blocked = engine.act(c, 'Kampfrausch');
    expect(blocked.events.single.type, 'rules.blocked');
    expect(blocked.campaign.hero.spentClassResources, isEmpty);
  });

  test('Rogue Cunning Action Dash consumes bonus, not ordinary Attack action', () {
    final engine = gm();
    var c = fight(engine, 'Schurke', 2, weaponId: 'weapon-dagger');
    final initial = c.encounter!.movementRemaining;
    final added = c.hero.speed!;
    final dash = engine.act(c, 'Flinke Aktion: Sprinten');
    expect(dash.events.single.type, 'class.cunningDash');
    c = dash.campaign;
    expect(c.encounter!.movementRemaining, initial + added);
    expect(c.encounter!.bonusActionUsed, true);
    expect(c.encounter!.actionUsed, false);
    expect(engine.act(c, 'Flinke Aktion: Sprinten').events.single.type, 'rules.blocked');
    expect(Campaign.fromJson(c.toJson()).encounter!.bonusActionUsed, true);
  });

  test('Sneak Attack with externally confirmed advantage is once per turn', () {
    final engine = gm();
    var c = fight(engine, 'Schurke', 5, weaponId: 'weapon-dagger');
    final pending = engine.act(c, 'Ich greife an.').campaign.pendingRoll!;
    c = c.copyWith(pendingRoll: PendingRoll(
      id: pending.id, type: pending.type, modifier: pending.modifier,
      difficulty: pending.difficulty, targetId: pending.targetId,
      targetName: pending.targetName, advantage: true));
    final hit = engine.resolveRoll(c, natural: 19);
    expect(hit.events.single.payload['sneakAttackRoll'], isNotNull);
    expect((hit.events.single.payload['sneakAttackRoll'] as Map)['rolls'], hasLength(3));
    expect(hit.campaign.encounter!.sneakAttackUsedThisTurn, false);
    // A new turn resets the once-per-turn flag; a still-running attack action
    // would preserve it until the enemy turn completes.
    expect(Campaign.fromJson(hit.campaign.toJson()).encounter, isNotNull);
  });

  test('Confirmed bludgeoning/piercing/slashing is resisted, unknown and fire is not', () {
    final hero = HeroCharacter(id: 'b', name: 'Barbar', className: 'Barbar',
        level: 5, hitPoints: 12, maxHitPoints: 12);
    Encounter typed(String type) => Encounter(id: 'typed', enemyName: 'Gegner',
      enemyHitPoints: 20, enemyMaxHitPoints: 20,
      enemyDamageType: type, rageStartedRound: 1, rageUntilRound: 2);
    expect(CombatClassActions.effectiveIncomingDamage(
      typed('slashing'), hero, 7), 3);
    expect(CombatClassActions.effectiveIncomingDamage(
      typed('piercing'), hero, 5), 2);
    expect(CombatClassActions.effectiveIncomingDamage(
      typed('bludgeoning'), hero, 8), 4);
    expect(CombatClassActions.effectiveIncomingDamage(typed('fire'), hero, 7), 7);
    expect(CombatClassActions.effectiveIncomingDamage(typed(''), hero, 7), 7);
    expect(() => Encounter.fromJson({
      ...typed('').toJson(), 'enemyDamageType': 'unknown-kind',
    }), throwsFormatException);
    final persisted = Encounter.fromJson(typed('slashing').toJson());
    expect(persisted.copyWith(round: 2).enemyDamageType, 'slashing');
  });

  test('Rage can be extended by a bonus action without an attack', () {
    final engine = gm();
    var c = fight(engine, 'Barbar', 3, weaponId: 'weapon-longsword');
    c = engine.act(c, 'Kampfrausch').campaign;
    c = engine.act(c, 'Zug beenden').campaign;
    final round = c.encounter!.round;
    final extension = engine.act(c, 'Kampfrausch verlängern');
    expect(extension.events.single.type, 'class.rageExtended');
    c = extension.campaign;
    expect(c.encounter!.rageUntilRound, round + 1);
    expect(c.hero.spentClassResources['rage'], 1);
    expect(engine.act(c, 'Kampfrausch verlängern').events.single.type,
      'rules.blocked');
  });

  test('Old encounters load without new fields, malformed Rage is rejected', () {
    final e = Encounter(id: 'enemy', enemyName: 'Test',
        enemyHitPoints: 20, enemyMaxHitPoints: 20);
    expect(Encounter.fromJson(e.toJson()).rageUntilRound, 0);
    expect(Encounter.fromJson(e.toJson()).sneakAttackUsedThisTurn, false);
    final broken = {...e.toJson(), 'rageStartedRound': 1,
      'rageUntilRound': 200};
    expect(() => Encounter.fromJson(broken), throwsFormatException);
    expect(ClassResourceRules.sneakAttackDice(5), 3);
  });
}
