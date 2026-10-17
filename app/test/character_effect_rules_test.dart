import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_effect_rules.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _Random implements Random {
  _Random([this.value = 10]);
  final int value;
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return (value - 1) % max;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  late GameEngine engine;
  late HeroCharacter hero;
  late _Random random;
  setUp(() {
    random = _Random();
    engine = GameEngine(dice: DiceEngine(random: random));
    hero = engine.createDemo().hero.copyWith(
      hitPoints: 30,
      maxHitPoints: 40,
      temporaryHitPoints: 8,
      concentratingOn: 'Segen',
      className: 'Kleriker',
      savingThrowProficiencies: const [],
      level: 5,
      abilities: const {
        'strength': 10,
        'dexterity': 10,
        'constitution': 14,
        'intelligence': 10,
        'wisdom': 16,
        'charisma': 10,
      },
    );
    random.calls = 0;
  });
  CharacterDamageResult damage({
    HeroCharacter? target,
    int amount = 11,
    DamageDefenses? defenses,
    DiceEngine? dice,
  }) => CharacterEffectRules.damage(
    target ?? hero,
    components: [DamageComponent(DamageType.fire, amount)],
    defenses: defenses ?? DamageDefenses(),
    dice: dice ?? engine.dice,
  );

  test('defenses then temp HP; save DC uses applied damage before buffer', () {
    final r = damage(
      amount: 49,
      defenses: DamageDefenses(resistances: [DamageType.fire]),
    );
    expect(r.damage, 24);
    expect(r.temporaryHitPointsAbsorbed, 8);
    expect(r.hitPointDamage, 16);
    expect(r.hero.hitPoints, 14);
    expect(r.concentrationDc, 12);
    expect(r.concentrationSave!.natural, 10);
    expect(r.concentrationSave!.total, 12);
    expect(r.concentrationLost, isFalse);
    expect((r.toJson()['components'] as List).single['applied'], 24);
    expect(hero.hitPoints, 30);
    expect(hero.temporaryHitPoints, 8);
  });
  test(
    'absorbed damage still saves; immunity avoids damage and randomness',
    () {
      final r = damage(amount: 7);
      expect(r.hero.hitPoints, 30);
      expect(r.concentrationSave, isNotNull);
      final immune = damage(
        amount: 100,
        defenses: DamageDefenses(immunities: [DamageType.fire]),
      );
      expect(immune.hero.toJson(), hero.toJson());
      expect(immune.concentrationSave, isNull);
      expect(random.calls, 1);
    },
  );
  test(
    'save uses proficiency and exhaustion once; failure ends concentration',
    () {
      final r = damage(
        target: hero.copyWith(
          exhaustionLevel: 2,
          savingThrowProficiencies: ['constitution'],
        ),
      );
      expect(r.concentrationSave!.modifier, 1);
      expect(r.concentrationSave!.total, 11);
      final failed = damage(dice: DiceEngine(random: _Random(2)));
      expect(failed.concentrationLost, isTrue);
      expect(failed.hero.concentratingOn, '');
    },
  );
  test('KO and incapacitation end concentration without a save', () {
    final fallen = damage(amount: 39);
    expect(fallen.hero.hitPoints, 0);
    expect(fallen.concentrationLost, isTrue);
    expect(fallen.concentrationSave, isNull);
    final unable = damage(
      target: hero.copyWith(conditions: ['betäubt']),
      amount: 1,
    );
    expect(unable.concentrationLost, isTrue);
    expect(unable.concentrationSave, isNull);
    expect(random.calls, 0);
  });
  test(
    'one mixed packet saves once; separate damage sources save separately',
    () {
      final r = CharacterEffectRules.damage(
        hero,
        components: const [
          DamageComponent(DamageType.fire, 7),
          DamageComponent(DamageType.cold, 9),
        ],
        defenses: DamageDefenses(resistances: [DamageType.fire]),
        dice: engine.dice,
      );
      expect(r.damage, 12);
      expect(random.calls, 1);
      damage(target: r.hero, amount: 1);
      expect(random.calls, 2);
    },
  );
  test(
    'rage and declared resistance do not stack or invent untyped defenses',
    () {
      final barb = hero.copyWith(className: 'Barbar');
      const fight = Encounter(
        id: 'fight',
        enemyName: 'Demo',
        enemyHitPoints: 10,
        enemyMaxHitPoints: 10,
        round: 2,
        rageStartedRound: 1,
        rageUntilRound: 3,
      );
      final defenses = CharacterEffectRules.defensesFor(
        barb,
        encounter: fight,
        declared: DamageDefenses(resistances: [DamageType.slashing]),
      );
      final r = CharacterEffectRules.damage(
        barb,
        components: const [DamageComponent(DamageType.slashing, 11)],
        defenses: defenses,
        dice: engine.dice,
      );
      expect(r.damage, 5);
      expect(damage(target: barb, defenses: defenses).damage, 11);
      expect(
        CharacterEffectRules.untypedDamage(
          barb,
          amount: 11,
          dice: engine.dice,
        ).damage,
        11,
      );
    },
  );
  test('petrified resistance applies to typed and legacy untyped damage', () {
    final stone = hero.copyWith(
      conditions: ['versteinert'],
      concentratingOn: '',
    );
    expect(
      damage(
        target: stone,
        defenses: CharacterEffectRules.defensesFor(stone),
      ).damage,
      5,
    );
    expect(
      CharacterEffectRules.untypedDamage(
        stone,
        amount: 11,
        dice: engine.dice,
      ).damage,
      5,
    );
  });
  test('invalid packets consume no random numbers and change no hero', () {
    expect(() => damage(amount: -1), throwsRangeError);
    expect(() => damage(amount: 100001), throwsRangeError);
    expect(
      () => CharacterEffectRules.damage(
        hero,
        components: [],
        defenses: DamageDefenses(),
        dice: engine.dice,
      ),
      throwsArgumentError,
    );
    expect(random.calls, 0);
    expect(hero.hitPoints, 30);
  });
  test(
    'effect journal records source, target, defenses and replayable state',
    () {
      final before = engine.createDemo().copyWith(hero: hero);
      final r = engine.applyDamage(
        before,
        source: '  Feuerfalle  ',
        components: const [DamageComponent(DamageType.fire, 11)],
        defenses: DamageDefenses(),
      );
      expect(r.events.single.type, 'effect.damage');
      expect(r.events.single.payload['source'], 'Feuerfalle');
      expect(r.events.single.payload['targetId'], hero.id);
      expect(r.campaign.revision, before.revision + 1);
      expect(Campaign.fromJson(r.campaign.toJson()).hero.hitPoints, 27);
      expect(
        MemoryEngine.replay(before, r.events).toJson(),
        r.campaign.toJson(),
      );
    },
  );
  test(
    'temporary HP never stack/heal; healing wakes and resets death saves',
    () {
      final before = engine.createDemo().copyWith(
        hero: hero.copyWith(
          hitPoints: 0,
          concentratingOn: '',
          conditions: ['bewusstlos'],
          deathFailures: 2,
        ),
      );
      final temp = engine
          .grantTemporaryHitPoints(before, source: 'Schutz', amount: 5)
          .campaign;
      expect(temp.hero.temporaryHitPoints, 8);
      expect(temp.hero.hitPoints, 0);
      expect(temp.hero.deathFailures, 2);
      final replaced = engine
          .grantTemporaryHitPoints(
            temp,
            source: 'Neu',
            amount: 3,
            replaceExisting: true,
          )
          .campaign;
      expect(replaced.hero.temporaryHitPoints, 3);
      final healed = engine.applyHealing(
        replaced,
        source: 'Verbündeter',
        amount: 60,
      );
      expect(healed.campaign.hero.hitPoints, 40);
      expect(healed.campaign.hero.temporaryHitPoints, 3);
      expect(healed.campaign.hero.conditions, isNot(contains('bewusstlos')));
      expect(healed.campaign.hero.deathFailures, 0);
    },
  );
  test(
    'pending, dead, missing HP or invalid source block explicit effects',
    () {
      final before = engine.createDemo();
      final pending = before.copyWith(
        pendingRoll: const PendingRoll(
          id: 'r',
          type: 'perception',
          modifier: 0,
          difficulty: 10,
        ),
      );
      expect(
        () => engine.applyHealing(pending, source: 'Quelle', amount: 5),
        throwsFormatException,
      );
      expect(
        () => engine.applyHealing(before, source: '  ', amount: 5),
        throwsFormatException,
      );
      expect(
        () => engine.applyHealing(before, source: 'x' * 201, amount: 5),
        throwsFormatException,
      );
      expect(
        () => engine.applyHealing(
          before.copyWith(hero: hero.copyWith(conditions: ['tot'])),
          source: 'Quelle',
          amount: 5,
        ),
        throwsFormatException,
      );
      expect(
        () => engine.applyHealing(
          before.copyWith(hero: hero.copyWith(hitPoints: null)),
          source: 'Quelle',
          amount: 5,
        ),
        throwsFormatException,
      );
    },
  );
  test('automatic failed save creates no die and cannot be rerolled', () {
    final before = engine.createDemo().copyWith(
      hero: hero.copyWith(
        conditions: ['betäubt'],
        concentratingOn: '',
        className: 'Kämpfer',
        level: 9,
      ),
    );
    random.calls = 0;
    final failed = engine.act(before, 'Rettungswurf: Stärke SG 10');
    expect(failed.events.single.type, 'saving.automaticFailure');
    expect(failed.events.single.payload['automaticFailure'], isTrue);
    expect(failed.events.single.payload.containsKey('roll'), isFalse);
    final retry = engine.act(
      failed.campaign,
      'Rettungswurf wiederholen: Unbeugsam',
    );
    expect(retry.events.single.type, 'rules.blocked');
    expect(retry.campaign.hero.spentClassResources, isEmpty);
    expect(random.calls, 0);
  });
}
