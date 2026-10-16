import 'class_resource_rules.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'rules_engine.dart';

/// SRD 5.2.1 Paladin 1: Lay on Hands, for the confirmed player character.
/// Targeting allies needs actual party-member records and is not guessed.
/// Both healing and removing Poisoned draw from the same long-rest pool.
class PaladinLayOnHands {
  const PaladinLayOnHands._();

  static int remaining(HeroCharacter hero) =>
      ClassResourceRules.remaining(hero, 'layOnHands');

  /// A confirmed Bonus Action; the encounter's action economy is checked by
  /// the caller. A Poisoned removal costs five points without healing.
  static LayOnHandsResult useOnSelf(HeroCharacter hero, {
    int healing = 0,
    bool removePoisoned = false,
  }) {
    if (ClassResourceRules.level(hero, 'Paladin') < 1) {
      throw StateError('Handauflegen erfordert mindestens eine Paladinstufe.');
    }
    final currentHp = hero.hitPoints;
    final maximumHp = hero.maxHitPoints;
    if (!ConditionRules.canTakeActions(hero) ||
        currentHp == null || currentHp <= 0 || maximumHp == null) {
      throw StateError('Handauflegen erfordert einen handlungsfähigen Charakter mit bestätigten Trefferpunkten.');
    }
    if (healing < 0 || healing > 100) {
      throw RangeError.range(healing, 0, 100, 'healing');
    }
    if (!removePoisoned && healing == 0) {
      throw StateError('Wähle Heilung oder die Entfernung von Vergiftet.');
    }
    if (removePoisoned && !hero.conditions.contains('vergiftet')) {
      throw StateError('Der Charakter ist nicht vergiftet.');
    }
    final cost = healing + (removePoisoned ? 5 : 0);
    if (cost > remaining(hero)) {
      throw StateError('Der Heilpunktevorrat reicht dafür nicht aus.');
    }
    final spent = ClassResourceRules.spend(hero, 'layOnHands', amount: cost);
    final healed = healing == 0 ? spent : RulesEngine.heal(spent, healing);
    final finalHero = removePoisoned ? healed.copyWith(
      conditions: [for (final condition in healed.conditions)
        if (condition != 'vergiftet') condition],
    ) : healed;
    return LayOnHandsResult(
      hero: finalHero,
      pointsSpent: cost,
      hitPointsRestored: (finalHero.hitPoints ?? 0) - currentHp,
      poisonedRemoved: removePoisoned,
    );
  }
}

class LayOnHandsResult {
  const LayOnHandsResult({required this.hero, required this.pointsSpent,
      required this.hitPointsRestored, required this.poisonedRemoved});
  final HeroCharacter hero;
  final int pointsSpent, hitPointsRestored;
  final bool poisonedRemoved;
}
