import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/death_saving_throw_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';

HeroCharacter fallen({
  String className = 'Kämpfer',
  int level = 1,
  String secondary = '',
  int secondaryLevel = 0,
  int exhaustion = 0,
  int successes = 0,
  int failures = 0,
  Map<String, int> spent = const {},
}) => HeroCharacter(
  id: 'death-save-hero',
  name: 'Liora',
  className: className,
  level: level,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 0,
  maxHitPoints: 30,
  temporaryHitPoints: 5,
  exhaustionLevel: exhaustion,
  deathSuccesses: successes,
  deathFailures: failures,
  spentClassResources: spent,
  conditions: const ['bewusstlos', 'liegend'],
);

void main() {
  group('SRD 5.2.1: Todesrettungswürfe', () {
    test(
      'Kein Attribut und keine normale Rettungswurfübung werden addiert',
      () {
        final hero = fallen().copyWith(
          abilities: {for (final ability in abilityNames) ability: 30},
          savingThrowProficiencies: abilityNames,
        );
        final result = DeathSavingThrowRules.resolve(hero: hero, natural: 9);
        expect(result.roll.modifier, 0);
        expect(result.roll.total, 9);
        expect(result.passed, isFalse);
        expect(result.hero.deathFailures, 1);
        expect(result.originalHero, same(hero));
        expect(hero.deathFailures, 0);
        expect(result.hero.temporaryHitPoints, 5);
      },
    );

    test('Mönch ab Stufe 14 erhält Gesamtstufen-Übungsbonus genau einmal', () {
      expect(
        DeathSavingThrowRules.modifier(fallen(className: 'Mönch', level: 13)),
        0,
      );
      final hero = fallen(className: 'Mönch', level: 14);
      final result = DeathSavingThrowRules.resolve(hero: hero, natural: 5);
      expect(result.roll.modifier, 5);
      expect(result.passed, isTrue);
      expect(result.hero.deathSuccesses, 1);
      expect(RulesEngine.deathSave(hero, 5).deathSuccesses, 1);
      expect(hero.savingThrowProficiencies, isEmpty);
    });

    test(
      'Zweitklasse und Klassenalias sind berechnet; Gesamtstufe allein nicht',
      () {
        expect(
          DeathSavingThrowRules.modifier(
            fallen(
              className: 'Paladin',
              level: 17,
              secondary: 'monk',
              secondaryLevel: 14,
            ),
          ),
          6,
        );
        expect(
          DeathSavingThrowRules.modifier(
            fallen(
              className: 'Paladin',
              level: 14,
              secondary: 'Mönch',
              secondaryLevel: 13,
            ),
          ),
          0,
        );
      },
    );

    test('Erschöpfung betrifft den Gesamtwert, nicht den Naturwurf', () {
      final hero = fallen(className: 'Mönch', level: 14, exhaustion: 2);
      final result = DeathSavingThrowRules.resolve(hero: hero, natural: 8);
      expect(result.roll.natural, 8);
      expect(result.roll.modifier, 1);
      expect(result.roll.total, 9);
      expect(result.passed, isFalse);
      expect(result.hero.deathFailures, 1);
    });

    test(
      'Natürliche 1 gibt zwei Fehlschläge; natürliche 20 heilt und setzt zurück',
      () {
        final failed = DeathSavingThrowRules.resolve(
          hero: fallen(className: 'Mönch', level: 20),
          natural: 1,
        );
        expect(failed.hero.deathFailures, 2);
        expect(failed.passed, isFalse);
        final healed = DeathSavingThrowRules.resolve(
          hero: fallen(exhaustion: 5, successes: 2, failures: 2),
          natural: 20,
        );
        expect(healed.roll.total, 10);
        expect(healed.hero.hitPoints, 1);
        expect(healed.hero.deathSuccesses, 0);
        expect(healed.hero.deathFailures, 0);
        expect(healed.hero.conditions, ['liegend']);
        expect(healed.passed, isTrue);
      },
    );

    test('Dritter Erfolg stabilisiert und setzt beide Zähler zurück', () {
      final result = DeathSavingThrowRules.resolve(
        hero: fallen(successes: 2, failures: 2),
        natural: 10,
      );
      expect(result.hero.conditions, contains('stabil'));
      expect(result.hero.hitPoints, 0);
      expect(result.hero.deathSuccesses, 0);
      expect(result.hero.deathFailures, 0);
      expect(result.hero.isDead, isFalse);
    });

    test('Dritter Fehlschlag ist zunächst nur ein vorläufiges Ergebnis', () {
      final hero = fallen(className: 'Kämpfer', level: 9, failures: 2);
      final result = DeathSavingThrowRules.resolve(hero: hero, natural: 2);
      expect(result.hero.isDead, isTrue);
      expect(hero.isDead, isFalse);
      expect(hero.deathFailures, 2);
      expect(
        DeathSavingThrowRules.canReroll(
          result,
          SavingThrowRerollFeature.indomitable,
        ),
        isTrue,
      );
    });

    test('Lebend mit TP, stabil oder tot erhält keinen weiteren Wurf', () {
      for (final hero in [
        fallen().copyWith(hitPoints: 1),
        fallen().copyWith(conditions: ['bewusstlos', 'stabil']),
        fallen().copyWith(conditions: ['bewusstlos', 'tot']),
        fallen(exhaustion: 6),
        fallen().copyWith(maxHitPoints: 0),
        HeroCharacter(id: 'unknown', name: 'Unbestätigt'),
      ]) {
        expect(
          () => DeathSavingThrowRules.resolve(hero: hero, natural: 10),
          throwsStateError,
        );
      }
    });

    test(
      'Ungültige Würfel, Klassenstufen, Erschöpfung und Zähler werden verworfen',
      () {
        for (final natural in [0, 21]) {
          expect(
            () =>
                DeathSavingThrowRules.resolve(hero: fallen(), natural: natural),
            throwsRangeError,
          );
        }
        for (final hero in [
          fallen(level: 0),
          fallen(level: 21),
          fallen(secondaryLevel: 1),
          fallen(secondary: 'Mönch'),
          fallen(
            className: 'Mönch',
            level: 20,
            secondary: 'monk',
            secondaryLevel: 6,
          ),
          fallen(failures: 3),
          fallen(successes: 3),
          fallen(failures: -1),
        ]) {
          expect(
            () => DeathSavingThrowRules.resolve(hero: hero, natural: 10),
            throwsStateError,
          );
        }
        expect(
          () => DeathSavingThrowRules.resolve(
            hero: fallen(exhaustion: -1),
            natural: 10,
          ),
          throwsRangeError,
        );
      },
    );
  });

  group('SRD 5.2.1: gewählte Todesrettungswurf-Wiederholung', () {
    test(
      'Unbeugsam ersetzt tödliches Ergebnis und verbraucht bei 0 TP einmal',
      () {
        final hero = fallen(className: 'Kämpfer', level: 9, failures: 2);
        final original = DeathSavingThrowRules.resolve(hero: hero, natural: 1);
        final result = DeathSavingThrowRules.rerollFailed(
          original: original,
          natural: 2,
          feature: SavingThrowRerollFeature.indomitable,
        );
        expect(original.hero.isDead, isTrue);
        expect(result.originalHero, same(hero));
        expect(result.originalRoll.natural, 1);
        expect(result.roll.natural, 2);
        expect(result.roll.modifier, 9);
        expect(result.roll.total, 11);
        expect(result.fighterLevelBonus, 9);
        expect(result.passed, isTrue);
        expect(result.hero.deathFailures, 2);
        expect(result.hero.deathSuccesses, 1);
        expect(result.hero.isDead, isFalse);
        expect(result.hero.hitPoints, 0);
        expect(result.resource, 'indomitable');
        expect(result.hero.spentClassResources['indomitable'], 1);
        expect(hero.spentClassResources, isEmpty);
        expect(HeroCharacter.fromJson(result.hero.toJson()).deathFailures, 2);
        expect(
          () => ClassResourceRules.spend(hero, 'indomitable'),
          throwsStateError,
        );
      },
    );

    test('Kämpferbonus benutzt die tatsächliche Zweitklassenstufe', () {
      final result = DeathSavingThrowRules.rerollFailed(
        original: DeathSavingThrowRules.resolve(
          hero: fallen(
            className: 'Paladin',
            level: 12,
            secondary: 'fighter',
            secondaryLevel: 9,
            exhaustion: 2,
          ),
          natural: 2,
        ),
        natural: 4,
        feature: SavingThrowRerollFeature.indomitable,
      );
      expect(result.fighterLevelBonus, 9);
      expect(result.roll.modifier, 5);
      expect(result.roll.total, 9);
      expect(result.hero.deathFailures, 1);
    });

    test(
      'Natürliche 1 bleibt trotz Unbeugsam-Gesamtwert 21 zwei Fehlschläge',
      () {
        final result = DeathSavingThrowRules.rerollFailed(
          original: DeathSavingThrowRules.resolve(
            hero: fallen(level: 20),
            natural: 2,
          ),
          natural: 1,
          feature: SavingThrowRerollFeature.indomitable,
        );
        expect(result.roll.total, 21);
        expect(result.passed, isFalse);
        expect(result.hero.deathFailures, 2);
        expect(result.hero.isDead, isFalse);
      },
    );

    test('Mönch 14 gibt Fokus aus und ersetzt Fehlschlag durch Heilung', () {
      final result = DeathSavingThrowRules.rerollFailed(
        original: DeathSavingThrowRules.resolve(
          hero: fallen(className: 'Mönch', level: 14, failures: 2),
          natural: 1,
        ),
        natural: 20,
        feature: SavingThrowRerollFeature.disciplinedSurvivor,
      );
      expect(result.hero.hitPoints, 1);
      expect(result.hero.isDead, isFalse);
      expect(result.hero.deathFailures, 0);
      expect(result.hero.deathSuccesses, 0);
      expect(result.hero.conditions, ['liegend']);
      expect(result.hero.spentClassResources['focusPoints'], 1);
      expect(result.roll.modifier, 5);
      expect(result.resource, 'focusPoints');
      expect(result.fighterLevelBonus, 0);
    });

    test(
      'Mönchwiederholung mit schlechterer natürlicher 1 ersetzt nur den Wurf',
      () {
        final result = DeathSavingThrowRules.rerollFailed(
          original: DeathSavingThrowRules.resolve(
            hero: fallen(
              className: 'Mönch',
              level: 14,
              failures: 1,
              exhaustion: 3,
            ),
            natural: 8,
          ),
          natural: 1,
          feature: SavingThrowRerollFeature.disciplinedSurvivor,
        );
        expect(result.hero.deathFailures, 3);
        expect(result.hero.isDead, isTrue);
        expect(result.hero.spentClassResources['focusPoints'], 1);
      },
    );

    test('Wiederholung kann den dritten Erfolg und Stabilisierung ergeben', () {
      final result = DeathSavingThrowRules.rerollFailed(
        original: DeathSavingThrowRules.resolve(
          hero: fallen(level: 9, successes: 2, failures: 2),
          natural: 2,
        ),
        natural: 2,
        feature: SavingThrowRerollFeature.indomitable,
      );
      expect(result.hero.conditions, contains('stabil'));
      expect(result.hero.deathSuccesses, 0);
      expect(result.hero.deathFailures, 0);
      expect(result.hero.spentClassResources['indomitable'], 1);
    });

    test(
      'Erfolgreicher Wurf und bereits wiederholter Wurf sind abgeschlossen',
      () {
        final successful = DeathSavingThrowRules.resolve(
          hero: fallen(level: 17),
          natural: 10,
        );
        final rerolled = DeathSavingThrowRules.rerollFailed(
          original: DeathSavingThrowRules.resolve(
            hero: fallen(level: 17),
            natural: 2,
          ),
          natural: 1,
          feature: SavingThrowRerollFeature.indomitable,
        );
        // Two more charges remain, but the same die cannot be rerolled again.
        expect(ClassResourceRules.remaining(rerolled.hero, 'indomitable'), 2);
        for (final result in [successful, rerolled]) {
          expect(
            DeathSavingThrowRules.canReroll(
              result,
              SavingThrowRerollFeature.indomitable,
            ),
            isFalse,
          );
          expect(
            () => DeathSavingThrowRules.rerollFailed(
              original: result,
              natural: 20,
              feature: SavingThrowRerollFeature.indomitable,
            ),
            throwsStateError,
          );
        }
      },
    );

    test(
      'Mindestklassenstufen und erschöpfte Nutzungen werden eingehalten',
      () {
        for (final (hero, feature) in [
          (fallen(level: 8), SavingThrowRerollFeature.indomitable),
          (
            fallen(className: 'Mönch', level: 13),
            SavingThrowRerollFeature.disciplinedSurvivor,
          ),
          (
            fallen(level: 9, spent: {'indomitable': 1}),
            SavingThrowRerollFeature.indomitable,
          ),
          (
            fallen(className: 'Mönch', level: 14, spent: {'focusPoints': 14}),
            SavingThrowRerollFeature.disciplinedSurvivor,
          ),
        ]) {
          final original = DeathSavingThrowRules.resolve(
            hero: hero,
            natural: 1,
          );
          expect(DeathSavingThrowRules.available(hero, feature), isFalse);
          expect(
            () => DeathSavingThrowRules.rerollFailed(
              original: original,
              natural: 20,
              feature: feature,
            ),
            throwsStateError,
          );
        }
      },
    );

    test(
      'Tote und stabile Figuren können keine Wiederholungsressourcen anbieten',
      () {
        for (final conditions in [
          ['bewusstlos', 'tot'],
          ['bewusstlos', 'stabil'],
        ]) {
          expect(
            DeathSavingThrowRules.available(
              fallen(level: 9).copyWith(conditions: conditions),
              SavingThrowRerollFeature.indomitable,
            ),
            isFalse,
          );
        }
      },
    );

    test(
      'Ungültige Wiederholung verbraucht nichts und wirft keinen gültigen Wurf',
      () {
        final original = DeathSavingThrowRules.resolve(
          hero: fallen(level: 9),
          natural: 2,
        );
        expect(
          () => DeathSavingThrowRules.rerollFailed(
            original: original,
            natural: 21,
            feature: SavingThrowRerollFeature.indomitable,
          ),
          throwsRangeError,
        );
        expect(original.originalHero.spentClassResources, isEmpty);
      },
    );
  });
}
