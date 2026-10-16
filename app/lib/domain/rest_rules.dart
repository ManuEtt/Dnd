import 'dice_engine.dart';
import 'models.dart';
import 'condition_rules.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';
import 'spellcasting_rules.dart';
import 'class_feature_resources.dart';
import 'class_resource_rules.dart';

/// Mechanically confirmed portion of the SRD 5.2.1 rest rules.
/// Tracks spent Hit Dice without changing the existing save schema version.
/// Timed interruptions, class-feature recovery, ability-score restoration and
/// Exhaustion need separate tracked world-time/status features; not implied.
class RestRules {
  const RestRules._();

  static Map<String, int> availableHitDice(HeroCharacter hero) {
    final first = findSrdClass(hero.className);
    final second = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)
        : null;
    if (first == null || (hero.hasSecondClass && second == null) ||
        hero.primaryClassLevel < 1 ||
        (hero.hasSecondClass && hero.secondaryClassLevel < 1)) {
      throw const FormatException('Für die Klasse fehlen gültige Trefferwürfel.');
    }
    final pool = <String, int>{};
    void add(int die, int count) {
      final key = 'd$die';
      pool[key] = (pool[key] ?? 0) + count;
    }
    add(first.hitDie, hero.primaryClassLevel);
    if (second != null) add(second.hitDie, hero.secondaryClassLevel);
    for (final spent in hero.spentHitDice.entries) {
      if (!pool.containsKey(spent.key) || spent.value < 0 ||
          spent.value > pool[spent.key]!) {
        throw const FormatException('Verbrauchte Trefferwürfel passen nicht zu den Klassenstufen.');
      }
      pool[spent.key] = pool[spent.key]! - spent.value;
    }
    return Map.unmodifiable(pool);
  }

  static ShortRestResult shortRest(
    HeroCharacter hero, {
    required DiceEngine dice,
    int? dieSides,
    int count = 1,
  }) {
    _ensureRestPossible(hero);
    if (count < 1 || count > 20) {
      throw RangeError.range(count, 1, 20, 'count');
    }
    final available = availableHitDice(hero);
    final requested = dieSides == null ?
        (available.entries.where((entry) => entry.value >= count).isEmpty
          ? null
          : available.entries.firstWhere((entry) => entry.value >= count).key)
        : 'd$dieSides';
    if (requested == null || !available.containsKey(requested) ||
        available[requested]! < count) {
      throw StateError('Nicht genügend passende Trefferwürfel verfügbar.');
    }
    final constitution = hero.abilities['constitution'];
    if (constitution == null) {
      throw StateError('Konstitution ist noch nicht bestätigt.');
    }
    final bonus = RulesEngine.abilityModifier(constitution);
    final rolls = <DiceResult>[];
    var healed = hero;
    for (var i = 0; i < count; i++) {
      final roll = dice.roll('1$requested');
      rolls.add(roll);
      final gain = roll.rolls.single + bonus;
      healed = RulesEngine.heal(healed, gain < 1 ? 1 : gain);
    }
    healed = ClassResourceRules.afterShortRest(
      ClassFeatureResources.afterShortRest(
        SpellcastingRules.afterShortRest(healed))).copyWith(spentHitDice: {
      ...hero.spentHitDice,
      requested: (hero.spentHitDice[requested] ?? 0) + count,
    });
    return ShortRestResult(
      hero: healed,
      dice: List.unmodifiable(rolls),
      dieType: requested,
      recovered: healed.hitPoints! - hero.hitPoints!,
      constitutionBonus: bonus,
    );
  }

  static HeroCharacter longRest(HeroCharacter hero) {
    _ensureRestPossible(hero);
    // The SRD restores all lost HP and all spent Hit Dice after a Long Rest.
    // No class-specific charges are fabricated by this generic rule.
    return ClassResourceRules.afterLongRest(
      ClassFeatureResources.afterLongRest(
        SpellcastingRules.afterLongRest(
          ExhaustionRules.afterLongRest(hero).copyWith(
            hitPoints: hero.maxHitPoints,
            temporaryHitPoints: 0,
            spentHitDice: const {},
          ),
        ),
      ),
    );
  }

  static void _ensureRestPossible(HeroCharacter hero) {
    if (hero.hitPoints == null || hero.maxHitPoints == null ||
        hero.hitPoints! <= 0 || hero.maxHitPoints! < 1 ||
        hero.hitPoints! > hero.maxHitPoints! || hero.isDead) {
      throw StateError('Eine Rast erfordert mindestens einen Trefferpunkt und einen bestätigten Charakterbogen.');
    }
  }
}

class ShortRestResult {
  const ShortRestResult({required this.hero, required this.dice,
    required this.dieType, required this.recovered,
    required this.constitutionBonus});
  final HeroCharacter hero;
  final List<DiceResult> dice;
  final String dieType;
  final int recovered;
  final int constitutionBonus;
}
