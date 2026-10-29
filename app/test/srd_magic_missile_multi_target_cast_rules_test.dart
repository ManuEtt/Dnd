import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_multi_target_cast_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_multi_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_volley_damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

class _MinimumDie implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _mage({
  String className = 'Magier',
  int level = 5,
  List<String> spells = const ['Magisches Geschoss'],
}) => HeroCharacter(
  id: 'mage',
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

const _a = SrdMagicMissileTarget(
  id: 'enemy-a',
  creatureConfirmed: true,
  visibleConfirmed: true,
  within120FeetConfirmed: true,
  noTotalCoverConfirmed: true,
);
const _b = SrdMagicMissileTarget(
  id: 'enemy-b',
  creatureConfirmed: true,
  visibleConfirmed: true,
  within120FeetConfirmed: true,
  noTotalCoverConfirmed: true,
);
const _normalA = SrdMissileTargetDefense(
  targetId: 'enemy-a',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.normal,
);
const _normalB = SrdMissileTargetDefense(
  targetId: 'enemy-b',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.normal,
);
const _shieldA = SrdMissileTargetDefense(
  targetId: 'enemy-a',
  shieldState: SrdMissileShieldState.activeConfirmed,
  forceDefense: EnemyForceDefense.unknown,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellDefinition missile;

  setUpAll(() async {
    final catalog = await SrdSpellCatalogLoader.load();
    missile = catalog.find('Magic Missile')!;
  });

  SrdMagicMissileAllocation allocation({
    int level = 1,
    List<String> ids = const ['enemy-a', 'enemy-a', 'enemy-a'],
    List<SrdMagicMissileTarget> targets = const [_a],
  }) => SrdMagicMissileMultiTargetRules.prepare(
    spell: missile,
    slotLevel: level,
    confirmedTargets: targets,
    dartTargetIds: ids,
  );

  SrdMagicMissileMultiTargetCast cast(
    SrdMagicMissileAllocation plan,
    _MinimumDie random, {
    HeroCharacter? hero,
    String castingClass = 'Magier',
    bool pactMagic = false,
    bool verbal = true,
    bool somatic = true,
    bool reactions = true,
    Iterable<SrdMissileTargetDefense> defenses = const [_normalA],
  }) => SrdMagicMissileMultiTargetCastRules.cast(
    hero: hero ?? _mage(),
    dice: DiceEngine(random: random),
    castingClass: castingClass,
    allocation: plan,
    targetDefenses: defenses,
    pactMagic: pactMagic,
    verbalComponentConfirmed: verbal,
    somaticComponentConfirmed: somatic,
    reactionDecisionsConfirmed: reactions,
  );

  test('three darts hit one target, one slot is spent exactly once', () {
    final before = _mage();
    final random = _MinimumDie();
    final result = cast(allocation(), random, hero: before);
    expect(random.calls, 3);
    expect(result.damage.dartCount, 3);
    expect(result.damage.appliedPerTarget, {'enemy-a': 6});
    expect(result.hero.spentSpellSlots, {'1': 1});
    expect(result.castingClass, 'Magier');
    expect(result.pactMagic, isFalse);
    expect(before.spentSpellSlots, isEmpty);
    expect(result.hero.className, before.className);
  });

  test('split darts respect each target Shield and Force defense', () {
    final random = _MinimumDie();
    final plan = allocation(
      level: 2,
      ids: const ['enemy-a', 'enemy-b', 'enemy-a', 'enemy-b'],
      targets: const [_a, _b],
    );
    final result = cast(
      plan,
      random,
      defenses: const [
        _shieldA,
        SrdMissileTargetDefense(
          targetId: 'enemy-b',
          shieldState: SrdMissileShieldState.absentConfirmed,
          forceDefense: EnemyForceDefense.vulnerable,
        ),
      ],
    );
    expect(random.calls, 2);
    expect(result.damage.shieldBlockedCount, 2);
    expect(result.damage.rawPerTarget, {'enemy-a': 0, 'enemy-b': 4});
    expect(result.damage.appliedPerTarget, {'enemy-a': 0, 'enemy-b': 8});
    expect(result.damage.darts.map((d) => d.targetId), plan.dartTargetIds);
    expect(result.hero.spentSpellSlots, {'2': 1});
  });

  test('resistance and immunity are evaluated per unshielded dart', () {
    final random = _MinimumDie();
    final result = cast(
      allocation(
        ids: const ['enemy-a', 'enemy-b', 'enemy-a'],
        targets: const [_a, _b],
      ),
      random,
      defenses: const [
        SrdMissileTargetDefense(
          targetId: 'enemy-a',
          shieldState: SrdMissileShieldState.absentConfirmed,
          forceDefense: EnemyForceDefense.resistant,
        ),
        SrdMissileTargetDefense(
          targetId: 'enemy-b',
          shieldState: SrdMissileShieldState.absentConfirmed,
          forceDefense: EnemyForceDefense.immune,
        ),
      ],
    );
    expect(random.calls, 3);
    expect(result.damage.appliedPerTarget, {'enemy-a': 2, 'enemy-b': 0});
    expect(result.damage.appliedTotal, 2);
  });

  test('all Shielded darts skip RNG but still consume the spell slot', () {
    final random = _MinimumDie();
    final result = cast(
      allocation(),
      random,
      defenses: const [_shieldA],
    );
    expect(random.calls, 0);
    expect(result.damage.shieldBlockedCount, 3);
    expect(result.damage.appliedTotal, 0);
    expect(result.hero.spentSpellSlots, {'1': 1});
  });

  test('all missing components and reactions fail before RNG', () {
    final random = _MinimumDie();
    for (final flags in [
      [false, true, true],
      [true, false, true],
      [true, true, false],
    ]) {
      expect(
        () => cast(
          allocation(),
          random,
          verbal: flags[0],
          somatic: flags[1],
          reactions: flags[2],
        ),
        throwsFormatException,
      );
    }
    expect(random.calls, 0);
  });

  test('unprepared, wrong class and exhausted slots fail before RNG', () {
    final random = _MinimumDie();
    final plan = allocation();
    expect(
      () => cast(plan, random, hero: _mage(spells: const [])),
      throwsFormatException,
    );
    expect(
      () => cast(plan, random, hero: _mage(className: 'Kleriker')),
      throwsFormatException,
    );
    expect(
      () => cast(plan, random, castingClass: 'Hexenmeister'),
      throwsFormatException,
    );
    expect(
      () => cast(
        plan,
        random,
        hero: _mage().copyWith(spentSpellSlots: {'1': 4}),
      ),
      throwsFormatException,
    );
    expect(random.calls, 0);
  });

  test('duplicate, missing, extra and unknown defenses fail before RNG', () {
    final random = _MinimumDie();
    final plan = allocation(
      ids: const ['enemy-a', 'enemy-b', 'enemy-a'],
      targets: const [_a, _b],
    );
    for (final defenses in <List<SrdMissileTargetDefense>>[
      const [_normalA],
      const [_normalA, _normalA],
      const [_normalA, _normalB, _shieldA],
      const [
        _normalA,
        SrdMissileTargetDefense(
          targetId: 'foreign',
          shieldState: SrdMissileShieldState.absentConfirmed,
          forceDefense: EnemyForceDefense.normal,
        ),
      ],
      const [
        _normalA,
        SrdMissileTargetDefense(
          targetId: 'enemy-b',
          shieldState: SrdMissileShieldState.unverified,
          forceDefense: EnemyForceDefense.normal,
        ),
      ],
      const [
        _normalA,
        SrdMissileTargetDefense(
          targetId: 'enemy-b',
          shieldState: SrdMissileShieldState.absentConfirmed,
          forceDefense: EnemyForceDefense.unknown,
        ),
      ],
    ]) {
      expect(
        () => cast(plan, random, defenses: defenses),
        throwsFormatException,
      );
    }
    expect(random.calls, 0);
  });

  test('multiclass Pact Magic spends the pact slot only', () {
    final random = _MinimumDie();
    final hero = _mage(
      level: 4,
    ).copyWith(secondaryClassName: 'Hexenmeister', secondaryClassLevel: 2);
    final result = cast(
      allocation(),
      random,
      hero: hero,
      pactMagic: true,
    );
    expect(random.calls, 3);
    expect(result.pactMagic, isTrue);
    expect(result.hero.spentPactSlots, 1);
    expect(result.hero.spentSpellSlots, isEmpty);
    expect(result.hero.secondaryClassName, 'Hexenmeister');
    expect(hero.spentPactSlots, 0);
  });

  test('upcasting at level nine resolves exactly eleven darts', () {
    final random = _MinimumDie();
    final result = cast(
      allocation(level: 9, ids: List.filled(11, 'enemy-a')),
      random,
      hero: _mage(level: 17),
    );
    expect(random.calls, 11);
    expect(result.damage.appliedTotal, 22);
    expect(result.hero.spentSpellSlots, {'9': 1});
    expect(result.damage.darts, hasLength(11));
  });

  test('defense evidence and result snapshots cannot be mutated', () {
    final defenses = <SrdMissileTargetDefense>[_normalA];
    final before = _mage();
    final result = cast(
      allocation(),
      _MinimumDie(),
      hero: before,
      defenses: defenses,
    );
    defenses.clear();
    expect(result.damage.appliedTotal, 6);
    expect(before.spentSpellSlots, isEmpty);
    expect(() => result.damage.darts.clear(), throwsUnsupportedError);
    expect(
      () => result.damage.appliedPerTarget['enemy-a'] = 900,
      throwsUnsupportedError,
    );
  });
}
