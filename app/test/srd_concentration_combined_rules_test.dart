import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_concentration_damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_concentration_save_modifier_rules.dart';

HeroCharacter _hero({int constitution = 16, int exhaustion = 0}) =>
    HeroCharacter(
      id: 'combined-concentration',
      name: 'Konzentrationsprobe',
      className: 'Kämpfer',
      level: 5,
      abilities: {
        'strength': 14,
        'dexterity': 12,
        'constitution': constitution,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
      },
      savingThrowProficiencies: const ['strength', 'constitution'],
      exhaustionLevel: exhaustion,
      hitPoints: 25,
      maxHitPoints: 40,
      concentratingOn: 'Invisibility',
    );

SrdConcentrationSaveModifierEvidence _prepare(
  HeroCharacter hero,
  int additionalModifier,
) => SrdConcentrationSaveModifierRules.prepare(
  hero,
  otherModifierSourcesReviewedConfirmed: true,
  rollCircumstancesReviewedConfirmed: true,
  confirmedAdditionalModifier: additionalModifier,
  additionalModifierIndependentlyConfirmed: true,
);

void main() {
  for (final (constitution, exhaustion, extra, expected) in [
    (16, 0, 30, 36),
    (8, 5, -30, -38),
  ]) {
    test(
      'confirmed total $expected flows from preparation into damage save',
      () {
        final hero = _hero(constitution: constitution, exhaustion: exhaustion);
        final original = jsonEncode(hero.toJson());
        final evidence = _prepare(hero, extra);
        expect(evidence.totalModifier, expected);
        evidence.validateUnchanged(hero);

        final result = SrdConcentrationDamageRules.resolve(
          hero,
          sources: [
            SrdConcentrationDamageSource(
              sourceId: 'confirmed-damage',
              damageTaken: 5,
              damageConfirmed: true,
              confirmedNaturalD20: 10,
              confirmedConstitutionSaveModifier: evidence.totalModifier,
              savingThrowModifiersConfirmed: true,
              rollCircumstancesConfirmed: evidence.isNormalRoll,
            ),
          ],
          postDamageHeroSnapshotConfirmed: true,
        );
        expect(result.checks.single.savingThrowModifier, expected);
        expect(result.checks.single.total, 10 + expected);
        expect(result.maintained, expected > 0);
        expect(
          HeroCharacter.fromJson(result.hero.toJson()).concentratingOn,
          expected > 0 ? 'Invisibility' : '',
        );
        expect(jsonEncode(hero.toJson()), original);
      },
    );
  }

  test('named secondary class with zero levels cannot confirm evidence', () {
    final hero = _hero().copyWith(
      secondaryClassName: 'Magier',
      secondaryClassLevel: 0,
    );
    final original = jsonEncode(hero.toJson());
    expect(() => _prepare(hero, 0), throwsFormatException);
    expect(jsonEncode(hero.toJson()), original);
  });
}
