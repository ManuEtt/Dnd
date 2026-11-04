import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_warlock_magical_cunning_rules.dart';

HeroCharacter _warlockProfile({
  String primary = 'Hexenmeister',
  String secondary = '',
  int secondaryLevel = 0,
  int level = 11,
  int spentSlots = 2,
}) => HeroCharacter(
  id: 'warlock-class-preflight',
  name: 'Klassenprüfung',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 20,
  maxHitPoints: 30,
  spentPactSlots: spentSlots,
);

void main() {
  group('Magical Cunning: Klassenprofil vor Wiederherstellung prüfen', () {
    final invalidProfiles = <String, HeroCharacter>{
      'unbekannte Hauptklasse mit Warlock-Nebenklasse': _warlockProfile(
        primary: 'Unbekannt',
        secondary: 'Warlock',
        secondaryLevel: 10,
        level: 12,
      ),
      'doppelte Warlock-Aliase': _warlockProfile(
        secondary: 'Warlock',
        secondaryLevel: 5,
        level: 12,
      ),
      'unbekannte Nebenklasse': _warlockProfile(
        secondary: 'Unbekannt',
        secondaryLevel: 2,
        level: 13,
      ),
      'Nebenklassenstufe ohne Klassenname': _warlockProfile(
        secondaryLevel: 1,
        level: 12,
      ),
      'Nebenklasse ohne Stufen': _warlockProfile(
        secondary: 'Fighter',
        secondaryLevel: 0,
      ),
      'Hauptklasse mit null Stufen': _warlockProfile(
        primary: 'Fighter',
        secondary: 'Warlock',
        secondaryLevel: 10,
        level: 10,
      ),
      'Gesamtstufe über 20': _warlockProfile(level: 21),
      'Gesamtstufe null': _warlockProfile(level: 0),
      'negative Nebenklassenstufe': _warlockProfile(
        secondaryLevel: -1,
      ),
    };

    for (final entry in invalidProfiles.entries) {
      test('${entry.key}: keine Freischaltung oder Ressourcenänderung', () {
        final hero = entry.value;
        final original = hero.toJson();

        expect(SrdWarlockMagicalCunningRules.maximumUses(hero), 0);
        expect(SrdWarlockMagicalCunningRules.maximumRecoveredSlots(hero), 0);
        expect(
          () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(hero),
          throwsFormatException,
        );
        expect(hero.toJson(), original);
        expect(hero.spentPactSlots, 2);
        expect(hero.spentClassResources, isEmpty);
      });
    }

    test('englischer Warlock-Alias auf Stufe 20: Eldritch Master', () {
      final hero = _warlockProfile(
        primary: 'Warlock',
        level: 20,
        spentSlots: 4,
      );
      final before = hero.toJson();

      expect(SrdWarlockMagicalCunningRules.maximumUses(hero), 1);
      expect(SrdWarlockMagicalCunningRules.maximumRecoveredSlots(hero), 4);
      final result = SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
        hero,
      );
      expect(result.eldritchMaster, isTrue);
      expect(result.recoveredSlots, 4);
      expect(result.hero.spentPactSlots, 0);
      expect(
        result.hero.spentClassResources[SrdWarlockMagicalCunningRules
            .resourceKey],
        1,
      );
      expect(hero.toJson(), before);
    });

    test('Fighter 2 / Warlock 11: zwei von drei Paktplätzen zurück', () {
      final hero = _warlockProfile(
        primary: 'Fighter',
        secondary: 'Warlock',
        secondaryLevel: 11,
        level: 13,
        spentSlots: 3,
      );

      expect(SrdWarlockMagicalCunningRules.maximumUses(hero), 1);
      expect(SrdWarlockMagicalCunningRules.maximumRecoveredSlots(hero), 2);
      final result = SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
        hero,
      );
      expect(result.recoveredSlots, 2);
      expect(result.hero.spentPactSlots, 1);
      expect(result.eldritchMaster, isFalse);
    });

    test('andere Klasse und Warlock Stufe 1 bleiben gesperrt', () {
      final fighter = _warlockProfile(primary: 'Fighter', spentSlots: 0);
      final warlockOne = _warlockProfile(level: 1, spentSlots: 1);
      for (final hero in [fighter, warlockOne]) {
        expect(SrdWarlockMagicalCunningRules.maximumUses(hero), 0);
        expect(SrdWarlockMagicalCunningRules.maximumRecoveredSlots(hero), 0);
        expect(
          () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(hero),
          throwsStateError,
        );
      }
    });
  });
}
