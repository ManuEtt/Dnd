import 'models.dart';

/// SRD 5.2.1, character creation, p. 21 (German edition p. 24).
/// These methods generate base scores; background increases are a separate step.
enum AbilityGenerationMethod { standardArray, pointBuy, randomRoll }

/// Immutable evidence of one four-d6 throw. The lowest die is excluded.
class AbilityRoll {
  AbilityRoll._(List<int> values) : dice = List.unmodifiable(values);
  final List<int> dice;

  int get score {
    final sorted = dice.toList()..sort();
    return sorted.skip(1).fold<int>(0, (sum, die) => sum + die);
  }
}

/// Six independent, immutable 4d6-drop-lowest rolls (SRD 5.2.1, p. 21).
class AbilityRollSet {
  AbilityRollSet._(List<AbilityRoll> values)
      : rolls = List.unmodifiable(values);

  final List<AbilityRoll> rolls;
  List<int> get scores => List.unmodifiable(rolls.map((roll) => roll.score));

  /// Injected d6 source permits deterministic tests; invalid dice fail closed.
  factory AbilityRollSet.generate({required int Function() rollD6}) {
    final rounds = <AbilityRoll>[];
    for (var round = 0; round < 6; round++) {
      final dice = <int>[];
      for (var die = 0; die < 4; die++) {
        final value = rollD6();
        if (value < 1 || value > 6) {
          throw const FormatException('Ein W6 muss 1 bis 6 ergeben.');
        }
        dice.add(value);
      }
      rounds.add(AbilityRoll._(dice));
    }
    return AbilityRollSet._(rounds);
  }
}


/// The SRD backgrounds' ability choices, not their complete game features.
/// SRD 5.2.1 p. 83 (German edition p. 93).
enum SrdBackground {
  acolyte,
  criminal,
  sage,
  soldier;

  String get label => switch (this) {
    acolyte => 'Akolyth',
    criminal => 'Krimineller',
    sage => 'Weiser',
    soldier => 'Soldat',
  };

  List<String> get abilityKeys => switch (this) {
    acolyte => const ['intelligence', 'wisdom', 'charisma'],
    criminal => const ['dexterity', 'constitution', 'intelligence'],
    sage => const ['constitution', 'intelligence', 'wisdom'],
    soldier => const ['strength', 'dexterity', 'constitution'],
  };
}

/// Immutable draft: invalid assignments can be displayed, but not composed.
/// Existing or historical character values are never inferred or modified.
class AbilityAllocation {
  AbilityAllocation({
    required this.method,
    required Map<String, int> baseScores,
    this.rollSet,
  }) : baseScores = Map.unmodifiable(baseScores);

  static const standardArray = <int>[15, 14, 13, 12, 10, 8];
  static const pointBudget = 27;
  static const pointCosts = <int, int>{
    8: 0,
    9: 1,
    10: 2,
    11: 3,
    12: 4,
    13: 5,
    14: 7,
    15: 9,
  };

  final AbilityGenerationMethod method;
  final Map<String, int> baseScores;
  final AbilityRollSet? rollSet;

  List<String> get errors {
    final result = _abilityKeyErrors(baseScores);
    if (method == AbilityGenerationMethod.standardArray) {
      final sorted = baseScores.values.toList()..sort();
      final expected = standardArray.toList()..sort();
      if (sorted.length != expected.length ||
          Iterable<int>.generate(expected.length).any(
            (index) =>
                index >= sorted.length || sorted[index] != expected[index],
          )) {
        result.add(
          'Der Standardsatz muss 15, 14, 13, 12, 10 und 8 jeweils einmal enthalten.',
        );
      }
    } else if (method == AbilityGenerationMethod.randomRoll) {
      final expected = rollSet?.scores.toList();
      expected?.sort();
      final actual = baseScores.values.toList()..sort();
      if (expected == null ||
          actual.length != expected.length ||
          !Iterable<int>.generate(expected.length).every(
            (i) => actual[i] == expected[i],
          )) {
        result.add(
          'Die sechs unveränderten Würfelergebnisse müssen genau einmal zugewiesen werden.',
        );
      }
    } else {
      if (baseScores.values.any((score) => !pointCosts.containsKey(score))) {
        result.add('Beim Punktekauf sind Basiswerte von 8 bis 15 erlaubt.');
      }
      final cost = pointCost;
      if (cost != null && cost > pointBudget) {
        result.add('Der Punktekauf darf höchstens 27 Punkte verbrauchen.');
      }
    }
    return List.unmodifiable(result);
  }

  bool get isValid => errors.isEmpty;

  /// Null for the standard array or an incomplete/out-of-range point-buy draft.
  /// An overspent but otherwise well-formed draft still exposes its actual cost.
  int? get pointCost {
    if (method != AbilityGenerationMethod.pointBuy ||
        _abilityKeyErrors(baseScores).isNotEmpty ||
        baseScores.values.any((score) => !pointCosts.containsKey(score))) {
      return null;
    }
    return baseScores.values.fold<int>(
      0,
      (sum, score) => sum + pointCosts[score]!,
    );
  }

  /// Negative for an overspent draft; unspent points do not invalidate a draft.
  int? get remainingPoints {
    final cost = pointCost;
    return cost == null ? null : pointBudget - cost;
  }

  bool get usesFullBudget => isValid && remainingPoints == 0;

  AbilityAllocation withScore(String ability, int score) {
    if (!abilityNames.contains(ability)) {
      throw ArgumentError.value(ability, 'ability', 'Unbekanntes Attribut.');
    }
    return AbilityAllocation(
      method: method,
      baseScores: {...baseScores, ability: score},
      rollSet: rollSet,
    );
  }

  /// Always recomputes from base scores, never from an earlier final result.
  /// A null background is a base-only preview, explicitly marked by the result.
  AbilityGenerationResult compose({BackgroundAbilityBoost? backgroundBoost}) {
    if (!isValid) throw FormatException(errors.join(' '));
    return AbilityGenerationResult._(
      baseScores: baseScores,
      finalScores: backgroundBoost?.applyTo(baseScores) ?? baseScores,
      backgroundBoost: backgroundBoost,
    );
  }
}

/// Explicit choice of +2/+1 on distinct eligible abilities, or +1 on all three.
/// Zero entries and abilities outside the selected background are rejected.
class BackgroundAbilityBoost {
  BackgroundAbilityBoost({
    required this.background,
    required Map<String, int> increases,
  }) : increases = Map.unmodifiable(increases);

  final SrdBackground background;
  final Map<String, int> increases;

  List<String> get errors {
    final result = <String>[];
    if (increases.keys.any((key) => !background.abilityKeys.contains(key))) {
      result.add('Die Erhöhungen müssen zum gewählten Hintergrund passen.');
    }
    final values = increases.values.toList()..sort();
    final twoAndOne = values.length == 2 && values[0] == 1 && values[1] == 2;
    final threeOnes = values.length == 3 && values.every((value) => value == 1);
    if (!twoAndOne && !threeOnes) {
      result.add(
        'Erhöhe zwei verschiedene erlaubte Attribute um 2 und 1 '
        'oder alle drei um jeweils 1.',
      );
    }
    return List.unmodifiable(result);
  }

  bool get isValid => errors.isEmpty;

  /// Separate composition supports valid pre-increase scores up to 20 without
  /// restricting the general character model or silently clamping a score.
  Map<String, int> applyTo(Map<String, int> baseScores) {
    final issues = [...errors, ..._abilityKeyErrors(baseScores)];
    if (baseScores.values.any((score) => score < 1 || score > 20)) {
      issues.add(
        'Vor einer Hintergrunderhöhung sind Werte von 1 bis 20 erlaubt.',
      );
    }
    if (baseScores.entries.any(
      (entry) => entry.value + (increases[entry.key] ?? 0) > 20,
    )) {
      issues.add('Eine Hintergrunderhöhung darf keinen Wert über 20 ergeben.');
    }
    if (issues.isNotEmpty) throw FormatException(issues.join(' '));
    return Map.unmodifiable({
      for (final key in abilityNames)
        key: baseScores[key]! + (increases[key] ?? 0),
    });
  }
}

/// Final values and their separate base assignment; neither is mutable.
/// [backgroundApplied] is about this step, not complete character creation.
class AbilityGenerationResult {
  AbilityGenerationResult._({
    required Map<String, int> baseScores,
    required Map<String, int> finalScores,
    required this.backgroundBoost,
  }) : baseScores = Map.unmodifiable(baseScores),
       finalScores = Map.unmodifiable(finalScores);

  final Map<String, int> baseScores;
  final Map<String, int> finalScores;
  final BackgroundAbilityBoost? backgroundBoost;
  bool get backgroundApplied => backgroundBoost != null;
}

List<String> _abilityKeyErrors(Map<String, int> scores) {
  if (scores.length != abilityNames.length ||
      abilityNames.any((key) => !scores.containsKey(key)) ||
      scores.keys.any((key) => !abilityNames.contains(key))) {
    return ['Es müssen genau die sechs bekannten Attribute zugewiesen werden.'];
  }
  return [];
}
