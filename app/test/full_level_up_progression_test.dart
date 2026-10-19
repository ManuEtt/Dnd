import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_creation_progression.dart';
import 'package:lebendiger_spielleiter/domain/class_progression_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/multiclass_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_level_up.dart';

HeroCharacter character({
  String first = 'Kämpfer',
  String second = '',
  int secondaryLevel = 0,
  int level = 3,
  int? experience,
  String subclass = '',
  String secondarySubclass = '',
}) => HeroCharacter(
  id: 'levelup-integration',
  name: 'Arescan',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondaryLevel,
  level: level,
  subclass: subclass,
  secondarySubclass: secondarySubclass,
  experience:
      experience ?? CharacterCreationProgression.startingExperience(level + 1),
  maxHitPoints: 20 + level * 6,
  hitPoints: 16 + level * 6,
  armorClass: 15,
  speed: 9,
  abilities: const {
    'strength': 16,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 14,
    'wisdom': 14,
    'charisma': 14,
  },
  skills: const ['Athletik'],
);

void main() {
  test('Alle zwölf SRD-Klassen können jede Stufe 1 bis 20 erreichen', () {
    for (final definition in srdCharacterClasses) {
      for (var currentLevel = 1; currentLevel < 20; currentLevel++) {
        final hero = character(
          first: definition.name,
          level: currentLevel,
          experience: CharacterCreationProgression.startingExperience(
            currentLevel + 1,
          ),
        );
        final proposal = SrdClassLevelUpRules.propose(
          hero: hero,
          className: definition.name,
          method: LevelUpMethod.experience,
        );
        final upgraded = proposal.applyTo(hero);
        expect(upgraded.level, currentLevel + 1, reason: definition.name);
        expect(upgraded.primaryClassLevel, currentLevel + 1);
        expect(upgraded.secondaryClassLevel, 0);
        expect(upgraded.maxHitPoints, greaterThan(hero.maxHitPoints!));
        expect(upgraded.hitPoints, greaterThan(hero.hitPoints!));
        expect(upgraded.experience, hero.experience);
        expect(
          HeroCharacter.fromJson(upgraded.toJson()).toJson(),
          upgraded.toJson(),
        );
        expect(
          ClassProgressionRules.attacksPerAttackAction(upgraded),
          greaterThanOrEqualTo(1),
        );
      }
    }
  });

  test('Zweite Unterklasse wird gespeichert und separat freigeschaltet', () {
    final hero = character(
      first: 'Kämpfer',
      second: 'Magier',
      secondaryLevel: 2,
      level: 5,
      subclass: 'Champion',
      experience: 14000,
    );
    final proposal = SrdClassLevelUpRules.propose(
      hero: hero,
      className: 'Magier',
      method: LevelUpMethod.experience,
      chosenSubclass: 'Evoker',
    );
    expect(proposal.classLevel, 3);
    final upgraded = proposal.applyTo(hero);
    expect(upgraded.level, 6);
    expect(upgraded.primaryClassLevel, 3);
    expect(upgraded.secondaryClassLevel, 3);
    expect(upgraded.subclass, 'Champion');
    expect(upgraded.secondarySubclass, 'Evoker');
    final unlocked = SrdClassFeatureCatalog.unlocked(upgraded);
    expect(
      unlocked.where(
        (f) =>
            f.className == 'Magier' &&
            f.isSubclass &&
            f.name == 'Evocation Savant',
      ),
      isNotEmpty,
    );
    expect(
      unlocked.where(
        (f) =>
            f.className == 'Kämpfer' &&
            f.isSubclass &&
            f.name == 'Improved Critical',
      ),
      isNotEmpty,
    );
    expect(
      HeroCharacter.fromJson(upgraded.toJson()).secondarySubclass,
      'Evoker',
    );
  });

  test('Zweite Unterklasse darf niemals vor Klassenstufe drei erscheinen', () {
    final hero = character(
      second: 'Magier',
      secondaryLevel: 1,
      level: 4,
      subclass: 'Champion',
      experience: 6500,
    );
    final raw = hero.toJson();
    raw['secondarySubclass'] = 'Evoker';
    expect(() => HeroCharacter.fromJson(raw), throwsFormatException);
    expect(
      () => SrdClassLevelUpRules.propose(
        hero: hero,
        className: 'Magier',
        method: LevelUpMethod.experience,
        chosenSubclass: 'Evoker',
      ),
      throwsFormatException,
    );
  });

  test('Sekundäre Unterklasse ist nie implizit gewählt', () {
    final hero = character(
      second: 'Magier',
      secondaryLevel: 2,
      level: 5,
      experience: 14000,
    );
    final upgraded = SrdClassLevelUpRules.propose(
      hero: hero,
      className: 'Magier',
      method: LevelUpMethod.experience,
    ).applyTo(hero);
    expect(upgraded.secondarySubclass, isEmpty);
    expect(
      upgraded.unverifiedNotes,
      contains('OFFENE SRD-STUFENWAHL: Magier 3 – Unterklasse wählen'),
    );
    expect(
      SrdClassFeatureCatalog.unlocked(
        upgraded,
      ).where((feature) => feature.className == 'Magier' && feature.isSubclass),
      isEmpty,
    );
  });

  test('Zweitklasse: XP-Schwelle und explizite Meilenstein-Ausnahme', () {
    final hero = character(level: 3, experience: 2699);
    expect(
      () => MulticlassRules.propose(
        hero: hero,
        newClass: 'Magier',
        method: LevelUpMethod.experience,
      ),
      throwsFormatException,
    );
    final milestone = MulticlassRules.propose(
      hero: hero,
      newClass: 'Magier',
      method: LevelUpMethod.milestone,
    );
    expect(milestone.totalLevel, 4);
    final qualified = hero.copyWith(experience: 2700);
    expect(
      MulticlassRules.propose(
        hero: qualified,
        newClass: 'Magier',
        method: LevelUpMethod.experience,
      ).applyTo(qualified).secondaryClassLevel,
      1,
    );
    expect(
      () => milestone.applyTo(hero.copyWith(experience: 2700)),
      throwsFormatException,
    );
  });

  test(
    'Multiclass-Vorschlag ist für tote Helden und unbekannte TP gesperrt',
    () {
      for (final invalid in [
        character().copyWith(conditions: ['tot']),
        character().copyWith(hitPoints: null),
        character().copyWith(maxHitPoints: null),
      ]) {
        expect(
          () => MulticlassRules.propose(
            hero: invalid,
            newClass: 'Magier',
            method: LevelUpMethod.milestone,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('Alte Speicherstände ohne Zweitunterklasse bleiben lesbar', () {
    final original = character(
      second: 'Magier',
      secondaryLevel: 3,
      level: 6,
      experience: 23000,
    );
    final historical = original.toJson()..remove('secondarySubclass');
    final restored = HeroCharacter.fromJson(historical);
    expect(restored.secondarySubclass, isEmpty);
    expect(restored.toJson(), original.toJson());
  });
}
