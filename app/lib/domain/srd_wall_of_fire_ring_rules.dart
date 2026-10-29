import 'dart:math' as math;

import 'srd_spell_catalog.dart';
import 'srd_spell_grid_target_rules.dart';
import 'srd_sphere_area_rules.dart';

/// Conservative 2D overlap of a thin ring wall with a 5-foot grid square.
/// Neither possible overlap nor a center ray is a confirmed spell hit.
class SrdWallOfFireRingCellCandidate {
  const SrdWallOfFireRingCellCandidate({
    required this.cell,
    required this.centerWithinWall,
    required this.fullBlockerRequiresReview,
    required this.centerRay,
  });

  final SrdGridCell cell;
  final bool centerWithinWall;

  /// A wall may intersect a known opaque obstacle; it must not disappear
  /// silently from the preview or be treated as a valid occupied surface.
  final bool fullBlockerRequiresReview;
  final SrdSphereCenterRay centerRay;
}

class SrdWallOfFireRingPreview {
  SrdWallOfFireRingPreview({
    required this.center,
    required this.outerDiameterFeet,
    required this.heightFeet,
    required List<SrdWallOfFireRingCellCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final SrdGridCell center;
  final int outerDiameterFeet;
  final int heightFeet;

  /// The SRD wall is one foot thick, irrespective of the ring diameter.
  int get thicknessFeet => 1;

  /// Potential footprint only; no saves, damage or side selection.
  final List<SrdWallOfFireRingCellCandidate> candidates;

  SrdWallOfFireRingCellCandidate? at(SrdGridCell cell) {
    for (final candidate in candidates) {
      if (candidate.cell == cell) return candidate;
    }
    return null;
  }
}

/// SRD 5.2.1, Spell Descriptions / Wall of Fire, CC BY 4.0.
/// https://www.dndbeyond.com/srd
///
/// Read-only ring-footprint preflight. The caller explicitly confirms that
/// the chosen grid square CENTER is the ring center, that the stated diameter
/// denotes the OUTER diameter, and that a solid surface supports the ring.
/// A square is retained if its closed footprint might touch the one-foot
/// wall, even at a corner. This is NOT 3D cover, fire-damage resolution,
/// occupied-creature detection, or confirmation of a legal final placement.
class SrdWallOfFireRingRules {
  const SrdWallOfFireRingRules._();

  static SrdWallOfFireRingPreview previewConfirmedSpell({
    required SrdSpellDefinition spell,
    required SrdSpellGridTargetRequest gridTarget,
    required bool ringShapeVerifiedFromEffect,
    required bool outerDiameterConventionConfirmed,
    required bool solidSurfaceConfirmed,
    required int verifiedOuterDiameterFeet,
    required int verifiedHeightFeet,
  }) {
    if (spell.id != 'spell-wall-of-fire' ||
        spell.name != 'Wall of Fire' ||
        spell.level != 4 ||
        spell.range.trim() != '120 feet') {
      throw const FormatException('Kein bestätigter Wall-of-Fire-Zauber.');
    }
    if (!ringShapeVerifiedFromEffect ||
        !outerDiameterConventionConfirmed ||
        !solidSurfaceConfirmed) {
      throw const FormatException(
        'Ringform, äußerer Durchmesser und feste Oberfläche '
        'müssen ausdrücklich bestätigt sein.',
      );
    }
    SrdSpellGridTargetRules.validateOrigin(spell, gridTarget);
    return preview(
      map: gridTarget.map,
      center: gridTarget.origin,
      outerDiameterFeet: verifiedOuterDiameterFeet,
      heightFeet: verifiedHeightFeet,
    );
  }

  static SrdWallOfFireRingPreview preview({
    required SrdSpellGridMap map,
    required SrdGridCell center,
    required int outerDiameterFeet,
    required int heightFeet,
  }) {
    if (outerDiameterFeet < 5 ||
        outerDiameterFeet > 20 ||
        outerDiameterFeet % 5 != 0 ||
        heightFeet < 5 ||
        heightFeet > 20 ||
        heightFeet % 5 != 0) {
      throw const FormatException(
        'Ringdurchmesser und Höhe benötigen bestätigte '
        '5-Fuß-Schritte bis höchstens 20 Fuß.',
      );
    }
    if (!map.fullBlockersSurveyedConfirmed ||
        !map.contains(center) ||
        map.fullBlockers.contains(center)) {
      throw const FormatException(
        'Ringmittelpunkt braucht eine vollständig bestätigte, '
        'freie 5-Fuß-Rasterkarte.',
      );
    }

    final outerRadius = outerDiameterFeet / 2.0;
    final innerRadius = outerRadius - 1.0;
    final outerSquared = outerRadius * outerRadius;
    final innerSquared = innerRadius * innerRadius;
    final radiusCells = (outerRadius / 5.0).ceil();
    final candidates = <SrdWallOfFireRingCellCandidate>[];

    for (
      var row = math.max(0, center.row - radiusCells - 1);
      row < map.height && row <= center.row + radiusCells + 1;
      row++
    ) {
      for (
        var col = math.max(0, center.column - radiusCells - 1);
        col < map.width && col <= center.column + radiusCells + 1;
        col++
      ) {
        final dx = (col - center.column).abs();
        final dy = (row - center.row).abs();
        final nearestX = math.max(0.0, dx - 0.5) * 5;
        final nearestY = math.max(0.0, dy - 0.5) * 5;
        final farthestX = (dx + 0.5) * 5;
        final farthestY = (dy + 0.5) * 5;
        final closestSquared = nearestX * nearestX + nearestY * nearestY;
        final farthestSquared = farthestX * farthestX + farthestY * farthestY;
        if (closestSquared > outerSquared || farthestSquared < innerSquared) {
          continue;
        }

        final cell = SrdGridCell(col, row);
        final blocked = map.fullBlockers.contains(cell);
        final rayClear =
            !blocked &&
            SrdSpellGridTargetRules.hasClearCenterRay(map, center, cell);
        final centerSquared = 25 * (dx * dx + dy * dy);
        candidates.add(
          SrdWallOfFireRingCellCandidate(
            cell: cell,
            centerWithinWall:
                centerSquared >= innerSquared && centerSquared <= outerSquared,
            fullBlockerRequiresReview: blocked,
            centerRay: rayClear
                ? SrdSphereCenterRay.clear
                : SrdSphereCenterRay.requiresCoverReview,
          ),
        );
      }
    }

    return SrdWallOfFireRingPreview(
      center: center,
      outerDiameterFeet: outerDiameterFeet,
      heightFeet: heightFeet,
      candidates: candidates,
    );
  }
}
