import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_ranger_tireless_rules.dart';

class _CountingRandom implements Random {
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

HeroCharacter _ranger(int? wisdom) => HeroCharacter(
  id: 'ranger-wisdom',
  name: 'Alva',
  className: 'Waldläufer',
  level: 10,
  abilities: {
    'strength': 12,
    'dexterity': 14,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': wisdom,
    'charisma': 10,
  },
  hitPoints: 12,
  maxHitPoints: 20,
);

void main() {
  test('invalid Wisdom cannot grant Tireless uses or roll dice', () {
    for (final wisdom in <int?>[null, -1, 0, 31, 100]) {
      final hero = _ranger(wisdom);
      final before = hero.toJson();
      final random = _CountingRandom();
      expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(hero), 0);
      expect(
        () => SrdRangerTirelessRules.useTemporaryHitPoints(
          hero,
          DiceEngine(random: random),
        ),
        throwsStateError,
      );
      expect(random.calls, 0);
      expect(hero.toJson(), before);
    }
  });

  test('minimum valid Wisdom still grants one use', () {
    final hero = _ranger(1);
    expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(hero), 1);
    final random = _CountingRandom();
    final result = SrdRangerTirelessRules.useTemporaryHitPoints(
      hero,
      DiceEngine(random: random),
    );
    expect(random.calls, 1);
    expect(result.usesRemaining, 0);
    expect(result.rolledTemporaryHitPoints, 1);
    expect(hero.spentClassResources, isEmpty);
  });
}
