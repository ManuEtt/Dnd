import 'dart:math' as math;

import 'srd_spell_catalog.dart';
import 'srd_spell_grid_target_rules.dart';
import 'srd_sphere_area_rules.dart';

/// Only eight explicitly selectable compass directions are implemented.
/// Arbitrary 3D directions and elevation still require a separate rule path.
enum SrdConeDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

class SrdConeCellCandidate {
  const SrdConeCellCandidate({
    required this.cell,
    required this.centerWithinCone,
    required this.originCellRequiresReview,
    required this.centerRay,
  });

  final SrdGridCell cell;

  /// Geometric midpoint inclusion only, NOT a verified creature or hit.
  final bool centerWithinCone;

  /// The origin POINT is normally excluded. The containing square can
  /// nevertheless overlap the rest of a cone, so it must not disappear.
  final bool originCellRequiresReview;

  /// A blocked center ray is NOT proof of Total Cover.
  final SrdSphereCenterRay centerRay;
}

class SrdConeAreaPreview {
  SrdConeAreaPreview({
    required this.origin,
    required this.lengthFeet,
    required this.direction,
    required List<SrdConeCellCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final SrdGridCell origin;
  final int lengthFeet;
  final SrdConeDirection direction;
  final List<SrdConeCellCandidate> candidates;

  SrdConeCellCandidate? at(SrdGridCell cell) {
    for (final candidate in candidates) {
      if (candidate.cell == cell) return candidate;
    }
    return null;
  }
}

/// SRD 5.2.1 Rules Glossary / Cone: width increases with distance from
/// the origin, reaching the same width as the chosen cone length.
///
/// This is a READ-ONLY horizontal projection onto a surveyed 5-foot grid:
/// possible square intersection and separately checked center-of-cell position.
/// It never selects affected creatures, applies saves/damage, or determines
/// full cover, line of sight or the vertical extent of a true 3D cone.
class SrdConeAreaRules {
  const SrdConeAreaRules._();

  static (int, int) _steps(SrdConeDirection direction) => switch (direction) {
    SrdConeDirection.north => (0, -1),
    SrdConeDirection.northEast => (1, -1),
    SrdConeDirection.east => (1, 0),
    SrdConeDirection.southEast => (1, 1),
    SrdConeDirection.south => (0, 1),
    SrdConeDirection.southWest => (-1, 1),
    SrdConeDirection.west => (-1, 0),
    SrdConeDirection.northWest => (-1, -1),
  };

  static SrdConeAreaPreview previewConfirmedSpell({
    required SrdSpellDefinition spell,
    required SrdSpellGridTargetRequest gridTarget,
    required bool coneShapeVerifiedFromEffect,
    required int verifiedEffectLengthFeet,
    required SrdConeDirection direction,
    bool includeOriginPointConfirmed = false,
  }) {
    if (!coneShapeVerifiedFromEffect) {
      throw const FormatException(
        'Kegelform und Länge müssen separat aus dem SRD-Effekt bestätigt sein.',
      );
    }
    SrdSpellGridTargetRules.validateOrigin(spell, gridTarget);
    return preview(
      map: gridTarget.map,
      origin: gridTarget.origin,
      lengthFeet: verifiedEffectLengthFeet,
      direction: direction,
      includeOriginPointConfirmed: includeOriginPointConfirmed,
    );
  }

  static SrdConeAreaPreview preview({
    required SrdSpellGridMap map,
    required SrdGridCell origin,
    required int lengthFeet,
    required SrdConeDirection direction,
    bool includeOriginPointConfirmed = false,
  }) {
    if (lengthFeet < 5 || lengthFeet > 120 || lengthFeet % 5 != 0) {
      throw const FormatException(
        'Kegellänge muss ein bestätigtes Vielfaches von 5 Fuß (5–120) sein.',
      );
    }
    if (!map.fullBlockersSurveyedConfirmed ||
        !map.contains(origin) ||
        map.fullBlockers.contains(origin)) {
      throw const FormatException(
        'Kegelursprung benötigt eine vollständig bestätigte freie Rasterkarte.',
      );
    }
    final (stepX, stepY) = _steps(direction);
    final magnitude = math.sqrt((stepX * stepX + stepY * stepY).toDouble());
    final ux = stepX / magnitude;
    final uy = stepY / magnitude;
    final length = lengthFeet / 5.0;
    final x = origin.column + 0.5;
    final y = origin.row + 0.5;
    final tip = (x, y);
    final left = (
      x + length * ux - length / 2 * uy,
      y + length * uy + length / 2 * ux,
    );
    final right = (
      x + length * ux + length / 2 * uy,
      y + length * uy - length / 2 * ux,
    );
    final triangle = [tip, left, right];

    final lowerX = triangle.map((p) => p.$1).reduce(math.min);
    final upperX = triangle.map((p) => p.$1).reduce(math.max);
    final lowerY = triangle.map((p) => p.$2).reduce(math.min);
    final upperY = triangle.map((p) => p.$2).reduce(math.max);
    final candidates = <SrdConeCellCandidate>[];

    for (var row = math.max(0, lowerY.floor() - 1);
        row < map.height && row <= upperY.ceil();
        row++) {
      for (var col = math.max(0, lowerX.floor() - 1);
          col < map.width && col <= upperX.ceil();
          col++) {
        final cell = SrdGridCell(col, row);
        if (map.fullBlockers.contains(cell) ||
            !_triangleTouchesSquare(triangle, col, row)) {
          continue;
        }

        final isOrigin = cell == origin;
        final deltaX = col - origin.column;
        final deltaY = row - origin.row;
        final forward = deltaX * ux + deltaY * uy;
        final sideways = deltaX * uy - deltaY * ux;
        final centered =
            forward >= 0 &&
            forward <= length &&
            sideways.abs() <= forward / 2;
        final clear =
            SrdSpellGridTargetRules.hasClearCenterRay(map, origin, cell);
        candidates.add(
          SrdConeCellCandidate(
            cell: cell,
            centerWithinCone:
                centered && (!isOrigin || includeOriginPointConfirmed),
            originCellRequiresReview: isOrigin,
            centerRay: clear
                ? SrdSphereCenterRay.clear
                : SrdSphereCenterRay.requiresCoverReview,
          ),
        );
      }
    }
    return SrdConeAreaPreview(
      origin: origin,
      lengthFeet: lengthFeet,
      direction: direction,
      candidates: candidates,
    );
  }

  /// SAT for a triangle and a closed axis-aligned square. Touching an edge
  /// or corner counts as a possible overlap and must be reviewed later.
  static bool _triangleTouchesSquare(
    List<(double, double)> triangle,
    int column,
    int row,
  ) {
    final square = [
      (column.toDouble(), row.toDouble()),
      (column + 1.0, row.toDouble()),
      (column + 1.0, row + 1.0),
      (column.toDouble(), row + 1.0),
    ];
    final axes = <(double, double)>[(1.0, 0.0), (0.0, 1.0)];
    for (var i = 0; i < 3; i++) {
      final a = triangle[i];
      final b = triangle[(i + 1) % 3];
      axes.add((-(b.$2 - a.$2), b.$1 - a.$1));
    }
    for (final axis in axes) {
      double dot((double, double) p) => p.$1 * axis.$1 + p.$2 * axis.$2;
      final triangleDots = triangle.map(dot);
      final squareDots = square.map(dot);
      final triangleMin = triangleDots.reduce(math.min);
      final triangleMax = triangleDots.reduce(math.max);
      final squareMin = squareDots.reduce(math.min);
      final squareMax = squareDots.reduce(math.max);
      if (triangleMax < squareMin - 1e-9 ||
          squareMax < triangleMin - 1e-9) {
        return false;
      }
    }
    return true;
  }
}
