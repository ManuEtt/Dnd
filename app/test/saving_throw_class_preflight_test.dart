import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';

class _CountingRandom implements Random {
  _CountingRandom([this.natural = 4]);
  final int natural;
  int draws = 0;

  @override
  int nextInt(int max) {
    draws++;
    return (natural - 1) % max;
  }

  @override
  bool nextBool() => throw UnsupportedError('Only d20 expected');
  @override
  double nextDouble() => throw UnsupportedError('Only d20 expected');
}

HeroCharacter _hero({
  String primary = 'Fighter',
  int level = 14,
  String secondary = '',
  int secondaryLevel = 0,
  List<String> proficiencies = const ['constitution'],
}) => HeroCharacter(
  id: 'reroll-profile',
  name: 'Bestätigter Charakter',
  className: primary,
  level: level,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  abilities: const {
    'strength': 14,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 14,
    'charisma': 10,
  },
  savingThrowProficiencies: proficiencies,
  hitPoints: 30,
  maxHitPoints: 40,
);

void main() {
  final invalidProfiles = <String, HeroCharacter>{
    'unconfirmed primary with Monk 14': _hero(
      primary: 'Historische Klasse',
      level: 15,
      secondary: 'Monk',
      secondaryLevel: 14,
    ),
    'unconfirmed primary with Fighter 9': _hero(
      primary: 'Historische Klasse',
      level: 10,
      secondary: 'Fighter',
      secondaryLevel: 9,
    ),
    'unknown secondary': _hero(
      level: 15,
      secondary: 'Unbestätigt',
      secondaryLevel: 1,
    ),
    'same canonical Monk twice': _hero(
      primary: 'Mönch',
      secondary: 'MONK',
      secondaryLevel: 7,
    ),
    'same canonical Fighter twice': _hero(
      level: 10,
      secondary: 'Kämpferin',
      secondaryLevel: 5,
    ),
    'named secondary with no level': _hero(secondary: 'Wizard'),
    'unnamed secondary has levels': _hero(secondaryLevel: 1),
    'negative secondary level': _hero(secondaryLevel: -1),
    'no primary level': _hero(secondary: 'Wizard', secondaryLevel: 14),
    'zero total level': _hero(level: 0),
    'total above SRD limit': _hero(level: 21),
    'duplicate recorded proficiency': _hero(
      proficiencies: const ['constitution', 'constitution'],
    ),
    'unknown recorded proficiency': _hero(
      proficiencies: const ['constitution', 'flying'],
    ),
    'invisible character is not a class alias': _hero(primary: '\u202eFighter'),
  };

  group('Invalid saving-throw reroll profiles', () {
    for (final entry in invalidProfiles.entries) {
      for (final feature in SavingThrowRerollFeature.values) {
        test('${entry.key}: $feature fails before RNG or resource spend', () {
          final hero = entry.value;
          final before = jsonEncode(hero.toJson());
          final random = _CountingRandom();
          expect(SavingThrowClassActions.available(hero, feature), isFalse);
          expect(
            () => SavingThrowClassActions.rerollFailed(
              hero: hero,
              dice: DiceEngine(random: random),
              ability: 'constitution',
              difficulty: 20,
              originalTotal: 3,
              feature: feature,
            ),
            throwsFormatException,
          );
          expect(random.draws, 0);
          expect(jsonEncode(hero.toJson()), before);
        });
      }
    }
  });

  group('All twelve confirmed classes can participate in valid splits', () {
    for (final entry in srdCharacterClasses) {
      for (final feature in SavingThrowRerollFeature.values) {
        test('${entry.name}: $feature keeps its exact class bonus', () {
          final monk = feature == SavingThrowRerollFeature.disciplinedSurvivor;
          final featureClass = monk ? 'Mönch' : 'Kämpfer';
          final featureLevel = monk ? 14 : 9;
          final single = entry.name == featureClass;
          final hero = _hero(
            primary: entry.name,
            level: featureLevel + (single ? 0 : 1),
            secondary: single ? '' : featureClass,
            secondaryLevel: single ? 0 : featureLevel,
          );
          final before = jsonEncode(hero.toJson());
          final random = _CountingRandom();
          expect(SavingThrowClassActions.available(hero, feature), isTrue);
          final result = SavingThrowClassActions.rerollFailed(
            hero: hero,
            dice: DiceEngine(random: random),
            ability: 'constitution',
            difficulty: 25,
            originalTotal: 3,
            feature: feature,
          );
          // CON +2; PB +5 for Monk 14, +4 for Fighter 9, no double training.
          expect(result.roll.modifier, monk ? 7 : 15);
          expect(result.roll.total, monk ? 11 : 19);
          expect(result.fighterLevelBonus, monk ? 0 : 9);
          expect(result.passed, isFalse);
          expect(result.hero.spentClassResources, {
            monk ? 'focusPoints' : 'indomitable': 1,
          });
          expect(random.draws, 1);
          expect(jsonEncode(hero.toJson()), before);
        });
      }
    }
  });

  for (final primary in ['Mönch', 'Monk', 'moench', ' MÖNCHIN ']) {
    for (final feature in SavingThrowRerollFeature.values) {
      test('$primary/Fighter: aliases, training and exhaustion apply once', () {
        final hero = _hero(
          primary: primary,
          level: 20,
          secondary: ' KAEMPFER ',
          secondaryLevel: 6,
        ).copyWith(exhaustionLevel: 1);
        if (feature == SavingThrowRerollFeature.indomitable) {
          expect(SavingThrowClassActions.available(hero, feature), isFalse);
          return; // Fighter 6 does not unlock Indomitable at total level 20.
        }
        final random = _CountingRandom(1);
        final result = SavingThrowClassActions.rerollFailed(
          hero: hero,
          dice: DiceEngine(random: random),
          ability: 'constitution',
          difficulty: 20,
          originalTotal: 10,
          feature: feature,
          extraModifier: 2,
        );
        // +2 CON +6 PB -2 Exhaustion +2 confirmed cover; new total is worse.
        expect(result.roll.modifier, 8);
        expect(result.roll.total, 9);
        expect(result.passed, isFalse);
        expect(random.draws, 1);
        expect(result.hero.className, primary);
        expect(result.hero.secondaryClassName, ' KAEMPFER ');
      });
    }
  }

  test(
    'availability stays false for dead, unknown-HP and exhausted resources',
    () {
      for (final hero in [
        _hero().copyWith(hitPoints: 0),
        _hero().copyWith(conditions: const ['tot']),
        _hero().copyWith(hitPoints: null),
        _hero().copyWith(spentClassResources: const {'indomitable': 2}),
      ]) {
        expect(
          SavingThrowClassActions.available(
            hero,
            SavingThrowRerollFeature.indomitable,
          ),
          isFalse,
        );
      }
    },
  );

  test('automatic save failure consumes neither a reroll nor a die', () {
    final random = _CountingRandom();
    final hero = _hero().copyWith(conditions: const ['bewusstlos']);
    expect(
      () => SavingThrowClassActions.rerollFailed(
        hero: hero,
        dice: DiceEngine(random: random),
        ability: 'strength',
        difficulty: 20,
        originalTotal: 0,
        feature: SavingThrowRerollFeature.indomitable,
      ),
      throwsStateError,
    );
    expect(random.draws, 0);
    expect(hero.spentClassResources, isEmpty);
  });
}
