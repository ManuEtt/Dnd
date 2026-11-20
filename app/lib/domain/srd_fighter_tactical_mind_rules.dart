import 'dart:convert';
import 'dart:math';

import 'class_feature_resources.dart';
import 'class_resource_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'skill_check_passives.dart';
import 'srd_class_feature_catalog.dart';

/// SRD 5.2.1, Fighter 2: Tactical Mind, printed p. 48 (CC BY 4.0).
/// A failed ability check can gain 1d10 instead of Second Wind healing.
/// The Second Wind use is expended only if the revised check succeeds.
///
/// This produces an uncommitted rule result. The caller must atomically record
/// the attempt, check outcome and hero, even when the resource is not spent.
/// Neither free narration nor a previously processed failure grants a retry.
class SrdFighterTacticalMindRules {
  const SrdFighterTacticalMindRules._();

  static const _abilityCheckTypes = {'preparedCheck', 'perception', 'escape'};

  static SrdFighterTacticalMindDecision prepare({
    required HeroCharacter hero,
    required PendingRoll check,
    required DiceResult failedRoll,
    required Set<String> previouslyAttemptedCheckIds,
  }) {
    _validateHero(hero);
    // Reuse the existing saved request contract, including its modifier,
    // difficulty, minimum-natural and attack-only metadata restrictions.
    final validated = PendingRoll.fromJson(check.toJson());
    if (!_abilityCheckTypes.contains(validated.type)) {
      throw const FormatException(
        'Taktischer Verstand benötigt eine bestätigte Attributsprobe.',
      );
    }
    _validateUnprocessed(validated.id, previouslyAttemptedCheckIds);
    _validateRoll(validated, failedRoll);
    if (validated.minimumNatural == 10 &&
        ClassResourceRules.level(hero, 'Schurke') < 7) {
      throw const FormatException(
        'Der natürliche Mindestwurf benötigt eine bestätigte Schurkenstufe 7.',
      );
    }
    final effective = SkillCheckPassives.effectiveTotal(
      total: failedRoll.total,
      natural: failedRoll.natural,
      minimumNatural: validated.minimumNatural,
    );
    // Ability checks have no automatic success/failure on natural 20/1.
    if (effective >= validated.difficulty) {
      throw const FormatException(
        'Taktischer Verstand ist nur nach einer fehlgeschlagenen Probe möglich.',
      );
    }
    return SrdFighterTacticalMindDecision._(
      check: validated,
      originalRoll: failedRoll,
      originalEffectiveTotal: effective,
      sourceSnapshot: jsonEncode(hero.toJson()),
    );
  }

  static SrdFighterTacticalMindResult resolve({
    required HeroCharacter hero,
    required SrdFighterTacticalMindDecision decision,
    required DiceEngine dice,
    required bool playerConfirmed,
    required Set<String> previouslyAttemptedCheckIds,
  }) {
    if (!playerConfirmed) {
      throw const FormatException(
        'Taktischen Verstand nach dem Fehlschlag ausdrücklich bestätigen.',
      );
    }
    if (jsonEncode(hero.toJson()) != decision.sourceSnapshot) {
      throw const FormatException(
        'Die Entscheidung ist durch eine Charakteränderung veraltet.',
      );
    }
    _validateUnprocessed(decision.check.id, previouslyAttemptedCheckIds);
    _validateHero(hero);
    // Even an unreachable DC still rolls the explicitly selected die. Do not
    // reroll the d20, add the Fighter level or apply the old modifier again.
    final bonus = dice.roll('1d10');
    final total = decision.originalEffectiveTotal + bonus.total;
    final passed = total >= decision.check.difficulty;
    return SrdFighterTacticalMindResult._(
      hero: passed
          ? hero.copyWith(spentSecondWind: hero.spentSecondWind + 1)
          : hero,
      checkId: decision.check.id,
      originalRoll: decision.originalRoll,
      bonusRoll: bonus,
      originalEffectiveTotal: decision.originalEffectiveTotal,
      total: total,
      difficulty: decision.check.difficulty,
      passed: passed,
      secondWindSpent: passed ? 1 : 0,
      attemptedCheckIds: Set.unmodifiable({
        ...previouslyAttemptedCheckIds,
        decision.check.id,
      }),
    );
  }

  static void _validateHero(HeroCharacter hero) {
    if (!SrdClassFeatureCatalog.hasConsistentClassLevels(hero)) {
      throw const FormatException(
        'Die bestätigten Klassen und Stufen sind nicht konsistent.',
      );
    }
    if (ClassFeatureResources.fighterLevel(hero) < 2) {
      throw StateError('Taktischer Verstand erfordert Kämpferstufe 2.');
    }
    if (hero.isDead ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.conditions.contains('bewusstlos')) {
      throw StateError(
        'Die Entscheidung benötigt einen lebenden, bewussten Charakter.',
      );
    }
    // Tactical Mind is not the Second Wind Bonus Action: no action, reaction,
    // healing or Tactical Shift movement is consumed or granted here.
    if (ClassFeatureResources.remainingSecondWind(hero) < 1) {
      throw StateError('Für Taktischen Verstand fehlt eine Nutzung Zweiter Wind.');
    }
  }

  static void _validateUnprocessed(String id, Set<String> attempted) {
    if (id.trim().isEmpty || attempted.contains(id)) {
      throw const FormatException(
        'Diese Probe wurde bereits mit Taktischem Verstand ausgewertet.',
      );
    }
  }

  static String _suffix(int modifier) => modifier == 0
      ? ''
      : modifier > 0
      ? '+$modifier'
      : '$modifier';

  static void _validateRoll(PendingRoll check, DiceResult roll) {
    if (roll.natural == null) {
      if (roll.expression != 'Manuelles Gesamtergebnis' ||
          roll.rolls.isNotEmpty ||
          roll.modifier != 0 ||
          roll.total < -DiceEngine.maxModifier ||
          roll.total > DiceEngine.maxModifier + 20) {
        throw const FormatException('Ungültiges bestätigtes Gesamtergebnis.');
      }
      return;
    }
    final natural = roll.natural!;
    final suffix = _suffix(check.modifier);
    final manual = roll.expression == 'Manueller W20$suffix';
    final expectedCount = manual
        ? 1
        : check.advantage != check.disadvantage
        ? 2
        : 1;
    if ((!manual && roll.expression != '1d20$suffix') ||
        natural < 1 ||
        natural > 20 ||
        roll.modifier != check.modifier ||
        roll.total != natural + check.modifier ||
        roll.rolls.length != expectedCount ||
        roll.rolls.any((value) => value < 1 || value > 20)) {
      throw const FormatException('Der W20 passt nicht zur bestätigten Probe.');
    }
    final chosen = expectedCount == 1
        ? roll.rolls.single
        : check.advantage
        ? max(roll.rolls[0], roll.rolls[1])
        : min(roll.rolls[0], roll.rolls[1]);
    if (chosen != natural) {
      throw const FormatException('Vorteil oder Nachteil ist nicht korrekt belegt.');
    }
  }
}

/// A choice bound to the confirmed character and the original failed check.
/// Discarding it changes nothing. This is not a completed check or saved event.
class SrdFighterTacticalMindDecision {
  const SrdFighterTacticalMindDecision._({
    required this.check,
    required this.originalRoll,
    required this.originalEffectiveTotal,
    required this.sourceSnapshot,
  });

  final PendingRoll check;
  final DiceResult originalRoll;
  final int originalEffectiveTotal;
  final String sourceSnapshot;
}

class SrdFighterTacticalMindResult {
  const SrdFighterTacticalMindResult._({
    required this.hero,
    required this.checkId,
    required this.originalRoll,
    required this.bonusRoll,
    required this.originalEffectiveTotal,
    required this.total,
    required this.difficulty,
    required this.passed,
    required this.secondWindSpent,
    required this.attemptedCheckIds,
  });

  final HeroCharacter hero;
  final String checkId;
  final DiceResult originalRoll, bonusRoll;
  final int originalEffectiveTotal, total, difficulty, secondWindSpent;
  final bool passed;

  /// Persist this evidence even on failure: retaining the resource is not
  /// permission to repeatedly process the same original failed check.
  final Set<String> attemptedCheckIds;

  Map<String, dynamic> toJson() => {
    'feature': 'Tactical Mind',
    'checkId': checkId,
    'originalRoll': originalRoll.toJson(),
    'bonusRoll': bonusRoll.toJson(),
    'originalEffectiveTotal': originalEffectiveTotal,
    'total': total,
    'difficulty': difficulty,
    'passed': passed,
    'secondWindSpent': secondWindSpent,
  };
}
