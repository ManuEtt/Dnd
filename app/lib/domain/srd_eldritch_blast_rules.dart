import 'condition_rules.dart';
import 'cover_rules.dart';
import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 – Eldritch Blast, Cantrip Upgrade.
///
/// A confirmed casting can produce multiple independent attack rolls. This
/// resolver does NOT spend actions, apply damage to HP, execute invocations,
/// ignite objects or write any campaign state. A caller must commit the
/// separately confirmed effect through its authoritative game action.
class SrdEldritchBlastRules {
  const SrdEldritchBlastRules._();

  static int beamCount(int characterLevel) {
    if (characterLevel < 1 || characterLevel > 20) {
      throw RangeError.range(characterLevel, 1, 20, 'characterLevel');
    }
    if (characterLevel >= 17) return 4;
    if (characterLevel >= 11) return 3;
    if (characterLevel >= 5) return 2;
    return 1;
  }

  /// Each entry specifies the target of ONE beam. Entries may share target IDs.
  ///
  /// Validates the entire proposed casting before consuming any dice. The
  /// given modifier is a *separately confirmed* spell-attack total, including
  /// class ability, proficiency and any source-verified exceptions.
  static SrdEldritchBlastResolution resolve({
    required HeroCharacter caster,
    required DiceEngine dice,
    required List<SrdEldritchBlastTarget> beams,
    required int confirmedSpellAttackModifier,
    required bool warlockSpellPreparationConfirmed,
    required bool actionAvailableConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noUnmodelledAttackOrDamageModifiersConfirmed,
  }) {
    final count = beamCount(caster.level);
    final primary = findSrdClass(caster.className)?.name;
    final secondary = caster.hasSecondClass
        ? findSrdClass(caster.secondaryClassName)?.name
        : null;
    if (caster.primaryClassLevel < 1 ||
        caster.secondaryClassLevel < 0 ||
        (caster.hasSecondClass &&
            (caster.secondaryClassLevel < 1 ||
                secondary == null ||
                secondary == primary)) ||
        (!caster.hasSecondClass && caster.secondaryClassLevel != 0) ||
        (primary != 'Hexenmeister' && secondary != 'Hexenmeister') ||
        !caster.spells.contains('Eldritch Blast') ||
        !warlockSpellPreparationConfirmed) {
      throw const FormatException(
        'Eldritch Blast ist nicht für eine eigene Hexenmeisterklasse '
        'und den bekannten Zaubertrick bestätigt.',
      );
    }
    if (!actionAvailableConfirmed ||
        !verbalComponentConfirmed ||
        !somaticComponentConfirmed ||
        !noUnmodelledAttackOrDamageModifiersConfirmed) {
      throw const FormatException(
        'Zauberaktion, Komponenten und Angriffs-/Schadensmodifikatoren '
        'müssen unabhängig bestätigt sein.',
      );
    }
    if (caster.isDead ||
        caster.hitPoints == 0 ||
        !ConditionRules.canTakeActions(caster) ||
        (caster.equippedArmorId.isNotEmpty && !caster.equippedArmorTrained) ||
        (caster.equippedShieldId.isNotEmpty && !caster.equippedShieldTrained)) {
      throw StateError('Dieser Charakter kann derzeit nicht zaubern.');
    }
    if (confirmedSpellAttackModifier < -30 ||
        confirmedSpellAttackModifier > 30) {
      throw RangeError.range(
        confirmedSpellAttackModifier,
        -30,
        30,
        'confirmedSpellAttackModifier',
      );
    }
    if (beams.length != count) {
      throw FormatException(
        'Eldritch Blast benötigt genau $count getrennt geprüfte Strahlen.',
      );
    }

    final effectiveArmorClasses = <int>[];
    for (final target in beams) {
      if (target.targetId.isEmpty ||
          target.targetId.trim() != target.targetId ||
          target.targetId.length > 200 ||
          !target.creatureOrObjectConfirmed ||
          !target.clearPathConfirmed ||
          !target.coverCircumstancesConfirmed ||
          !target.attackCircumstancesConfirmed ||
          target.distanceFeet < 0 ||
          target.distanceFeet > 120 ||
          target.baseArmorClass < 1 ||
          target.baseArmorClass > 100) {
        throw const FormatException(
          'Jeder Strahl benötigt ein gültiges, erreichbares und '
          'ausdrücklich bestätigtes Einzelziel.',
        );
      }
      // Reject unverified/invalid AC before any random rolls. A total-cover
      // target cannot be attacked, even on a natural 20.
      final relativeCover = target.sourceOppositeCover
          ? target.cover
          : CoverLevel.none;
      effectiveArmorClasses.add(
        CoverRules.armorClass(target.baseArmorClass, relativeCover),
      );
    }

    final resolved = <SrdEldritchBlastBeamResult>[];
    for (var i = 0; i < beams.length; i++) {
      final target = beams[i];
      final attack = dice.check(
        modifier: confirmedSpellAttackModifier,
        advantage: target.advantage,
        disadvantage: target.disadvantage,
      );
      final outcome = RulesEngine.attack(
        roll: attack,
        armorClass: effectiveArmorClasses[i],
      );
      final damage = outcome.hit
          ? dice.roll(outcome.critical ? '2d10' : '1d10')
          : null;
      resolved.add(
        SrdEldritchBlastBeamResult(
          targetId: target.targetId,
          attack: attack,
          effectiveArmorClass: effectiveArmorClasses[i],
          hit: outcome.hit,
          critical: outcome.critical,
          forceDamageRoll: damage,
        ),
      );
    }
    return SrdEldritchBlastResolution(
      characterLevel: caster.level,
      beams: List.unmodifiable(resolved),
    );
  }
}

/// Independently confirmed facts for a SINGLE 120-ft beam.
class SrdEldritchBlastTarget {
  const SrdEldritchBlastTarget({
    required this.targetId,
    required this.distanceFeet,
    required this.baseArmorClass,
    required this.cover,
    required this.creatureOrObjectConfirmed,
    required this.clearPathConfirmed,
    required this.coverCircumstancesConfirmed,
    required this.attackCircumstancesConfirmed,
    required this.sourceOppositeCover,
    this.advantage = false,
    this.disadvantage = false,
  });

  final String targetId;
  final int distanceFeet;
  final int baseArmorClass;
  final CoverLevel cover;
  final bool creatureOrObjectConfirmed;
  final bool clearPathConfirmed;
  final bool coverCircumstancesConfirmed;
  final bool attackCircumstancesConfirmed;
  final bool sourceOppositeCover;
  final bool advantage, disadvantage;
}

class SrdEldritchBlastBeamResult {
  const SrdEldritchBlastBeamResult({
    required this.targetId,
    required this.attack,
    required this.effectiveArmorClass,
    required this.hit,
    required this.critical,
    required this.forceDamageRoll,
  });

  final String targetId;
  final DiceResult attack;
  final int effectiveArmorClass;
  final bool hit, critical;

  /// Null on a miss; no bonus damage from invocations is invented.
  final DiceResult? forceDamageRoll;
  int get rawForceDamage => forceDamageRoll?.total ?? 0;
}

class SrdEldritchBlastResolution {
  const SrdEldritchBlastResolution({
    required this.characterLevel,
    required this.beams,
  });

  final int characterLevel;
  final List<SrdEldritchBlastBeamResult> beams;
  int get totalRawForceDamage =>
      beams.fold<int>(0, (total, beam) => total + beam.rawForceDamage);
}
