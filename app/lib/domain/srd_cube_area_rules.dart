import 'srd_spell_grid_target_rules.dart';
import 'srd_sphere_area_rules.dart';

/// Conservative, axis-aligned horizontal projection of an SRD cube.
///
/// The caller supplies a separately verified side length and the cube's
/// chosen face-origin square. This does not model height, face orientation,
/// spell-specific origin placement, or affected creatures.
class SrdCubeAreaPreview {
  SrdCubeAreaPreview({
    required this.origin,
    required this.sideFeet,
    required List<SrdCubeCellCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final SrdGridCell origin;
  final int sideFeet;
  final List<SrdCubeCellCandidate> candidates;
}

class SrdCubeCellCandidate {
  const SrdCubeCellCandidate({
    required this.cell,
    required this.centerRay,
  });

  final SrdGridCell cell;
  final SrdSphereCenterRay centerRay;
}

/// Axis-aligned *candidate* squares, never an automatic hit verdict.
///
/// A cube's actual point of origin is on a face, not necessarily the center
/// of a 5-foot tile. Therefore the caller must confirm the desired square
/// footprint independently before any spell effect is committed.
class SrdCubeAreaRules {
  const SrdCubeAreaRules._();

  static SrdCubeAreaPreview preview({
    required SrdSpellGridMap map,
    required SrdGridCell origin,
    required int sideFeet,
    required bool axisAlignedFootprintConfirmed,
  }) {
    if (!axisAlignedFootprintConfirmed) {
      throw const FormatException('Würfel-Ausrichtung ist nicht bestätigt.');
    }
    if (sideFeet < 5 || sideFeet > 120 || sideFeet % 5 != 0) {
      throw const FormatException('Ungültige Würfel-Kantenlänge.');
    }
    if (!map.fullBlockersSurveyedConfirmed ||
        !map.contains(origin) ||
        map.fullBlockers.contains(origin)) {
      throw const FormatException('Würfelursprung ist nicht bestätigt.');
    }
    final side = sideFeet ~/ 5;
    final candidates = <SrdCubeCellCandidate>[];
    for (var row = origin.row; row < origin.row + side && row < map.height; row++) {
      for (var col = origin.column; col < origin.column + side && col < map.width; col++) {
        final cell = SrdGridCell(col, row);
        if (map.fullBlockers.contains(cell)) continue;
        candidates.add(SrdCubeCellCandidate(
          cell: cell,
          centerRay: SrdSpellGridTargetRules.hasClearCenterRay(map, origin, cell)
              ? SrdSphereCenterRay.clear
              : SrdSphereCenterRay.requiresCoverReview,
        ));
      }
    }
    return SrdCubeAreaPreview(origin: origin, sideFeet: sideFeet, candidates: candidates);
  }
}
