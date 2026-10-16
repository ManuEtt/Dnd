import 'character_rule_engine.dart';
import 'class_resource_rules.dart';
import 'condition_rules.dart';
import 'models.dart';

/// SRD 5.2.1 Monk Focus: bonus-action options with explicit point expenditure.
/// Does not claim to resolve opportunity attacks or absent map/jump mechanics.
enum MonkBonusAction { patientDefense, stepOfTheWind }

class MonkBonusResult {
  const MonkBonusResult({required this.hero, required this.encounter,
    required this.focusSpent, required this.movementAdded});
  final HeroCharacter hero;
  final Encounter encounter;
  final int focusSpent, movementAdded;
}

class MonkFocusActions {
  const MonkFocusActions._();

  static MonkBonusResult use(HeroCharacter hero, Encounter encounter, {
    required MonkBonusAction action,
    bool enhanced = false,
  }) {
    if (ClassResourceRules.level(hero, 'Mönch') < 2) {
      throw StateError('Mönchsfokus erfordert mindestens Mönchsstufe 2.');
    }
    if (encounter.isFinished || encounter.activeParticipant != 'hero' ||
        !ConditionRules.canTakeActions(hero)) {
      throw StateError('Der Charakter kann diese Bonusaktion nicht ausführen.');
    }
    if (encounter.bonusActionUsed) {
      throw StateError('Die Bonusaktion wurde in diesem Zug bereits verbraucht.');
    }
    var movementAdded = 0;
    if (action == MonkBonusAction.stepOfTheWind) {
      if (!ConditionRules.canMove(hero)) {
        throw StateError('Schritt des Windes erfordert Bewegungsfähigkeit.');
      }
      // Each Dash adds the current effective speed, not the remaining speed.
      final speed = CharacterRuleEngine.movementWholeMeters(hero);
      if (speed == null || speed <= 0) {
        throw StateError('Die Bewegungsrate ist nicht bestätigt.');
      }
      movementAdded = speed;
    }
    // Charge only after all deterministic validations succeeded.
    final updatedHero = enhanced
        ? ClassResourceRules.spend(hero, 'focusPoints') : hero;
    return MonkBonusResult(
      hero: updatedHero,
      focusSpent: enhanced ? 1 : 0,
      movementAdded: movementAdded,
      encounter: encounter.copyWith(
        bonusActionUsed: true,
        movementRemaining: encounter.movementRemaining + movementAdded,
        disengagedThisTurn: encounter.disengagedThisTurn ||
            action == MonkBonusAction.patientDefense || enhanced,
        dodgeActive: encounter.dodgeActive ||
            (action == MonkBonusAction.patientDefense && enhanced),
        jumpDoubledThisTurn: encounter.jumpDoubledThisTurn ||
            (action == MonkBonusAction.stepOfTheWind && enhanced),
      ),
    );
  }
}
