import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/rules/rules_api.dart';

HeroCharacter _bard({
  String primary = 'Barde',
  String secondary = '',
  int level = 18,
  int secondaryLevel = 0,
  int spent = 3,
  int? charisma = 16,
}) => HeroCharacter(
  id: 'bard-profile',
  name: 'Testfigur',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 40,
  maxHitPoints: 40,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d8',
  weaponProficient: true,
  abilities: {
    'strength': 12,
    'dexterity': 14,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': charisma,
  },
  spentClassResources: {'bardicInspiration': spent},
);

void main() {
  group('Überlegene Inspiration benötigt konsistente Klassenstufen', () {
    final invalidProfiles = <String, HeroCharacter>{
      'unbekannte Hauptklasse neben Barde 18': _bard(
        primary: 'Unbekannte Klasse',
        secondary: 'Barde',
        secondaryLevel: 18,
        level: 20,
      ),
      'unbekannte Zweitklasse neben Barde 18': _bard(
        secondary: 'Unbekannte Klasse',
        secondaryLevel: 2,
        level: 20,
      ),
      'gleiche Klasse mit deutschem und englischem Alias': _bard(
        secondary: 'Bard',
        secondaryLevel: 2,
        level: 20,
      ),
      'gleiche Klasse mit demselben Namen': _bard(
        secondary: 'Barde',
        secondaryLevel: 2,
        level: 20,
      ),
      'benannte Zweitklasse ohne Stufe': _bard(secondary: 'Fighter'),
      'Zweitklassenstufe ohne Zweitklasse': _bard(secondaryLevel: 2, level: 20),
      'negative Zweitklassenstufe': _bard(secondaryLevel: -1),
      'negative Gesamtstufe': _bard(level: -1),
      'Gesamtstufe null': _bard(level: 0),
      'Gesamtstufe über 20': _bard(level: 21),
      'Zweitklasse ohne verbleibende Erstklassenstufe': _bard(
        primary: 'Fighter',
        secondary: 'Bard',
        secondaryLevel: 18,
        level: 18,
      ),
      'Zweitklasse höher als Gesamtstufe': _bard(
        primary: 'Fighter',
        secondary: 'Bard',
        secondaryLevel: 19,
        level: 18,
      ),
    };
    for (final entry in invalidProfiles.entries) {
      test('${entry.key}: keine automatische Ressourcengutschrift', () {
        final hero = entry.value;
        final before = Map<String, int>.of(hero.spentClassResources);
        final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
        expect(result.recovered, 0);
        expect(result.hero, same(hero));
        expect(hero.spentClassResources, before);
      });
    }

    test(
      'Ungültiges Profil wird nicht nachträglich über Charisma bestätigt',
      () {
        final hero = _bard(
          primary: 'Unbekannte Klasse',
          secondary: 'Bard',
          secondaryLevel: 18,
          level: 20,
          charisma: null,
        );
        final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
        expect(result.recovered, 0);
        expect(result.hero, same(hero));
      },
    );

    for (final name in ['Barde', 'Bard', 'bard', ' BARD ']) {
      test('Bestätigter Alias $name erhält genau zwei Nutzungen zurück', () {
        final hero = _bard(primary: name);
        final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
        expect(result.recovered, 2);
        expect(result.hero.spentClassResources['bardicInspiration'], 1);
        expect(hero.spentClassResources['bardicInspiration'], 3);
        expect(
          ClassResourceRules.remaining(result.hero, 'bardicInspiration'),
          2,
        );
      });
    }

    for (final bardFirst in [true, false]) {
      test('Barde 18 und Kämpfer 2, Barde zuerst: $bardFirst', () {
        final hero = _bard(
          primary: bardFirst ? 'Bard' : 'Fighter',
          secondary: bardFirst ? 'Fighter' : 'Bard',
          secondaryLevel: bardFirst ? 2 : 18,
          level: 20,
        );
        final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
        expect(result.recovered, 2);
        expect(
          ClassResourceRules.remaining(result.hero, 'bardicInspiration'),
          2,
        );
        final restored = HeroCharacter.fromJson(result.hero.toJson());
        expect(restored.toJson(), result.hero.toJson());
        expect(
          SrdBardSuperiorInspirationRules.onInitiative(restored).recovered,
          0,
        );
      });
    }

    test('Gesamtstufe 20 mit Barde 17 schaltet das Merkmal nicht frei', () {
      final hero = _bard(secondary: 'Fighter', secondaryLevel: 3, level: 20);
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 0);
      expect(result.hero, same(hero));
    });

    test('Stufe 20 bleibt verfügbar und verändert keine andere Ressource', () {
      final hero = _bard(level: 20);
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 2);
      expect(result.hero.toJson(), {
        ...hero.toJson(),
        'spentClassResources': {'bardicInspiration': 1},
      });
    });

    test('Mehrklassen-Fokusverbrauch bleibt bei der Gutschrift erhalten', () {
      final hero = _bard(secondary: 'Monk', secondaryLevel: 2, level: 20)
          .copyWith(
            spentClassResources: {'bardicInspiration': 3, 'focusPoints': 1},
          );
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 2);
      expect(result.hero.spentClassResources, {
        'bardicInspiration': 1,
        'focusPoints': 1,
      });
      expect(hero.spentClassResources['focusPoints'], 1);
    });

    test('Bestätigtes Profil verlangt weiterhin bekanntes Charisma', () {
      expect(
        () =>
            SrdBardSuperiorInspirationRules.onInitiative(_bard(charisma: null)),
        throwsStateError,
      );
    });

    test('Bestätigtes Profil weist weiterhin überzogenen Verbrauch zurück', () {
      expect(
        () => SrdBardSuperiorInspirationRules.onInitiative(_bard(spent: 4)),
        throwsFormatException,
      );
    });
  });
}
