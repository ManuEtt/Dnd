import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_savage_attacker_rules.dart';

HeroCharacter soldier({bool confirmed = true, String background = 'Soldat'}) =>
    HeroCharacter(
      id: 'soldier',
      name: 'Soldat',
      background: background,
      startingBackgroundPackage: confirmed
          ? SrdBackgroundPackageChoice(
              background: SrdBackground.soldier,
              takeGold: true,
              gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
            )
          : null,
    );

DiceResult evidence(String expression, List<int> rolls, {int modifier = 0}) =>
    DiceResult(
      expression: expression,
      rolls: rolls,
      modifier: modifier,
      total: rolls.fold<int>(modifier, (sum, die) => sum + die),
    );

SavageAttackerChoice choose({
  HeroCharacter? hero,
  bool hit = true,
  bool weapon = true,
  bool used = false,
  bool alternative = true,
  bool critical = false,
  DiceResult? first,
  DiceResult? second,
  DiceResult? firstCrit,
  DiceResult? secondCrit,
  String expression = '2d6+3',
}) => SrdSavageAttackerRules.choose(
  hero: hero ?? soldier(),
  weaponDamageExpression: expression,
  original: first ?? evidence('2d6+3', [2, 3], modifier: 3),
  alternative: second ?? evidence('2d6+3', [5, 6], modifier: 3),
  confirmedWeaponHit: hit,
  confirmedWeaponAttack: weapon,
  alreadyUsedThisTurn: used,
  chooseAlternative: alternative,
  critical: critical,
  originalCriticalExtra: firstCrit,
  alternativeCriticalExtra: secondCrit,
);

void main() {
  test('only confirmed soldier choice grants the feat, never feature text', () {
    expect(SrdSavageAttackerRules.hasConfirmedFeat(soldier()), true);
    final old = soldier(confirmed: false);
    expect(SrdSavageAttackerRules.hasConfirmedFeat(old), false);
    expect(
      SrdSavageAttackerRules.hasConfirmedFeat(
        old.copyWith(features: ['Herkunftstalent: Wilder Angreifer']),
      ),
      false,
    );
    expect(
      SrdSavageAttackerRules.hasConfirmedFeat(
        soldier(background: 'Krimineller'),
      ),
      false,
    );
    expect(() => choose(hero: old), throwsFormatException);
    expect(
      () => choose(hero: soldier(background: 'Weiser')),
      throwsFormatException,
    );
  });

  test('player can choose higher OR lower independent weapon roll', () {
    final high = choose();
    expect(high.originalWeaponDiceTotal, 5);
    expect(high.alternativeWeaponDiceTotal, 11);
    expect(high.selectedWeaponDiceTotal, 11);
    expect(high.selectedWeaponSubtotal, 14);
    expect(high.usedAlternative, true);
    final low = choose(alternative: false);
    expect(low.selectedWeaponDiceTotal, 5);
    expect(low.selectedWeaponSubtotal, 8);
    expect(low.usedAlternative, false);
  });

  test('misses, spells or second activation on same turn are blocked', () {
    expect(() => choose(hit: false), throwsFormatException);
    expect(() => choose(weapon: false), throwsFormatException);
    expect(() => choose(used: true), throwsFormatException);
  });

  test('critical hit compares two complete independent weapon dice pools', () {
    final result = choose(
      critical: true,
      firstCrit: evidence('2d6+3', [6, 6], modifier: 3),
      secondCrit: evidence('2d6+3', [1, 1], modifier: 3),
    );
    expect(result.originalWeaponDiceTotal, 17);
    expect(result.alternativeWeaponDiceTotal, 13);
    expect(result.selectedWeaponSubtotal, 16);
    // Critical dice have no additional flat +3; rage/sneak remain separate.
    expect(result.weaponFlatModifier, 3);
    expect(result.critical, true);
  });

  test('incomplete or spurious critical dice are rejected', () {
    expect(() => choose(critical: true), throwsFormatException);
    expect(
      () => choose(firstCrit: evidence('2d6+3', [1, 2], modifier: 3)),
      throwsFormatException,
    );
    expect(
      () => choose(
        critical: true,
        firstCrit: evidence('2d6+3', [1, 2], modifier: 3),
      ),
      throwsFormatException,
    );
  });

  test('forged totals, wrong dice, modifiers and manual rolls fail closed', () {
    final valid = evidence('2d6+3', [4, 4], modifier: 3);
    final bad = <DiceResult>[
      evidence('2d6+3', [0, 7], modifier: 3),
      evidence('2d6+3', [2], modifier: 3),
      evidence('1d6+3', [2], modifier: 3),
      evidence('2d6+3', [3, 3], modifier: 0),
      DiceResult(expression: '2d6+3', rolls: [2, 2], modifier: 3, total: 99),
      DiceResult(
        expression: 'Manuelles Gesamtergebnis',
        rolls: const [],
        modifier: 0,
        total: 12,
      ),
      DiceResult(
        expression: '2d6+3',
        rolls: [2, 2],
        modifier: 3,
        total: 7,
        natural: 2,
      ),
    ];
    for (final invalid in bad) {
      expect(
        () => choose(first: invalid, second: valid),
        throwsFormatException,
      );
      expect(
        () => choose(first: valid, second: invalid),
        throwsFormatException,
      );
    }
  });

  test('noncanonical, unsupported or out-of-range weapon dice fail', () {
    for (final expression in [
      '0d6',
      '101d6',
      '1d20',
      '1d3',
      '1d6+1001',
      '1d6+0',
      '1W6',
      ' 1d6 ',
    ]) {
      expect(
        () => choose(expression: expression),
        throwsFormatException,
      );
    }
  });

  test('does not mutate source rolls, hero or their JSON state', () {
    final hero = soldier();
    final before = hero.toJson();
    final first = evidence('2d6+3', [1, 6], modifier: 3);
    final originalFaces = first.rolls.toList();
    final proposal = choose(hero: hero, first: first);
    expect(first.rolls, originalFaces);
    expect(hero.toJson(), before);
    expect(HeroCharacter.fromJson(before).toJson(), before);
    expect(proposal.selectedWeaponSubtotal, 14);
  });
}
