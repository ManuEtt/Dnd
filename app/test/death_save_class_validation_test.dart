import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/death_saving_throw_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';

HeroCharacter _fallen({
  String primary = 'Kämpfer',
  int level = 20,
  String secondary = '',
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'class-proof',
  name: 'Bestätigter Charakter',
  className: primary,
  level: level,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 0,
  maxHitPoints: 40,
  deathFailures: 1,
  conditions: const ['bewusstlos', 'liegend'],
);

void _expectUnconfirmedClassesRejected(HeroCharacter hero) {
  final before = jsonEncode(hero.toJson());
  expect(() => DeathSavingThrowRules.modifier(hero), throwsFormatException);
  expect(
    () => DeathSavingThrowRules.resolve(hero: hero, natural: 4),
    throwsFormatException,
  );
  expect(() => RulesEngine.deathSave(hero, 4), throwsFormatException);
  for (final feature in SavingThrowRerollFeature.values) {
    expect(
      () => DeathSavingThrowRules.available(hero, feature),
      throwsFormatException,
    );
  }
  expect(jsonEncode(hero.toJson()), before);
}

void main() {
  group('SRD death saves require confirmed class identities', () {
    for (final unknown in [
      '',
      'Unbestätigt',
      'Mönch (Hausregel)',
      '\u202eMönch',
    ]) {
      test('unknown primary "$unknown" cannot authorize Monk 14', () {
        _expectUnconfirmedClassesRejected(
          _fallen(primary: unknown, secondary: 'Mönch', secondaryLevel: 14),
        );
      });
      test('unknown primary "$unknown" cannot authorize Fighter 9', () {
        _expectUnconfirmedClassesRejected(
          _fallen(primary: unknown, secondary: 'Kämpfer', secondaryLevel: 9),
        );
      });
    }

    for (final unknown in ['Unbestätigt', ' ', 'fighter?', '\u202eMönch']) {
      for (final known in ['Mönch', 'Kämpfer']) {
        test('$known with unknown secondary "$unknown" is rejected', () {
          _expectUnconfirmedClassesRejected(
            _fallen(primary: known, secondary: unknown, secondaryLevel: 6),
          );
        });
      }
    }

    test(
      'unconfirmed single class does not silently receive a basic SRD roll',
      () {
        _expectUnconfirmedClassesRejected(
          _fallen(primary: 'Historische Klasse'),
        );
      },
    );

    for (final entry in srdCharacterClasses) {
      test(
        '${entry.name}: valid single class keeps its proper death-save rule',
        () {
          final hero = _fallen(primary: entry.name);
          final result = DeathSavingThrowRules.resolve(hero: hero, natural: 4);
          final monk = entry.name == 'Mönch';
          expect(result.roll.modifier, monk ? 6 : 0);
          expect(result.passed, monk);
          expect(result.hero.deathSuccesses, monk ? 1 : 0);
          expect(result.hero.deathFailures, monk ? 1 : 2);
          expect(
            DeathSavingThrowRules.available(
              hero,
              SavingThrowRerollFeature.disciplinedSurvivor,
            ),
            monk,
          );
          expect(
            DeathSavingThrowRules.available(
              hero,
              SavingThrowRerollFeature.indomitable,
            ),
            entry.name == 'Kämpfer',
          );
        },
      );

      if (entry.name != 'Mönch') {
        test(
          '${entry.name}/Monk: total proficiency with Monk class level 14',
          () {
            final hero = _fallen(
              primary: entry.name,
              secondary: 'monk',
              secondaryLevel: 14,
            );
            final result = DeathSavingThrowRules.resolve(
              hero: hero,
              natural: 4,
            );
            expect(result.roll.modifier, 6);
            expect(result.passed, isTrue);
            expect(hero.deathSuccesses, 0);
          },
        );
      }
    }

    for (final (primary, secondary) in [
      ('Mönchin', 'fighter'),
      ('moench', 'Kämpferin'),
      (' MONK ', ' KAEMPFER '),
    ]) {
      test('canonical aliases $primary/$secondary retain Focus reroll', () {
        final hero = _fallen(
          primary: primary,
          secondary: secondary,
          secondaryLevel: 6,
        );
        final failed = DeathSavingThrowRules.resolve(hero: hero, natural: 1);
        final rerolled = DeathSavingThrowRules.rerollFailed(
          original: failed,
          natural: 4,
          feature: SavingThrowRerollFeature.disciplinedSurvivor,
        );
        expect(rerolled.roll.modifier, 6);
        expect(rerolled.passed, isTrue);
        expect(rerolled.hero.spentClassResources, {'focusPoints': 1});
        expect(rerolled.hero.deathFailures, 1);
        expect(hero.spentClassResources, isEmpty);
      });
    }

    test('known duplicate class aliases still fail their level validation', () {
      expect(
        () => DeathSavingThrowRules.resolve(
          hero: _fallen(primary: 'Mönch', secondary: 'monk', secondaryLevel: 6),
          natural: 4,
        ),
        throwsStateError,
      );
    });

    test(
      'historical unknown names remain readable and unchanged in Hero JSON',
      () {
        for (final hero in [
          _fallen(primary: 'Historische Klasse'),
          _fallen(
            primary: 'Unbestätigt',
            secondary: 'Mönch',
            secondaryLevel: 14,
          ),
          _fallen(primary: 'Mönch', secondary: 'Historisch', secondaryLevel: 6),
        ]) {
          final before = jsonEncode(hero.toJson());
          final restored = HeroCharacter.fromJson(
            jsonDecode(before) as Map<String, dynamic>,
          );
          expect(jsonEncode(restored.toJson()), before);
          _expectUnconfirmedClassesRejected(restored);
        }
      },
    );
  });
}
