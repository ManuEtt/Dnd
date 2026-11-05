import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_monk_slow_fall_rules.dart';

HeroCharacter _monk({
  String primary = 'Mönch',
  String secondary = '',
  int level = 7,
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'slow-fall-class-profile',
  name: 'Sanfter Fall',
  className: primary,
  secondaryClassName: secondary,
  level: level,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 20,
  maxHitPoints: 20,
  abilities: const {
    'strength': 10,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 16,
    'charisma': 10,
  },
);

SrdMonkSlowFallResult _preview(HeroCharacter hero) =>
    SrdMonkSlowFallRules.previewConfirmedReaction(
      hero,
      confirmedFallDamage: 37,
      fallConfirmed: true,
      reactionAvailable: true,
      reactionConfirmed: true,
    );

void main() {
  group('Sanfter Fall: gültige Klassen vor Mönchsreaktion', () {
    test('ungültige Profile geben keinen Schadensschutz frei', () {
      final invalid = <HeroCharacter>[
        _monk(primary: 'Unbekannt'),
        _monk(
          primary: 'Unbekannt',
          secondary: 'Mönch',
          level: 7,
          secondaryLevel: 4,
        ),
        _monk(
          primary: 'Mönch',
          secondary: 'Unbekannt',
          level: 7,
          secondaryLevel: 2,
        ),
        _monk(
          primary: 'Mönch',
          secondary: 'Monk',
          level: 8,
          secondaryLevel: 4,
        ),
        _monk(
          primary: 'Monk',
          secondary: 'Mönchin',
          level: 8,
          secondaryLevel: 4,
        ),
        _monk(secondary: 'Kämpfer', secondaryLevel: 0),
        _monk(secondaryLevel: 2),
        _monk(level: 0),
        _monk(level: 21),
        _monk(secondaryLevel: -1),
        _monk(
          primary: 'Kämpfer',
          secondary: 'Mönch',
          level: 7,
          secondaryLevel: 7,
        ),
      ];
      for (final hero in invalid) {
        final before = hero.toJson();
        expect(SrdMonkSlowFallRules.maximumReduction(hero), isNull);
        expect(() => _preview(hero), throwsFormatException);
        expect(hero.toJson(), before);
      }
    });

    test('deutsche/englische Aliasnamen und Mehrklassen bleiben gültig', () {
      final valid = <(HeroCharacter, int)>[
        (_monk(primary: 'Mönch', level: 4), 20),
        (_monk(primary: 'Monk', level: 7), 35),
        (_monk(primary: 'Mönchin', level: 5), 25),
        (
          _monk(
            primary: 'Kämpfer',
            secondary: 'Monk',
            level: 7,
            secondaryLevel: 4,
          ),
          20,
        ),
        (
          _monk(
            primary: 'Mönch',
            secondary: 'Wizard',
            level: 8,
            secondaryLevel: 4,
          ),
          20,
        ),
      ];
      for (final (hero, reduction) in valid) {
        final before = hero.toJson();
        expect(SrdMonkSlowFallRules.maximumReduction(hero), reduction);
        final result = _preview(hero);
        expect(result.maximumReduction, reduction);
        expect(result.monkClassLevel, reduction ~/ 5);
        expect(result.preventedDamage, reduction);
        expect(result.remainingDamage, 37 - reduction);
        expect(hero.toJson(), before);
      }
    });

    test('Gesamtstufe ersetzt keine Mönchsstufe und JSON bleibt stabil', () {
      final early = _monk(
        primary: 'Kämpfer',
        secondary: 'Mönch',
        level: 20,
        secondaryLevel: 3,
      );
      expect(SrdMonkSlowFallRules.maximumReduction(early), isNull);
      expect(() => _preview(early), throwsFormatException);

      final confirmed = _monk(level: 4);
      final snapshot = confirmed.toJson();
      final reloaded = HeroCharacter.fromJson(snapshot);
      expect(SrdMonkSlowFallRules.maximumReduction(reloaded), 20);
      expect(_preview(reloaded).remainingDamage, 17);
      expect(confirmed.toJson(), snapshot);
      expect(reloaded.toJson(), snapshot);
    });
  });
}
