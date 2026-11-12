import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_initiative_features.dart';
import 'package:lebendiger_spielleiter/domain/monk_perfect_focus.dart';

HeroCharacter _monk({
  String primary = 'Mönch',
  String secondary = '',
  int level = 15,
  int secondaryLevel = 0,
  int spent = 15,
}) => HeroCharacter(
  id: 'monk-profile',
  name: 'Testfigur',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 35,
  maxHitPoints: 40,
  armorClass: 16,
  speed: 9,
  weaponDamage: '1d8',
  weaponProficient: true,
  abilities: const {
    'strength': 12,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 16,
    'charisma': 16,
  },
  spentClassResources: {'focusPoints': spent},
);

void main() {
  group('Perfekter Fokus benötigt konsistente Klassenstufen', () {
    final invalidProfiles = <String, HeroCharacter>{
      'unbekannte Hauptklasse neben Mönch 15': _monk(
        primary: 'Unbekannte Klasse',
        secondary: 'Monk',
        secondaryLevel: 15,
        level: 17,
      ),
      'unbekannte Zweitklasse neben Mönch 15': _monk(
        secondary: 'Unbekannte Klasse',
        secondaryLevel: 2,
        level: 17,
      ),
      'gleiche Klasse mit deutschem und englischem Alias': _monk(
        secondary: 'Monk',
        secondaryLevel: 2,
        level: 17,
      ),
      'gleiche Klasse mit demselben Namen': _monk(
        secondary: 'Mönch',
        secondaryLevel: 2,
        level: 17,
      ),
      'benannte Zweitklasse ohne Stufe': _monk(secondary: 'Fighter'),
      'Zweitklassenstufe ohne Zweitklasse': _monk(secondaryLevel: 2, level: 17),
      'negative Zweitklassenstufe': _monk(secondaryLevel: -1),
      'negative Gesamtstufe': _monk(level: -1),
      'Gesamtstufe null': _monk(level: 0),
      'Gesamtstufe über 20': _monk(level: 21, spent: 21),
      'Zweitklasse ohne verbleibende Erstklassenstufe': _monk(
        primary: 'Fighter',
        secondary: 'Monk',
        secondaryLevel: 15,
        level: 15,
      ),
      'Zweitklasse höher als Gesamtstufe': _monk(
        primary: 'Fighter',
        secondary: 'Monk',
        secondaryLevel: 16,
        level: 15,
      ),
    };
    for (final entry in invalidProfiles.entries) {
      test('${entry.key}: keine automatische Fokusgutschrift', () {
        final hero = entry.value;
        final before = Map<String, int>.of(hero.spentClassResources);
        final result = MonkPerfectFocus.onInitiative(hero);
        expect(result.recovered, 0);
        expect(result.hero, same(hero));
        expect(hero.spentClassResources, before);
      });
    }

    for (final name in ['Mönch', 'Monk', 'monk', ' MONK ']) {
      test('Bestätigter Alias $name erhält genau vier Fokuspunkte zurück', () {
        final hero = _monk(primary: name);
        final result = MonkPerfectFocus.onInitiative(hero);
        expect(result.recovered, 4);
        expect(result.hero.spentClassResources['focusPoints'], 11);
        expect(hero.spentClassResources['focusPoints'], 15);
        expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 4);
        expect(result.hero.hitPoints, 35);
      });
    }

    for (final monkFirst in [true, false]) {
      test('Mönch 15 und Kämpfer 2, Mönch zuerst: $monkFirst', () {
        final hero = _monk(
          primary: monkFirst ? 'Monk' : 'Fighter',
          secondary: monkFirst ? 'Fighter' : 'Monk',
          secondaryLevel: monkFirst ? 2 : 15,
          level: 17,
        );
        final result = MonkPerfectFocus.onInitiative(hero);
        expect(result.recovered, 4);
        expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 4);
        final restored = HeroCharacter.fromJson(result.hero.toJson());
        expect(restored.toJson(), result.hero.toJson());
        expect(MonkPerfectFocus.onInitiative(restored).recovered, 0);
      });
    }

    test('Gesamtstufe 17 mit Mönch 14 schaltet das Merkmal nicht frei', () {
      final hero = _monk(
        secondary: 'Fighter',
        secondaryLevel: 3,
        level: 17,
        spent: 14,
      );
      final result = MonkPerfectFocus.onInitiative(hero);
      expect(result.recovered, 0);
      expect(result.hero, same(hero));
    });

    test('Stufe 20 regeneriert vier ohne weitere Charakteränderung', () {
      final hero = _monk(level: 20, spent: 20);
      final result = MonkPerfectFocus.onInitiative(hero);
      expect(result.recovered, 4);
      expect(result.hero.toJson(), {
        ...hero.toJson(),
        'spentClassResources': {'focusPoints': 16},
      });
    });

    test('Andere Mehrklassenressourcen bleiben unangetastet', () {
      final hero = _monk(secondary: 'Bard', secondaryLevel: 2, level: 17)
          .copyWith(
            spentClassResources: {'focusPoints': 15, 'bardicInspiration': 1},
          );
      final result = MonkPerfectFocus.onInitiative(hero);
      expect(result.recovered, 4);
      expect(result.hero.spentClassResources, {
        'focusPoints': 11,
        'bardicInspiration': 1,
      });
    });

    test('Unheimlicher Stoffwechsel verhindert doppelte Regeneration', () {
      final hero = _monk();
      final result = MonkPerfectFocus.onInitiative(
        hero,
        uncannyMetabolismUsed: true,
      );
      expect(result.recovered, 0);
      expect(result.hero, same(hero));
    });

    test('Vier oder mehr verfügbare Punkte erzeugen keine Gutschrift', () {
      for (final spent in [11, 10, 0]) {
        final hero = _monk(spent: spent);
        final result = MonkPerfectFocus.onInitiative(hero);
        expect(result.recovered, 0);
        expect(result.hero, same(hero));
      }
    });

    test(
      'Gültiges Klassenprofil weist überzogenen Verbrauch weiterhin zurück',
      () {
        expect(
          () => MonkPerfectFocus.onInitiative(_monk(spent: 16)),
          throwsFormatException,
        );
      },
    );

    test('Initiative-Dispatcher nutzt dieselbe gültige Fokusberechtigung', () {
      final hero = _monk();
      final result = MonkInitiativeFeatures.onInitiative(hero);
      expect(result.focusRecovered, 4);
      expect(result.hitPointsRecovered, 0);
      expect(result.uncannyMetabolismUsed, isFalse);
      expect(result.martialArtsDieRoll, isNull);
      expect(result.hero.hitPoints, hero.hitPoints);
    });

    test('Initiative-Dispatcher gibt ungültigem Profil keinen Fokus', () {
      final hero = _monk(
        primary: 'Unbekannte Klasse',
        secondary: 'Monk',
        secondaryLevel: 15,
        level: 17,
      );
      final result = MonkInitiativeFeatures.onInitiative(hero);
      expect(result.hero, same(hero));
      expect(result.focusRecovered, 0);
      expect(result.hitPointsRecovered, 0);
      expect(result.uncannyMetabolismUsed, isFalse);
      expect(result.martialArtsDieRoll, isNull);
    });
  });
}
