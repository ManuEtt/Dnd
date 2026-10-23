import 'dart:math' as math;

import 'srd_spell_catalog.dart';
import 'srd_spell_grid_target_rules.dart';
import 'srd_sphere_area_rules.dart';

/// Eight supported planar directions; 3D and arbitrary rotation are excluded.
enum SrdLineDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

class SrdLineCellCandidate {
  const SrdLineCellCandidate({
    required this.cell,
    required this.centerWithinLine,
    required this.originCellRequiresReview,
    required this.centerRay,
  });

  final SrdGridCell cell;

  /// Only the center of this square is inside the projected line rectangle.
  /// This does not determine the creatures actually affected by the spell.
  final bool centerWithinLine;

  /// The origin point is normally excluded, but its containing square may
  /// intersect the area. Do not infer that the entire square is excluded.
  final bool originCellRequiresReview;

  /// Blocked center rays mean review is needed, not proven Total Cover.
  final SrdSphereCenterRay centerRay;
}

class SrdLineAreaPreview {
  SrdLineAreaPreview({
    required this.origin,
    required this.lengthFeet,
    required this.widthFeet,
    required this.direction,
    required List<SrdLineCellCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final SrdGridCell origin;
  final int lengthFeet;
  final int widthFeet;
  final SrdLineDirection direction;
  final List<SrdLineCellCandidate> candidates;

  SrdLineCellCandidate? at(SrdGridCell cell) {
    for (final candidate in candidates) {
      if (candidate.cell == cell) return candidate;
    }
    return null;
  }
}

/// Read-only 2D SRD 5.2.1 Line area candidates on a confirmed 5-foot map.
///
/// The line is projected as a rectangle starting at the origin POINT and
/// extending in one of eight directions with the separately verified width.
/// Even an edge/corner touch is a candidate requiring a later rules check.
/// Neither a center in the rectangle nor a clear center ray establishes a
/// real 3D hit, cover grade, target type, save or damage.
class SrdLineAreaRules {
  const SrdLineAreaRules._();

  static (int, int) _steps(SrdLineDirection direction) => switch (direction) {
    SrdLineDirection.north => (0, -1),
    SrdLineDirection.northEast => (1, -1),
    SrdLineDirection.east => (1, 0),
    SrdLineDirection.southEast => (1, 1),
    SrdLineDirection.south => (0, 1),
    SrdLineDirection.southWest => (-1, 1),
    SrdLineDirection.west => (-1, 0),
    SrdLineDirection.northWest => (-1, -1),
  };

  /// Spell range to the origin is NOT the area length or area width.
  /// The caller must confirm the shape and both dimensions from the spell.
  static SrdLineAreaPreview previewConfirmedSpell({
    required SrdSpellDefinition spell,
    required SrdSpellGridTargetRequest gridTarget,
    required bool lineShapeVerifiedFromEffect,
    required int verifiedEffectLengthFeet,
    required int verifiedEffectWidthFeet,
    required SrdLineDirection direction,
    bool includeOriginPointConfirmed = false,
  }) {
    if (!lineShapeVerifiedFromEffect) {
      throw const FormatException(
        'Linienform, Länge und Breite müssen aus dem Zaubereffekt bestätigt sein.',
      );
    }
    SrdSpellGridTargetRules.validateOrigin(spell, gridTarget);
    return preview(
      map: gridTarget.map,
      origin: gridTarget.origin,
      lengthFeet: verifiedEffectLengthFeet,
      widthFeet: verifiedEffectWidthFeet,
      direction: direction,
      includeOriginPointConfirmed: includeOriginPointConfirmed,
    );
  }

  static SrdLineAreaPreview preview({
    required SrdSpellGridMap map,
    required SrdGridCell origin,
    required int lengthFeet,
    required int widthFeet,
    required SrdLineDirection direction,
    bool includeOriginPointConfirmed = false,
  }) {
    if (lengthFeet < 5 || lengthFeet > 300 || lengthFeet % 5 != 0) {
      throw const FormatException(
        'Linienlänge benötigt bestätigte 5-Fuß-Schritte (5–300 Fuß).',
      );
    }
    if (widthFeet < 5 || widthFeet > 60 || widthFeet % 5 != 0) {
      throw const FormatException(
        'Linienbreite benötigt bestätigte 5-Fuß-Schritte (5–60 Fuß).',
      );
    }
    if (!map.fullBlockersSurveyedConfirmed ||
        !map.contains(origin) ||
        map.fullBlockers.contains(origin)) {
      throw const FormatException(
        'Linienursprung benötigt eine bestätigte, freie Rasterkarte.',
      );
    }

    final (stepX, stepY) = _steps(direction);
    final magnitude = math.sqrt((stepX * stepX + stepY * stepY).toDouble());
    final ux = stepX / magnitude;
    final uy = stepY / magnitude;
    final length = lengthFeet / 5.0;
    final halfWidth = widthFeet / 10.0;
    final x = origin.column + 0.5;
    final y = origin.row + 0.5;

    // The four corners of the closed horizontal projected rectangle.
    final rectangle = <(double, double)>[
      (x - uy * halfWidth, y + ux * halfWidth),
      (x + ux * length - uy * halfWidth, y + uy * length + ux * halfWidth),
      (x + ux * length + uy * halfWidth, y + uy * length - ux * halfWidth),
      (x + uy * halfWidth, y - ux * halfWidth),
    ];
    final minX = rectangle.map((point) => point.$1).reduce(math.min);
    final maxX = rectangle.map((point) => point.$1).reduce(math.max);
    final minY = rectangle.map((point) => point.$2).reduce(math.min);
    final maxY = rectangle.map((point) => point.$2).reduce(math.max);
    final candidates = <SrdLineCellCandidate>[];

    for (
      var row = math.max(0, minY.floor() - 1);
      row < map.height && row <= maxY.ceil();
      row++
    ) {
      for (
        var col = math.max(0, minX.floor() - 1);
        col < map.width && col <= maxX.ceil();
        col++
      ) {
        final cell = SrdGridCell(col, row);
        if (map.fullBlockers.contains(cell) ||
            !_rectangleTouchesSquare(rectangle, col, row)) {
          continue;
        }
        final isOrigin = cell == origin;
        final dx = col - origin.column;
        final dy = row - origin.row;
        final forward = dx * ux + dy * uy;
        final sideways = dx * uy - dy * ux;
        final centered =
            forward >= -1e-9 &&
            forward <= length + 1e-9 &&
            sideways.abs() <= halfWidth + 1e-9;
        final clear = SrdSpellGridTargetRules.hasClearCenterRay(
          map,
          origin,
          cell,
        );
        candidates.add(
          SrdLineCellCandidate(
            cell: cell,
            centerWithinLine:
                centered && (!isOrigin || includeOriginPointConfirmed),
            originCellRequiresReview: isOrigin,
            centerRay: clear
                ? SrdSphereCenterRay.clear
                : SrdSphereCenterRay.requiresCoverReview,
          ),
        );
      }
    }

    return SrdLineAreaPreview(
      origin: origin,
      lengthFeet: lengthFeet,
      widthFeet: widthFeet,
      direction: direction,
      candidates: candidates,
    );
  }

  /// Separating Axis Theorem for a rotated closed rectangle and unit square.
  /// Touching an edge is retained to avoid falsely ruling out partial cells.
  static bool _rectangleTouchesSquare(
    List<(double, double)> rectangle,
    int column,
    int row,
  ) {
    final square = <(double, double)>[
      (column.toDouble(), row.toDouble()),
      (column + 1.0, row.toDouble()),
      (column + 1.0, row + 1.0),
      (column.toDouble(), row + 1.0),
    ];
    final axes = <(double, double)>[(1.0, 0.0), (0.0, 1.0)];
    for (var i = 0; i < 4; i++) {
      final a = rectangle[i];
      final b = rectangle[(i + 1) % 4];
      axes.add((-(b.$2 - a.$2), b.$1 - a.$1));
    }
    for (final axis in axes) {
      double dot((double, double) point) =>
          point.$1 * axis.$1 + point.$2 * axis.$2;
      final rectangleDots = rectangle.map(dot);
      final squareDots = square.map(dot);
      if (rectangleDots.reduce(math.max) < squareDots.reduce(math.min) - 1e-9 ||
          squareDots.reduce(math.max) < rectangleDots.reduce(math.min) - 1e-9) {
        return false;
      }
    }
    return true;
  }
}
