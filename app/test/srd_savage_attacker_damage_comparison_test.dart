import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_savage_attacker_damage_comparison.dart';

DiceResult rolled(String expression, List<int> faces, {int modifier = 0}) =>
    DiceResult(
      expression: expression,
      rolls: faces,
      modifier: modifier,
      total: faces.fold<int>(modifier, (sum, value) => sum + value),
    );

HeroCharacter soldier({
  String damage = '2d6+3',
  List<String> features = const [],
  bool equippedGreatsword = false,
}) {
  final demo = GameEngine().createDemo().hero;
  return demo.copyWith(
    background: SrdBackground.soldier.label,
    startingBackgroundPackage: SrdBackgroundPackageChoice(
      background: SrdBackground.soldier,
      takeGold: true,
      gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
    ),
    className: 'Kämpfer',
    level: 1,
    features: features,
    weaponDamage: damage,
    weaponAbility: 'strength',
    abilities: const {
      'strength': 16,
      'dexterity': 12,
      'constitution': 14,
      'intelligence': 10,
      'wisdom': 10,
      'charisma': 10,
    },
    equippedWeaponId: equippedGreatsword ? 'greatsword' : '',
    inventory: equippedGreatsword
        ? const [
            InventoryItem(
              id: 'greatsword',
              name: 'Zweihandschwert',
              catalogId: 'weapon-greatsword',
            ),
          ]
        : const [],
  );
}

const fight = Encounter(
  id: 'target-1',
  enemyName: 'Wächter',
  enemyHitPoints: 75,
  enemyMaxHitPoints: 75,
);

SavageAttackerDamageComparison preview({
  HeroCharacter? hero,
  Encounter encounter = fight,
  bool chooseAlternative = true,
  bool hit = true,
  bool weapon = true,
  bool critical = false,
  DiceResult? original,
  DiceResult? alternative,
  DiceResult? originalCriticalExtra,
  DiceResult? alternativeCriticalExtra,
  String expression = '2d6+3',
}) => SrdSavageAttackerDamageComparisonRules.compare(
  hero: hero ?? soldier(),
  encounter: encounter,
  weaponDamageExpression: expression,
  original: original ?? rolled('2d6+3', [1, 2], modifier: 3),
  alternative: alternative ?? rolled('2d6+3', [5, 6], modifier: 3),
  confirmedWeaponHit: hit,
  confirmedWeaponAttack: weapon,
  chooseAlternative: chooseAlternative,
  critical: critical,
  originalCriticalExtra: originalCriticalExtra,
  alternativeCriticalExtra: alternativeCriticalExtra,
);

void main() {
  test('original and alternative use real weapon rules, bonuses once', () {
    final high = preview();
    expect(high.originalWeaponSubtotal, 9);
    expect(high.alternativeWeaponSubtotal, 17);
    expect(high.selectedWeaponSubtotal, 17);
    expect(high.selectedDifference, 8);
    expect(high.choice.weaponFlatModifier, 3);
    final low = preview(chooseAlternative: false);
    expect(low.selectedWeaponSubtotal, 9);
    expect(low.selectedDifference, 0);
    expect(low.choice.usedAlternative, false);
  });

  test(
    'critical dice add two different pools without repeating flat bonus',
    () {
      final compared = preview(
        critical: true,
        originalCriticalExtra: rolled('2d6+3', [6, 2], modifier: 3),
        alternativeCriticalExtra: rolled('2d6+3', [3, 1], modifier: 3),
      );
      expect(compared.originalWeaponSubtotal, 17);
      expect(compared.alternativeWeaponSubtotal, 21);
      expect(compared.selectedWeaponSubtotal, 21);
      expect(compared.selectedDifference, 4);
    },
  );

  test('great weapon fighting changes each candidate independently', () {
    final hero = soldier(
      damage: '2d6',
      features: const ['Kampfstil: Kampf mit großen Waffen'],
      equippedGreatsword: true,
    );
    final original = rolled('2d6', [1, 2]);
    final alternative = rolled('2d6', [3, 6]);
    final compared = preview(
      hero: hero,
      original: original,
      alternative: alternative,
      expression: '2d6',
    );
    expect(RulesEngine.weaponDamageSubtotal(hero, baseRoll: original), 9);
    expect(RulesEngine.weaponDamageSubtotal(hero, baseRoll: alternative), 12);
    expect(compared.originalWeaponSubtotal, 9);
    expect(compared.alternativeWeaponSubtotal, 12);
    expect(compared.selectedDifference, 3);
    // Dice totals differ by 6, not 3: the Fighting Style must be reapplied.
    expect(
      compared.choice.alternativeWeaponDiceTotal -
          compared.choice.originalWeaponDiceTotal,
      6,
    );
  });

  test('critical great weapon fighting is applied to each critical set', () {
    final hero = soldier(
      damage: '2d6',
      features: const ['Kampfstil: Kampf mit großen Waffen'],
      equippedGreatsword: true,
    );
    final compared = preview(
      hero: hero,
      expression: '2d6',
      original: rolled('2d6', [1, 2]),
      alternative: rolled('2d6', [3, 6]),
      critical: true,
      originalCriticalExtra: rolled('2d6', [1, 1]),
      alternativeCriticalExtra: rolled('2d6', [2, 6]),
    );
    expect(compared.originalWeaponSubtotal, 15);
    expect(compared.alternativeWeaponSubtotal, 21);
    expect(compared.selectedDifference, 6);
  });

  test('no state mutation, no target HP commit or resource spending', () {
    final hero = soldier();
    final heroBefore = hero.toJson();
    final encounterBefore = fight.toJson();
    preview(hero: hero, encounter: fight);
    expect(hero.toJson(), heroBefore);
    expect(fight.toJson(), encounterBefore);
    expect(fight.enemyHitPoints, 75);
    expect(fight.savageAttackerUsedThisTurn, false);
  });

  test('missing feat, spent turn, enemy turn and KO fail closed', () {
    final hero = soldier();
    expect(
      () => preview(hero: hero.copyWith(startingBackgroundPackage: null)),
      throwsFormatException,
    );
    expect(
      () =>
          preview(encounter: fight.copyWith(savageAttackerUsedThisTurn: true)),
      throwsFormatException,
    );
    expect(
      () => preview(encounter: fight.copyWith(activeParticipant: 'enemy')),
      throwsFormatException,
    );
    expect(
      () => preview(hero: hero.copyWith(hitPoints: 0)),
      throwsFormatException,
    );
  });

  test('no fabricated weapon expression, misses or spells', () {
    expect(() => preview(expression: '2d6'), throwsFormatException);
    expect(() => preview(hit: false), throwsFormatException);
    expect(() => preview(weapon: false), throwsFormatException);
    expect(
      () => preview(alternative: rolled('2d6+3', [7, 1], modifier: 3)),
      throwsFormatException,
    );
    expect(() => preview(critical: true), throwsFormatException);
  });
}
