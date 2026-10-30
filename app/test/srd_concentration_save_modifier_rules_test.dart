import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_concentration_save_modifier_rules.dart';

HeroCharacter _hero({
  String className = 'Magier',
  int level = 5,
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
  int? constitution = 14,
  int exhaustion = 0,
  int? hitPoints = 22,
  List<String> proficiencies = const [],
  List<String> conditions = const [],
  String concentratingOn = 'Invisibility',
}) => HeroCharacter(
  id: 'concentration-save-evidence',
  name: 'Konzentrationsmagier',
  className: className,
  level: level,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  abilities: {
    'strength': 10,
    'dexterity': 12,
    'constitution': constitution,
    'intelligence': 18,
    'wisdom': 12,
    'charisma': 10,
  },
  savingThrowProficiencies: proficiencies,
  exhaustionLevel: exhaustion,
  hitPoints: hitPoints,
  maxHitPoints: 40,
  conditions: conditions,
  concentratingOn: concentratingOn,
);

SrdConcentrationSaveModifierEvidence _prepare(
  HeroCharacter hero, {
  bool otherReviewed = true,
  bool rollReviewed = true,
  int extra = 0,
  bool extraConfirmed = false,
  bool advantage = false,
  bool disadvantage = false,
}) => SrdConcentrationSaveModifierRules.prepare(
  hero,
  otherModifierSourcesReviewedConfirmed: otherReviewed,
  rollCircumstancesReviewedConfirmed: rollReviewed,
  confirmedAdditionalModifier: extra,
  additionalModifierIndependentlyConfirmed: extraConfirmed,
  situationalAdvantage: advantage,
  situationalDisadvantage: disadvantage,
);

void main() {
  test('Constitution ability and recorded proficiency are used once', () {
    final wizard = _hero();
    final untrained = _prepare(wizard);
    expect(untrained.baseModifier, 2);
    expect(untrained.totalModifier, 2);
    expect(untrained.additionalModifier, 0);
    expect(untrained.isNormalRoll, isTrue);

    final fighter = _hero(
      className: 'Kämpfer',
      proficiencies: const ['strength', 'constitution'],
    );
    final practiced = _prepare(fighter);
    expect(practiced.baseModifier, 5);
    expect(practiced.totalModifier, 5);
    expect(practiced.isNormalRoll, isTrue);
    expect(wizard.spentSpellSlots, isEmpty);
  });

  test('Monk 14 Disciplined Survivor grants proficiency but never twice', () {
    final monk = _hero(className: 'Mönch', level: 14);
    final gained = _prepare(monk);
    expect(gained.baseModifier, 7);
    final alreadyRecorded = _prepare(
      _hero(
        className: 'Mönch',
        level: 14,
        proficiencies: const ['constitution'],
      ),
    );
    expect(alreadyRecorded.baseModifier, 7);
    final lower = _prepare(_hero(className: 'Mönch', level: 13));
    expect(lower.baseModifier, 2);

    final multiclass = _prepare(
      _hero(
        className: 'Kleriker',
        secondaryClassName: 'Mönch',
        secondaryClassLevel: 14,
        level: 17,
      ),
    );
    expect(multiclass.baseModifier, 8);
  });

  test('Exhaustion affects every concentration saving throw once', () {
    final hero = _hero(
      className: 'Kämpfer',
      level: 9,
      exhaustion: 2,
      proficiencies: const ['constitution'],
    );
    final evidence = _prepare(hero);
    // CON +2, level-9 proficiency +4, exhaustion -4.
    expect(evidence.baseModifier, 2);
    expect(evidence.totalModifier, 2);
    expect(hero.exhaustionLevel, 2);
  });

  test('confirmed additional modifiers remain explicit and bounded', () {
    final hero = _hero();
    expect(
      () => _prepare(hero, otherReviewed: false),
      throwsFormatException,
    );
    expect(() => _prepare(hero, rollReviewed: false), throwsFormatException);
    expect(() => _prepare(hero, extra: 2), throwsFormatException);
    expect(
      () => _prepare(hero, extra: 31, extraConfirmed: true),
      throwsRangeError,
    );
    expect(
      () => _prepare(hero, extra: -31, extraConfirmed: true),
      throwsRangeError,
    );
    final positive = _prepare(hero, extra: 5, extraConfirmed: true);
    expect(positive.baseModifier, 2);
    expect(positive.additionalModifier, 5);
    expect(positive.totalModifier, 7);
    final negative = _prepare(hero, extra: -2, extraConfirmed: true);
    expect(negative.totalModifier, 0);
  });

  test('advantage and disadvantage cancel but never stack', () {
    final hero = _hero();
    final advantage = _prepare(hero, advantage: true);
    expect(advantage.advantage, isTrue);
    expect(advantage.disadvantage, isFalse);
    expect(advantage.isNormalRoll, isFalse);

    final opposed = _prepare(
      hero,
      advantage: true,
      disadvantage: true,
    );
    expect(opposed.advantage, isTrue);
    expect(opposed.disadvantage, isTrue);
    expect(opposed.isNormalRoll, isTrue);
    expect(opposed.totalModifier, 2);
  });

  test('missing ability, incoherent class and altered proficiency fail', () {
    final bad = [
      _hero(constitution: null),
      _hero(constitution: 0),
      _hero(constitution: 31),
      _hero(className: 'Unbekannt'),
      _hero(level: 0),
      _hero(level: 21),
      _hero(secondaryClassLevel: 1),
      _hero(secondaryClassName: 'Magier', secondaryClassLevel: 1),
      _hero(secondaryClassName: 'Unbekannt', secondaryClassLevel: 1),
      _hero(secondaryClassName: 'Mönch', secondaryClassLevel: 5),
      _hero(proficiencies: const ['constitution', 'constitution']),
      _hero(proficiencies: const ['constitution', 'invented']),
    ];
    for (final hero in bad) {
      expect(
        () => _prepare(hero),
        throwsA(anyOf(isA<FormatException>(), isA<StateError>(), isA<RangeError>())),
        reason: hero.classSummary,
      );
    }
  });

  test('incapacitation, lost concentration and unknown HP fail closed', () {
    final bad = [
      _hero(hitPoints: null),
      _hero(hitPoints: 0),
      _hero(conditions: const ['bewusstlos']),
      _hero(conditions: const ['betäubt']),
      _hero(conditions: const ['handlungsunfähig']),
      _hero(conditions: const ['tot']),
      _hero(concentratingOn: ''),
      _hero(concentratingOn: ' Invisibility '),
    ];
    for (final hero in bad) {
      expect(() => _prepare(hero), throwsStateError);
    }
  });

  test('evidence binds to exact immutable hero snapshot and JSON', () {
    final hero = _hero();
    final before = jsonEncode(hero.toJson());
    final evidence = _prepare(
      hero,
      extra: 2,
      extraConfirmed: true,
      disadvantage: true,
    );
    evidence.validateUnchanged(hero);
    expect(evidence.totalModifier, 4);
    expect(evidence.disadvantage, isTrue);
    expect(jsonEncode(hero.toJson()), before);

    final restored = HeroCharacter.fromJson(hero.toJson());
    evidence.validateUnchanged(restored);
    expect(
      () => evidence.validateUnchanged(hero.copyWith(gold: 17)),
      throwsFormatException,
    );
    expect(
      () => evidence.validateUnchanged(
        hero.copyWith(concentratingOn: 'Web'),
      ),
      throwsFormatException,
    );
  });
}
