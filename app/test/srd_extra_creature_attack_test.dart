import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_extra_creature_attack_rules.dart';

class _RandomRolls implements Random {
  _RandomRolls(this.values);
  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) {
    final value = values[calls % values.length] % max;
    calls++;
    return value;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _hero() => HeroCharacter(
  id: 'hero',
  name: 'Aria',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d4',
);

Campaign _game(GameEngine engine) => engine.createDemo().copyWith(
  hero: _hero(),
  encounter: const Encounter(
    id: 'foe',
    enemyName: 'Main foe',
    enemyHitPoints: 30,
    enemyMaxHitPoints: 30,
    heroInitiative: 15,
    enemyInitiative: 12,
  ),
  trackedAreaCreatures: const [
    TrackedAreaCreature(
      id: 'orc',
      name: 'Orc',
      hitPoints: 10,
      maxHitPoints: 10,
      initiativeTotal: 20,
      initiativeController: 'gm',
    ),
    TrackedAreaCreature(
      id: 'goblin',
      name: 'Goblin',
      hitPoints: 12,
      maxHitPoints: 12,
      initiativeTotal: 10,
      initiativeController: 'gm',
    ),
  ],
);

Campaign _queue(GameEngine engine) => engine
    .establishManualTurnQueue(
      _game(engine),
      orderedActorIds: const ['orc', 'hero', 'foe', 'goblin'],
      baseInitiativeConfirmed: true,
      tiedOrderConfirmed: false,
    )
    .campaign;

ConfirmedExtraCreatureAttack _input({
  int bonus = 4,
  int ac = 12,
  String damage = '1d6+2',
  CoverLevel cover = CoverLevel.none,
  bool opposite = false,
  bool verified = true,
  bool advantage = false,
  bool disadvantage = false,
}) => ConfirmedExtraCreatureAttack(
  attackBonus: bonus,
  weaponDamage: damage,
  damageType: DamageType.slashing,
  targetArmorClass: ac,
  targetCover: cover,
  coverOppositeAttacker: opposite,
  targetInReachConfirmed: verified,
  attackerCanActConfirmed: verified,
  targetCanBeAttackedConfirmed: verified,
  noUnmodelledAttackModifiersConfirmed: verified,
  noUnmodelledDamageAdjustmentsConfirmed: verified,
  noTargetReactionConfirmed: verified,
  noAdditionalAttackEffectsConfirmed: verified,
  advantage: advantage,
  disadvantage: disadvantage,
);

void main() {
  test('Legacy manual queue lacks actionUsed; false roundtrips exactly', () {
    final q = _queue(GameEngine());
    final j = q.toJson();
    final raw = Map<String, dynamic>.from(j['manualTurnQueue'] as Map);
    expect(raw.containsKey('actionUsed'), false);
    final restored = Campaign.fromJson(j);
    expect(restored.toJson(), j);
    expect(restored.manualTurnQueue!.actionUsed, false);
  });

  test(
    'Successful basic attack spends one separate action and persists HP',
    () {
      final rng = _RandomRolls([14, 2]);
      final engine = GameEngine(
        dice: DiceEngine(random: rng),
        clock: () => DateTime.utc(2026, 10, 21),
      );
      final before = _queue(engine);
      final result = engine.manualExtraCreatureAttack(
        before,
        attackerId: 'orc',
        targetId: 'goblin',
        attack: _input(),
      );
      expect(result.events.single.type, 'combat.manualExtraCreatureAttack');
      expect(result.events.single.payload['attackRoll']['natural'], 15);
      expect(result.events.single.payload['damage'], 5);
      expect(result.events.single.payload['critical'], false);
      expect(result.campaign.trackedAreaCreatures[1].hitPoints, 7);
      expect(result.campaign.trackedAreaCreatures[0].hitPoints, 10);
      expect(result.campaign.manualTurnQueue!.actionUsed, true);
      expect(result.campaign.encounter!.enemyHitPoints, 30);
      expect(result.campaign.encounter!.activeParticipant, 'hero');
      expect(result.campaign.hero.hitPoints, 20);
      expect(rng.calls, 2);
      expect(result.campaign.revision, before.revision + 1);
      expect(
        Campaign.fromJson(result.campaign.toJson()).toJson(),
        result.campaign.toJson(),
      );
      expect(
        () => engine.manualExtraCreatureAttack(
          result.campaign,
          attackerId: 'orc',
          targetId: 'goblin',
          attack: _input(),
        ),
        throwsFormatException,
      );
      expect(rng.calls, 2);
      final next = engine.advanceManualTurnQueue(result.campaign);
      expect(next.campaign.manualTurnQueue!.activeActorId, 'hero');
      expect(next.campaign.manualTurnQueue!.actionUsed, false);
      expect(next.campaign.trackedAreaCreatures[1].hitPoints, 7);
    },
  );

  test('Natural one always misses and never consumes damage dice', () {
    final rng = _RandomRolls([0]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final result = engine.manualExtraCreatureAttack(
      _queue(engine),
      attackerId: 'orc',
      targetId: 'goblin',
      attack: _input(bonus: 30),
    );
    expect(result.events.single.payload['hit'], false);
    expect(result.events.single.payload['damageRoll'], isNull);
    expect(result.campaign.trackedAreaCreatures[1].hitPoints, 12);
    expect(result.campaign.manualTurnQueue!.actionUsed, true);
    expect(rng.calls, 1);
  });

  test('Critical natural 20 doubles only damage dice, not static bonus', () {
    final rng = _RandomRolls([19, 3, 4]);
    final outcome = SrdExtraCreatureAttackRules.resolve(
      DiceEngine(random: rng),
      _input(ac: 95, damage: '1d6+2'),
    );
    expect(outcome.hit, true);
    expect(outcome.critical, true);
    expect(outcome.damageRoll!.rolls, [4]);
    expect(outcome.criticalExtraRoll!.rolls, [5]);
    expect(outcome.damage, 11);
    expect(rng.calls, 3);
  });

  test('Half cover adds AC only when opposite from attacker', () {
    final guarded = SrdExtraCreatureAttackRules.resolve(
      DiceEngine(random: _RandomRolls([9])),
      _input(bonus: 2, ac: 12, cover: CoverLevel.half, opposite: true),
    );
    expect(guarded.effectiveArmorClass, 14);
    expect(guarded.attackRoll.total, 12);
    expect(guarded.hit, false);
    final uncovered = SrdExtraCreatureAttackRules.resolve(
      DiceEngine(random: _RandomRolls([9, 0])),
      _input(bonus: 2, ac: 12, cover: CoverLevel.half, opposite: false),
    );
    expect(uncovered.effectiveArmorClass, 12);
    expect(uncovered.hit, true);
  });

  test('Advantage & disadvantage cancel without third attack die', () {
    final rng = _RandomRolls([1, 17, 0]);
    final result = SrdExtraCreatureAttackRules.resolve(
      DiceEngine(random: rng),
      _input(advantage: true, disadvantage: true),
    );
    expect(result.attackRoll.rolls, [2]);
    expect(result.hit, false);
    expect(rng.calls, 1);
  });

  test('Incomplete stats/confirmation and total cover reject before dice', () {
    final rng = _RandomRolls([19]);
    for (final bad in [
      _input(verified: false),
      _input(bonus: 31),
      _input(ac: 0),
      _input(damage: '11d6+2'),
      _input(damage: '2d20+1'),
      _input(cover: CoverLevel.total),
      _input(ac: 95, cover: CoverLevel.threeQuarters, opposite: true),
    ]) {
      expect(
        () => SrdExtraCreatureAttackRules.resolve(DiceEngine(random: rng), bad),
        throwsFormatException,
      );
    }
    expect(rng.calls, 0);
  });

  test(
    'Manual marker refuses hero, main foe or stale attacker before dice',
    () {
      final rng = _RandomRolls([19]);
      final engine = GameEngine(dice: DiceEngine(random: rng));
      final game = _queue(engine);
      for (final target in ['hero', 'foe', 'orc', 'ghost']) {
        expect(
          () => engine.manualExtraCreatureAttack(
            game,
            attackerId: 'orc',
            targetId: target,
            attack: _input(),
          ),
          throwsFormatException,
        );
      }
      expect(
        () => engine.manualExtraCreatureAttack(
          game,
          attackerId: 'goblin',
          targetId: 'orc',
          attack: _input(),
        ),
        throwsFormatException,
      );
      final moved = engine.advanceManualTurnQueue(game);
      expect(
        () => engine.manualExtraCreatureAttack(
          moved.campaign,
          attackerId: 'orc',
          targetId: 'goblin',
          attack: _input(),
        ),
        throwsFormatException,
      );
      expect(rng.calls, 0);
    },
  );

  test('Counterfeit actionUsed storage value is rejected', () {
    final campaign = _queue(GameEngine());
    final data = campaign.toJson();
    final raw = Map<String, dynamic>.from(data['manualTurnQueue'] as Map);
    raw['actionUsed'] = 2;
    data['manualTurnQueue'] = raw;
    expect(() => Campaign.fromJson(data), throwsFormatException);
  });
}
