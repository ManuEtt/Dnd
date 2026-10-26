import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_eldritch_blast_rules.dart';

class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) {
    final value = values[calls++];
    if (value < 0 || value >= max) throw RangeError.value(value);
    return value;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _warlock({
  int level = 5,
  String className = 'Hexenmeister',
  String secondary = '',
  int secondaryLevel = 0,
  List<String> spells = const ['Eldritch Blast'],
}) => HeroCharacter(
  id: 'eldritch-blast-caster',
  name: 'Strahlenwirker',
  className: className,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  spells: spells,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 10,
    'charisma': 18,
  },
  hitPoints: 20,
  maxHitPoints: 20,
);

SrdEldritchBlastTarget _target(
  String id, {
  int distance = 60,
  int armorClass = 14,
  CoverLevel cover = CoverLevel.none,
  bool opposite = true,
  bool pathConfirmed = true,
  bool coverConfirmed = true,
  bool kindConfirmed = true,
  bool circumstancesConfirmed = true,
  bool advantage = false,
  bool disadvantage = false,
}) => SrdEldritchBlastTarget(
  targetId: id,
  distanceFeet: distance,
  baseArmorClass: armorClass,
  cover: cover,
  creatureOrObjectConfirmed: kindConfirmed,
  clearPathConfirmed: pathConfirmed,
  coverCircumstancesConfirmed: coverConfirmed,
  attackCircumstancesConfirmed: circumstancesConfirmed,
  sourceOppositeCover: opposite,
  advantage: advantage,
  disadvantage: disadvantage,
);

SrdEldritchBlastResolution _resolve({
  HeroCharacter? caster,
  List<SrdEldritchBlastTarget>? beams,
  _SequenceRandom? random,
  int modifier = 6,
  bool prepared = true,
  bool action = true,
  bool verbal = true,
  bool somatic = true,
  bool unmodelledClear = true,
}) {
  final hero = caster ?? _warlock();
  return SrdEldritchBlastRules.resolve(
    caster: hero,
    dice: DiceEngine(random: random ?? _SequenceRandom([14, 5, 2, 3])),
    beams: beams ?? [_target('a'), _target('b')],
    confirmedSpellAttackModifier: modifier,
    warlockSpellPreparationConfirmed: prepared,
    actionAvailableConfirmed: action,
    verbalComponentConfirmed: verbal,
    somaticComponentConfirmed: somatic,
    noUnmodelledAttackOrDamageModifiersConfirmed: unmodelledClear,
  );
}

void main() {
  test('beam count uses CHARACTER level 1/5/11/17, not class level', () {
    const checkpoints = <int, int>{
      1: 1,
      4: 1,
      5: 2,
      10: 2,
      11: 3,
      16: 3,
      17: 4,
      20: 4,
    };
    for (final entry in checkpoints.entries) {
      expect(SrdEldritchBlastRules.beamCount(entry.key), entry.value);
    }
    for (final invalid in [0, 21]) {
      expect(() => SrdEldritchBlastRules.beamCount(invalid), throwsRangeError);
    }
    final hero = _warlock(
      level: 11,
      className: 'Magier',
      secondary: 'Hexenmeister',
      secondaryLevel: 2,
    );
    final result = _resolve(
      caster: hero,
      beams: [_target('a'), _target('b'), _target('c')],
      random: _SequenceRandom([14, 0, 14, 0, 14, 0]),
    );
    expect(result.beams, hasLength(3));
    expect(result.characterLevel, 11);
  });

  test(
    'separate attacks can hit different targets with independent damage',
    () {
      final hero = _warlock(level: 5);
      final before = jsonEncode(hero.toJson());
      final result = _resolve(
        caster: hero,
        beams: [_target('goblin'), _target('orc')],
        random: _SequenceRandom([9, 3, 2]),
      );
      expect(result.beams.map((e) => e.targetId), ['goblin', 'orc']);
      expect(result.beams[0].attack.natural, 10);
      expect(result.beams[0].hit, isTrue);
      expect(result.beams[0].rawForceDamage, 4);
      expect(result.beams[1].attack.natural, 3);
      expect(result.beams[1].hit, isFalse);
      expect(result.beams[1].forceDamageRoll, isNull);
      expect(result.totalRawForceDamage, 4);
      expect(jsonEncode(hero.toJson()), before);
    },
  );

  test('all beams may use SAME target, with a distinct attack for each', () {
    final result = _resolve(
      beams: [_target('dragon'), _target('dragon')],
      random: _SequenceRandom([12, 0, 8, 5]),
    );
    expect(result.beams.map((b) => b.targetId), ['dragon', 'dragon']);
    expect(result.beams.map((b) => b.attack.natural), [13, 9]);
    expect(result.beams.map((b) => b.rawForceDamage), [1, 6]);
    expect(result.totalRawForceDamage, 7);
  });

  test('natural 1 misses, 20 crits with TWO damage dice for that beam', () {
    final rng = _SequenceRandom([0, 19, 3, 8]);
    final result = _resolve(
      beams: [_target('a', armorClass: 1), _target('b', armorClass: 100)],
      random: rng,
      modifier: -20,
    );
    expect(result.beams.first.hit, isFalse);
    expect(result.beams.first.critical, isFalse);
    expect(result.beams.first.forceDamageRoll, isNull);
    expect(result.beams.last.hit, isTrue);
    expect(result.beams.last.critical, isTrue);
    expect(result.beams.last.forceDamageRoll!.rolls, [4, 9]);
    expect(result.beams.last.rawForceDamage, 13);
    expect(rng.calls, 4);
  });

  test('half/three-quarter cover apply to each beam when opposite', () {
    final result = _resolve(
      beams: [
        _target('half', cover: CoverLevel.half),
        _target('other', cover: CoverLevel.threeQuarters, opposite: false),
      ],
      random: _SequenceRandom([9, 4, 9, 4]),
    );
    expect(result.beams.first.effectiveArmorClass, 16);
    expect(result.beams.last.effectiveArmorClass, 14);
    expect(result.beams.first.hit, isTrue);
    expect(result.beams.last.hit, isTrue);
  });

  test('full cover on LATER beam blocks all rolls and damage upfront', () {
    final rng = _SequenceRandom([19, 9]);
    expect(
      () => _resolve(
        beams: [
          _target('clear'),
          _target('wall', cover: CoverLevel.total),
        ],
        random: rng,
      ),
      throwsFormatException,
    );
    expect(rng.calls, 0);
  });

  test('advantage, disadvantage and cancellation are per beam', () {
    final result = _resolve(
      beams: [
        _target('first', advantage: true),
        _target('second', advantage: true, disadvantage: true),
      ],
      random: _SequenceRandom([2, 18, 0, 9, 1]),
    );
    expect(result.beams.first.attack.rolls, [3, 19]);
    expect(result.beams.first.attack.natural, 19);
    expect(result.beams.first.rawForceDamage, 1);
    expect(result.beams.last.attack.rolls, [10]);
    expect(result.beams.last.attack.natural, 10);
    expect(result.beams.last.rawForceDamage, 2);
  });

  test(
    'wrong beam count, target kind/path/range fail without consuming RNG',
    () {
      final bad = [
        [_target('a')],
        [_target('a'), _target('b'), _target('c')],
        [_target('a'), _target('b', distance: 121)],
        [_target('a'), _target('b', distance: -1)],
      [_target('a'), _target('b', armorClass: -1)],
      [_target('a'), _target('b', armorClass: 101)],
        [_target('a'), _target('b', pathConfirmed: false)],
        [_target('a'), _target('b', kindConfirmed: false)],
        [_target('a'), _target('b', coverConfirmed: false)],
        [_target('a'), _target('b', circumstancesConfirmed: false)],
        [_target('a'), _target('')],
        [_target('a'), _target(' b')],
      ];
      for (final beams in bad) {
        final rng = _SequenceRandom([19, 0]);
        expect(
          () => _resolve(beams: beams, random: rng),
          throwsFormatException,
        );
        expect(rng.calls, 0);
      }
    },
  );

  test('spell eligibility, turn action and components fail closed', () {
    for (final hero in [
      _warlock(className: 'Magier'),
      _warlock(spells: const []),
      _warlock(
        className: 'Hexenmeister',
        level: 5,
        secondary: 'Magier',
        secondaryLevel: 5,
      ),
      _warlock(level: 0),
    ]) {
      expect(() => _resolve(caster: hero), throwsA(isA<Object>()));
    }
    for (final value in [false]) {
      expect(() => _resolve(prepared: value), throwsFormatException);
      expect(() => _resolve(action: value), throwsFormatException);
      expect(() => _resolve(verbal: value), throwsFormatException);
      expect(() => _resolve(somatic: value), throwsFormatException);
      expect(() => _resolve(unmodelledClear: value), throwsFormatException);
    }
    for (final modifier in [-31, 31]) {
      expect(() => _resolve(modifier: modifier), throwsRangeError);
    }
  });

  test('no resources, HP or state are changed; output is read-only', () {
    final hero = _warlock().copyWith(spentPactSlots: 1, concentratingOn: 'Hex');
    final snapshot = jsonEncode(hero.toJson());
    final result = _resolve(
      caster: hero,
      beams: [_target('a'), _target('b')],
      random: _SequenceRandom([9, 5, 9, 7]),
    );
    expect(result.totalRawForceDamage, 14);
    expect(jsonEncode(hero.toJson()), snapshot);
    expect(hero.spentPactSlots, 1);
    expect(hero.concentratingOn, 'Hex');
    expect(() => result.beams.add(result.beams.first), throwsUnsupportedError);
  });
}
