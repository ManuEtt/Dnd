import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/acid_splash_rules.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.values);
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

HeroCharacter _hero({
  int level = 5,
  String className = 'Magier',
  List<String> spells = const ['Säurespritzer'],
}) => HeroCharacter(
  id: 'acid-caster',
  name: 'Ari',
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
  hitPoints: 25,
  maxHitPoints: 25,
  armorClass: 13,
  speed: 9,
  weaponDamage: '1d4',
);

AcidSplashTarget _target(
  String id, {
  String? name,
  int hp = 20,
  int maxHp = 20,
  int dexteritySaveModifier = 0,
  CoverLevel cover = CoverLevel.none,
  bool sourceOppositeCover = false,
  bool confirmed = true,
  bool saveAdvantage = false,
  bool saveDisadvantage = false,
}) => AcidSplashTarget(
  id: id,
  name: name ?? id,
  hitPoints: hp,
  maxHitPoints: maxHp,
  dexteritySaveModifier: dexteritySaveModifier,
  cover: cover,
  sourceOppositeCover: sourceOppositeCover,
  coverRelationshipConfirmed: confirmed,
  inSphereConfirmed: confirmed,
  effectPathConfirmed: confirmed,
  noAcidDamageAdjustmentConfirmed: confirmed,
  saveCircumstancesConfirmed: confirmed,
  saveAdvantage: saveAdvantage,
  saveDisadvantage: saveDisadvantage,
);

AcidSplashResult _cast(
  HeroCharacter hero,
  _FixedRandom random, {
  List<AcidSplashTarget>? targets,
  String castingClass = 'Magier',
  bool radiusConfirmed = true,
  bool allConfirmed = true,
  bool v = true,
  bool s = true,
  bool dc = true,
}) => AcidSplashRules.cast(
  hero,
  dice: DiceEngine(random: random),
  castingClass: castingClass,
  targets: targets ?? [_target('foe')],
  sphereOriginWithinRangeConfirmed: radiusConfirmed,
  everyCreatureInSphereIncludedConfirmed: allConfirmed,
  verbalComponentConfirmed: v,
  somaticComponentConfirmed: s,
  noUnmodelledDcModifiersConfirmed: dc,
);

const _encounter = Encounter(
  id: 'foe',
  enemyName: 'Wächter',
  enemyHitPoints: 25,
  enemyMaxHitPoints: 25,
  enemyArmorClass: 14,
);

GameUpdate _engine(
  GameEngine engine,
  Campaign campaign, {
  bool isolated = true,
  bool path = true,
  int dexterityModifier = 0,
  bool sourceOppositeCover = false,
}) => engine.castAcidSplash(
  campaign,
  castingClass: 'Magier',
  confirmedTargetDexteritySaveModifier: dexterityModifier,
  originWithin60FeetConfirmed: true,
  currentEnemyIsOnlyCreatureInSphereConfirmed: isolated,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noUnmodelledDcModifiersConfirmed: true,
  targetSaveCircumstancesConfirmed: true,
  targetCoverRelationshipConfirmed: true,
  effectPathConfirmed: path,
  noAcidDamageAdjustmentConfirmed: true,
  targetSourceOppositeCover: sourceOppositeCover,
);

void main() {
  test('Valid target IDs stay distinct and share a single damage roll', () {
    final rng = _FixedRandom([0, 0, 0, 0]);
    final hero = _hero();
    final previous = hero.toJson();
    final outcome = _cast(
      hero,
      rng,
      targets: [_target('creature-1'), _target('creature-2')],
    );
    expect(outcome.targets.map((impact) => impact.id), [
      'creature-1',
      'creature-2',
    ]);
    expect(outcome.targets.map((impact) => impact.damage), [2, 2]);
    expect(outcome.damageRoll!.rolls, [1, 1]);
    expect(rng.calls, 4);
    expect(hero.toJson(), previous);
  });

  test('Reject ambiguous target IDs before any random roll', () {
    final rng = _FixedRandom([0]);
    final hero = _hero();
    final original = hero.toJson();
    for (final invalidId in <String>[
      ' ',
      ' foe',
      'foe ',
      '\tfoe',
      'foe\n',
      'fo\noe',
      'fo\u0000e',
      'fo\u007Fe',
    ]) {
      expect(
        () => _cast(hero, rng, targets: [_target('valid'), _target(invalidId)]),
        throwsFormatException,
        reason: 'Ambiguous ID: $invalidId',
      );
    }
    expect(rng.calls, 0);
    expect(hero.toJson(), original);
  });

  test('Cantrip scales at character levels 5, 11, 17', () {
    expect(AcidSplashRules.damageDice(1), 1);
    expect(AcidSplashRules.damageDice(4), 1);
    expect(AcidSplashRules.damageDice(5), 2);
    expect(AcidSplashRules.damageDice(10), 2);
    expect(AcidSplashRules.damageDice(11), 3);
    expect(AcidSplashRules.damageDice(16), 3);
    expect(AcidSplashRules.damageDice(17), 4);
    expect(AcidSplashRules.damageDice(20), 4);
    expect(() => AcidSplashRules.damageDice(21), throwsRangeError);
  });

  test('Three different saves, ONE shared damage roll for two failures', () {
    // SG 14: nat 1 fails, nat 20 succeeds, nat 1 fails.
    final rng = _FixedRandom([0, 19, 0, 4, 5]);
    final before = _hero();
    final targets = [
      _target('orc', hp: 20),
      _target(
        'shielded',
        hp: 15,
        maxHp: 15,
        dexteritySaveModifier: 2,
        cover: CoverLevel.half,
        sourceOppositeCover: true,
      ),
      _target('kobold', hp: 5, maxHp: 5),
    ];
    final result = _cast(before, rng, targets: targets);
    expect(result.dc, 14);
    expect(result.targets, hasLength(3));
    expect(result.targets[0].save.succeeded, false);
    expect(result.targets[1].save.succeeded, true);
    expect(result.targets[1].coverBonus, 2);
    expect(result.targets[2].save.succeeded, false);
    expect(result.damageRoll!.expression, '2d6');
    expect(result.damageRoll!.rolls, [5, 6]);
    expect(result.targets.map((x) => x.damage), [11, 0, 11]);
    expect(result.targets.map((x) => x.hitPointsAfter), [9, 15, 0]);
    expect(rng.calls, 5);
    expect(result.hero.spentSpellSlots, isEmpty);
    expect(before.spentSpellSlots, isEmpty);
    expect(targets.first.hitPoints, 20);
    expect(result.targets[0].toJson()['savingThrowRoll']['natural'], 1);
  });

  test('All successful saves spend an action in caller but no damage dice', () {
    final rng = _FixedRandom([19, 19]);
    final outcome = _cast(_hero(), rng, targets: [_target('a'), _target('b')]);
    expect(outcome.damageRoll, isNull);
    expect(outcome.targets.map((e) => e.damage), [0, 0]);
    expect(rng.calls, 2);
  });

  test('Natural 1 and 20 are not automatic save outcomes', () {
    final result = _cast(
      _hero(),
      _FixedRandom([0, 19, 0, 0]),
      targets: [
        _target('successOnOne', dexteritySaveModifier: 20),
        _target('failsOnTwenty', dexteritySaveModifier: -20),
      ],
    );
    expect(result.targets[0].save.succeeded, true);
    expect(result.targets[0].save.roll.natural, 1);
    expect(result.targets[1].save.succeeded, false);
    expect(result.targets[1].save.roll.natural, 20);
  });

  test(
    'Saving throw half and three-quarter cover comes from sphere origin',
    () {
      final result = _cast(
        _hero(),
        _FixedRandom([10, 10, 0, 0]),
        targets: [
          _target('cover', cover: CoverLevel.half, sourceOppositeCover: true),
          _target('notOpposite', cover: CoverLevel.threeQuarters),
        ],
      );
      expect(result.targets[0].coverBonus, 2);
      expect(result.targets[0].save.roll.total, 13);
      expect(result.targets[1].coverBonus, 0);
      expect(result.targets[1].save.roll.total, 11);
    },
  );

  test('Preflight rejects incomplete area and duplicate target BEFORE RNG', () {
    final rng = _FixedRandom([19]);
    final h = _hero();
    expect(() => _cast(h, rng, allConfirmed: false), throwsFormatException);
    expect(() => _cast(h, rng, radiusConfirmed: false), throwsFormatException);
    expect(() => _cast(h, rng, v: false), throwsFormatException);
    expect(() => _cast(h, rng, s: false), throwsFormatException);
    expect(() => _cast(h, rng, dc: false), throwsFormatException);
    expect(
      () => _cast(h, rng, targets: [_target('a'), _target('a')]),
      throwsFormatException,
    );
    expect(
      () => _cast(h, rng, targets: [_target('a', confirmed: false)]),
      throwsFormatException,
    );
    expect(
      () =>
          _cast(h, rng, targets: [_target('covered', cover: CoverLevel.total)]),
      throwsFormatException,
    );
    expect(
      () => _cast(
        h,
        rng,
        targets: [_target('tooHigh', dexteritySaveModifier: 31)],
      ),
      throwsFormatException,
    );
    expect(
      () => _cast(
        h,
        rng,
        targets: [
          _target(
            'tooHighWithCover',
            dexteritySaveModifier: 29,
            cover: CoverLevel.threeQuarters,
            sourceOppositeCover: true,
          ),
        ],
      ),
      throwsFormatException,
    );
    expect(rng.calls, 0);
  });

  test('Invalid caster never rolls or charges resources', () {
    final rng = _FixedRandom([19]);
    expect(() => _cast(_hero(spells: []), rng), throwsFormatException);
    expect(
      () => _cast(_hero(className: 'Kleriker'), rng, castingClass: 'Kleriker'),
      throwsFormatException,
    );
    expect(rng.calls, 0);
    final sorcerer = _hero(
      className: 'Zauberer',
      spells: const ['Acid Splash'],
    );
    expect(
      _cast(
        sorcerer,
        _FixedRandom([19]),
        castingClass: 'Zauberer',
      ).castingClass,
      'Zauberer',
    );
  });

  test('Game action persists the sole tracked enemy, dice and no slot', () {
    final rng = _FixedRandom([0, 3, 4]);
    final engine = GameEngine(
      dice: DiceEngine(random: rng),
      clock: () => DateTime.utc(2026, 10, 20),
    );
    final initial = engine.createDemo().copyWith(
      hero: _hero(),
      encounter: _encounter,
    );
    final after = _engine(engine, initial);
    expect(after.events.single.type, 'spell.acidSplash');
    expect(after.events.single.payload['areaRadiusFeet'], 5);
    expect(after.events.single.payload['savingThrowDc'], 14);
    expect(after.events.single.payload['targetResolutions'], hasLength(1));
    expect(after.events.single.payload['targetResolutions'][0]['damage'], 9);
    expect(after.campaign.encounter!.enemyHitPoints, 16);
    expect(after.campaign.encounter!.actionUsed, true);
    expect(after.campaign.encounter!.spellSlotExpendedThisTurn, false);
    expect(after.campaign.hero.spentSpellSlots, isEmpty);
    expect(after.campaign.revision, initial.revision + 1);
    expect(
      Campaign.fromJson(after.campaign.toJson()).toJson(),
      after.campaign.toJson(),
    );
    expect(() => _engine(engine, after.campaign), throwsFormatException);
  });

  test('Multi-creature scene must refuse incomplete persistence, no dice', () {
    final rng = _FixedRandom([0]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final initial = engine.createDemo().copyWith(
      hero: _hero(),
      encounter: _encounter,
    );
    expect(
      () => _engine(engine, initial, isolated: false),
      throwsFormatException,
    );
    expect(() => _engine(engine, initial, path: false), throwsFormatException);
    for (final encounter in [
      _encounter.copyWith(activeParticipant: 'enemy'),
      _encounter.copyWith(actionUsed: true),
      _encounter.copyWith(enemyCover: CoverLevel.total),
    ]) {
      expect(
        () => _engine(engine, initial.copyWith(encounter: encounter)),
        throwsFormatException,
      );
    }
    expect(rng.calls, 0);
  });
}
