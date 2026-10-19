import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_creation_progression.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/primary_class_level_up.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';

HeroCharacter _hero(
  String cls, {
  int level = 1,
  int experience = 355000,
  int constitution = 14,
  String subclass = '',
  int hp = 18,
  int maxHp = 22,
  int secondClassLevel = 0,
}) => HeroCharacter(
  id: 'level-$cls',
  name: 'Testheld',
  className: cls,
  level: level,
  secondaryClassName: secondClassLevel == 0 ? '' : 'Schurke',
  secondaryClassLevel: secondClassLevel,
  subclass: subclass,
  hitPoints: hp,
  maxHitPoints: maxHp,
  experience: experience,
  abilities: {
    'strength': 14,
    'dexterity': 14,
    'constitution': constitution,
    'intelligence': 12,
    'wisdom': 14,
    'charisma': 14,
  },
);

void main() {
  test('Alle zwölf SRD-Klassen steigen von 1 auf 2 mit ihrem Trefferwürfel', () {
    expect(srdCharacterClasses, hasLength(12));
    for (final cls in srdCharacterClasses) {
      final original = _hero(cls.name, experience: 300);
      final proposal = PrimaryClassLevelUp.propose(
        hero: original,
        milestoneAdvancement: false,
      );
      final expectedGain = cls.hitDie ~/ 2 + 1 + 2;
      expect(proposal.hitPointGain, expectedGain, reason: cls.name);
      expect(proposal.newClassLevel, 2, reason: cls.name);
      final advanced = proposal.applyTo(original);
      expect(advanced.level, 2, reason: cls.name);
      expect(advanced.hitPoints, original.hitPoints! + expectedGain);
      expect(advanced.maxHitPoints, original.maxHitPoints! + expectedGain);
      expect(advanced.experience, original.experience);
      expect(advanced.secondaryClassLevel, 0);
      expect(advanced.features, original.features);
      expect(advanced.inventory, original.inventory);
      expect(
        HeroCharacter.fromJson(advanced.toJson()).toJson(),
        advanced.toJson(),
      );
      // No feature list is fabricated. Features are derived by class level.
      expect(
        SrdClassFeatureCatalog.unlocked(advanced).where(
          (f) => f.classLevel == 2 && f.className == cls.name,
        ),
        isNotEmpty,
        reason: cls.name,
      );
    }
  });

  test('Ohne nötige EP wird ausdrücklich gewählter Meilenstein verlangt', () {
    final original = _hero('Barde', experience: 0);
    expect(
      () => PrimaryClassLevelUp.propose(
        hero: original,
        milestoneAdvancement: false,
      ),
      throwsFormatException,
    );
    final after = PrimaryClassLevelUp.propose(
      hero: original,
      milestoneAdvancement: true,
    ).applyTo(original);
    expect(after.level, 2);
    expect(after.experience, 0);
    expect(CharacterCreationProgression.startingExperience(2), 300);
  });

  test('Klassenstufe 3 erfordert explizit die im SRD zugelassene Unterklasse', () {
    for (final cls in srdCharacterClasses) {
      final before = _hero(cls.name, level: 2);
      expect(
        () => PrimaryClassLevelUp.propose(
          hero: before,
          milestoneAdvancement: false,
        ),
        throwsFormatException,
        reason: cls.name,
      );
      final subclass = SrdClassFeatureCatalog.defaultSubclass[cls.name]!;
      final approved = PrimaryClassLevelUp.propose(
        hero: before,
        milestoneAdvancement: false,
        chosenSubclass: subclass,
      );
      final after = approved.applyTo(before);
      expect(after.subclass, subclass, reason: cls.name);
      expect(after.level, 3);
      expect(
        SrdClassFeatureCatalog.unlocked(after)
            .where((feature) => feature.subclass == subclass),
        isNotEmpty,
        reason: cls.name,
      );
    }
  });

  test('Stufe 4 verlangt ASI-Auswahl; +2 und +1/+1 sind erlaubt', () {
    final start = _hero('Magier', level: 3, subclass: 'Evoker');
    expect(
      () => PrimaryClassLevelUp.propose(
        hero: start,
        milestoneAdvancement: false,
      ),
      throwsFormatException,
    );
    final asis = PrimaryClassLevelUp.propose(
      hero: start,
      milestoneAdvancement: false,
      abilityIncreases: {'intelligence': 2},
    );
    expect(asis.applyTo(start).abilities['intelligence'], 14);
    expect(asis.pendingSelections, isEmpty);
    final split = PrimaryClassLevelUp.propose(
      hero: start,
      milestoneAdvancement: false,
      abilityIncreases: {'dexterity': 1, 'wisdom': 1},
    );
    expect(split.applyTo(start).abilities['dexterity'], 15);
    expect(split.applyTo(start).abilities['wisdom'], 15);

    final deferred = PrimaryClassLevelUp.propose(
      hero: start,
      milestoneAdvancement: false,
      deferFeat: true,
    );
    expect(deferred.applyTo(start).abilities, start.abilities);
    expect(deferred.pendingSelections, contains(contains('noch wählen')));
    expect(deferred.applyTo(start).unverifiedNotes, isNotEmpty);
  });

  test('Konstitutionsbonus bei ASI wirkt rückwirkend auf alle neuen Stufen', () {
    final original = _hero(
      'Kämpfer', level: 3, hp: 25, maxHp: 30, constitution: 13,
      subclass: 'Champion',
    );
    final proposal = PrimaryClassLevelUp.propose(
      hero: original,
      milestoneAdvancement: false,
      abilityIncreases: {'constitution': 2},
    );
    // Fixed 6 + old CON(1), plus four levels * CON-modifier delta(1).
    expect(proposal.fixedHitPointGain, 7);
    expect(proposal.hitPointGain, 11);
    final advanced = proposal.applyTo(original);
    expect(advanced.maxHitPoints, 41);
    expect(advanced.hitPoints, 36);
    expect(advanced.abilities['constitution'], 15);
  });

  test('Fighter 6 and Rogue 10 also require a feat decision', () {
    expect(PrimaryClassLevelUp.needsAbilityFeat('Kämpfer', 6), isTrue);
    expect(PrimaryClassLevelUp.needsAbilityFeat('Kämpfer', 14), isTrue);
    expect(PrimaryClassLevelUp.needsAbilityFeat('Schurke', 10), isTrue);
    expect(PrimaryClassLevelUp.needsAbilityFeat('Barde', 6), isFalse);
  });

  test('Invalid ability boosts, caps and feat choices fail atomically', () {
    final start = _hero('Barde', level: 3, subclass: 'College of Lore');
    for (final boosts in <Map<String, int>>[
      {'wisdom': 3},
      {'wisdom': 1},
      {'charisma': 1, 'wisdom': 2},
      {'wisdom': 1, 'intelligence': 1, 'dexterity': 1},
      {'unknown': 2},
    ]) {
      expect(
        () => PrimaryClassLevelUp.propose(
          hero: start, milestoneAdvancement: false,
          abilityIncreases: boosts,
        ),
        throwsFormatException,
      );
    }
    final capped = start.copyWith(
      abilities: {...start.abilities, 'wisdom': 20},
    );
    expect(
      () => PrimaryClassLevelUp.propose(
        hero: capped,
        milestoneAdvancement: false,
        abilityIncreases: {'wisdom': 2},
      ),
      throwsFormatException,
    );
    expect(
      () => PrimaryClassLevelUp.propose(
        hero: _hero('Barde'),
        milestoneAdvancement: false,
        abilityIncreases: {'charisma': 2},
      ),
      throwsFormatException,
    );
  });

  test('Vorschau ist revisionsgebunden, keine Doppelanwendung', () {
    final before = _hero('Barbar', experience: 300);
    final proposal = PrimaryClassLevelUp.propose(
      hero: before,
      milestoneAdvancement: false,
    );
    expect(
      () => proposal.applyTo(before.copyWith(experience: 500)),
      throwsFormatException,
    );
    final once = proposal.applyTo(before);
    expect(() => proposal.applyTo(once), throwsFormatException);
  });

  test('Bei Stufe 20 ist Schluss, eine Zweitklasse wird nicht erhöht', () {
    expect(
      () => PrimaryClassLevelUp.propose(
        hero: _hero('Barbar', level: 20),
        milestoneAdvancement: true,
      ),
      throwsFormatException,
    );
    final before = _hero('Kämpfer', level: 4, secondClassLevel: 1,
        subclass: 'Champion');
    final result = PrimaryClassLevelUp.propose(
      hero: before,
      milestoneAdvancement: false,
    ).applyTo(before);
    expect(result.primaryClassLevel, 4);
    expect(result.secondaryClassLevel, 1);
    expect(result.level, 5);
  });

  test('Unbekannte Klasse, unbestätigte TP oder KO werden abgewiesen', () {
    for (final invalid in [
      _hero('Eigene Hausregel-Klasse'),
      _hero('Kämpfer').copyWith(maxHitPoints: null),
      _hero('Kämpfer').copyWith(abilities: {'constitution': null}),
    ]) {
      expect(
        () => PrimaryClassLevelUp.propose(
          hero: invalid,
          milestoneAdvancement: true,
        ),
        throwsFormatException,
      );
    }
  });
}
