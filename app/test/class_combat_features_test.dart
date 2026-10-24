import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/class_combat_features.dart';

class OneRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  test('Champion critical threshold is based on Fighter class level', () {
    HeroCharacter hero(int level, String subclass) => HeroCharacter(
      id: 'f',
      name: 'Kämpfer',
      className: 'Kämpfer',
      level: level,
      subclass: subclass,
    );
    expect(
      ClassCombatFeatures.weaponCriticalThreshold(hero(2, 'Champion')),
      20,
    );
    expect(
      ClassCombatFeatures.weaponCriticalThreshold(hero(3, 'Champion')),
      19,
    );
    expect(
      ClassCombatFeatures.weaponCriticalThreshold(hero(15, 'Champion')),
      18,
    );
    expect(
      ClassCombatFeatures.weaponCriticalThreshold(hero(20, 'Battle Master')),
      20,
    );
    final nineteen = DiceEngine(
      random: OneRandom(),
    ).check(modifier: 0, natural: 19);
    expect(
      RulesEngine.attack(
        roll: nineteen,
        armorClass: 100,
        criticalThreshold: 19,
      ).critical,
      true,
    );
    expect(RulesEngine.attack(roll: nineteen, armorClass: 100).hit, false);
  });

  test('Sneak Attack is gated by weapon, advantage and turn use', () {
    final rogue = HeroCharacter(
      id: 'r',
      name: 'Dieb',
      className: 'Schurke',
      level: 5,
      weaponProficient: true,
      equippedWeaponId: 'one',
      inventory: const [
        InventoryItem(id: 'one', name: 'Dolch', catalogId: 'weapon-dagger'),
      ],
    );
    int dice({
      bool a = false,
      bool d = false,
      bool ally = false,
      bool nearTarget = true,
      bool allyCanAct = true,
      bool used = false,
    }) => ClassCombatFeatures.eligibleSneakAttackDice(
      rogue,
      hasAdvantage: a,
      hasDisadvantage: d,
      adjacentConsciousAlly: ally,
      allyWithinFiveFeetOfTargetConfirmed: nearTarget,
      allyNotIncapacitatedConfirmed: allyCanAct,
      alreadyUsedThisTurn: used,
    );
    expect(dice(a: true), 3);
    expect(dice(ally: true), 3);
    expect(dice(a: true, d: true), 0);
    expect(dice(ally: true, d: true), 0);
    expect(dice(a: true, d: true, ally: true), 3);
    expect(dice(a: true, used: true), 0);
    // Being conscious does not prove the ally can act (e.g. Stunned).
    expect(dice(ally: true, allyCanAct: false), 0);
    // An ally adjacent to the rogue, but not the target, does not qualify.
    expect(dice(ally: true, nearTarget: false), 0);
    expect(dice(ally: true, nearTarget: false, allyCanAct: false), 0);
    // An independently confirmed Advantage still permits Sneak Attack.
    expect(dice(a: true, ally: true, nearTarget: false), 3);
    expect(dice(a: true, ally: true, allyCanAct: false), 3);
    // Canceled Advantage must not bypass unconfirmed ally criteria.
    expect(dice(a: true, d: true, ally: true, nearTarget: false), 0);
    expect(dice(a: true, d: true, ally: true, allyCanAct: false), 0);
    final roll = ClassCombatFeatures.rollSneakAttack(
      DiceEngine(random: OneRandom()),
      3,
      critical: true,
    );
    expect(roll.rolls.length, 6);
    expect(roll.total, 6);
    expect(
      () => ClassCombatFeatures.rollSneakAttack(
        DiceEngine(random: OneRandom()),
        11,
      ),
      throwsRangeError,
    );
  });

  test('Sneak Attack uses only the explicitly attacking inventory weapon', () {
    final rogue = HeroCharacter(
      id: 'r',
      name: 'Dieb',
      className: 'Schurke',
      level: 5,
      equippedWeaponId: 'axe',
      inventory: const [
        InventoryItem(id: 'axe', name: 'Handaxt', catalogId: 'weapon-handaxe'),
        InventoryItem(id: 'dagger', name: 'Dolch', catalogId: 'weapon-dagger'),
      ],
    );
    int eligible(HeroCharacter hero, {String? weaponId}) =>
        ClassCombatFeatures.eligibleSneakAttackDice(
          hero,
          attackingWeaponId: weaponId,
          hasAdvantage: true,
          hasDisadvantage: false,
          adjacentConsciousAlly: false,
          alreadyUsedThisTurn: false,
        );

    expect(eligible(rogue), 0);
    expect(eligible(rogue, weaponId: 'dagger'), 3);
    final daggerPrimary = rogue.copyWith(equippedWeaponId: 'dagger');
    expect(eligible(daggerPrimary), 3);
    expect(eligible(daggerPrimary, weaponId: 'axe'), 0);
    // An explicit missing weapon must never fall back to the primary dagger.
    expect(eligible(daggerPrimary, weaponId: ''), 0);
    expect(eligible(daggerPrimary, weaponId: 'missing'), 0);
    expect(
      eligible(
        daggerPrimary.copyWith(
          inventory: [...rogue.inventory, rogue.inventory.last],
        ),
        weaponId: 'dagger',
      ),
      0,
    );
    expect(
      eligible(
        daggerPrimary.copyWith(
          inventory: const [
            InventoryItem(
              id: 'dagger',
              name: 'Dolch',
              catalogId: 'weapon-dagger',
              quantity: 0,
            ),
          ],
        ),
        weaponId: 'dagger',
      ),
      0,
    );
  });
}
