import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/fire_bolt_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) {
    final value = values[calls % values.length];
    calls++;
    return value % max;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _caster({
  int level = 5,
  String className = 'Magier',
  List<String> spells = const ['Feuerpfeil'],
}) => HeroCharacter(
  id: 'fire-caster',
  name: 'Arina',
  className: className,
  level: level,
  spells: spells,
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

const _encounter = Encounter(
  id: 'fire-enemy',
  enemyName: 'Wächter',
  enemyHitPoints: 50,
  enemyMaxHitPoints: 50,
  enemyArmorClass: 12,
);

FireBoltResult _cast(
  HeroCharacter hero,
  _SequenceRandom random, {
  String castingClass = 'Magier',
  int targetArmorClass = 12,
  CoverLevel cover = CoverLevel.none,
  bool visible = true,
  bool range = true,
  bool verbal = true,
  bool somatic = true,
  bool defense = true,
  bool shield = true,
  bool circumstances = true,
  bool advantage = false,
  bool disadvantage = false,
  bool prone = false,
  bool near = false,
}) => FireBoltRules.cast(
  hero,
  dice: DiceEngine(random: random),
  castingClass: castingClass,
  targetArmorClass: targetArmorClass,
  targetCover: cover,
  targetVisibleConfirmed: visible,
  targetWithinRangeConfirmed: range,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
  noFireResistanceOrImmunityConfirmed: defense,
  noUnresolvedShieldReactionConfirmed: shield,
  situationalAttackConditionsConfirmed: circumstances,
  advantage: advantage,
  disadvantage: disadvantage,
  targetProne: prone,
  targetWithinFiveFeet: near,
);

GameUpdate _engine(GameEngine engine, Campaign game) => engine.castFireBolt(
  game,
  castingClass: 'Magier',
  targetVisibleConfirmed: true,
  targetWithinRangeConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noFireResistanceOrImmunityConfirmed: true,
  noUnresolvedShieldReactionConfirmed: true,
  situationalAttackConditionsConfirmed: true,
);

void main() {
  test('Cantrip levels 1–20 yield 1/2/3/4d10', () {
    expect(FireBoltRules.diceCount(1), 1);
    expect(FireBoltRules.diceCount(4), 1);
    expect(FireBoltRules.diceCount(5), 2);
    expect(FireBoltRules.diceCount(10), 2);
    expect(FireBoltRules.diceCount(11), 3);
    expect(FireBoltRules.diceCount(16), 3);
    expect(FireBoltRules.diceCount(17), 4);
    expect(FireBoltRules.diceCount(20), 4);
    expect(() => FireBoltRules.diceCount(21), throwsRangeError);
  });

  test('Natural 20 always hits, doubles dice, never spends a slot', () {
    final random = _SequenceRandom([19, 0, 0, 0, 0]);
    final before = _caster(level: 5);
    final cast = _cast(before, random, targetArmorClass: 99);
    expect(cast.hit, isTrue);
    expect(cast.critical, isTrue);
    expect(cast.attackRoll.natural, 20);
    expect(cast.damageRoll!.rolls, [1, 1, 1, 1]);
    expect(cast.damageRoll!.expression, '4d10');
    expect(cast.damage, 4);
    expect(random.calls, 5);
    expect(cast.hero.spentSpellSlots, isEmpty);
    expect(before.spentSpellSlots, isEmpty);
  });

  test('Natural 1 always misses, no fire damage dice are rolled', () {
    final random = _SequenceRandom([0]);
    final result = _cast(_caster(level: 17), random, targetArmorClass: 1);
    expect(result.hit, isFalse);
    expect(result.damage, 0);
    expect(result.damageRoll, isNull);
    expect(random.calls, 1);
  });

  test('Confirmed cover and active Shield change hit outcome', () {
    // Attack roll 12 + Int 3 + proficiency 3 = 18.
    final random = _SequenceRandom([11, 4, 4]);
    final hit = _cast(_caster(), random, targetArmorClass: 18);
    expect(hit.hit, isTrue);
    expect(hit.damage, 10);
    final covered = _cast(
      _caster(),
      _SequenceRandom([11, 4]),
      targetArmorClass: 18,
      cover: CoverLevel.half,
    );
    expect(covered.hit, isFalse);
    expect(covered.effectiveArmorClass, 20);
    expect(
      () => _cast(_caster(), _SequenceRandom([19]), cover: CoverLevel.total),
      throwsFormatException,
    );
  });

  test('Unverified targets, components and defenses reject before random', () {
    final random = _SequenceRandom([19]);
    final hero = _caster();
    expect(() => _cast(hero, random, visible: false), throwsFormatException);
    expect(() => _cast(hero, random, range: false), throwsFormatException);
    expect(() => _cast(hero, random, verbal: false), throwsFormatException);
    expect(() => _cast(hero, random, somatic: false), throwsFormatException);
    expect(() => _cast(hero, random, defense: false), throwsFormatException);
    expect(() => _cast(hero, random, shield: false), throwsFormatException);
    expect(
      () => _cast(hero, random, circumstances: false),
      throwsFormatException,
    );
    expect(random.calls, 0);
  });

  test('Only Magier/Zauberer with known Fire Bolt and valid stats', () {
    final random = _SequenceRandom([19]);
    expect(
      () => _cast(_caster(spells: const []), random),
      throwsFormatException,
    );
    expect(
      () => _cast(
        _caster(className: 'Kleriker'),
        random,
        castingClass: 'Kleriker',
      ),
      throwsFormatException,
    );
    final sorcerer = _caster(
      className: 'Zauberer',
      spells: const ['Fire Bolt'],
    );
    final roll = _cast(sorcerer, random, castingClass: 'Zauberer');
    expect(roll.spellcastingAbility, 'charisma');
    expect(roll.hero.className, 'Zauberer');
    expect(random.calls, greaterThan(0));
  });

  test('Ranged attacks on a prone faraway target suffer disadvantage', () {
    // Attack 18 versus 2 due to prone farther than 5ft.
    final random = _SequenceRandom([17, 1]);
    final roll = _cast(_caster(), random, prone: true, targetArmorClass: 14);
    expect(roll.attackRoll.rolls, [18, 2]);
    expect(roll.attackRoll.natural, 2);
    expect(roll.hit, isFalse);
    expect(random.calls, 2);
    final near = _cast(
      _caster(),
      _SequenceRandom([17]),
      prone: true,
      near: true,
      targetArmorClass: 14,
    );
    expect(near.hit, isTrue);
  });

  test('GameEngine stores attack and damage atomically without slot use', () {
    final random = _SequenceRandom([11, 4, 4]);
    final engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 10, 20),
    );
    final demo = engine.createDemo();
    final game = demo.copyWith(hero: _caster(), encounter: _encounter);
    final result = _engine(engine, game);
    expect(result.events.single.type, 'spell.fireBolt');
    expect(result.campaign.encounter!.enemyHitPoints, 40);
    expect(result.campaign.encounter!.actionUsed, isTrue);
    expect(result.campaign.encounter!.spellSlotExpendedThisTurn, isFalse);
    expect(result.campaign.hero.spentSpellSlots, isEmpty);
    expect(result.events.single.payload['attackRoll']['natural'], 12);
    expect(result.events.single.payload['damageRoll']['total'], 10);
    expect(result.events.single.payload['damageType'], 'fire');
    expect(result.campaign.revision, game.revision + 1);
    expect(
      Campaign.fromJson(result.campaign.toJson()).toJson(),
      result.campaign.toJson(),
    );
    expect(() => _engine(engine, result.campaign), throwsFormatException);
  });

  test('Combat validates turn and target before consuming RNG', () {
    final random = _SequenceRandom([19]);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final game = engine.createDemo().copyWith(
      hero: _caster(),
      encounter: _encounter,
    );
    for (final enemy in [
      _encounter.copyWith(actionUsed: true),
      _encounter.copyWith(activeParticipant: 'enemy'),
      _encounter.copyWith(enemyCover: CoverLevel.total),
      _encounter.copyWith(surgeReserved: true),
    ]) {
      expect(
        () => _engine(engine, game.copyWith(encounter: enemy)),
        throwsFormatException,
      );
    }
    expect(random.calls, 0);
  });

  test('Existing Shield +5 AC is respected; nat20 still hits', () {
    final engine = GameEngine(
      dice: DiceEngine(random: _SequenceRandom([11, 4])),
    );
    final game = engine.createDemo().copyWith(
      hero: _caster(),
      encounter: _encounter.copyWith(
        enemyShieldActive: true,
        enemyArmorClass: 15,
      ),
    );
    final result = _engine(engine, game);
    expect(result.events.single.payload['effectiveArmorClass'], 20);
    expect(result.events.single.payload['hit'], false);
    expect(result.campaign.encounter!.enemyHitPoints, 50);
  });
}
