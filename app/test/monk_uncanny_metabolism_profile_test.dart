import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/rules/rules_api.dart';

class _CountingRandom implements Random {
  final bounds = <int>[];

  @override
  int nextInt(int max) {
    bounds.add(max);
    return 3 % max;
  }

  @override
  bool nextBool() => throw UnsupportedError('Only dice are expected.');

  @override
  double nextDouble() => throw UnsupportedError('Only dice are expected.');
}

HeroCharacter _monk({int level = 2}) => HeroCharacter(
  id: 'metabolism-profile',
  name: 'Liora',
  className: 'Mönch',
  level: level,
  hitPoints: 10,
  maxHitPoints: 30,
  spentClassResources: {'focusPoints': level},
);

void main() {
  group('Unheimlicher Stoffwechsel prüft das bestätigte Klassenprofil', () {
    final invalid = <String, HeroCharacter>{
      'unbekannte erste Klasse': _monk().copyWith(
        className: 'Unbekannt',
        level: 4,
        secondaryClassName: 'Monk',
        secondaryClassLevel: 2,
      ),
      'unbekannte zweite Klasse': _monk().copyWith(
        level: 4,
        secondaryClassName: 'Unbekannt',
        secondaryClassLevel: 2,
      ),
      'gleiche Klasse mit übersetztem Alias': _monk().copyWith(
        level: 4,
        secondaryClassName: 'Monk',
        secondaryClassLevel: 2,
      ),
      'ausgewählte Zweitklasse ohne Stufe': _monk().copyWith(
        secondaryClassName: 'Fighter',
      ),
      'Zweitklassenstufe ohne Klasse': _monk().copyWith(secondaryClassLevel: 1),
      'negative Zweitklassenstufe': _monk().copyWith(
        secondaryClassName: 'Fighter',
        secondaryClassLevel: -1,
      ),
      'Gesamtstufe null': _monk().copyWith(level: 0),
      'negative Gesamtstufe': _monk().copyWith(level: -1),
      'Gesamtstufe über zwanzig': _monk().copyWith(level: 21),
      'keine verbleibende erste Klassenstufe': _monk().copyWith(
        secondaryClassName: 'Fighter',
        secondaryClassLevel: 2,
      ),
      'Zweitklasse über Gesamtstufe': _monk().copyWith(
        secondaryClassName: 'Fighter',
        secondaryClassLevel: 3,
      ),
    };

    for (final entry in invalid.entries) {
      test('${entry.key}: kein Wurf und keine Ressourcenänderung', () {
        final hero = entry.value;
        final spent = Map<String, int>.of(hero.spentClassResources);
        final random = _CountingRandom();
        expect(
          () => MonkInitiativeFeatures.onInitiative(
            hero,
            useUncannyMetabolism: true,
            dice: DiceEngine(random: random),
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'deutscher Klassenfehler',
              'Die bestätigten Klassen und Stufen sind nicht konsistent.',
            ),
          ),
        );
        expect(random.bounds, isEmpty);
        expect(hero.spentClassResources, spent);
        expect(hero.hitPoints, 10);
      });
    }

    for (final alias in ['Mönch', 'Monk', 'monk', ' MONK ']) {
      test('Bestätigter Klassenalias $alias bleibt benutzbar', () {
        final random = _CountingRandom();
        final hero = _monk().copyWith(className: alias);
        final result = MonkInitiativeFeatures.onInitiative(
          hero,
          useUncannyMetabolism: true,
          dice: DiceEngine(random: random),
        );
        expect(random.bounds, [6]);
        expect(result.martialArtsDieRoll, 4);
        expect(result.hero.hitPoints, 16);
        expect(result.focusRecovered, 2);
        expect(result.hero.spentClassResources, {'uncannyMetabolism': 1});
        expect(hero.hitPoints, 10);
        expect(hero.spentClassResources, {'focusPoints': 2});
      });
    }

    for (final secondaryMonk in [false, true]) {
      test('Mehrklasse mit Mönch als ${secondaryMonk ? 2 : 1}. Klasse', () {
        final hero = _monk().copyWith(
          className: secondaryMonk ? 'Fighter' : 'Monk',
          secondaryClassName: secondaryMonk ? 'Monk' : 'Fighter',
          secondaryClassLevel: secondaryMonk ? 2 : 9,
          level: 11,
          spentClassResources: {'focusPoints': 2, 'indomitable': 1},
        );
        final random = _CountingRandom();
        final result = MonkInitiativeFeatures.onInitiative(
          hero,
          useUncannyMetabolism: true,
          dice: DiceEngine(random: random),
        );
        expect(random.bounds, [6]);
        expect(result.hero.hitPoints, 16);
        expect(result.hero.spentClassResources, {
          'indomitable': 1,
          'uncannyMetabolism': 1,
        });
        expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 2);
      });
    }

    for (final entry in {2: 6, 5: 8, 11: 10, 15: 10, 17: 12, 20: 12}.entries) {
      test('Klassenstufe ${entry.key}: richtiger Würfel und TP-Obergrenze', () {
        final hero = _monk(level: entry.key).copyWith(hitPoints: 29);
        final random = _CountingRandom();
        final result = MonkInitiativeFeatures.onInitiative(
          hero,
          useUncannyMetabolism: true,
          dice: DiceEngine(random: random),
        );
        expect(random.bounds, [entry.value]);
        expect(result.hitPointsRecovered, 1);
        expect(result.hero.hitPoints, 30);
        expect(result.focusRecovered, entry.key);
        expect(result.hero.spentClassResources, {'uncannyMetabolism': 1});
      });
    }

    test(
      'Ohne Einwilligung keine Heilung, kein Stoffwechsel und kein Wurf',
      () {
        final hero = _monk();
        final random = _CountingRandom();
        final result = MonkInitiativeFeatures.onInitiative(
          hero,
          dice: DiceEngine(random: random),
        );
        expect(result.hero, same(hero));
        expect(result.uncannyMetabolismUsed, false);
        expect(result.martialArtsDieRoll, isNull);
        expect(random.bounds, isEmpty);
      },
    );

    test('Vorprüfung liefert nur bestätigte Werte und verändert nichts', () {
      final hero = _monk(
        level: 5,
      ).copyWith(spentClassResources: {'focusPoints': 3});
      final before = hero.toJson();
      expect(MonkInitiativeFeatures.prepareUncannyMetabolism(hero), (
        monkLevel: 5,
        remainingFocus: 2,
        martialArtsDieSides: 8,
      ));
      expect(hero.toJson(), before);
    });

    for (final spent in [-1, 3]) {
      test('Ungültiger Fokusverbrauch $spent scheitert vor dem Wurf', () {
        final hero = _monk().copyWith(
          spentClassResources: {'focusPoints': spent},
        );
        final random = _CountingRandom();
        expect(
          () => MonkInitiativeFeatures.onInitiative(
            hero,
            useUncannyMetabolism: true,
            dice: DiceEngine(random: random),
          ),
          throwsFormatException,
        );
        expect(random.bounds, isEmpty);
        expect(hero.spentClassResources, {'focusPoints': spent});
      });
    }
  });
}
