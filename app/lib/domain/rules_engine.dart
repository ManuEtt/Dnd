import 'damage_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'condition_rules.dart';
import 'death_saving_throw_rules.dart';
import 'fighter_style_combat_rules.dart';

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
      (hero.weaponProficient ? proficiencyBonus(hero.level) : 0) +
      FighterStyleCombatRules.archeryBonus(
        hero,
        FighterStyleCombatRules.equippedWeapon(hero),
      ) +
      ExhaustionRules.d20Modifier(hero);

  static int initiativeBonus(HeroCharacter hero) =>
      _ability(hero, 'dexterity') + ExhaustionRules.d20Modifier(hero);

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
        _ability(hero, hero.weaponAbility) +
        FighterStyleCombatRules.greatWeaponDamageBonus(hero, baseRoll) +
        (criticalExtra == null
            ? 0
            : FighterStyleCombatRules.greatWeaponDamageBonus(
                hero,
                criticalExtra,
              ));
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
    int criticalThreshold = 20,
  }) {
    if (criticalThreshold < 18 || criticalThreshold > 20) {
      throw RangeError.range(criticalThreshold, 18, 20);
    }
    if (armorClass < 1 || armorClass > 100) {
      throw RangeError.range(armorClass, 1, 100, 'armorClass');
    }
    if (roll.natural == 1) {
      return const AttackOutcome(hit: false, critical: false);
    }
    if (roll.natural != null && roll.natural! >= criticalThreshold) {
      return const AttackOutcome(hit: true, critical: true);
    }
    return AttackOutcome(hit: roll.total >= armorClass, critical: false);
  }

  /// Grant temporary hit points; they never add together. A player may elect
  /// to replace a larger pool with a smaller new pool via [replaceExisting].
  static HeroCharacter grantTemporaryHitPoints(
    HeroCharacter hero,
    int amount, {
    bool replaceExisting = false,
  }) {
    _validateAmount(amount);
    if (hero.temporaryHitPoints < 0 || hero.temporaryHitPoints > 100000) {
      throw StateError('Ungültige temporäre Trefferpunkte.');
    }
    if (hero.isDead) {
      throw StateError(
        'Tote Charaktere erhalten keine temporären Trefferpunkte.',
      );
    }
    if (!replaceExisting && amount <= hero.temporaryHitPoints) return hero;
    return hero.copyWith(temporaryHitPoints: amount);
  }

  static HeroCharacter damage(
    HeroCharacter hero,
    int amount, {
    bool critical = false,
  }) {
    _validateHitPoints(hero);
    _validateAmount(amount);
    if (amount == 0 || hero.isDead) return hero;
    if (hero.temporaryHitPoints < 0 || hero.temporaryHitPoints > 100000) {
      throw StateError('Ungültige temporäre Trefferpunkte.');
    }
    // Temporary HP buffer actual HP loss, not the fact of taking damage.
    // SRD 5.2.1 p. 18: any damage at 0 HP causes a death-save failure, even
    // when Temporary HP absorb it. Critical damage causes two failures.
    final absorbed = amount < hero.temporaryHitPoints
        ? amount
        : hero.temporaryHitPoints;
    final remaining = amount - absorbed;
    final temporaryLeft = hero.temporaryHitPoints - absorbed;
    final hp = hero.hitPoints!;
    final maxHp = hero.maxHitPoints!;
    final conditions = [...hero.conditions]..remove(stable);
    if (hp == 0) {
      final instantDeath = amount >= maxHp;
      final failures = instantDeath
          ? 3
          : hero.deathFailures + (critical ? 2 : 1);
      _addCondition(conditions, unconscious);
      if (failures >= 3) _addCondition(conditions, dead);
      return hero.copyWith(
        temporaryHitPoints: temporaryLeft,
        conditions: conditions,
        concentratingOn: '',
        deathSuccesses: instantDeath ? 0 : hero.deathSuccesses,
        deathFailures: failures > 3 ? 3 : failures,
      );
    }
    if (remaining == 0) {
      return hero.copyWith(temporaryHitPoints: temporaryLeft);
    }
    final remainingDamage = remaining - hp;
    if (remainingDamage >= maxHp) {
      _addCondition(conditions, unconscious);
      _addCondition(conditions, dead);
      return hero.copyWith(
        hitPoints: 0,
        temporaryHitPoints: temporaryLeft,
        conditions: conditions,
        concentratingOn: '',
        deathSuccesses: 0,
        deathFailures: 3,
      );
    }
    final nextHp = hp - remaining;
    if (nextHp <= 0) {
      _addCondition(conditions, unconscious);
      return hero.copyWith(
        hitPoints: 0,
        temporaryHitPoints: temporaryLeft,
        conditions: conditions,
        concentratingOn: '',
        deathSuccesses: 0,
        deathFailures: 0,
      );
    }
    return hero.copyWith(
      hitPoints: nextHp,
      temporaryHitPoints: temporaryLeft,
      conditions: conditions,
    );
  }

  /// Resolve explicitly typed damage against explicitly known defenses before
  /// applying existing HP, death-save and concentration bookkeeping.
  /// Unknown defense profiles are not silently guessed from character names.
  /// Existing untyped encounters continue using [damage] until their source
  /// provides a verified damage type and a defense profile.
  static HeroCharacter damageWithDefenses(
    HeroCharacter hero, {
    required Iterable<DamageComponent> components,
    required DamageDefenses defenses,
    bool critical = false,
  }) {
    final result = DamageRules.resolve(components, defenses: defenses);
    return damage(hero, result.total, critical: critical);
  }

  static HeroCharacter heal(HeroCharacter hero, int amount) {
    _validateHitPoints(hero);
    _validateAmount(amount);
    if (hero.isDead) {
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
    return DeathSavingThrowRules.resolve(hero: hero, natural: natural).hero;
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
