import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_automation.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';

HeroCharacter _hero({
  String primary = 'Barde',
  String secondary = '',
  int level = 5,
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'class-feature-profile-gate',
  name: 'Regelprobe',
  className: primary,
  secondaryClassName: secondary,
  level: level,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 12,
  maxHitPoints: 12,
  abilities: const {
    'strength': 12,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 14,
    'wisdom': 14,
    'charisma': 16,
  },
);

void main() {
  group('SRD-Klassenkatalog: ungültige Profile sperren Freischaltungen', () {
    test('alte und direkt erzeugte widersprüchliche Klassenprofile', () {
      final invalid = <HeroCharacter>[
        _hero(primary: 'Unbekannt'),
        _hero(
          primary: 'Unbekannt',
          secondary: 'Barde',
          level: 10,
          secondaryLevel: 5,
        ),
        _hero(
          primary: 'Barde',
          secondary: 'Unbekannt',
          level: 10,
          secondaryLevel: 5,
        ),
        _hero(
          primary: 'Barde',
          secondary: 'Bard',
          level: 10,
          secondaryLevel: 5,
        ),
        _hero(
          primary: 'Bardin',
          secondary: 'Barde',
          level: 10,
          secondaryLevel: 5,
        ),
        _hero(secondary: 'Kämpfer'),
        _hero(secondaryLevel: 1),
        _hero(secondaryLevel: -1),
        _hero(level: 0),
        _hero(level: 21),
        _hero(
          primary: 'Kämpfer',
          secondary: 'Barde',
          level: 5,
          secondaryLevel: 5,
        ),
        _hero(
          primary: 'Barde',
          secondary: 'Magier',
          level: 5,
          secondaryLevel: 6,
        ),
      ];
      for (final hero in invalid) {
        final snapshot = hero.toJson();
        expect(
          SrdClassFeatureCatalog.hasConsistentClassLevels(hero),
          isFalse,
        );
        expect(SrdClassFeatureCatalog.unlocked(hero), isEmpty);
        expect(SrdClassAutomation.unlocked(hero), isEmpty);
        expect(SrdClassAutomation.derivedValues(hero), isEmpty);
        expect(hero.toJson(), snapshot);
      }
    });

    test('gültige SRD-Aliase und Klassenstufen bleiben erhalten', () {
      final bard = _hero(primary: 'Bardin');
      final bardSnapshot = bard.toJson();
      expect(SrdClassFeatureCatalog.hasConsistentClassLevels(bard), isTrue);
      expect(
        SrdClassFeatureCatalog.unlocked(bard)
            .any((feature) => feature.name == 'Font of Inspiration'),
        isTrue,
      );
      expect(
        SrdClassAutomation.unlocked(bard)
            .any((entry) => entry.feature.name == 'Font of Inspiration'),
        isTrue,
      );
      expect(SrdClassAutomation.derivedValues(bard), isNotEmpty);
      expect(bard.toJson(), bardSnapshot);

      final barbarian = _hero(primary: 'Barbarian', level: 18);
      expect(
        SrdClassFeatureCatalog.unlocked(barbarian)
            .any((feature) => feature.name == 'Indomitable Might'),
        isTrue,
      );
      expect(SrdClassAutomation.derivedValues(barbarian), isNotEmpty);

      final monk = _hero(primary: 'Mönchin', level: 4);
      expect(
        SrdClassFeatureCatalog.unlocked(monk)
            .any((feature) => feature.name == 'Slow Fall'),
        isTrue,
      );
      expect(SrdClassAutomation.derivedValues(monk), isNotEmpty);
    });

    test('legales Multiclassing verwendet die einzelnen Klassenstufen', () {
      final mixed = _hero(
        primary: 'Fighter',
        secondary: 'Rogue',
        level: 10,
        secondaryLevel: 5,
      );
      final snapshot = mixed.toJson();
      expect(SrdClassFeatureCatalog.hasConsistentClassLevels(mixed), isTrue);
      final features = SrdClassFeatureCatalog.unlocked(mixed);
      expect(features.any((feature) => feature.name == 'Sneak Attack'), isTrue);
      expect(features.any((feature) => feature.name == 'Extra Attack'), isTrue);
      expect(
        features.any((feature) => feature.name == 'Two Extra Attacks'),
        isFalse,
      );
      final values = SrdClassAutomation.derivedValues(mixed);
      expect(
        values.singleWhere(
          (value) => value.name == 'Hinterhältiger Angriff',
        ).value,
        '3W6',
      );
      expect(
        values.any((value) => value.name == 'Zweite Luft gesamt'),
        isTrue,
      );
      expect(mixed.toJson(), snapshot);

      final ranger = _hero(
        primary: 'Ranger',
        secondary: 'Wizard',
        level: 20,
        secondaryLevel: 2,
      );
      expect(SrdClassFeatureCatalog.hasConsistentClassLevels(ranger), isTrue);
      expect(
        SrdClassFeatureCatalog.unlocked(ranger)
            .any((feature) => feature.name == 'Feral Senses'),
        isTrue,
      );
      expect(SrdClassAutomation.derivedValues(ranger), isNotEmpty);
    });

    test('Freischaltungen bleiben unveränderlich und speicherneutral', () {
      final hero = _hero(primary: 'Wizard', level: 5);
      final saved = hero.toJson();
      final reloaded = HeroCharacter.fromJson(saved);
      expect(SrdClassFeatureCatalog.hasConsistentClassLevels(reloaded), isTrue);
      final features = SrdClassFeatureCatalog.unlocked(reloaded);
      final values = SrdClassAutomation.derivedValues(reloaded);
      expect(features, isNotEmpty);
      expect(values, isNotEmpty);
      expect(() => features.clear(), throwsUnsupportedError);
      expect(() => values.clear(), throwsUnsupportedError);
      expect(reloaded.toJson(), saved);
      expect(hero.toJson(), saved);
    });
  });
}
