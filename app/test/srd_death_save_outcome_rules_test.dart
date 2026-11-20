import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_death_save_outcome_rules.dart';

HeroCharacter fallen({
  int successes = 0,
  int failures = 0,
  String className = 'Kämpfer',
  int level = 1,
}) => HeroCharacter(
  id: 'preview-death',
  name: 'Testheld',
  className: className,
  level: level,
  hitPoints: 0,
  maxHitPoints: 20,
  deathSuccesses: successes,
  deathFailures: failures,
  conditions: const ['bewusstlos', 'liegend'],
);

void main() {
  test('ordinary death save: ten successes and ten failures', () {
    final hero = fallen();
    final result = SrdDeathSaveOutcomeRules.preview(hero);
    expect(result.successfulRolls, 11); // 10..20
    expect(result.failedRolls, 9); // 1..9
    expect(result.stabilizingRolls, 0);
    expect(result.fatalRolls, 0);
    expect(result.regainingHitPointsRolls, 1);
    expect(result.revivalProbability, 0.05);
    expect(hero.deathSuccesses, 0);
    expect(hero.deathFailures, 0);
  });

  test('third success stabilizes; natural 20 restores one hit point', () {
    final result = SrdDeathSaveOutcomeRules.preview(fallen(successes: 2));
    expect(result.stabilizingRolls, 10); // 10..19
    expect(result.regainingHitPointsRolls, 1);
  });

  test('two failures make natural 1 and other failures fatal', () {
    final result = SrdDeathSaveOutcomeRules.preview(fallen(failures: 2));
    expect(result.fatalRolls, 9);
    expect(result.deathProbability, 0.45);
  });

  test('one failure makes natural 1 immediately fatal', () {
    final result = SrdDeathSaveOutcomeRules.preview(fallen(failures: 1));
    expect(result.fatalRolls, 1);
  });

  test('class bonus affects ordinary successes, not natural 1', () {
    final result = SrdDeathSaveOutcomeRules.preview(
      fallen(className: 'Mönch', level: 14),
    );
    expect(result.successfulRolls, 16); // 5..20
    expect(result.failedRolls, 4);
  });

  test('ineligible characters are rejected by canonical resolver', () {
    expect(
      () => SrdDeathSaveOutcomeRules.preview(fallen().copyWith(hitPoints: 1)),
      throwsStateError,
    );
    expect(
      () => SrdDeathSaveOutcomeRules.preview(fallen(failures: 3)),
      throwsStateError,
    );
  });
}
