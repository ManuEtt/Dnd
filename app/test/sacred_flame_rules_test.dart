import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/sacred_flame_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_saving_throw_rules.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.values);
  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) {
    final choice = values[calls % values.length] % max;
    calls++;
    return choice;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({
  int level = 5,
  String className = 'Kleriker',
  List<String> spells = const ['Heilige Flamme'],
}) => HeroCharacter(
  id: 'radiant-caster',
  name: 'Arina',
  className: className,
  level: level,
  spells: spells,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 16,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d4',
);

const _encounter = Encounter(
  id: 'radiant-enemy',
  enemyName: 'Wächter',
  enemyHitPoints: 50,
  enemyMaxHitPoints: 50,
  enemyArmorClass: 14,
);

SacredFlameResult _cast(
  HeroCharacter hero,
  _FixedRandom random, {
  int bonus = 0,
  CoverLevel cover = CoverLevel.none,
  bool visible = true,
  bool range = true,
  bool verbal = true,
  bool somatic = true,
  bool radiant = true,
  bool dc = true,
  bool save = true,
  bool advantage = false,
  bool disadvantage = false,
}) => SacredFlameRules.cast(
  hero,
  dice: DiceEngine(random: random),
  confirmedTargetDexteritySaveModifier: bonus,
  targetCover: cover,
  targetVisibleConfirmed: visible,
  targetWithinRangeConfirmed: range,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
  noRadiantDamageAdjustmentConfirmed: radiant,
  noUnmodelledDcModifiersConfirmed: dc,
  saveCircumstancesConfirmed: save,
  saveAdvantage: advantage,
  saveDisadvantage: disadvantage,
);

GameUpdate _gameCast(GameEngine engine, Campaign campaign, {int bonus = 0}) =>
    engine.castSacredFlame(
      campaign,
      confirmedTargetDexteritySaveModifier: bonus,
      targetVisibleConfirmed: true,
      targetWithinRangeConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      noRadiantDamageAdjustmentConfirmed: true,
      noUnmodelledDcModifiersConfirmed: true,
      saveCircumstancesConfirmed: true,
    );

void main() {
  test('SRD cantrip scales 1/2/3/4d8 by total character level', () {
    expect(SacredFlameRules.diceCount(1), 1);
    expect(SacredFlameRules.diceCount(4), 1);
    expect(SacredFlameRules.diceCount(5), 2);
    expect(SacredFlameRules.diceCount(10), 2);
    expect(SacredFlameRules.diceCount(11), 3);
    expect(SacredFlameRules.diceCount(16), 3);
    expect(SacredFlameRules.diceCount(17), 4);
    expect(SacredFlameRules.diceCount(20), 4);
    expect(() => SacredFlameRules.diceCount(0), throwsRangeError);
  });

  test('Spell save DC 8 + proficiency + Wisdom; no guessed modifiers', () {
    final hero = _hero();
    expect(
      SrdSpellSavingThrowRules.spellSaveDc(
        hero,
        spellcastingAbility: 'wisdom',
        noUnmodelledDcModifiersConfirmed: true,
      ),
      14,
    );
    expect(
      () => SrdSpellSavingThrowRules.spellSaveDc(
        hero,
        spellcastingAbility: 'wisdom',
        noUnmodelledDcModifiersConfirmed: false,
      ),
      throwsFormatException,
    );
  });

  test('Natural 20 does not automatically succeed on a saving throw', () {
    final random = _FixedRandom([19, 0, 0]);
    final cast = _cast(_hero(), random, bonus: -10);
    expect(cast.savingThrow.roll.natural, 20);
    expect(cast.savingThrow.roll.total, 10);
    expect(cast.savingThrow.succeeded, isFalse);
    expect(cast.damageRoll!.rolls, [1, 1]);
    expect(cast.damage, 2);
    expect(random.calls, 3);
  });

  test('Natural 1 may succeed with large confirmed saving throw bonus', () {
    final random = _FixedRandom([0]);
    final cast = _cast(_hero(), random, bonus: 20);
    expect(cast.savingThrow.roll.natural, 1);
    expect(cast.savingThrow.succeeded, isTrue);
    expect(cast.damage, 0);
    expect(cast.damageRoll, isNull);
    expect(random.calls, 1);
  });

  test('Half and three-quarter cover give no save bonus', () {
    for (final cover in [CoverLevel.half, CoverLevel.threeQuarters]) {
      final cast = _cast(_hero(), _FixedRandom([0, 2, 3]), cover: cover);
      expect(cast.savingThrow.modifier, 0);
      expect(cast.savingThrow.dc, 14);
      expect(cast.savingThrow.roll.total, 1);
      expect(cast.damage, 7);
    }
    final rng = _FixedRandom([19]);
    expect(
      () => _cast(_hero(), rng, cover: CoverLevel.total),
      throwsFormatException,
    );
    expect(rng.calls, 0);
  });

  test('Advantage and disadvantage roll exactly two d20 and cancel', () {
    final advantage = _cast(
      _hero(),
      _FixedRandom([1, 17]),
      advantage: true,
      bonus: 0,
    );
    expect(advantage.savingThrow.roll.rolls, [2, 18]);
    expect(advantage.savingThrow.succeeded, isTrue);

    final disadvantage = _cast(
      _hero(),
      _FixedRandom([1, 17, 2, 3]),
      disadvantage: true,
    );
    expect(disadvantage.savingThrow.roll.rolls, [2, 18]);
    expect(disadvantage.savingThrow.succeeded, isFalse);

    final both = _cast(
      _hero(),
      _FixedRandom([17]),
      advantage: true,
      disadvantage: true,
    );
    expect(both.savingThrow.roll.rolls, [18]);
    expect(both.savingThrow.succeeded, isTrue);
  });

  test('Invalid preparation, classes, confirmations never roll dice', () {
    final rng = _FixedRandom([19]);
    expect(() => _cast(_hero(spells: const []), rng), throwsFormatException);
    expect(() => _cast(_hero(className: 'Magier'), rng), throwsFormatException);
    for (final flags in [
      {'visible': false},
      {'range': false},
      {'verbal': false},
      {'somatic': false},
      {'radiant': false},
      {'dc': false},
      {'save': false},
    ]) {
      expect(
        () => _cast(
          _hero(),
          rng,
          visible: flags['visible'] ?? true,
          range: flags['range'] ?? true,
          verbal: flags['verbal'] ?? true,
          somatic: flags['somatic'] ?? true,
          radiant: flags['radiant'] ?? true,
          dc: flags['dc'] ?? true,
          save: flags['save'] ?? true,
        ),
        throwsFormatException,
      );
    }
    expect(() => _cast(_hero(), rng, bonus: 31), throwsFormatException);
    expect(rng.calls, 0);
  });

  test('Multiclass Cleric can cast; save and slots stay independent', () {
    final hero = _hero(
      level: 6,
      className: 'Magier',
    ).copyWith(secondaryClassName: 'Kleriker', secondaryClassLevel: 1);
    final cast = _cast(hero, _FixedRandom([0, 2, 3]));
    expect(cast.damage, 7);
    expect(cast.hero.className, 'Magier');
    expect(cast.hero.secondaryClassName, 'Kleriker');
    expect(cast.hero.spentSpellSlots, isEmpty);
    expect(cast.hero.spentPactSlots, 0);
  });

  test('Wizard 5 / Cleric 1 uses Wisdom and total-level proficiency', () {
    final base = _hero(level: 6, className: 'Wizard');
    final hero = HeroCharacter.fromJson(
      base
          .copyWith(
            secondaryClassName: 'Cleric',
            secondaryClassLevel: 1,
            abilities: {...base.abilities, 'intelligence': 20, 'wisdom': 12},
          )
          .toJson(),
    );
    final before = hero.toJson();
    final random = _FixedRandom([11]);

    final cast = _cast(hero, random);

    // 8 + Wisdom 1 + total-level proficiency 3.
    expect(cast.savingThrow.dc, 12);
    expect(cast.savingThrow.succeeded, isTrue);
    expect(cast.damageRoll, isNull);
    expect(random.calls, 1);
    expect(cast.hero.toJson(), before);
    expect(hero.toJson(), before);
  });

  for (final classes in {
    'alias duplicate': ['Cleric', 'Kleriker'],
    'unknown primary': ['Unbekannt', 'Cleric'],
    'unknown secondary': ['Cleric', 'Unbekannt'],
  }.entries) {
    test('Imported ${classes.key} rejects Sacred Flame before RNG', () {
      // Historical spellings remain importable; casting must still validate
      // the complete class combination before authorizing an effect.
      final hero = HeroCharacter.fromJson(
        _hero(level: 6, className: classes.value.first)
            .copyWith(
              secondaryClassName: classes.value.last,
              secondaryClassLevel: 1,
            )
            .toJson(),
      );
      final before = hero.toJson();
      final random = _FixedRandom([0]);

      expect(() => _cast(hero, random), throwsFormatException);
      expect(random.calls, 0);
      expect(hero.toJson(), before);
    });
  }

  for (final entry in {
    'secondary levels without a class': _hero(
      level: 6,
    ).copyWith(secondaryClassLevel: 1),
    'secondary class without levels': _hero(
      level: 6,
    ).copyWith(secondaryClassName: 'Wizard'),
    'no primary levels': _hero(
      level: 6,
      className: 'Wizard',
    ).copyWith(secondaryClassName: 'Cleric', secondaryClassLevel: 6),
    'negative secondary levels': _hero(
      level: 6,
    ).copyWith(secondaryClassName: 'Wizard', secondaryClassLevel: -1),
  }.entries) {
    test('Contradictory ${entry.key} reject Sacred Flame before RNG', () {
      final hero = entry.value;
      final before = hero.toJson();
      final random = _FixedRandom([0]);

      expect(() => _cast(hero, random), throwsFormatException);
      expect(random.calls, 0);
      expect(hero.toJson(), before);
    });
  }

  test('Enemy save rejects unconfirmed modifiers before randomness', () {
    final rng = _FixedRandom([19]);
    expect(
      () => SrdSpellSavingThrowRules.resolve(
        dice: DiceEngine(random: rng),
        dc: 14,
        confirmedTargetModifier: 2,
        saveCircumstancesConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellSavingThrowRules.resolve(
        dice: DiceEngine(random: rng),
        dc: 14,
        confirmedTargetModifier: 31,
        saveCircumstancesConfirmed: true,
      ),
      throwsRangeError,
    );
    expect(rng.calls, 0);
  });

  test('GameEngine saves damage, save roll, action and event checkpoint', () {
    final rng = _FixedRandom([0, 2, 3]);
    final engine = GameEngine(
      dice: DiceEngine(random: rng),
      clock: () => DateTime.utc(2026, 10, 20),
    );
    final initial = engine.createDemo().copyWith(
      hero: _hero(),
      encounter: _encounter.copyWith(enemyCover: CoverLevel.half),
    );
    final result = _gameCast(engine, initial);
    expect(result.events.single.type, 'spell.sacredFlame');
    expect(result.events.single.payload['savingThrowDc'], 14);
    expect(result.events.single.payload['savingThrowSucceeded'], false);
    expect(result.events.single.payload['savingThrowRoll']['natural'], 1);
    expect(result.events.single.payload['damageType'], 'radiant');
    expect(result.events.single.payload['damage'], 7);
    expect(result.campaign.encounter!.enemyHitPoints, 43);
    expect(result.campaign.encounter!.actionUsed, true);
    expect(result.campaign.encounter!.spellSlotExpendedThisTurn, false);
    expect(result.campaign.hero.spentSpellSlots, isEmpty);
    expect(result.campaign.revision, initial.revision + 1);
    expect(
      Campaign.fromJson(result.campaign.toJson()).toJson(),
      result.campaign.toJson(),
    );
    expect(() => _gameCast(engine, result.campaign), throwsFormatException);
  });

  test('Successful enemy save consumes action but never deals damage', () {
    final engine = GameEngine(dice: DiceEngine(random: _FixedRandom([19])));
    final game = engine.createDemo().copyWith(
      hero: _hero(),
      encounter: _encounter,
    );
    final result = _gameCast(engine, game);
    expect(result.campaign.encounter!.enemyHitPoints, 50);
    expect(result.campaign.encounter!.actionUsed, true);
    expect(result.events.single.payload['damageRoll'], isNull);
  });

  test('Invalid turn and total cover are blocked before dice', () {
    final rng = _FixedRandom([0]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final game = engine.createDemo().copyWith(
      hero: _hero(),
      encounter: _encounter,
    );
    for (final fight in [
      _encounter.copyWith(actionUsed: true),
      _encounter.copyWith(activeParticipant: 'enemy'),
      _encounter.copyWith(enemyCover: CoverLevel.total),
      _encounter.copyWith(surgeReserved: true),
    ]) {
      expect(
        () => _gameCast(engine, game.copyWith(encounter: fight)),
        throwsFormatException,
      );
    }
    expect(rng.calls, 0);
  });
}
