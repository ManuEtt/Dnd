import 'dart:math' as math;

import 'condition_rules.dart';
import 'models.dart';

/// One independently confirmed instance of damage while concentrating.
///
/// Each distinct damage source requires its own Constitution saving throw.
/// The supplied natural d20 must already account for any separately checked
/// Advantage/Disadvantage; no die is rolled or inferred from story text here.
class SrdConcentrationDamageSource {
  const SrdConcentrationDamageSource({
    required this.sourceId,
    required this.damageTaken,
    required this.damageConfirmed,
    this.confirmedNaturalD20,
    this.confirmedConstitutionSaveModifier,
    this.savingThrowModifiersConfirmed = false,
    this.rollCircumstancesConfirmed = false,
  });

  final String sourceId;
  final int damageTaken;
  final bool damageConfirmed;
  final int? confirmedNaturalD20;
  final int? confirmedConstitutionSaveModifier;
  final bool savingThrowModifiersConfirmed;
  final bool rollCircumstancesConfirmed;
}

/// Pure, auditable resolution of a single Constitution concentration save.
class SrdConcentrationDamageCheck {
  const SrdConcentrationDamageCheck({
    required this.sourceId,
    required this.damageTaken,
    required this.difficultyClass,
    required this.naturalD20,
    required this.savingThrowModifier,
    required this.total,
    required this.succeeded,
  });

  final String sourceId;
  final int damageTaken;
  final int difficultyClass;
  final int naturalD20;
  final int savingThrowModifier;
  final int total;
  final bool succeeded;
}

/// The returned hero is a new snapshot; the input hero is never modified.
/// The caller must persist it and its confirmation event atomically.
class SrdConcentrationDamageResult {
  const SrdConcentrationDamageResult({
    required this.hero,
    required this.checks,
    required this.maintained,
    required this.endedWithoutSave,
  });

  final HeroCharacter hero;
  final List<SrdConcentrationDamageCheck> checks;
  final bool maintained;
  final bool endedWithoutSave;
}

/// SRD 5.2.1 Rules Glossary / Concentration: DC = max(10, damage ~/ 2),
/// capped at 30 (unlike the older SRD 5.1 rule without this cap).
///
/// This is a standalone, deterministic rule transition, not an integrated
/// combat command. The caller must independently confirm that damage and its
/// effects were already applied to the supplied hero snapshot.
class SrdConcentrationDamageRules {
  const SrdConcentrationDamageRules._();

  static int difficultyClass(int confirmedDamage) {
    if (confirmedDamage < 1) {
      throw RangeError.range(confirmedDamage, 1, null, 'confirmedDamage');
    }
    return math.min(30, math.max(10, confirmedDamage ~/ 2));
  }

  static SrdConcentrationDamageResult resolve(
    HeroCharacter hero, {
    required List<SrdConcentrationDamageSource> sources,
    required bool postDamageHeroSnapshotConfirmed,
  }) {
    if (!postDamageHeroSnapshotConfirmed) {
      throw const FormatException(
        'Der Charakterzustand nach dem Schaden ist nicht bestätigt.',
      );
    }
    if (hero.concentratingOn.trim().isEmpty ||
        hero.concentratingOn != hero.concentratingOn.trim()) {
      throw const FormatException(
        'Es ist kein eindeutig bestätigter Konzentrationseffekt aktiv.',
      );
    }
    if (sources.isEmpty) {
      throw const FormatException('Keine Schadensquelle bestätigt.');
    }

    // Validate the entire batch before ANY state transition. A successful
    // earlier save must not hide an invalid later damage source.
    final identifiers = <String>{};
    for (final source in sources) {
      if (source.sourceId.isEmpty ||
          source.sourceId != source.sourceId.trim() ||
          source.sourceId.length > 128 ||
          !identifiers.add(source.sourceId) ||
          !source.damageConfirmed) {
        throw const FormatException(
          'Schadensquelle ist unbekannt, doppelt oder nicht bestätigt.',
        );
      }
      difficultyClass(source.damageTaken);
    }

    if (hero.hitPoints == null) {
      throw const FormatException(
        'Trefferpunkte nach dem Schaden sind nicht bestätigt.',
      );
    }
    if (hero.isDead ||
        hero.hitPoints! <= 0 ||
        !ConditionRules.canTakeActions(hero)) {
      // Incapacitated or dead ends concentration without rolling a save.
      return SrdConcentrationDamageResult(
        hero: hero.copyWith(concentratingOn: ''),
        checks: const [],
        maintained: false,
        endedWithoutSave: true,
      );
    }

    for (final source in sources) {
      final die = source.confirmedNaturalD20;
      final modifier = source.confirmedConstitutionSaveModifier;
      if (!source.savingThrowModifiersConfirmed ||
          !source.rollCircumstancesConfirmed ||
          die == null ||
          die < 1 ||
          die > 20 ||
          modifier == null ||
          modifier < -30 ||
          modifier > 30) {
        throw const FormatException(
          'W20 und vollständiger Konstitutionsrettungswurf sind nicht bestätigt.',
        );
      }
    }

    final checks = <SrdConcentrationDamageCheck>[];
    for (final source in sources) {
      final dc = difficultyClass(source.damageTaken);
      final natural = source.confirmedNaturalD20!;
      final modifier = source.confirmedConstitutionSaveModifier!;
      final total = natural + modifier;
      // Natural 1/20 have no automatic result on ordinary saving throws.
      final success = total >= dc;
      checks.add(
        SrdConcentrationDamageCheck(
          sourceId: source.sourceId,
          damageTaken: source.damageTaken,
          difficultyClass: dc,
          naturalD20: natural,
          savingThrowModifier: modifier,
          total: total,
          succeeded: success,
        ),
      );
      if (!success) {
        return SrdConcentrationDamageResult(
          hero: hero.copyWith(concentratingOn: ''),
          checks: List.unmodifiable(checks),
          maintained: false,
          endedWithoutSave: false,
        );
      }
    }
    return SrdConcentrationDamageResult(
      hero: hero,
      checks: List.unmodifiable(checks),
      maintained: true,
      endedWithoutSave: false,
    );
  }
}
