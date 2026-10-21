import 'srd_spell_catalog.dart';
import 'srd_spell_grid_target_rules.dart';

/// Geometric approximation of one square on a 2D, 5-foot tactical map.
/// "Possible" is deliberately NOT "affected": the SRD requires the actual
/// effect, 3D geometry, square coverage and cover to be resolved separately.
enum SrdSphereCenterRay { clear, requiresCoverReview }

class SrdSphereCellCandidate {
  const SrdSphereCellCandidate({
    required this.cell,
    required this.centerWithinRadius,
    required this.centerRay,
  });

  final SrdGridCell cell;

  /// True only when the *center* lies in the circle. False means that
  /// the square can still overlap the sphere around its edge or corner.
  final bool centerWithinRadius;

  /// Blocked center rays are uncertain, NOT definitely shielded by Total Cover.
  final SrdSphereCenterRay centerRay;
}

class SrdSphereAreaPreview {
  SrdSphereAreaPreview({
    required this.origin,
    required this.radiusFeet,
    required List<SrdSphereCellCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final SrdGridCell origin;
  final int radiusFeet;
  final List<SrdSphereCellCandidate> candidates;

  /// Candidate cells that need a separate obstacle/cover ruling.
  int get coverReviewCount => candidates
      .where(
        (candidate) =>
            candidate.centerRay == SrdSphereCenterRay.requiresCoverReview,
      )
      .length;

  /// Only geometrically centered cells with an unobstructed center ray.
  /// These are still not confirmed spell targets or damage recipients.
  Iterable<SrdGridCell> get clearCenterCells => candidates
      .where(
        (candidate) =>
            candidate.centerWithinRadius &&
            candidate.centerRay == SrdSphereCenterRay.clear,
      )
      .map((candidate) => candidate.cell);

  SrdSphereCellCandidate? at(SrdGridCell position) {
    for (final entry in candidates) {
      if (entry.cell == position) return entry;
    }
    return null;
  }
}

/// SRD 5.2.1 sphere shape: candidate ground squares around a verified origin.
///
/// A square is a *possible overlap* when any part of its closed 2D footprint
/// touches the circle. This intentionally over-includes marginal cells,
/// rather than pretending to know the required square-coverage convention.
/// No target, damage, saving throw, wall-breaking or effect is resolved.
///
/// Radius is caller-provided and must already be verified against the
/// spell's *effect description*: it is NOT read from the casting range.
/// A 2D preview cannot conclude full 3D area-of-effect eligibility.
class SrdSphereAreaRules {
  const SrdSphereAreaRules._();

  /// Connects a separately verified sphere shape and its effect radius to
  /// the already checked caster-to-origin spell range / clear path.
  /// The SRD spell catalogue stores range, NOT an authoritative AoE radius.
  static SrdSphereAreaPreview previewConfirmedSpell({
    required SrdSpellDefinition spell,
    required SrdSpellGridTargetRequest gridTarget,
    required bool sphereShapeVerifiedFromEffect,
    required int verifiedEffectRadiusFeet,
  }) {
    if (!sphereShapeVerifiedFromEffect) {
      throw const FormatException(
        'Die Kugelform muss separat aus dem SRD-Zaubereffekt bestätigt sein.',
      );
    }
    SrdSpellGridTargetRules.validateOrigin(spell, gridTarget);
    return preview(
      map: gridTarget.map,
      origin: gridTarget.origin,
      radiusFeet: verifiedEffectRadiusFeet,
    );
  }

  static SrdSphereAreaPreview preview({
    required SrdSpellGridMap map,
    required SrdGridCell origin,
    required int radiusFeet,
  }) {
    if (radiusFeet < 5 || radiusFeet > 120 || radiusFeet % 5 != 0) {
      throw const FormatException(
        'Kugelvorschau unterstützt bestätigte Radien von 5–120 Fuß in 5-Fuß-Schritten.',
      );
    }
    if (!map.fullBlockersSurveyedConfirmed ||
        !map.contains(origin) ||
        map.fullBlockers.contains(origin)) {
      throw const FormatException(
        'Der Kugelursprung muss ein bestätigtes, freies Rasterfeld sein.',
      );
    }
    final radiusCells = radiusFeet ~/ 5;
    final result = <SrdSphereCellCandidate>[];

    final minRow = origin.row - radiusCells - 1;
    final maxRow = origin.row + radiusCells + 1;
    final minColumn = origin.column - radiusCells - 1;
    final maxColumn = origin.column + radiusCells + 1;
    for (
      var row = minRow < 0 ? 0 : minRow;
      row <= maxRow && row < map.height;
      row++
    ) {
      for (
        var col = minColumn < 0 ? 0 : minColumn;
        col <= maxColumn && col < map.width;
        col++
      ) {
        final cell = SrdGridCell(col, row);
        if (map.fullBlockers.contains(cell)) {
          // Opaque wall squares are not free ground squares to preview.
          continue;
        }

        final dx = (col - origin.column).abs();
        final dy = (row - origin.row).abs();

        // Closest point of the closed target square to the origin at the
        // origin square's center. Units: half of one 5-foot grid cell.
        final halfDx = dx == 0 ? 0 : 2 * dx - 1;
        final halfDy = dy == 0 ? 0 : 2 * dy - 1;
        final diameterInCells = 2 * radiusCells;
        if (halfDx * halfDx + halfDy * halfDy >
            diameterInCells * diameterInCells) {
          continue;
        }
        final rayClear = SrdSpellGridTargetRules.hasClearCenterRay(
          map,
          origin,
          cell,
        );
        result.add(
          SrdSphereCellCandidate(
            cell: cell,
            centerWithinRadius: dx * dx + dy * dy <= radiusCells * radiusCells,
            centerRay: rayClear
                ? SrdSphereCenterRay.clear
                : SrdSphereCenterRay.requiresCoverReview,
          ),
        );
      }
    }
    return SrdSphereAreaPreview(
      origin: origin,
      radiusFeet: radiusFeet,
      candidates: result,
    );
  }
}
