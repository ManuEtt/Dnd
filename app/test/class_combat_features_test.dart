import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/class_combat_features.dart';

class OneRandom implements Random {
  @override int nextInt(int max) => 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

void main() {
  test('Champion critical threshold is based on Fighter class level', () {
    HeroCharacter hero(int level, String subclass) => HeroCharacter(
        id: 'f', name: 'Kämpfer', className: 'Kämpfer', level: level,
        subclass: subclass);
    expect(ClassCombatFeatures.weaponCriticalThreshold(hero(2, 'Champion')),20);
    expect(ClassCombatFeatures.weaponCriticalThreshold(hero(3, 'Champion')),19);
    expect(ClassCombatFeatures.weaponCriticalThreshold(hero(15,'Champion')),18);
    expect(ClassCombatFeatures.weaponCriticalThreshold(hero(20,'Battle Master')),20);
    final nineteen = DiceEngine(random: OneRandom()).check(
        modifier: 0, natural: 19);
    expect(RulesEngine.attack(roll: nineteen,armorClass:100,
        criticalThreshold:19).critical,true);
    expect(RulesEngine.attack(roll: nineteen,armorClass:100).hit,false);
  });

  test('Sneak Attack is gated by weapon, advantage and turn use', () {
    final rogue = HeroCharacter(id:'r',name:'Dieb',className:'Schurke',
      level:5,weaponProficient:true,equippedWeaponId:'one',
      inventory: const [InventoryItem(id:'one',name:'Dolch',
        catalogId:'weapon-dagger')]);
    int dice({bool a=false,bool d=false,bool ally=false,bool used=false}) =>
      ClassCombatFeatures.eligibleSneakAttackDice(rogue,
        hasAdvantage:a,hasDisadvantage:d,
        adjacentConsciousAlly:ally,alreadyUsedThisTurn:used);
    expect(dice(a:true),3);
    expect(dice(ally:true),3);
    expect(dice(a:true,d:true),0);
    expect(dice(ally:true,d:true),0);
    expect(dice(a:true,d:true,ally:true),3);
    expect(dice(a:true,used:true),0);
    final roll=ClassCombatFeatures.rollSneakAttack(
       DiceEngine(random:OneRandom()),3,critical:true);
    expect(roll.rolls.length,6);
    expect(roll.total,6);
    expect(() => ClassCombatFeatures.rollSneakAttack(
       DiceEngine(random:OneRandom()),11),throwsRangeError);
  });
}
