import 'class_resource_rules.dart';
import 'condition_rules.dart';
import 'condition_effects.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 Paladin 1: Lay on Hands, for the confirmed player character.
/// Targeting allies needs actual party-member records and is not guessed.
/// Both healing and removing Poisoned draw from the same long-rest pool.
class PaladinLayOnHands {
  const PaladinLayOnHands._();

  /// Directly constructed and older profiles can contain contradictory class
  /// names or level splits. Such data must not unlock healing resources.
  static int? _paladinLevel(HeroCharacter hero) {
    if (hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        hero.secondaryClassLevel < 0) {
      return null;
    }
    final primary = findSrdClass(hero.className)?.name;
    final secondary = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (primary == null ||
        (hero.hasSecondClass
            ? hero.secondaryClassLevel < 1 ||
                  secondary == null ||
                  secondary == primary
            : hero.secondaryClassLevel != 0)) {
      return null;
    }
    return (primary == 'Paladin' ? hero.primaryClassLevel : 0) +
        (secondary == 'Paladin' ? hero.secondaryClassLevel : 0);
  }

  /// Read-only availability fails closed for inconsistent legacy profiles.
  /// Explicit use rejects the profile before spending any healing points.
  static int remaining(HeroCharacter hero) {
    if ((_paladinLevel(hero) ?? 0) < 1) return 0;
    return ClassResourceRules.remaining(hero, 'layOnHands');
  }

  /// A confirmed Bonus Action; the encounter's action economy is checked by
  /// the caller. A Poisoned removal costs five points without healing.
  static LayOnHandsResult useOnSelf(
    HeroCharacter hero, {
    int healing = 0,
    bool removePoisoned = false,
  }) {
    final paladinLevel = _paladinLevel(hero);
    if (paladinLevel == null) {
      throw const FormatException(
        'Die bestätigten Klassen und Stufen sind nicht konsistent.',
      );
    }
    if (paladinLevel < 1) {
      throw StateError('Handauflegen erfordert mindestens eine Paladinstufe.');
    }
    final currentHp = hero.hitPoints;
    final maximumHp = hero.maxHitPoints;
    if (!ConditionRules.canTakeActions(hero) ||
        currentHp == null ||
        currentHp <= 0 ||
        maximumHp == null) {
      throw StateError(
        'Handauflegen erfordert einen handlungsfähigen Charakter mit bestätigten Trefferpunkten.',
      );
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
    final finalHero = removePoisoned
        ? ConditionEffectRules.endCondition(healed, 'vergiftet')
        : healed;
    return LayOnHandsResult(
      hero: finalHero,
      pointsSpent: cost,
      hitPointsRestored: (finalHero.hitPoints ?? 0) - currentHp,
      poisonedRemoved: removePoisoned,
    );
  }
}

class LayOnHandsResult {
  const LayOnHandsResult({
    required this.hero,
    required this.pointsSpent,
    required this.hitPointsRestored,
    required this.poisonedRemoved,
  });
  final HeroCharacter hero;
  final int pointsSpent, hitPointsRestored;
  final bool poisonedRemoved;
}
