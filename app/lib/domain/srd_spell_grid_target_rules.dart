import 'dart:math' as math;

import 'srd_spell_catalog.dart';
import 'srd_spell_target_rules.dart';

/// A single square on an explicitly surveyed 5-foot tactical grid.
/// These are tile coordinates, NOT a real-world map or inferred story fact.
class SrdGridCell {
  const SrdGridCell(this.column, this.row);

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      other is SrdGridCell && column == other.column && row == other.row;

  @override
  int get hashCode => Object.hash(column, row);
}

/// Snapshot of known, full-height and fully blocking squares.
///
/// An empty obstacle set does not prove the map is complete. The caller must
/// explicitly confirm that every relevant full blocker was surveyed. Partial
/// cover, low walls, creature cover, elevation and height are outside scope.
class SrdSpellGridMap {
  SrdSpellGridMap({
    required this.width,
    required this.height,
    required Iterable<SrdGridCell> fullBlockers,
    required this.fullBlockersSurveyedConfirmed,
  }) : fullBlockers = Set.unmodifiable(fullBlockers) {
    if (width < 1 || height < 1 || width > 200 || height > 200) {
      throw const FormatException('Ungültige Rasterkartengröße.');
    }
    for (final cell in this.fullBlockers) {
      if (!contains(cell)) {
        throw const FormatException(
          'Blockierende Felder müssen innerhalb der Karte liegen.',
        );
      }
    }
  }

  final int width;
  final int height;
  final Set<SrdGridCell> fullBlockers;
  final bool fullBlockersSurveyedConfirmed;

  bool contains(SrdGridCell cell) =>
      cell.column >= 0 &&
      cell.row >= 0 &&
      cell.column < width &&
      cell.row < height;
}

/// Exact map inputs for one caster square and one spell-origin square.
///
/// The caller still separately checks whether the spell can affect a
/// particular target, whether the target is seen, and any touch reach.
class SrdSpellGridTargetRequest {
  const SrdSpellGridTargetRequest({
    required this.map,
    required this.caster,
    required this.origin,
    this.withinTouchReachConfirmed = false,
  });

  final SrdSpellGridMap map;
  final SrdGridCell caster;
  final SrdGridCell origin;
  final bool withinTouchReachConfirmed;
}

/// Deterministic 2D center-ray witness and SRD spell-origin distance.
///
/// A clear *center-to-center* ray proves one unobstructed map route when the
/// confirmed terrain model is complete; a blocked center ray does NOT prove
/// that the target has total cover (another route might exist). Fail closed
/// at tile edges and corner touches rather than inventing clearance.
/// This is not the full SRD line of sight or 3D cover engine.
class SrdSpellGridTargetRules {
  const SrdSpellGridTargetRules._();

  static int distanceFeet(SrdGridCell a, SrdGridCell b) =>
      5 * math.max((b.column - a.column).abs(), (b.row - a.row).abs());

  static SrdSpellTargetFacts factsFor(
    SrdSpellDefinition spell,
    SrdSpellGridTargetRequest request,
  ) {
    final map = request.map;
    if (!map.fullBlockersSurveyedConfirmed) {
      throw const FormatException(
        'Die blockierenden Rasterfelder sind nicht vollständig bestätigt.',
      );
    }
    if (!map.contains(request.caster) || !map.contains(request.origin)) {
      throw const FormatException(
        'Zaubernder oder Zauberursprung liegt außerhalb der Rasterkarte.',
      );
    }
    if (map.fullBlockers.contains(request.caster) ||
        map.fullBlockers.contains(request.origin)) {
      throw const FormatException(
        'Zaubernder oder Zauberursprung liegt in einem blockierenden Feld.',
      );
    }
    if (!_centerRayIsClear(map, request.caster, request.origin)) {
      throw const FormatException(
        'Der gerade Rasterweg wird von einem bestätigten Hindernis blockiert.',
      );
    }

    final range = spell.range.trim();
    if (range == 'Self') {
      return SrdSpellTargetFacts(
        mode: SrdSpellOriginMode.caster,
        originDistanceFeet: distanceFeet(request.caster, request.origin),
      );
    }
    if (range == 'Touch') {
      return SrdSpellTargetFacts(
        mode: SrdSpellOriginMode.touched,
        clearPathConfirmed: true,
        withinTouchReachConfirmed: request.withinTouchReachConfirmed,
      );
    }
    return SrdSpellTargetFacts(
      mode: SrdSpellOriginMode.distant,
      originDistanceFeet: distanceFeet(request.caster, request.origin),
      clearPathConfirmed: true,
    );
  }

  static SrdSpellTargetAssessment validateOrigin(
    SrdSpellDefinition spell,
    SrdSpellGridTargetRequest request,
  ) => SrdSpellTargetRules.validateOrigin(spell, factsFor(spell, request));

  /// An inclusive segment-vs-closed-square intersection. Touching a corner
  /// or edge of an opaque square is deliberately NOT treated as a clear ray.
  static bool _centerRayIsClear(
    SrdSpellGridMap map,
    SrdGridCell caster,
    SrdGridCell origin,
  ) {
    final x0 = caster.column + 0.5;
    final y0 = caster.row + 0.5;
    final dx = (origin.column - caster.column).toDouble();
    final dy = (origin.row - caster.row).toDouble();

    for (final wall in map.fullBlockers) {
      var lower = 0.0;
      var upper = 1.0;

      bool clip(double p, double q) {
        if (p == 0) return q >= 0;
        final ratio = q / p;
        if (p < 0) {
          if (ratio > upper) return false;
          if (ratio > lower) lower = ratio;
        } else {
          if (ratio < lower) return false;
          if (ratio < upper) upper = ratio;
        }
        return true;
      }

      final intersects =
          clip(-dx, x0 - wall.column) &&
          clip(dx, wall.column + 1 - x0) &&
          clip(-dy, y0 - wall.row) &&
          clip(dy, wall.row + 1 - y0) &&
          lower <= upper;
      if (intersects) return false;
    }
    return true;
  }
}
