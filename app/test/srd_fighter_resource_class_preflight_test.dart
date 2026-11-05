import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_feature_resources.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _CountingRandom implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls += 1;
    return 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({
  String primary = 'Kämpfer',
  String secondary = '',
  int secondaryLevel = 0,
  int level = 6,
  int spentWind = 0,
  int spentSurge = 0,
}) => HeroCharacter(
  id: 'fighter-class-preflight',
  name: 'Klassenprobe',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 10,
  maxHitPoints: 35,
  spentSecondWind: spentWind,
  spentActionSurge: spentSurge,
);

void main() {
  group('Kämpfer-Ressourcen nur bei gültigem SRD-Klassenprofil', () {
    final invalid = <String, HeroCharacter>{
      'Fighter und Kämpfer als doppelte Klasse': _hero(
        primary: 'Fighter',
        secondary: 'Kämpfer',
        secondaryLevel: 6,
        level: 12,
      ),
      'unbekannte Hauptklasse vor Fighter': _hero(
        primary: 'Unbekannt',
        secondary: 'Fighter',
        secondaryLevel: 5,
        level: 10,
      ),
      'unbekannte Nebenklasse nach Fighter': _hero(
        secondary: 'Unbekannt',
        secondaryLevel: 2,
      ),
      'fehlender Name für die Nebenklassenstufe': _hero(secondaryLevel: 2),
      'Nebenklasse ohne eigene Stufe': _hero(secondary: 'Wizard'),
      'Hauptklasse ohne eigene Stufe': _hero(
        primary: 'Wizard',
        secondary: 'Fighter',
        secondaryLevel: 6,
        level: 6,
      ),
      'negative Nebenklassenstufe': _hero(secondaryLevel: -1),
      'Gesamtlevel null': _hero(level: 0),
      'Gesamtlevel über zwanzig': _hero(level: 21),
    };

    for (final entry in invalid.entries) {
      test('${entry.key}: keine Kämpferfähigkeiten oder Würfel', () {
        final hero = entry.value;
        final before = hero.toJson();
        final random = _CountingRandom();

        expect(ClassFeatureResources.fighterLevel(hero), 0);
        expect(ClassFeatureResources.secondWindMaximum(hero), 0);
        expect(ClassFeatureResources.actionSurgeMaximum(hero), 0);
        expect(ClassFeatureResources.remainingSecondWind(hero), 0);
        expect(ClassFeatureResources.remainingActionSurge(hero), 0);
        expect(
          () => ClassFeatureResources.useSecondWind(
            hero,
            DiceEngine(random: random),
          ),
          throwsStateError,
        );
        expect(
          () => ClassFeatureResources.spendActionSurge(hero),
          throwsStateError,
        );
        expect(random.calls, 0);
        expect(hero.toJson(), before);
        expect(hero.spentSecondWind, 0);
        expect(hero.spentActionSurge, 0);
      });
    }

    test('invalid spent fighter resource blocks rest recovery', () {
      final hero = _hero(
        primary: 'Fighter',
        secondary: 'Kämpfer',
        secondaryLevel: 3,
        spentWind: 1,
      );
      final snapshot = hero.toJson();
      expect(
        () => ClassFeatureResources.validate(hero),
        throwsFormatException,
      );
      expect(
        () => ClassFeatureResources.afterShortRest(hero),
        throwsFormatException,
      );
      expect(
        () => ClassFeatureResources.afterLongRest(hero),
        throwsFormatException,
      );
      expect(hero.toJson(), snapshot);
      expect(hero.spentSecondWind, 1);
    });

    test('englischer Fighter-Alias Stufe 17 behält beide Ressourcen', () {
      final hero = _hero(primary: 'Fighter', level: 17);
      final original = hero.toJson();
      final random = _CountingRandom();

      expect(ClassFeatureResources.fighterLevel(hero), 17);
      expect(ClassFeatureResources.secondWindMaximum(hero), 4);
      expect(ClassFeatureResources.actionSurgeMaximum(hero), 2);
      final healed = ClassFeatureResources.useSecondWind(
        hero,
        DiceEngine(random: random),
      );
      expect(random.calls, 1);
      expect(healed.totalHealing, 18);
      expect(healed.hero.hitPoints, 28);
      expect(healed.hero.spentSecondWind, 1);
      final surged = ClassFeatureResources.spendActionSurge(healed.hero);
      expect(surged.spentActionSurge, 1);
      expect(hero.toJson(), original);
      final reloaded = HeroCharacter.fromJson(surged.toJson());
      expect(reloaded.toJson(), surged.toJson());
    });

    test('Fighter als zweite Klasse nutzt nur deren Stufen', () {
      final hero = _hero(
        primary: 'Wizard',
        secondary: 'Fighter',
        secondaryLevel: 10,
        level: 13,
      );
      final original = hero.toJson();
      expect(ClassFeatureResources.fighterLevel(hero), 10);
      expect(ClassFeatureResources.secondWindMaximum(hero), 4);
      expect(ClassFeatureResources.actionSurgeMaximum(hero), 1);

      final surged = ClassFeatureResources.spendActionSurge(hero);
      expect(surged.spentActionSurge, 1);
      final rested = ClassFeatureResources.afterShortRest(surged);
      expect(rested.spentActionSurge, 0);
      expect(rested.spentSecondWind, 0);
      expect(hero.toJson(), original);
    });

    test('eine andere Klasse bekommt keine Kämpferressourcen', () {
      final hero = _hero(primary: 'Magier', level: 5);
      expect(ClassFeatureResources.fighterLevel(hero), 0);
      expect(ClassFeatureResources.secondWindMaximum(hero), 0);
      expect(ClassFeatureResources.actionSurgeMaximum(hero), 0);
      expect(
        () => ClassFeatureResources.spendActionSurge(hero),
        throwsStateError,
      );
    });

    test('Kämpfer Stufe eins bekommt nur Zweite Luft', () {
      final hero = _hero(level: 1);
      expect(ClassFeatureResources.fighterLevel(hero), 1);
      expect(ClassFeatureResources.secondWindMaximum(hero), 2);
      expect(ClassFeatureResources.actionSurgeMaximum(hero), 0);
      expect(
        () => ClassFeatureResources.spendActionSurge(hero),
        throwsStateError,
      );
    });
  });
}
