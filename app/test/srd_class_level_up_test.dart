import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_creation_progression.dart';
import 'package:lebendiger_spielleiter/domain/class_progression_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_level_up.dart';

HeroCharacter hero({
  String className = 'Kämpfer',
  int level = 1,
  int constitution = 14,
  int? xp = 300,
  String secondary = '',
  int secondaryLevel = 0,
  String subclass = '',
}) => HeroCharacter(
  id: 'levelup-hero',
  name: 'Tira',
  className: className,
  level: level,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  subclass: subclass,
  experience: xp,
  hitPoints: 8,
  maxHitPoints: 14,
  armorClass: 16,
  speed: 9,
  abilities: {
    'strength': 14,
    'dexterity': 14,
    'constitution': constitution,
    'intelligence': 14,
    'wisdom': 14,
    'charisma': 14,
  },
  skills: const ['Athletik'],
  features: const ['Bestehende bestätigte Fähigkeit'],
  inventory: const [InventoryItem(id: 'backpack', name: 'Rucksack')],
  unverifiedNotes: const ['Importierte Spielnotiz'],
);

void main() {
  test('12 Klassen: fester SRD-TP-Anstieg ab zweiter Klassenstufe', () {
    for (final klass in srdCharacterClasses) {
      final current = hero(className: klass.name);
      final proposal = SrdClassLevelUpRules.propose(
        hero: current,
        className: klass.name,
        method: LevelUpMethod.experience,
      );
      expect(proposal.hitDie, klass.hitDie, reason: klass.name);
      expect(
        proposal.hpGain,
        klass.hitDie ~/ 2 + 3,
        reason: klass.name,
      ); // fixed midpoint+1 plus KON +2
      expect(proposal.classLevel, 2);
      final raised = proposal.applyTo(current);
      expect(raised.level, 2);
      expect(raised.primaryClassLevel, 2);
      expect(raised.secondaryClassLevel, 0);
      expect(raised.maxHitPoints, 14 + proposal.hpGain);
      expect(raised.hitPoints, 8 + proposal.hpGain);
      expect(raised.experience, 300);
      expect(raised.features, current.features);
      expect(raised.skills, current.skills);
      expect(raised.inventory.single.id, 'backpack');
      expect(HeroCharacter.fromJson(raised.toJson()).toJson(), raised.toJson());
    }
  });

  test('Schaden und feste TP bleiben unabhängig; 1 TP Mindestgewinn', () {
    final current = hero(constitution: 1);
    final proposal = SrdClassLevelUpRules.propose(
      hero: current,
      className: 'Kämpfer',
      method: LevelUpMethod.milestone,
    );
    // d10 fixed 6 + (-5) => 1, always at least one.
    expect(proposal.hpGain, 1);
    final raised = proposal.applyTo(current);
    expect(raised.hitPoints, 9);
    expect(raised.maxHitPoints, 15);
    expect(raised.maxHitPoints! - raised.hitPoints!, 6);
  });

  test('Erfahrungsaufstieg verlangt die tatsächliche EP-Schwelle', () {
    final current = hero(xp: 299);
    expect(
      () => SrdClassLevelUpRules.propose(
        hero: current,
        className: 'Kämpfer',
        method: LevelUpMethod.experience,
      ),
      throwsFormatException,
    );
    expect(
      SrdClassLevelUpRules.propose(
        hero: current,
        className: 'Kämpfer',
        method: LevelUpMethod.milestone,
      ).totalLevel,
      2,
    );
    expect(
      CharacterCreationProgression.proficiencyBonus(
        SrdClassLevelUpRules.propose(
          hero: hero(level: 4, xp: 6500),
          className: 'Kämpfer',
          method: LevelUpMethod.experience,
        ).totalLevel,
      ),
      3,
    );
  });

  test(
    'Unterklassenwahl ist explizit, keine unbekannte Unterklasse zugeschrieben',
    () {
      final current = hero(level: 2, xp: 900, className: 'Kämpfer');
      final pending = SrdClassLevelUpRules.propose(
        hero: current,
        className: 'Kämpfer',
        method: LevelUpMethod.experience,
      );
      expect(pending.requiredChoices, contains('Unterklasse wählen'));
      final without = pending.applyTo(current);
      expect(without.subclass, isEmpty);
      expect(
        without.unverifiedNotes,
        contains('OFFENE SRD-STUFENWAHL: Kämpfer 3 – Unterklasse wählen'),
      );
      final chosen = SrdClassLevelUpRules.propose(
        hero: current,
        className: 'Kämpfer',
        method: LevelUpMethod.experience,
        chosenSubclass: SrdClassFeatureCatalog.defaultSubclass['Kämpfer']!,
      );
      final raised = chosen.applyTo(current);
      expect(raised.subclass, 'Champion');
      expect(
        raised.unverifiedNotes.any((n) => n.contains('Unterklasse wählen')),
        isFalse,
      );
      expect(raised.features, current.features);
      expect(
        () => SrdClassLevelUpRules.propose(
          hero: current,
          className: 'Kämpfer',
          method: LevelUpMethod.experience,
          chosenSubclass: 'Nicht im SRD',
        ),
        throwsFormatException,
      );
    },
  );

  test('Talente und epische Gabe bleiben offen statt automatisch erteilt', () {
    final fourth = hero(level: 3, xp: 2700, className: 'Schurke');
    final raised = SrdClassLevelUpRules.propose(
      hero: fourth,
      className: 'Schurke',
      method: LevelUpMethod.experience,
    ).applyTo(fourth);
    expect(raised.level, 4);
    expect(raised.unverifiedNotes.any((n) => n.contains('Talent')), isTrue);
    expect(raised.features, fourth.features);
    for (final className in ['Kämpfer', 'Schurke']) {
      final at18 = hero(level: 18, xp: 355000, className: className);
      final result = SrdClassLevelUpRules.propose(
        hero: at18,
        className: className,
        method: LevelUpMethod.experience,
      ).applyTo(at18);
      expect(
        result.unverifiedNotes.any((n) => n.contains('Epische Gabe')),
        isTrue,
      );
    }
  });

  test(
    'Bestehende Zweitklasse aufsteigen ohne neue Start-Übungen und Ausrüstung',
    () {
      final current = hero(
        className: 'Kämpfer',
        secondary: 'Magier',
        secondaryLevel: 2,
        level: 5,
        xp: 14000,
      );
      final proposal = SrdClassLevelUpRules.propose(
        hero: current,
        className: 'Magier',
        method: LevelUpMethod.experience,
      );
      expect(proposal.isSecondary, isTrue);
      expect(proposal.classLevel, 3);
      final result = proposal.applyTo(current);
      expect(result.level, 6);
      expect(result.primaryClassLevel, 3);
      expect(result.secondaryClassLevel, 3);
      expect(result.inventory, current.inventory);
      expect(result.savingThrowProficiencies, current.savingThrowProficiencies);
      expect(
        result.unverifiedNotes.any((n) => n.contains('Unterklasse wählen')),
        isTrue,
      );
    },
  );

  test('Vorschlag ist bei veränderten TP, EP und Attributen ungültig', () {
    final current = hero();
    final proposal = SrdClassLevelUpRules.propose(
      hero: current,
      className: 'Kämpfer',
      method: LevelUpMethod.experience,
    );
    for (final modified in [
      current.copyWith(hitPoints: 7),
      current.copyWith(experience: 301),
      current.copyWith(abilities: {...current.abilities, 'constitution': 16}),
      current.copyWith(maxHitPoints: 15),
    ]) {
      expect(() => proposal.applyTo(modified), throwsFormatException);
    }
  });

  test(
    'Level 20, unbekannte Klasse, fehlende TP/KO und Tod werden abgewiesen',
    () {
      final atMax = hero(level: 20, xp: 355000);
      expect(
        () => SrdClassLevelUpRules.propose(
          hero: atMax,
          className: 'Kämpfer',
          method: LevelUpMethod.milestone,
        ),
        throwsFormatException,
      );
      for (final invalid in [
        HeroCharacter(
          id: 'missing-hp',
          name: 'Unvollständig',
          className: 'Kämpfer',
          level: 1,
          hitPoints: 8,
          experience: 300,
          abilities: const {'constitution': 14},
        ),
        HeroCharacter(
          id: 'missing-current-hp',
          name: 'Unvollständig',
          className: 'Kämpfer',
          level: 1,
          maxHitPoints: 14,
          experience: 300,
          abilities: const {'constitution': 14},
        ),
        hero().copyWith(abilities: {...hero().abilities, 'constitution': null}),
        hero().copyWith(conditions: ['tot']),
      ]) {
        expect(
          () => SrdClassLevelUpRules.propose(
            hero: invalid,
            className: 'Kämpfer',
            method: LevelUpMethod.milestone,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => SrdClassLevelUpRules.propose(
          hero: hero(),
          className: 'Unbekannt',
          method: LevelUpMethod.milestone,
        ),
        throwsFormatException,
      );
    },
  );

  test('Berechnete Angriffe folgen bestätigter Klassenstufe', () {
    final initial = hero(level: 4, xp: 6500);
    final result = SrdClassLevelUpRules.propose(
      hero: initial,
      className: 'Kämpfer',
      method: LevelUpMethod.experience,
    ).applyTo(initial);
    expect(ClassProgressionRules.attacksPerAttackAction(result), 2);
  });
}
