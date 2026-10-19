import 'models.dart';

/// SRD 5.2.1 (2024) Exhaustion. This differs from the 2014 six-step table.
/// All calculations are pure; only confirmed character updates mutate a copy.
/// Source: https://www.dndbeyond.com/sources/dnd/br-2024/rules-glossary
class ExhaustionRules {
  const ExhaustionRules._();

  static int _validate(int level) {
    if (level < 0 || level > 6) {
      throw RangeError.range(level, 0, 6, 'exhaustionLevel');
    }
    return level;
  }

  /// Every level subtracts 2 from an ability check, attack, or saving throw.
  static int d20Modifier(HeroCharacter hero) =>
      -2 * _validate(hero.exhaustionLevel);

  /// The app's existing speed field is in meters. Five feet = 1.5 m.
  /// Keep base speed unchanged; movement is calculated for this turn only.
  static double? effectiveSpeedMeters(HeroCharacter hero) {
    final speed = hero.speed;
    if (speed == null) return null;
    final reduced = speed - 1.5 * _validate(hero.exhaustionLevel);
    return reduced < 0 ? 0 : reduced;
  }

  /// Movement actions currently use whole meters. Never round UP beyond
  /// the reduced allowance or modify the saved base speed.
  static int? availableWholeMeters(HeroCharacter hero) =>
      effectiveSpeedMeters(hero)?.floor();

  /// This is an explicitly confirmed rule action; do not automatically infer
  /// Exhaustion from generic story text or from the legacy conditions list.
  static HeroCharacter gain(HeroCharacter hero, {int levels = 1}) {
    if (levels < 1 || levels > 6) {
      throw RangeError.range(levels, 1, 6, 'levels');
    }
    if (hero.isDead) {
      throw StateError(
        'Tote Charaktere können keine weitere Erschöpfung erhalten.',
      );
    }
    final next = (_validate(hero.exhaustionLevel) + levels).clamp(0, 6).toInt();
    return hero.copyWith(
      exhaustionLevel: next,
      concentratingOn: next == 6 ? '' : hero.concentratingOn,
      conditions: next == 6 && !hero.conditions.contains('tot')
          ? [...hero.manualConditions, 'tot']
          : hero.manualConditions,
    );
  }

  /// SRD 5.2.1: finishing a valid Long Rest removes exactly one level.
  /// Time requirements and rest interruptions are not tracked yet.
  static HeroCharacter afterLongRest(HeroCharacter hero) {
    if (hero.isDead) {
      throw StateError('Ein toter Charakter kann nicht rasten.');
    }
    final level = _validate(hero.exhaustionLevel);
    return level == 0 ? hero : hero.copyWith(exhaustionLevel: level - 1);
  }
}

/// Read-only effects of established SRD conditions, without automatically
/// fabricating a source, duration, target, or concentration state.
/// Synonyms from older free-form character sheets remain untouched.
class ConditionRules {
  const ConditionRules._();

  /// SRD 5.2.1, Unconscious (Rules Glossary, p. 191): becoming unconscious
  /// also makes the creature Prone; after Unconscious ends it remains Prone.
  /// This persistent consequence is a separate manual condition, NOT a
  /// synthetic entry in the independent source-effect ledger.
  ///
  /// Apply only in confirmed rule transitions. Merely reading a legacy save
  /// must not silently rewrite its history; a later confirmed recovery can
  /// establish the required Prone consequence without losing effect metadata.
  static HeroCharacter retainProneFromUnconscious(
    HeroCharacter before,
    HeroCharacter after,
  ) {
    if ((!before.conditions.contains('bewusstlos') &&
            !after.conditions.contains('bewusstlos')) ||
        after.manualConditions.contains('liegend')) {
      return after;
    }
    return after.copyWith(conditions: [...after.manualConditions, 'liegend']);
  }

  static const Map<String, String> descriptions = {
    'blind':
        'Kann nicht sehen; Angriffe haben Nachteil, Angriffe gegen dich Vorteil.',
    'bezaubert':
        'Kann dem Verursacher nicht schaden; dieser hat Vorteile beim sozialen Umgang.',
    'taub': 'Kann nicht hören; Hörwahrnehmung ist nicht möglich.',
    'verängstigt':
        'Quellenabhängiger Nachteil auf Angriffe und Proben; nicht näherkommen.',
    'gepackt': 'Bewegungsrate 0; Ende unter anderem bei Befreiung.',
    'handlungsunfähig': 'Keine Aktion, Bonusaktion oder Reaktion.',
    'unsichtbar':
        'Ohne besondere Sinne nicht sichtbar; Angriffsfolgen sind situationsabhängig.',
    'gelähmt':
        'Handlungsunfähig und bewegungsunfähig; bestimmte Rettungswürfe misslingen.',
    'versteinert':
        'Verwandelt und handlungsunfähig; zusätzliche Resistenz-/Immunitätsregeln.',
    'vergiftet': 'Nachteil auf Angriffswürfe und Attributsproben.',
    'liegend':
        'Angriffe mit Nachteil; Nah-/Fernangriffe gegen dich situationsabhängig.',
    'festgesetzt': 'Bewegungsrate 0; eigene Angriffe mit Nachteil.',
    'betäubt':
        'Handlungsunfähig; Stärke-/Geschicklichkeitsrettung misslingt; Angriffe gegen dich haben Vorteil.',
    'bewusstlos': 'Handlungsunfähig; kann nicht wahrnehmen oder handeln.',
  };

  static bool has(HeroCharacter hero, String condition) =>
      hero.conditions.contains(condition);

  static bool canTakeActions(HeroCharacter hero) =>
      !hero.isDead &&
      !const {
        'bewusstlos',
        'handlungsunfähig',
        'gelähmt',
        'versteinert',
        'betäubt',
      }.any(hero.conditions.contains);

  static bool canMove(HeroCharacter hero) =>
      !hero.isDead &&
      !const {
        'bewusstlos',
        'gelähmt',
        'versteinert',
        'gepackt',
        'festgesetzt',
      }.any(hero.conditions.contains) &&
      (ExhaustionRules.effectiveSpeedMeters(hero) ?? 0) > 0;

  /// SRD 5.2.1, Rules Glossary: Paralyzed/Petrified (p. 186),
  /// Stunned (p. 188), Unconscious (p. 190). These conditions only
  /// automatically fail Strength/Dexterity saves, not all D20 Tests.
  /// Stunned alone does not set Speed to 0 in the 2024 rules.
  static bool hasAutomaticSavingThrowFailure(
    HeroCharacter hero,
    String ability,
  ) =>
      (ability == 'strength' || ability == 'dexterity') &&
      const {
        'gelähmt',
        'versteinert',
        'betäubt',
        'bewusstlos',
      }.any(hero.conditions.contains);

  /// Only unconditional sources are summarized here. Do NOT infer line of
  /// sight, concealment, attacker distance, or a particular charmer.
  static bool hasUnconditionalAttackDisadvantage(HeroCharacter hero) => const {
    'blind',
    'vergiftet',
    'liegend',
    'festgesetzt',
  }.any(hero.conditions.contains);

  static bool hasUnconditionalAttackerAdvantage(HeroCharacter hero) => const {
    'blind',
    'festgesetzt',
    'betäubt',
    'gelähmt',
    'bewusstlos',
  }.any(hero.conditions.contains);
}
