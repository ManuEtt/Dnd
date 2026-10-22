import 'condition_rules.dart';
import 'models.dart';

/// One explicitly confirmed cause of a 2024 SRD condition.
/// SRD 5.2.1, Rules Glossary "Condition": multiple instances of the same
/// condition do not stack, but each cause can end independently.
/// An encounter-bound expiry is only processed at a confirmed OWN turn end.
class ConditionEffect {
  ConditionEffect({
    required this.id,
    required this.condition,
    required String source,
    this.expiresInEncounterId,
    this.expiresAtOwnTurnEndRound,
  }) : source = source.trim() {
    if (id.isEmpty || id.trim() != id || id.length > 200) {
      throw const FormatException('Ungültige Zustandseffekt-ID.');
    }
    if (!ConditionRules.descriptions.containsKey(condition)) {
      throw const FormatException('Unbekannter quellgebundener Zustand.');
    }
    if (this.source.isEmpty || this.source.length > 200) {
      throw const FormatException('Ungültige Zustandsquelle.');
    }
    if ((expiresInEncounterId == null) != (expiresAtOwnTurnEndRound == null)) {
      throw const FormatException('Unvollständiger Zugendpunkt.');
    }
    if (expiresInEncounterId != null &&
        (expiresInEncounterId!.isEmpty ||
            expiresInEncounterId!.trim() != expiresInEncounterId ||
            expiresInEncounterId!.length > 200)) {
      throw const FormatException('Ungültige Begegnungsreferenz.');
    }
    if (expiresAtOwnTurnEndRound != null &&
        (expiresAtOwnTurnEndRound! < 1 ||
            expiresAtOwnTurnEndRound! > 1000000)) {
      throw const FormatException('Ungültiger Zugendpunkt.');
    }
  }

  final String id;
  final String condition;
  final String source;
  final String? expiresInEncounterId;
  final int? expiresAtOwnTurnEndRound;

  Map<String, dynamic> toJson() => {
    'id': id,
    'condition': condition,
    'source': source,
    if (expiresInEncounterId != null)
      'expiresInEncounterId': expiresInEncounterId,
    if (expiresAtOwnTurnEndRound != null)
      'expiresAtOwnTurnEndRound': expiresAtOwnTurnEndRound,
  };

  factory ConditionEffect.fromJson(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Zustandseffekt muss ein Objekt sein.');
    }
    String requiredString(String key) {
      final entry = value[key];
      if (entry is! String) {
        throw FormatException('Ungültiges Zustandseffekt-Feld: $key.');
      }
      return entry;
    }

    final encounter = value['expiresInEncounterId'];
    final round = value['expiresAtOwnTurnEndRound'];
    if (encounter != null && encounter is! String) {
      throw const FormatException('Ungültige Begegnungsreferenz.');
    }
    if (round != null && round is! int) {
      throw const FormatException('Ungültiger Zugendpunkt.');
    }
    return ConditionEffect(
      id: requiredString('id'),
      condition: requiredString('condition'),
      source: requiredString('source'),
      expiresInEncounterId: encounter as String?,
      expiresAtOwnTurnEndRound: round as int?,
    );
  }
}

/// How long an explicitly confirmed external condition remains active.
/// No wall clock or generic spell duration is inferred from these choices.
enum ConditionEffectDuration { untilRemoved, currentTurnEnd, nextTurnEnd }

/// Pure operations. The game controller must still authorize and atomically
/// checkpoint any externally requested change before it is committed.
class ConditionEffectRules {
  const ConditionEffectRules._();

  static List<ConditionEffect> validated(List<ConditionEffect> effects) {
    if (effects.length > 100) {
      throw const FormatException('Zu viele Zustandseffekte.');
    }
    final ids = <String>{};
    for (final effect in effects) {
      if (!ids.add(effect.id)) {
        throw const FormatException('Doppelte Zustandseffekt-ID.');
      }
    }
    return List.unmodifiable(effects);
  }

  static HeroCharacter add(HeroCharacter hero, ConditionEffect effect) {
    if (hero.conditionEffects.any((entry) => entry.id == effect.id)) {
      throw StateError('Zustandseffekt-ID bereits vergeben.');
    }
    // SRD 5.2.1, Rules Glossary: Incapacitated breaks Concentration.
    // Derived incapacitation (such as Paralyzed) has the same consequence.
    // The effect and concentration change are one confirmed state transition.
    const incapacitating = {
      'handlungsunfähig',
      'gelähmt',
      'versteinert',
      'betäubt',
      'bewusstlos',
    };
    final updated = hero.copyWith(
      conditionEffects: [...hero.conditionEffects, effect],
      concentratingOn: incapacitating.contains(effect.condition)
          ? ''
          : hero.concentratingOn,
    );
    return effect.condition == 'bewusstlos'
        ? ConditionRules.retainProneFromUnconscious(hero, updated)
        : updated;
  }

  static HeroCharacter removeById(HeroCharacter hero, String id) {
    if (!hero.conditionEffects.any((effect) => effect.id == id)) {
      throw StateError('Zustandseffekt-ID nicht vorhanden.');
    }
    final updated = hero.copyWith(
      conditionEffects: [
        for (final effect in hero.conditionEffects)
          if (effect.id != id) effect,
      ],
    );
    return ConditionRules.retainProneFromUnconscious(hero, updated);
  }

  /// A rule that explicitly ends this condition removes every cause AND its
  /// legacy/manual occurrence. Other conditions are preserved.
  static HeroCharacter endCondition(HeroCharacter hero, String condition) {
    if (!ConditionRules.descriptions.containsKey(condition)) {
      throw const FormatException('Unbekannter quellgebundener Zustand.');
    }
    final updated = hero.copyWith(
      conditions: [
        for (final entry in hero.manualConditions)
          if (entry != condition) entry,
      ],
      conditionEffects: [
        for (final effect in hero.conditionEffects)
          if (effect.condition != condition) effect,
      ],
    );
    return condition == 'bewusstlos'
        ? ConditionRules.retainProneFromUnconscious(hero, updated)
        : updated;
  }

  /// Only the owning encounter's confirmed hero-turn boundary may expire this
  /// effect. Never expire from elapsed wall time or a different encounter.
  static HeroCharacter expireAtOwnTurnEnd(
    HeroCharacter hero, {
    required String encounterId,
    required int round,
  }) {
    if (encounterId.isEmpty || round < 1) {
      throw ArgumentError('Ungültige Begegnung oder Runde.');
    }
    final remaining = [
      for (final effect in hero.conditionEffects)
        if (effect.expiresInEncounterId != encounterId ||
            effect.expiresAtOwnTurnEndRound == null ||
            effect.expiresAtOwnTurnEndRound! > round)
          effect,
    ];
    if (remaining.length == hero.conditionEffects.length) return hero;
    return ConditionRules.retainProneFromUnconscious(
      hero,
      hero.copyWith(conditionEffects: remaining),
    );
  }
}
