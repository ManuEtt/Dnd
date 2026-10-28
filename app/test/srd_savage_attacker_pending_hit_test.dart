import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_savage_attacker_pending_hit.dart';

DiceResult roll(List<int> dice, {String expression = '2d6'}) => DiceResult(
  expression: expression,
  rolls: dice,
  modifier: 0,
  total: dice.fold<int>(0, (sum, die) => sum + die),
);

Campaign campaign({bool critical = false}) {
  final demo = GameEngine().createDemo();
  final soldier = demo.hero.copyWith(
    background: SrdBackground.soldier.label,
    startingBackgroundPackage: SrdBackgroundPackageChoice(
      background: SrdBackground.soldier,
      takeGold: true,
      gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
    ),
    weaponDamage: '2d6',
    hitPoints: 12,
    maxHitPoints: 12,
  );
  final encounter = Encounter(
    id: 'enemy-1',
    enemyName: 'Wächter',
    enemyHitPoints: 30,
    enemyMaxHitPoints: 30,
    round: 2,
  );
  return demo.copyWith(
    revision: 7,
    hero: soldier,
    encounter: encounter,
    pendingSavageAttackerHit: PendingSavageAttackerHit(
      attackRollId: 'roll-17',
      encounterId: 'enemy-1',
      offeredAtRevision: 7,
      round: 2,
      weaponDamageExpression: '2d6',
      original: roll([1, 2]),
      alternative: roll([5, 6]),
      critical: critical,
      originalCriticalExtra: critical ? roll([2, 3]) : null,
      alternativeCriticalExtra: critical ? roll([6, 6]) : null,
    ),
  );
}

void main() {
  test(
    'optional pending choice roundtrips without changing schema version',
    () {
      final before = campaign();
      final json = before.toJson();
      final after = Campaign.fromJson(json);
      expect(json['schemaVersion'], 1);
      expect(after.toJson(), json);
      expect(after.pendingSavageAttackerHit!.original.rolls, [1, 2]);
      expect(after.pendingSavageAttackerHit!.alternative.rolls, [5, 6]);
      expect(after.encounter!.enemyHitPoints, 30);
      expect(after.encounter!.savageAttackerUsedThisTurn, false);
      expect(after.revision, 7);
    },
  );

  test('older campaigns without field retain exact previous JSON', () {
    final old = campaign().copyWith(pendingSavageAttackerHit: null).toJson();
    expect(old.containsKey('pendingSavageAttackerHit'), false);
    expect(Campaign.fromJson(old).toJson(), old);
  });

  test('critical candidates survive full JSON roundtrip', () {
    final data = campaign(critical: true).toJson();
    final restored = Campaign.fromJson(data).pendingSavageAttackerHit!;
    expect(restored.originalCriticalExtra!.rolls, [2, 3]);
    expect(restored.alternativeCriticalExtra!.rolls, [6, 6]);
  });

  test(
    'tampered dice, duplicates of modifiers or missing crit pool rejected',
    () {
      final valid = campaign().toJson();
      final pending = Map<String, dynamic>.from(
        valid['pendingSavageAttackerHit'] as Map<String, dynamic>,
      );
      final fake = <Map<String, dynamic>>[
        {
          ...pending,
          'alternative': {...pending['alternative'] as Map, 'total': 99},
        },
        {
          ...pending,
          'original': {
            ...pending['original'] as Map,
            'rolls': [0, 8],
          },
        },
        {
          ...pending,
          'original': {...pending['original'] as Map, 'modifier': 1},
        },
        {...pending, 'critical': true},
        {...pending, 'attackRollId': 'roll /../../'},
        {...pending, 'weaponDamageExpression': '1d100'},
        {...pending, 'round': -1},
      ];
      for (final value in fake) {
        expect(
          () =>
              Campaign.fromJson({...valid, 'pendingSavageAttackerHit': value}),
          throwsFormatException,
        );
      }
    },
  );

  test('stale revision, wrong target/round and spent turn fail closed', () {
    final valid = campaign().toJson();
    final pending = valid['pendingSavageAttackerHit'] as Map<String, dynamic>;
    for (final changes in [
      <String, dynamic>{'revision': 8},
      <String, dynamic>{
        'pendingSavageAttackerHit': {...pending, 'encounterId': 'enemy-2'},
      },
      <String, dynamic>{
        'pendingSavageAttackerHit': {...pending, 'round': 3},
      },
      <String, dynamic>{
        'encounter': {
          ...valid['encounter'] as Map,
          'savageAttackerUsedThisTurn': true,
        },
      },
      <String, dynamic>{
        'encounter': {
          ...valid['encounter'] as Map,
          'activeParticipant': 'enemy',
        },
      },
      <String, dynamic>{
        'encounter': {...valid['encounter'] as Map, 'enemyHitPoints': 0},
      },
    ]) {
      expect(
        () => Campaign.fromJson({...valid, ...changes}),
        throwsFormatException,
      );
    }
  });

  test('unconfirmed feat and concurrent roll are not resumed', () {
    final valid = campaign().toJson();
    final plain = campaign().hero.copyWith(startingBackgroundPackage: null);
    expect(
      () => Campaign.fromJson({...valid, 'hero': plain.toJson()}),
      throwsFormatException,
    );
    expect(
      () => Campaign.fromJson({
        ...valid,
        'pendingRoll': {
          'id': 'roll-18',
          'type': 'attack',
          'modifier': 2,
          'difficulty': 12,
          'targetId': 'enemy-1',
          'targetName': 'Wächter',
          'expression': '1d20',
        },
      }),
      throwsFormatException,
    );
  });

  test('copyWith preserves proposal unless deliberately cleared', () {
    final before = campaign();
    expect(
      before.copyWith(scene: 'Andere Szene').pendingSavageAttackerHit,
      same(before.pendingSavageAttackerHit),
    );
    expect(
      before.copyWith(pendingSavageAttackerHit: null).pendingSavageAttackerHit,
      null,
    );
  });
}
