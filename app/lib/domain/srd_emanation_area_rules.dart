import 'srd_spell_catalog.dart';
import 'srd_spell_grid_target_rules.dart';
import 'srd_sphere_area_rules.dart';

/// The SRD Emanation source is a creature or an object, never a free point.
enum SrdEmanationSourceKind { creature, object }

/// Effect duration/movement is confirmed by the caller, not inferred from
/// casting range. A moving source requires a fresh preview at its new square.
enum SrdEmanationMotion { followsSource, instantaneous, stationary }

class SrdEmanationCellCandidate {
  const SrdEmanationCellCandidate({
    required this.cell,
    required this.centerWithinDistance,
    required this.originSquareRequiresReview,
    required this.centerRay,
  });

  final SrdGridCell cell;

  /// A center inside the horizontal footprint is not a confirmed target.
  final bool centerWithinDistance;

  /// Excluding the source does NOT exclude other occupants of this square.
  final bool originSquareRequiresReview;

  /// A blocked center ray requires review, not automatic total cover.
  final SrdSphereCenterRay centerRay;
}

class SrdEmanationAreaPreview {
  SrdEmanationAreaPreview({
    required this.origin,
    required this.distanceFeet,
    required this.sourceKind,
    required this.motion,
    required this.includeSourceByChoice,
    required List<SrdEmanationCellCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final SrdGridCell origin;
  final int distanceFeet;
  final SrdEmanationSourceKind sourceKind;
  final SrdEmanationMotion motion;

  /// The SRD default is to exclude the origin creature/object, but the
  /// creator can explicitly choose otherwise. This is NOT a tile filter.
  final bool includeSourceByChoice;

  /// A following Emanation must be recalculated after confirmed movement.
  bool get needsRepreviewAfterMovement =>
      motion == SrdEmanationMotion.followsSource;

  /// Possible ground squares only; no hit, immunity or save is established.
  final List<SrdEmanationCellCandidate> candidates;

  SrdEmanationCellCandidate? at(SrdGridCell cell) {
    for (final candidate in candidates) {
      if (candidate.cell == cell) return candidate;
    }
    return null;
  }
}

/// SRD 5.2.1, Rules Glossary / Emanation; Wizards of the Coast LLC,
/// CC BY 4.0: https://www.dndbeyond.com/srd
///
/// Read-only 2D horizontal projection from a confirmed, single-cell source.
/// A creature/object can actually occupy multiple squares or have height:
/// without a verified center point and one-square footprint, fail closed.
/// Movement, creature occupancy, actual 3D total cover, saves, damage,
/// turn triggers and spell-specific exemptions require other rules.
class SrdEmanationAreaRules {
  const SrdEmanationAreaRules._();

  /// Casting range to the origin is distinct from the Emanation's extent.
  static SrdEmanationAreaPreview previewConfirmedSpell({
    required SrdSpellDefinition spell,
    required SrdSpellGridTargetRequest gridTarget,
    required bool emanationShapeVerifiedFromEffect,
    required int verifiedEffectDistanceFeet,
    required SrdEmanationSourceKind sourceKind,
    required SrdEmanationMotion motion,
    required bool sourceCenterAndSingleCellConfirmed,
    bool includeSourceByChoice = false,
  }) {
    if (!emanationShapeVerifiedFromEffect) {
      throw const FormatException(
        'Emanationsform und Ausdehnung benötigen eine bestätigte Zauberwirkung.',
      );
    }
    SrdSpellGridTargetRules.validateOrigin(spell, gridTarget);
    return preview(
      map: gridTarget.map,
      origin: gridTarget.origin,
      distanceFeet: verifiedEffectDistanceFeet,
      sourceKind: sourceKind,
      motion: motion,
      sourceCenterAndSingleCellConfirmed: sourceCenterAndSingleCellConfirmed,
      includeSourceByChoice: includeSourceByChoice,
    );
  }

  static SrdEmanationAreaPreview preview({
    required SrdSpellGridMap map,
    required SrdGridCell origin,
    required int distanceFeet,
    required SrdEmanationSourceKind sourceKind,
    required SrdEmanationMotion motion,
    required bool sourceCenterAndSingleCellConfirmed,
    bool includeSourceByChoice = false,
  }) {
    if (!sourceCenterAndSingleCellConfirmed) {
      throw const FormatException(
        'Emanationsursprung benötigt einen bestätigten Punkt in einem Feld.',
      );
    }

    // The known 2D circle intersection and blocker witness are shared with
    // sphere/cylinder previews. It is an over-inclusive candidate list.
    final disk = SrdSphereAreaRules.preview(
      map: map,
      origin: origin,
      radiusFeet: distanceFeet,
    );
    return SrdEmanationAreaPreview(
      origin: origin,
      distanceFeet: distanceFeet,
      sourceKind: sourceKind,
      motion: motion,
      includeSourceByChoice: includeSourceByChoice,
      candidates: [
        for (final item in disk.candidates)
          SrdEmanationCellCandidate(
            cell: item.cell,
            centerWithinDistance: item.centerWithinRadius,
            originSquareRequiresReview: item.cell == origin,
            centerRay: item.centerRay,
          ),
      ],
    );
  }
}
