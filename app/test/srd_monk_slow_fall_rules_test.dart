import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/rules/rules_api.dart';

HeroCharacter slowFallMonk({
  String className = 'Mönch',
  int level = 4,
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
  int? hitPoints = 20,
  List<String> conditions = const [],
}) => HeroCharacter(
  id: 'slow-fall-monk',
  name: 'Leiser Schritt',
  className: className,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  level: level,
  maxHitPoints: 20,
  hitPoints: hitPoints,
  speed: 9,
  armorClass: 13,
  conditions: conditions,
  abilities: const {
    'strength': 10,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 16,
    'charisma': 10,
  },
);

SrdMonkSlowFallResult preflight(
  HeroCharacter hero, {
  int? damage = 37,
  bool fall = true,
  bool freeReaction = true,
  bool approved = true,
  Encounter? encounter,
}) => SrdMonkSlowFallRules.previewConfirmedReaction(
  hero,
  confirmedFallDamage: damage,
  fallConfirmed: fall,
  reactionAvailable: freeReaction,
  reactionConfirmed: approved,
  encounter: encounter,
);

void main() {
  test('Only Monk class level 4+ unlocks five times Monk level', () {
    expect(SrdMonkSlowFallRules.maximumReduction(slowFallMonk(level: 3)), isNull);
    for (final level in [4, 5, 10, 20]) {
      expect(
        SrdMonkSlowFallRules.maximumReduction(slowFallMonk(level: level)),
        level * 5,
      );
    }
    expect(
      SrdMonkSlowFallRules.maximumReduction(
        slowFallMonk(className: 'Kämpfer', level: 20),
      ),
      isNull,
    );
  });

  test('Confirmed falling damage is reduced without negative HP/damage', () {
    final monk = slowFallMonk();
    final exact = preflight(monk, damage: 20);
    expect(exact.monkClassLevel, 4);
    expect(exact.confirmedFallDamage, 20);
    expect(exact.maximumReduction, 20);
    expect(exact.preventedDamage, 20);
    expect(exact.remainingDamage, 0);

    final small = preflight(monk, damage: 7);
    expect(small.preventedDamage, 7);
    expect(small.remainingDamage, 0);

    final large = preflight(monk, damage: 37);
    expect(large.preventedDamage, 20);
    expect(large.remainingDamage, 17);
    expect(preflight(monk, damage: 0).remainingDamage, 0);
  });

  test('Multiclass uses Monk class levels, not total character level', () {
    final mixed = slowFallMonk(
      className: 'Kämpfer',
      secondaryClassName: 'Mönch',
      secondaryClassLevel: 4,
      level: 7,
    );
    expect(SrdMonkSlowFallRules.maximumReduction(mixed), 20);
    expect(preflight(mixed, damage: 40).remainingDamage, 20);
    final below = mixed.copyWith(
      level: 6,
      secondaryClassLevel: 3,
    );
    expect(SrdMonkSlowFallRules.maximumReduction(below), isNull);
    expect(() => preflight(below), throwsFormatException);

    final primary = slowFallMonk(
      secondaryClassName: 'Magier',
      secondaryClassLevel: 3,
      level: 7,
    );
    expect(SrdMonkSlowFallRules.maximumReduction(primary), 20);
  });

  test('Unknown fall, unknown damage, consent and Reaction fail closed', () {
    final monk = slowFallMonk();
    expect(() => preflight(monk, damage: null), throwsFormatException);
    expect(() => preflight(monk, damage: -1), throwsFormatException);
    expect(() => preflight(monk, damage: 1000001), throwsFormatException);
    expect(() => preflight(monk, fall: false), throwsFormatException);
    expect(() => preflight(monk, freeReaction: false), throwsFormatException);
    expect(() => preflight(monk, approved: false), throwsFormatException);
  });

  test('Encounter cannot reuse an already spent Reaction', () {
    const encounter = Encounter(
      id: 'slow-fall-encounter',
      enemyName: 'Wache',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      reactionUsed: true,
    );
    final hero = slowFallMonk();
    expect(
      () => preflight(hero, encounter: encounter),
      throwsFormatException,
    );
    expect(encounter.reactionUsed, isTrue);
    final unused = encounter.copyWith(reactionUsed: false);
    expect(preflight(hero, encounter: unused).remainingDamage, 17);
    expect(unused.reactionUsed, false);
  });

  test('Incapacitation or unconfirmed HP forbids a Reaction', () {
    for (final condition in [
      'bewusstlos',
      'handlungsunfähig',
      'gelähmt',
      'versteinert',
      'betäubt',
    ]) {
      final hero = slowFallMonk(conditions: [condition]);
      expect(() => preflight(hero), throwsFormatException);
    }
    expect(
      () => preflight(slowFallMonk(hitPoints: null)),
      throwsFormatException,
    );
    expect(() => preflight(slowFallMonk(hitPoints: 0)), throwsFormatException);
  });

  test('Preflight never mutates HP, reaction, class resources or JSON', () {
    final hero = slowFallMonk();
    const encounter = Encounter(
      id: 'fall-audit',
      enemyName: 'Wache',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      reactionUsed: false,
    );
    final heroBefore = hero.toJson();
    final combatBefore = encounter.toJson();
    final plan = preflight(hero, damage: 32, encounter: encounter);
    expect(plan.remainingDamage, 12);
    expect(hero.toJson(), heroBefore);
    expect(encounter.toJson(), combatBefore);
    final canonical = HeroCharacter.fromJson(heroBefore).toJson();
    expect(HeroCharacter.fromJson(canonical).toJson(), canonical);
    expect(
      SrdMonkSlowFallRules.maximumReduction(HeroCharacter.fromJson(canonical)),
      20,
    );
  });
}
