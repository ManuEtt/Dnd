import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _FixedRandom implements Random {
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

Campaign _campaign(GameEngine engine, {Encounter? encounter}) {
  final initial = engine.createDemo();
  return initial.copyWith(
    hero: initial.hero.copyWith(
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
    encounter:
        encounter ??
        const Encounter(
          id: 'enemy-shield',
          enemyName: 'Gegner',
          enemyHitPoints: 80,
          enemyMaxHitPoints: 80,
        ),
  );
}

GameUpdate _cast(
  GameEngine engine,
  Campaign current, {
  bool shield = true,
  bool components = true,
  int? slots = 2,
  bool noShield = false,
}) => engine.castMagicMissile(
  current,
  castingClass: 'Magier',
  slotLevel: 1,
  pactMagic: false,
  targetVisibleConfirmed: true,
  targetWithinRangeConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noProtectionConfirmed: noShield,
  confirmedForceDefense: EnemyForceDefense.normal,
  shieldReactionConfirmed: shield,
  shieldPreparedAndComponentsConfirmed: components,
  confirmedEnemyShieldSlots: slots,
);

void main() {
  test('Schildreaktion blockiert alle Geschosse ohne Schadenswurf', () {
    final random = _FixedRandom();
    final engine = GameEngine(dice: DiceEngine(random: random));
    final original = _campaign(engine);
    final result = _cast(engine, original);
    final next = result.campaign;
    expect(random.calls, 0);
    expect(next.encounter!.enemyHitPoints, 80);
    expect(next.encounter!.enemyShieldActive, isTrue);
    expect(next.encounter!.enemyShieldReactionUsed, isTrue);
    expect(next.encounter!.enemyShieldSlotsRemaining, 1);
    expect(next.encounter!.effectiveEnemyArmorClass, 17);
    expect(next.encounter!.actionUsed, isTrue);
    expect(next.hero.spentSpellSlots, {'1': 1});
    expect(result.events.single.type, 'spell.magicMissile');
    expect(result.events.single.payload['shieldBlocked'], isTrue);
    expect(result.events.single.payload['shieldReactionTriggered'], isTrue);
    expect(result.events.single.payload['appliedMissileDamage'], [0, 0, 0]);
    expect(result.events.single.payload['missileRolls'], isEmpty);
    expect(result.events.single.payload['damage'], 0);
    expect(original.encounter!.enemyShieldSlotsRemaining, isNull);
    expect(Campaign.fromJson(next.toJson()).toJson(), next.toJson());
  });

  test('Schild läuft zu Beginn des nächsten Gegnerzuges ab', () {
    final engine = GameEngine(dice: DiceEngine(random: _FixedRandom()));
    final afterShield = _cast(engine, _campaign(engine)).campaign;
    final nextRound = engine.act(afterShield, 'Zug beenden').campaign;
    expect(nextRound.encounter!.round, 2);
    expect(nextRound.encounter!.enemyShieldActive, isFalse);
    expect(nextRound.encounter!.enemyShieldReactionUsed, isFalse);
    expect(nextRound.encounter!.enemyShieldSlotsRemaining, 1);
  });

  test(
    'Schildbonus wird bei weiteren Angriffen im selben Zug berücksichtigt',
    () {
      final engine = GameEngine(dice: DiceEngine(random: _FixedRandom()));
      final confirmed = const Encounter(
        id: 'e',
        enemyName: 'Gegner',
        enemyHitPoints: 80,
        enemyMaxHitPoints: 80,
        enemyArmorClass: 12,
        enemyShieldActive: true,
        enemyShieldReactionUsed: true,
        enemyShieldSlotsRemaining: 0,
      );
      final withShield = _campaign(engine, encounter: confirmed);
      final requested = engine.act(withShield, 'Ich greife an').campaign;
      expect(requested.pendingRoll!.difficulty, 17);
      expect(requested.encounter!.enemyShieldActive, isTrue);
    },
  );

  test(
    'Unbestätigte oder verbrauchte Reaktion verändert weder Würfel noch Zustand',
    () {
      final random = _FixedRandom();
      final engine = GameEngine(dice: DiceEngine(random: random));
      final before = _campaign(engine);
      for (final reject in [
        () => _cast(engine, before, components: false),
        () => _cast(engine, before, slots: null),
        () => _cast(engine, before, slots: 0),
        () => _cast(engine, before, noShield: true),
        () => _cast(
          engine,
          before.copyWith(
            encounter: before.encounter!.copyWith(
              enemyShieldReactionUsed: true,
            ),
          ),
        ),
        () => _cast(
          engine,
          before.copyWith(
            encounter: before.encounter!.copyWith(enemyShieldSlotsRemaining: 0),
          ),
        ),
        () => _cast(
          engine,
          before.copyWith(
            encounter: before.encounter!.copyWith(enemyShieldSlotsRemaining: 1),
          ),
          slots: 2,
        ),
      ]) {
        expect(reject, throwsFormatException);
      }
      expect(before.hero.spentSpellSlots, isEmpty);
      expect(before.encounter!.enemyHitPoints, 80);
      expect(random.calls, 0);
    },
  );

  test(
    'Legacy ohne Schilddaten bleibt unbekannt; manipulierte Daten scheitern',
    () {
      final old = const Encounter(
        id: 'old',
        enemyName: 'Alt',
        enemyHitPoints: 10,
        enemyMaxHitPoints: 10,
      ).toJson();
      expect(old.containsKey('enemyShieldSlotsRemaining'), isFalse);
      final resumed = Encounter.fromJson(old);
      expect(resumed.enemyShieldSlotsRemaining, isNull);
      expect(resumed.enemyShieldActive, isFalse);
      expect(resumed.enemyShieldReactionUsed, isFalse);
      final valid = Encounter.fromJson({
        ...old,
        'enemyShieldSlotsRemaining': 0,
        'enemyShieldReactionUsed': true,
        'enemyShieldActive': true,
      });
      expect(valid.enemyShieldSlotsRemaining, 0);
      expect(Encounter.fromJson(valid.toJson()).enemyShieldActive, isTrue);
      for (final invalid in [
        {'enemyShieldSlotsRemaining': -1},
        {'enemyShieldSlotsRemaining': '5'},
        {'enemyShieldSlotsRemaining': 100},
        {'enemyShieldActive': true},
        {'enemyShieldActive': true, 'enemyShieldReactionUsed': true},
      ]) {
        expect(
          () => Encounter.fromJson({...old, ...invalid}),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'Bereits aktives Schild verhindert späteren Schaden ohne zweite Reaktion',
    () {
      final engine = GameEngine(dice: DiceEngine(random: _FixedRandom()));
      final encounter = const Encounter(
        id: 'active',
        enemyName: 'Gegner',
        enemyHitPoints: 80,
        enemyMaxHitPoints: 80,
        enemyShieldActive: true,
        enemyShieldReactionUsed: true,
        enemyShieldSlotsRemaining: 1,
      );
      final result = _cast(
        engine,
        _campaign(engine, encounter: encounter),
        shield: false,
        noShield: true,
        slots: null,
      );
      expect(result.events.single.payload['damage'], 0);
      expect(result.events.single.payload['shieldReactionTriggered'], isFalse);
      expect(result.campaign.encounter!.enemyShieldSlotsRemaining, 1);
    },
  );
}
