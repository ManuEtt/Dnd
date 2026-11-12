import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_ranger_feral_senses_rules.dart';

HeroCharacter _ranger({
  String primary = 'Waldläufer',
  String secondary = '',
  int level = 18,
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'feral-senses-class-profile',
  name: 'Waldwacht',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 14,
  speed: 9,
  abilities: const {
    'strength': 12,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 16,
    'charisma': 10,
  },
);

bool? _within(HeroCharacter hero, int distance) =>
    SrdRangerFeralSensesRules.withinConfirmedRange(
      hero,
      distanceFeet: distance,
      distanceConfirmed: true,
    );

void main() {
  group('Wilde Sinne: validierte Waldläufer-Klassenprofile', () {
    test('Ungültige Klassenprofile gewähren keine Blindsicht', () {
      final invalid = <HeroCharacter>[
        _ranger(primary: 'Unbekannt'),
        _ranger(
          primary: 'Unbekannt',
          secondary: 'Waldläufer',
          level: 20,
          secondaryLevel: 18,
        ),
        _ranger(
          primary: 'Waldläufer',
          secondary: 'Unbekannt',
          level: 20,
          secondaryLevel: 1,
        ),
        _ranger(
          primary: 'Waldläufer',
          secondary: 'Ranger',
          level: 20,
          secondaryLevel: 1,
        ),
        _ranger(
          primary: 'Ranger',
          secondary: 'Waldläuferin',
          level: 20,
          secondaryLevel: 1,
        ),
        _ranger(secondary: 'Magier', secondaryLevel: 0),
        _ranger(secondaryLevel: 1),
        _ranger(level: 0),
        _ranger(level: 21),
        _ranger(secondaryLevel: -1),
        _ranger(
          primary: 'Kämpfer',
          secondary: 'Ranger',
          level: 20,
          secondaryLevel: 20,
        ),
        _ranger(
          primary: 'Waldläufer',
          secondary: 'Magier',
          level: 18,
          secondaryLevel: 18,
        ),
      ];
      for (final hero in invalid) {
        final saved = hero.toJson();
        expect(SrdRangerFeralSensesRules.blindsightRangeFeet(hero), isNull);
        expect(_within(hero, 15), isNull);
        expect(hero.toJson(), saved);
      }
    });

    test('Gültige Alias- und Mehrklassenprofile behalten 30 Fuß', () {
      final valid = <HeroCharacter>[
        _ranger(),
        _ranger(primary: 'Ranger'),
        _ranger(primary: 'Waldläuferin'),
        _ranger(
          primary: 'Fighter',
          secondary: 'Ranger',
          level: 20,
          secondaryLevel: 18,
        ),
        _ranger(
          primary: 'Waldläufer',
          secondary: 'Wizard',
          level: 20,
          secondaryLevel: 2,
        ),
      ];
      for (final hero in valid) {
        final before = hero.toJson();
        expect(SrdRangerFeralSensesRules.blindsightRangeFeet(hero), 30);
        expect(_within(hero, 30), isTrue);
        expect(_within(hero, 31), isFalse);
        expect(hero.toJson(), before);
      }
    });

    test('Nur eigene Waldläuferstufe 18 und bestätigte Entfernung', () {
      final ranger17 = _ranger(
        primary: 'Fighter',
        secondary: 'Ranger',
        level: 20,
        secondaryLevel: 17,
      );
      expect(SrdRangerFeralSensesRules.blindsightRangeFeet(ranger17), isNull);
      expect(_within(ranger17, 5), isNull);
      final unrelated = _ranger(primary: 'Wizard', level: 20);
      expect(SrdRangerFeralSensesRules.blindsightRangeFeet(unrelated), isNull);

      final hero = _ranger();
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRange(
          hero,
          distanceFeet: 15,
          distanceConfirmed: false,
        ),
        isNull,
      );
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRange(
          hero,
          distanceFeet: null,
          distanceConfirmed: true,
        ),
        isNull,
      );
    });

    test('Gültiger Altspielstand benötigt kein neues Merkmalfeld', () {
      final hero = _ranger();
      final saved = hero.toJson();
      final restored = HeroCharacter.fromJson(saved);
      expect(restored.toJson(), saved);
      expect(SrdRangerFeralSensesRules.blindsightRangeFeet(restored), 30);
      expect(restored.features, isEmpty);
      expect(hero.toJson(), saved);
    });
  });
}
