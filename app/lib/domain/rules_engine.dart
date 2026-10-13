import 'dice_engine.dart';
import 'models.dart';

class AttackOutcome {
  const AttackOutcome({required this.hit, required this.critical});
  final bool hit;
  final bool critical;
}

/// All mechanical character changes belong here, never in narrative output.
class RulesEngine {
  static const unconscious = 'bewusstlos';
  static const stable = 'stabil';
  static const dead = 'tot';

  static int abilityModifier(int score) {
    if (score < 1 || score > 30) {
      throw RangeError.range(score, 1, 30, 'score');
    }
    return ((score - 10) / 2).floor();
  }

  static int proficiencyBonus(int level) {
    if (level < 1 || level > 20) {
      throw RangeError.range(level, 1, 20, 'level');
    }
    return 2 + (level - 1) ~/ 4;
  }

  static int attackBonus(HeroCharacter hero) =>
      _ability(hero, hero.weaponAbility) +
      (hero.weaponProficient ? proficiencyBonus(hero.level) : 0);

  static int initiativeBonus(HeroCharacter hero) => _ability(hero, 'dexterity');

  static int initiative(HeroCharacter hero) => initiativeBonus(hero);

  /// [baseRoll] includes any flat weapon bonus, but excludes the ability bonus.
  /// On a critical only the extra dice are added: flat bonuses are applied once.
  static int weaponDamage(
    HeroCharacter hero, {
    required DiceResult baseRoll,
    DiceResult? criticalExtra,
  }) {
    final result =
        baseRoll.total +
        (criticalExtra == null
            ? 0
            : criticalExtra.total - criticalExtra.modifier) +
        _ability(hero, hero.weaponAbility);
    return result < 0 ? 0 : result;
  }

  static int remainingHitPoints({required int hitPoints, required int damage}) {
    if (hitPoints < 0) throw RangeError.value(hitPoints, 'hitPoints');
    _validateAmount(damage);
    return damage >= hitPoints ? 0 : hitPoints - damage;
  }

  static AttackOutcome attack({
    required DiceResult roll,
    required int armorClass,
  }) {
    if (armorClass < 1 || armorClass > 100) {
      throw RangeError.range(armorClass, 1, 100, 'armorClass');
    }
    if (roll.natural == 1) {
      return const AttackOutcome(hit: false, critical: false);
    }
    if (roll.natural == 20) {
      return const AttackOutcome(hit: true, critical: true);
    }
    return AttackOutcome(hit: roll.total >= armorClass, critical: false);
  }

  static HeroCharacter damage(
    HeroCharacter hero,
    int amount, {
    bool critical = false,
  }) {
    _validateHitPoints(hero);
    _validateAmount(amount);
    if (amount == 0 || hero.conditions.contains(dead)) return hero;
    final hp = hero.hitPoints!;
    final maxHp = hero.maxHitPoints!;
    final conditions = [...hero.conditions]..remove(stable);
    final remainingDamage = amount - hp;
    if (remainingDamage >= maxHp) {
      _addCondition(conditions, unconscious);
      _addCondition(conditions, dead);
      return hero.copyWith(
        hitPoints: 0,
        conditions: conditions,
        deathSuccesses: 0,
        deathFailures: 3,
      );
    }
    if (hp == 0) {
      final failures = hero.deathFailures + (critical ? 2 : 1);
      _addCondition(conditions, unconscious);
      if (failures >= 3) _addCondition(conditions, dead);
      return hero.copyWith(
        conditions: conditions,
        deathFailures: failures > 3 ? 3 : failures,
      );
    }
    final nextHp = hp - amount;
    if (nextHp <= 0) {
      _addCondition(conditions, unconscious);
      return hero.copyWith(
        hitPoints: 0,
        conditions: conditions,
        deathSuccesses: 0,
        deathFailures: 0,
      );
    }
    return hero.copyWith(hitPoints: nextHp, conditions: conditions);
  }

  static HeroCharacter heal(HeroCharacter hero, int amount) {
    _validateHitPoints(hero);
    _validateAmount(amount);
    if (hero.conditions.contains(dead)) {
      throw StateError('Ein toter Charakter kann nicht normal geheilt werden.');
    }
    if (amount == 0) return hero;
    final nextHp = hero.hitPoints! + amount;
    return hero.copyWith(
      hitPoints: nextHp > hero.maxHitPoints! ? hero.maxHitPoints! : nextHp,
      conditions: [...hero.conditions]
        ..remove(unconscious)
        ..remove(stable),
      deathSuccesses: 0,
      deathFailures: 0,
    );
  }

  static HeroCharacter deathSave(HeroCharacter hero, int natural) {
    _validateHitPoints(hero);
    if (natural < 1 || natural > 20) {
      throw RangeError.range(natural, 1, 20, 'natural');
    }
    if (hero.hitPoints != 0 ||
        hero.conditions.contains(dead) ||
        hero.conditions.contains(stable)) {
      throw StateError('Dieser Charakter benötigt keinen Todesrettungswurf.');
    }
    if (natural == 20) return heal(hero, 1);
    final conditions = [...hero.conditions];
    _addCondition(conditions, unconscious);
    var successes = hero.deathSuccesses;
    var failures = hero.deathFailures;
    if (natural >= 10) {
      successes++;
    } else {
      failures += natural == 1 ? 2 : 1;
    }
    if (failures >= 3) {
      _addCondition(conditions, dead);
      failures = 3;
    } else if (successes >= 3) {
      _addCondition(conditions, stable);
      successes = 0;
      failures = 0;
    }
    return hero.copyWith(
      conditions: conditions,
      deathSuccesses: successes,
      deathFailures: failures,
    );
  }

  static int _ability(HeroCharacter hero, String key) {
    final score = hero.abilities[key];
    if (score == null) {
      throw StateError('Der Attributswert $key ist noch nicht bestätigt.');
    }
    return abilityModifier(score);
  }

  static void _validateHitPoints(HeroCharacter hero) {
    final hp = hero.hitPoints;
    final maxHp = hero.maxHitPoints;
    if (hp == null || maxHp == null) {
      throw StateError('Die Trefferpunkte sind noch nicht bestätigt.');
    }
    if (maxHp < 1 || hp < 0 || hp > maxHp) {
      throw StateError('Die gespeicherten Trefferpunkte sind ungültig.');
    }
  }

  static void _validateAmount(int amount) {
    if (amount < 0 || amount > 100000) {
      throw RangeError.range(amount, 0, 100000, 'amount');
    }
  }

  static void _addCondition(List<String> conditions, String condition) {
    if (!conditions.contains(condition)) conditions.add(condition);
  }
}
