import 'dart:convert';
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

HeroCharacter _ranger() => HeroCharacter(
  id: 'verified-ranger',
  name: 'Waldläufer-Profil',
  className: 'Waldläufer',
  level: 10,
  abilities: const {'wisdom': 16},
  hitPoints: 20,
  maxHitPoints: 30,
  exhaustionLevel: 2,
);

void main() {
  test('unbestätigte Klassenprofile verleihen weder Tireless noch Wurf', () {
    final base = _ranger();
    final invalid = <HeroCharacter>[
      base.copyWith(
        className: 'Unbekannt',
        secondaryClassName: 'Ranger',
        secondaryClassLevel: 10,
        level: 12,
      ),
      base.copyWith(
        className: 'Ranger',
        secondaryClassName: 'Waldläufer',
        secondaryClassLevel: 5,
        level: 15,
      ),
      base.copyWith(
        secondaryClassName: 'Unbekannt',
        secondaryClassLevel: 1,
        level: 11,
      ),
      base.copyWith(secondaryClassLevel: 1, level: 11),
      base.copyWith(
        className: 'Fighter',
        secondaryClassName: 'Waldläufer',
        secondaryClassLevel: 10,
        level: 10,
      ),
      base.copyWith(level: 21),
      base.copyWith(level: 0),
    ];
    for (final hero in invalid) {
      final before = jsonEncode(hero.toJson());
      final random = _CountingRandom();
      expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(hero), 0);
      expect(SrdRangerTirelessRules.canReduceExhaustion(hero), isFalse);
      expect(
        SrdRangerTirelessRules.afterShortRest(hero).toJson(),
        hero.toJson(),
      );
      expect(
        () => SrdRangerTirelessRules.useTemporaryHitPoints(
          hero,
          DiceEngine(random: random),
        ),
        throwsFormatException,
      );
      expect(random.calls, 0);
      expect(jsonEncode(hero.toJson()), before);
    }
  });

  test('gültiger Waldläufer-Alias behält Unermüdlich ab Stufe zehn', () {
    final ranger = _ranger().copyWith(className: 'Ranger');
    expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(ranger), 3);
    expect(SrdRangerTirelessRules.canReduceExhaustion(ranger), isTrue);
    final shortRest = SrdRangerTirelessRules.afterShortRest(ranger);
    expect(shortRest.exhaustionLevel, 1);
    expect(ranger.exhaustionLevel, 2);
    final random = _CountingRandom();
    final magic = SrdRangerTirelessRules.useTemporaryHitPoints(
      ranger,
      DiceEngine(random: random),
    );
    expect(random.calls, 1);
    expect(magic.rolledTemporaryHitPoints, 4);
    expect(magic.usesRemaining, 2);
    expect(
      magic.hero.spentClassResources[SrdRangerTirelessRules.resourceKey],
      1,
    );
  });

  test('gültiger Mehrklassen-Waldläufer nutzt eigene Klassenstufe', () {
    final multiclass = _ranger().copyWith(
      className: 'Fighter',
      secondaryClassName: 'Ranger',
      secondaryClassLevel: 10,
      level: 12,
    );
    expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(multiclass), 3);
    expect(
      SrdRangerTirelessRules.afterShortRest(multiclass).exhaustionLevel,
      1,
    );
    final magic = SrdRangerTirelessRules.useTemporaryHitPoints(
      multiclass,
      DiceEngine(random: _CountingRandom()),
    );
    expect(magic.hero.temporaryHitPoints, 4);
    expect(magic.hero.level, 12);
    expect(multiclass.spentClassResources, isEmpty);
    final belowLevel = multiclass.copyWith(secondaryClassLevel: 9, level: 11);
    expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(belowLevel), 0);
    expect(SrdRangerTirelessRules.canReduceExhaustion(belowLevel), isFalse);
  });
}
