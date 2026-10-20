import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _MaxDie implements Random {
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return max - 1;
  }

  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0.999;
}

Campaign _fight(
  GameEngine engine, {
  EnemyForceDefense defense = EnemyForceDefense.unknown,
}) {
  final demo = engine.createDemo();
  return demo.copyWith(
    hero: demo.hero.copyWith(
      className: 'Magier',
      level: 5,
      spells: ['Magisches Geschoss'],
      abilities: const {
        'strength': 10,
        'dexterity': 12,
        'constitution': 14,
        'intelligence': 16,
        'wisdom': 12,
        'charisma': 14,
      },
    ),
    encounter: Encounter(
      id: 'defended-foe',
      enemyName: 'Prüfgegner',
      enemyHitPoints: 80,
      enemyMaxHitPoints: 80,
      enemyForceDefense: defense,
    ),
  );
}

GameUpdate _cast(
  GameEngine engine,
  Campaign before, {
  EnemyForceDefense? confirmedDefense,
  bool noShield = true,
}) => engine.castMagicMissile(
  before,
  castingClass: 'Magier',
  slotLevel: 1,
  pactMagic: false,
  targetVisibleConfirmed: true,
  targetWithinRangeConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noProtectionConfirmed: noShield,
  confirmedForceDefense: confirmedDefense,
);

void main() {
  group('SRD 5.2.1: Energieschaden-Abwehr je Geschoss', () {
    test('Widerstand wird pro Geschoss gerundet, nicht nach Summe', () {
      final rng = _MaxDie();
      final engine = GameEngine(dice: DiceEngine(random: rng));
      final result = _cast(
        engine,
        _fight(engine),
        confirmedDefense: EnemyForceDefense.resistant,
      );
      expect(rng.calls, 3);
      expect(result.events.single.payload['rawDamage'], 15);
      expect(result.events.single.payload['appliedMissileDamage'], [2, 2, 2]);
      expect(result.events.single.payload['damage'], 6);
      expect(result.campaign.encounter!.enemyHitPoints, 74);
      expect(
        result.campaign.encounter!.enemyForceDefense,
        EnemyForceDefense.resistant,
      );
      expect(result.campaign.hero.spentSpellSlots, {'1': 1});
      expect(result.campaign.encounter!.actionUsed, isTrue);
    });

    test(
      'Immunität reduziert auf null, kostet aber bestätigten Zauberplatz',
      () {
        final rng = _MaxDie();
        final engine = GameEngine(dice: DiceEngine(random: rng));
        final result = _cast(
          engine,
          _fight(engine),
          confirmedDefense: EnemyForceDefense.immune,
        );
        expect(result.campaign.encounter!.enemyHitPoints, 80);
        expect(result.events.single.payload['damage'], 0);
        expect(result.campaign.hero.spentSpellSlots, {'1': 1});
        expect(
          result.campaign.encounter!.enemyForceDefense,
          EnemyForceDefense.immune,
        );
      },
    );

    test(
      'Verwundbarkeit verdoppelt jedes Geschoss; Normal bleibt unverändert',
      () {
        final engine = GameEngine(dice: DiceEngine(random: _MaxDie()));
        final vulnerable = _cast(
          engine,
          _fight(engine),
          confirmedDefense: EnemyForceDefense.vulnerable,
        );
        expect(vulnerable.events.single.payload['damage'], 30);
        expect(vulnerable.campaign.encounter!.enemyHitPoints, 50);
        final ordinary = _cast(
          engine,
          _fight(engine),
          confirmedDefense: EnemyForceDefense.normal,
        );
        expect(ordinary.events.single.payload['damage'], 15);
      },
    );

    test(
      'Bekannte Gegnerabwehr gilt auch für Legacy-Aufruf ohne erneute Auswahl',
      () {
        final engine = GameEngine(dice: DiceEngine(random: _MaxDie()));
        final before = _fight(engine, defense: EnemyForceDefense.immune);
        final cast = _cast(engine, before);
        expect(cast.campaign.encounter!.enemyHitPoints, 80);
        expect(cast.events.single.payload['enemyForceDefense'], 'immune');
      },
    );

    test(
      'Keine Schildbestätigung oder unbekannte explizite Auswahl: keinerlei Zufall',
      () {
        final rng = _MaxDie();
        final engine = GameEngine(dice: DiceEngine(random: rng));
        final before = _fight(engine);
        expect(
          () => _cast(engine, before, noShield: false),
          throwsFormatException,
        );
        expect(
          () => _cast(
            engine,
            before,
            confirmedDefense: EnemyForceDefense.unknown,
          ),
          throwsFormatException,
        );
        expect(rng.calls, 0);
        expect(before.encounter!.enemyForceDefense, EnemyForceDefense.unknown);
        expect(before.hero.spentSpellSlots, isEmpty);
      },
    );

    test(
      'Speicherformat: alte Saves unknown, neue explizit, gefälscht abweisen',
      () {
        final old = const Encounter(
          id: 'legacy',
          enemyName: 'Alte Begegnung',
          enemyHitPoints: 10,
          enemyMaxHitPoints: 10,
        ).toJson();
        expect(old.containsKey('enemyForceDefense'), isFalse);
        expect(
          Encounter.fromJson(old).enemyForceDefense,
          EnemyForceDefense.unknown,
        );
        final explicit = Encounter.fromJson({
          ...old,
          'enemyForceDefense': 'resistant',
        });
        expect(explicit.enemyForceDefense, EnemyForceDefense.resistant);
        expect(
          Encounter.fromJson(explicit.toJson()).enemyForceDefense,
          EnemyForceDefense.resistant,
        );
        for (final invalid in [
          'resistAll',
          'SHIELD',
          '',
          123,
          'immune,vulnerable',
        ]) {
          expect(
            () => Encounter.fromJson({...old, 'enemyForceDefense': invalid}),
            throwsFormatException,
          );
        }
      },
    );

    test('Direkte Schadensregel verlangt bestätigten Typ', () {
      expect(
        () => EnemyForceDefenseRules.apply([
          5,
          5,
          5,
        ], defense: EnemyForceDefense.unknown),
        throwsFormatException,
      );
      expect(
        EnemyForceDefenseRules.apply([
          5,
          5,
          5,
        ], defense: EnemyForceDefense.resistant).appliedTotal,
        6,
      );
    });
  });
}
