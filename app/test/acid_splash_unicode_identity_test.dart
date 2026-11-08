import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/acid_splash_rules.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _CountingRandom implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return max - 1;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _hero() => HeroCharacter(
  id: 'acid-caster',
  name: 'Ari',
  className: 'Magier',
  level: 5,
  spells: const ['Säurespritzer'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 25,
  maxHitPoints: 25,
  armorClass: 13,
  speed: 9,
  weaponDamage: '1d4',
);

AcidSplashTarget _target({String id = 'enemy-1', String name = 'Wächter'}) =>
    AcidSplashTarget(
      id: id,
      name: name,
      hitPoints: 20,
      maxHitPoints: 20,
      dexteritySaveModifier: 0,
      cover: CoverLevel.none,
      sourceOppositeCover: false,
      coverRelationshipConfirmed: true,
      inSphereConfirmed: true,
      effectPathConfirmed: true,
      noAcidDamageAdjustmentConfirmed: true,
      saveCircumstancesConfirmed: true,
    );

AcidSplashResult _cast(
  HeroCharacter hero,
  _CountingRandom random, {
  required AcidSplashTarget target,
}) => AcidSplashRules.cast(
  hero,
  dice: DiceEngine(random: random),
  castingClass: 'Magier',
  targets: [target],
  sphereOriginWithinRangeConfirmed: true,
  everyCreatureInSphereIncludedConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noUnmodelledDcModifiersConfirmed: true,
);

void main() {
  test('international visible target IDs and names remain unchanged', () {
    final hero = _hero();
    final original = jsonEncode(hero.toJson());
    final random = _CountingRandom();
    final result = _cast(
      hero,
      random,
      target: _target(id: 'drache-Ä-α', name: 'Drächin 🐉'),
    );
    expect(result.targets.single.id, 'drache-Ä-α');
    expect(result.targets.single.name, 'Drächin 🐉');
    expect(result.targets.single.toJson()['targetName'], 'Drächin 🐉');
    expect(result.dc, 14);
    expect(result.targets.single.save.succeeded, isTrue);
    expect(result.damageRoll, isNull);
    expect(random.calls, 1);
    expect(jsonEncode(hero.toJson()), original);
  });

  test('invisible controls in IDs or names fail before the first roll', () {
    final hero = _hero();
    final original = jsonEncode(hero.toJson());
    final random = _CountingRandom();
    const controls = <String>[
      '\u0085',
      '\u00AD',
      '\u034F',
      '\u061C',
      '\u180E',
      '\u200B',
      '\u200D',
      '\u200F',
      '\u2028',
      '\u2029',
      '\u202A',
      '\u202E',
      '\u2060',
      '\u2066',
      '\u2069',
      '\u206A',
      '\u206F',
      '\uFEFF',
      '\uFFF9',
      '\uFFFB',
    ];
    for (final control in controls) {
      expect(
        () => _cast(hero, random, target: _target(id: 'enemy' + control + '1')),
        throwsFormatException,
        reason:
            'Hidden target ID control ' +
            control.runes.single.toRadixString(16),
      );
      expect(
        () => _cast(
          hero,
          random,
          target: _target(name: 'Wächter' + control + 'A'),
        ),
        throwsFormatException,
        reason:
            'Hidden target name control ' +
            control.runes.single.toRadixString(16),
      );
    }
    expect(random.calls, 0);
    expect(jsonEncode(hero.toJson()), original);
  });

  test('an invalid secondary area target prevents all dice', () {
    final random = _CountingRandom();
    final hero = _hero();
    final before = jsonEncode(hero.toJson());
    expect(
      () => AcidSplashRules.cast(
        hero,
        dice: DiceEngine(random: random),
        castingClass: 'Magier',
        targets: [
          _target(id: 'safe', name: 'Alva'),
          _target(id: 'second', name: 'Fremd\u202Ename'),
        ],
        sphereOriginWithinRangeConfirmed: true,
        everyCreatureInSphereIncludedConfirmed: true,
        verbalComponentConfirmed: true,
        somaticComponentConfirmed: true,
        noUnmodelledDcModifiersConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(random.calls, 0);
    expect(jsonEncode(hero.toJson()), before);
  });

  test('encounter rejects hidden ID without events, HP or dice', () {
    final random = _CountingRandom();
    final engine = GameEngine(dice: DiceEngine(random: random));
    final initial = engine.createDemo().copyWith(
      hero: _hero(),
      encounter: const Encounter(
        id: 'enemy\u2066-1',
        enemyName: 'Wächter',
        enemyHitPoints: 20,
        enemyMaxHitPoints: 20,
        enemyArmorClass: 14,
      ),
    );
    final before = jsonEncode(initial.toJson());
    expect(
      () => engine.castAcidSplash(
        initial,
        castingClass: 'Magier',
        confirmedTargetDexteritySaveModifier: 0,
        originWithin60FeetConfirmed: true,
        currentEnemyIsOnlyCreatureInSphereConfirmed: true,
        verbalComponentConfirmed: true,
        somaticComponentConfirmed: true,
        noUnmodelledDcModifiersConfirmed: true,
        targetSaveCircumstancesConfirmed: true,
        targetCoverRelationshipConfirmed: true,
        effectPathConfirmed: true,
        noAcidDamageAdjustmentConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(random.calls, 0);
    expect(jsonEncode(initial.toJson()), before);
    expect(initial.encounter!.enemyHitPoints, 20);
  });
}
