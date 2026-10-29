import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_volley_damage_rules.dart';

const _normal = SrdMissileTargetDefense(
  targetId: 'a',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.normal,
);
const _resistant = SrdMissileTargetDefense(
  targetId: 'a',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.resistant,
);
const _vulnerable = SrdMissileTargetDefense(
  targetId: 'b',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.vulnerable,
);
const _shielded = SrdMissileTargetDefense(
  targetId: 'a',
  shieldState: SrdMissileShieldState.activeConfirmed,
  forceDefense: EnemyForceDefense.unknown,
);

SrdMagicMissileVolleyDamage _resolve({
  int slotLevel = 1,
  bool confirmed = true,
  List<SrdMissileDartEvidence> darts = const [
    SrdMissileDartEvidence(targetId: 'a', naturalD4: 1),
    SrdMissileDartEvidence(targetId: 'a', naturalD4: 2),
    SrdMissileDartEvidence(targetId: 'a', naturalD4: 3),
  ],
  Iterable<SrdMissileTargetDefense> targets = const [_normal],
}) => SrdMagicMissileVolleyDamageRules.resolve(
  slotLevel: slotLevel,
  allocationAndReactionsConfirmed: confirmed,
  darts: darts,
  targetDefenses: targets,
);

void main() {
  test('three simultaneous darts retain individual rolls and order', () {
    final result = _resolve();
    expect(result.dartCount, 3);
    expect(result.darts.map((dart) => dart.naturalD4), [1, 2, 3]);
    expect(result.darts.map((dart) => dart.rawDamage), [2, 3, 4]);
    expect(result.rawPerTarget, {'a': 9});
    expect(result.appliedPerTarget, {'a': 9});
    expect(result.rawTotal, 9);
    expect(result.appliedTotal, 9);
    expect(result.shieldBlockedCount, 0);
  });

  test('resistance rounds each dart down before summing per target', () {
    final result = _resolve(targets: const [_resistant]);
    expect(result.darts.map((dart) => dart.appliedDamage), [1, 1, 2]);
    expect(result.rawPerTarget['a'], 9);
    expect(result.appliedPerTarget['a'], 4);
  });

  test('two creatures have independent resistance and vulnerability', () {
    final result = _resolve(
      targets: const [_resistant, _vulnerable],
      darts: const [
        SrdMissileDartEvidence(targetId: 'a', naturalD4: 1),
        SrdMissileDartEvidence(targetId: 'b', naturalD4: 4),
        SrdMissileDartEvidence(targetId: 'a', naturalD4: 2),
      ],
    );
    expect(result.rawPerTarget, {'a': 5, 'b': 5});
    expect(result.appliedPerTarget, {'a': 2, 'b': 10});
    expect(result.appliedTotal, 12);
    expect(result.darts.map((dart) => dart.appliedDamage), [1, 10, 1]);
  });

  test('Shield blocks only its target, without a defensive damage roll', () {
    final result = _resolve(
      targets: const [
        _shielded,
        SrdMissileTargetDefense(
          targetId: 'b',
          shieldState: SrdMissileShieldState.absentConfirmed,
          forceDefense: EnemyForceDefense.normal,
        ),
      ],
      darts: const [
        SrdMissileDartEvidence(targetId: 'a', naturalD4: null),
        SrdMissileDartEvidence(targetId: 'b', naturalD4: 4),
        SrdMissileDartEvidence(targetId: 'a', naturalD4: null),
      ],
    );
    expect(result.shieldBlockedCount, 2);
    expect(result.rawPerTarget, {'a': 0, 'b': 5});
    expect(result.appliedPerTarget, {'a': 0, 'b': 5});
    expect(result.darts.first.blockedByShield, isTrue);
    expect(result.darts.last.naturalD4, isNull);
  });

  test('confirmed immunity yields zero despite rolled damage', () {
    final immune = _resolve(
      targets: const [
        SrdMissileTargetDefense(
          targetId: 'a',
          shieldState: SrdMissileShieldState.absentConfirmed,
          forceDefense: EnemyForceDefense.immune,
        ),
      ],
    );
    expect(immune.rawTotal, 9);
    expect(immune.appliedTotal, 0);
    expect(immune.shieldBlockedCount, 0);
    expect(immune.darts.every((dart) => !dart.blockedByShield), isTrue);
  });

  test('eleven darts at slot 9 preserve all individual outcomes', () {
    final darts = List<SrdMissileDartEvidence>.filled(
      11,
      const SrdMissileDartEvidence(targetId: 'a', naturalD4: 4),
    );
    final result = _resolve(slotLevel: 9, darts: darts);
    expect(result.dartCount, 11);
    expect(result.appliedTotal, 55);
    expect(result.darts.length, 11);
  });

  test('unconfirmed context and malformed slot or dart count fail closed', () {
    expect(() => _resolve(confirmed: false), throwsFormatException);
    for (final slot in [0, -1, 10]) {
      expect(() => _resolve(slotLevel: slot), throwsFormatException);
    }
    expect(() => _resolve(darts: const []), throwsFormatException);
    expect(
      () => _resolve(
        darts: const [
          SrdMissileDartEvidence(targetId: 'a', naturalD4: 1),
          SrdMissileDartEvidence(targetId: 'a', naturalD4: 1),
        ],
      ),
      throwsFormatException,
    );
  });

  test('unknown shield or force defense is not inferred as safe', () {
    for (final target in [
      const SrdMissileTargetDefense(
        targetId: 'a',
        shieldState: SrdMissileShieldState.unverified,
        forceDefense: EnemyForceDefense.normal,
      ),
      const SrdMissileTargetDefense(
        targetId: 'a',
        shieldState: SrdMissileShieldState.absentConfirmed,
        forceDefense: EnemyForceDefense.unknown,
      ),
    ]) {
      expect(() => _resolve(targets: [target]), throwsFormatException);
    }
  });

  test('shielded targets reject rolls; unshielded require valid d4', () {
    final withRolls = _resolve;
    expect(() => withRolls(targets: const [_shielded]), throwsFormatException);
    for (final roll in [null, 0, -1, 5]) {
      expect(
        () => _resolve(
          darts: [
            SrdMissileDartEvidence(targetId: 'a', naturalD4: roll),
            const SrdMissileDartEvidence(targetId: 'a', naturalD4: 2),
            const SrdMissileDartEvidence(targetId: 'a', naturalD4: 3),
          ],
        ),
        throwsFormatException,
      );
    }
  });

  test('foreign, duplicated, unused and malformed IDs are rejected', () {
    expect(
      () => _resolve(
        darts: const [
          SrdMissileDartEvidence(targetId: 'b', naturalD4: 1),
          SrdMissileDartEvidence(targetId: 'a', naturalD4: 2),
          SrdMissileDartEvidence(targetId: 'a', naturalD4: 3),
        ],
      ),
      throwsFormatException,
    );
    expect(
      () => _resolve(targets: const [_normal, _normal]),
      throwsFormatException,
    );
    expect(
      () => _resolve(targets: const [_normal, _vulnerable]),
      throwsFormatException,
    );
    for (final id in ['', 'a b', 'a\n', '✦']) {
      expect(
        () => _resolve(
          targets: [
            SrdMissileTargetDefense(
              targetId: id,
              shieldState: SrdMissileShieldState.absentConfirmed,
              forceDefense: EnemyForceDefense.normal,
            ),
          ],
        ),
        throwsFormatException,
      );
    }
  });

  test('result snapshots cannot be altered by modifying caller inputs', () {
    final darts = [
      const SrdMissileDartEvidence(targetId: 'a', naturalD4: 1),
      const SrdMissileDartEvidence(targetId: 'a', naturalD4: 2),
      const SrdMissileDartEvidence(targetId: 'a', naturalD4: 3),
    ];
    final targets = <SrdMissileTargetDefense>[_normal];
    final result = _resolve(darts: darts, targets: targets);
    darts.clear();
    targets.clear();
    expect(result.appliedTotal, 9);
    expect(result.darts.length, 3);
    expect(() => result.darts.clear(), throwsUnsupportedError);
    expect(() => result.appliedPerTarget['a'] = 999, throwsUnsupportedError);
    expect(() => result.rawPerTarget.clear(), throwsUnsupportedError);
  });
}
