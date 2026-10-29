import 'srd_spell_catalog.dart';

/// A separately confirmed creature for an SRD 5.2.1 Magic Missile allocation.
///
/// The flags are evidence supplied by the rule/encounter boundary, not facts
/// inferred from AI narration. Protection such as Shield is resolved later.
class SrdMagicMissileTarget {
  const SrdMagicMissileTarget({
    required this.id,
    required this.creatureConfirmed,
    required this.visibleConfirmed,
    required this.within120FeetConfirmed,
    required this.noTotalCoverConfirmed,
  });

  /// Stable creature identity, never a potentially ambiguous display name.
  final String id;
  final bool creatureConfirmed;
  final bool visibleConfirmed;
  final bool within120FeetConfirmed;
  final bool noTotalCoverConfirmed;
}

/// Immutable, read-only distribution of simultaneous missiles.
///
/// This is NOT a spell cast, attack, damage result, Shield ruling, slot
/// reservation or campaign update. The caller must separately validate the
/// caster, spell preparation, action, components and resource transaction.
class SrdMagicMissileAllocation {
  SrdMagicMissileAllocation._({
    required this.slotLevel,
    required List<String> dartTargetIds,
    required Map<String, int> dartsPerTarget,
  }) : dartTargetIds = List.unmodifiable(dartTargetIds),
       dartsPerTarget = Map.unmodifiable(dartsPerTarget);

  final int slotLevel;
  final List<String> dartTargetIds;
  final Map<String, int> dartsPerTarget;

  int get dartCount => slotLevel + 2;
}

/// SRD 5.2.1, Spells / Magic Missile, printed page 146 (CC BY 4.0).
///
/// Three darts at level 1, plus one per additional slot level. Every dart is
/// allocated to a separately confirmed visible creature within 120 feet.
/// Repetition of the same identity is intentional; all darts strike at once.
/// No dice are rolled, defenses guessed or resources spent by this preflight.
class SrdMagicMissileMultiTargetRules {
  const SrdMagicMissileMultiTargetRules._();

  static final RegExp _stableId = RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:-]{0,159}$');

  static SrdMagicMissileAllocation prepare({
    required SrdSpellDefinition spell,
    required int slotLevel,
    required Iterable<SrdMagicMissileTarget> confirmedTargets,
    required List<String> dartTargetIds,
  }) {
    if (spell.name != 'Magic Missile' ||
        spell.level != 1 ||
        spell.castingTime != 'Action' ||
        spell.range != '120 feet' ||
        spell.duration != 'Instantaneous' ||
        spell.components != 'V, S' ||
        !spell.verbal ||
        !spell.somatic ||
        spell.material ||
        spell.concentration ||
        spell.ritual ||
        spell.classes.length != 2 ||
        !spell.classes.toSet().containsAll(const ['Sorcerer', 'Wizard'])) {
      throw UnsupportedError(
        'Die bestätigten Metadaten für Magic Missile fehlen.',
      );
    }
    if (slotLevel < 1 || slotLevel > 9) {
      throw const FormatException('Ungültiger Zauberplatzgrad.');
    }
    final targets = confirmedTargets.toList(growable: false);
    final dartCount = slotLevel + 2;
    if (targets.isEmpty || targets.length > dartCount) {
      throw const FormatException('Ungültige Anzahl bestätigter Ziele.');
    }
    final ids = <String>{};
    for (final target in targets) {
      if (!_stableId.hasMatch(target.id) || !ids.add(target.id)) {
        throw const FormatException('Doppelte oder ungültige Kreaturen-ID.');
      }
      if (!target.creatureConfirmed ||
          !target.visibleConfirmed ||
          !target.within120FeetConfirmed ||
          !target.noTotalCoverConfirmed) {
        throw const FormatException(
          'Kreatur, Sicht, Reichweite und freie Zielverbindung '
          'müssen für jedes Ziel bestätigt sein.',
        );
      }
    }
    if (dartTargetIds.length != dartCount) {
      throw const FormatException(
        'Jedes gleichzeitig wirkende Geschoss benötigt genau ein Ziel.',
      );
    }
    final counts = <String, int>{};
    for (final id in dartTargetIds) {
      if (!ids.contains(id)) {
        throw const FormatException(
          'Geschoss verweist auf keine bestätigte Kreaturen-ID.',
        );
      }
      counts[id] = (counts[id] ?? 0) + 1;
    }
    if (counts.length != ids.length) {
      throw const FormatException(
        'Alle angegebenen Zielidentitäten benötigen mindestens ein Geschoss.',
      );
    }
    return SrdMagicMissileAllocation._(
      slotLevel: slotLevel,
      dartTargetIds: dartTargetIds,
      dartsPerTarget: counts,
    );
  }
}
