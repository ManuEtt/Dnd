import 'dice_engine.dart';
import 'enemy_force_defense.dart';
import 'magic_missile_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';
import 'srd_magic_missile_multi_target_rules.dart';
import 'srd_magic_missile_volley_damage_rules.dart';

/// One fully validated domain-level cast and its simultaneous damage results.
///
/// This value is NOT a committed campaign update. The encounter layer still
/// owns action economy, HP changes, revision checks, event IDs and persistence.
class SrdMagicMissileMultiTargetCast {
  const SrdMagicMissileMultiTargetCast({
    required this.hero,
    required this.allocation,
    required this.damage,
    required this.castingClass,
    required this.pactMagic,
  });

  /// A new hero snapshot with exactly one spell slot deducted.
  final HeroCharacter hero;
  final SrdMagicMissileAllocation allocation;
  final SrdMagicMissileVolleyDamage damage;
  final String castingClass;
  final bool pactMagic;
}

/// SRD 5.2.1, Magic Missile (p. 146) and Shield (p. 161), CC BY 4.0.
///
/// Bridges the independently tested allocation and per-dart damage rules to
/// the existing spellcasting resource contract. Validates all target defenses,
/// reaction decisions, components, caster and slots BEFORE consuming any RNG.
/// No narrative assertion or implicit target-defense assumption is accepted.
class SrdMagicMissileMultiTargetCastRules {
  const SrdMagicMissileMultiTargetCastRules._();

  static SrdMagicMissileMultiTargetCast cast({
    required HeroCharacter hero,
    required DiceEngine dice,
    required String castingClass,
    required SrdMagicMissileAllocation allocation,
    required Iterable<SrdMissileTargetDefense> targetDefenses,
    required bool pactMagic,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool reactionDecisionsConfirmed,
  }) {
    if (!verbalComponentConfirmed ||
        !somaticComponentConfirmed ||
        !reactionDecisionsConfirmed) {
      throw const FormatException(
        'Komponenten und alle Schildreaktionen müssen bestätigt sein.',
      );
    }

    // An allocation can only come from the official SRD spell preflight.
    final spellName = MagicMissileRules.preparedName(hero);
    final canonicalClass = findSrdClass(castingClass)?.name;
    if (spellName == null ||
        canonicalClass == null ||
        !MagicMissileRules.castingClasses(hero).contains(canonicalClass)) {
      throw const FormatException(
        'Magisches Geschoss ist nicht für diese Zauberklasse vorbereitet.',
      );
    }
    if (!MagicMissileRules.slots(hero).any(
      (slot) =>
          slot.level == allocation.slotLevel &&
          slot.pactMagic == pactMagic &&
          slot.remaining > 0,
    )) {
      throw const FormatException('Kein passender freier Zauberplatz.');
    }

    final targets = targetDefenses.toList(growable: false);
    final approvedIds = allocation.dartsPerTarget.keys.toSet();
    if (targets.length != approvedIds.length) {
      throw const FormatException(
        'Jede gewählte Kreatur benötigt genau eine Abwehrbestätigung.',
      );
    }
    final defensesById = <String, SrdMissileTargetDefense>{};
    for (final target in targets) {
      if (!approvedIds.contains(target.targetId) ||
          defensesById.containsKey(target.targetId) ||
          target.shieldState == SrdMissileShieldState.unverified ||
          (target.shieldState == SrdMissileShieldState.absentConfirmed &&
              target.forceDefense == EnemyForceDefense.unknown)) {
        throw const FormatException(
          'Abwehr oder Schildstatus eines Geschossziels ist nicht bestätigt.',
        );
      }
      defensesById[target.targetId] = target;
    }

    // A failed slot/hero validation must not roll dice or persist anything.
    final spent = SpellcastingRules.cast(
      MagicMissileRules.normalized(hero),
      spellName: spellName,
      spellLevel: 1,
      slotLevel: allocation.slotLevel,
      pactMagic: pactMagic,
    );
    final darts = <SrdMissileDartEvidence>[];
    for (final id in allocation.dartTargetIds) {
      final shielded =
          defensesById[id]!.shieldState ==
          SrdMissileShieldState.activeConfirmed;
      darts.add(
        SrdMissileDartEvidence(
          targetId: id,
          naturalD4: shielded ? null : dice.roll('1d4').rolls.single,
        ),
      );
    }
    final damage = SrdMagicMissileVolleyDamageRules.resolve(
      slotLevel: allocation.slotLevel,
      allocationAndReactionsConfirmed: true,
      darts: darts,
      targetDefenses: targets,
    );
    return SrdMagicMissileMultiTargetCast(
      hero: spent.hero.copyWith(
        className: hero.className,
        secondaryClassName: hero.secondaryClassName,
      ),
      allocation: allocation,
      damage: damage,
      castingClass: canonicalClass,
      pactMagic: pactMagic,
    );
  }
}
