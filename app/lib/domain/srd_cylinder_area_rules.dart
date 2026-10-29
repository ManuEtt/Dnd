import 'srd_spell_catalog.dart';
import 'srd_spell_grid_target_rules.dart';
import 'srd_sphere_area_rules.dart';

/// The SRD cylinder starts at the centre of its circular top or bottom.
/// Heights are relative to that face; no absolute elevation is inferred.
enum SrdCylinderOriginFace { top, bottom }

class SrdCylinderCellCandidate {
  const SrdCylinderCellCandidate({
    required this.cell,
    required this.centerWithinBase,
    required this.centerRay,
  });

  final SrdGridCell cell;

  /// Center of the ground square is within the projected circular base.
  /// A false value does not rule out partial intersection with that square.
  final bool centerWithinBase;

  /// Only a horizontal center-ray witness, never a 3D cover decision.
  final SrdSphereCenterRay centerRay;
}

class SrdCylinderAreaPreview {
  SrdCylinderAreaPreview({
    required this.origin,
    required this.radiusFeet,
    required this.heightFeet,
    required this.originFace,
    required List<SrdCylinderCellCandidate> candidates,
  }) : candidates = List.unmodifiable(candidates);

  final SrdGridCell origin;
  final int radiusFeet;
  final int heightFeet;
  final SrdCylinderOriginFace originFace;

  /// Possible ground-footprint squares; not verified affected creatures.
  final List<SrdCylinderCellCandidate> candidates;

  /// Positive vertical offsets point upward, relative to the selected face.
  int get minVerticalOffsetFeet =>
      originFace == SrdCylinderOriginFace.top ? -heightFeet : 0;

  int get maxVerticalOffsetFeet =>
      originFace == SrdCylinderOriginFace.bottom ? heightFeet : 0;

  SrdCylinderCellCandidate? at(SrdGridCell cell) {
    for (final candidate in candidates) {
      if (candidate.cell == cell) return candidate;
    }
    return null;
  }
}

/// SRD 5.2.1, Rules Glossary / Cylinder (CC BY 4.0):
/// https://www.dndbeyond.com/srd
///
/// A cylinder has a circular base, a height, and its origin at the center
/// of either circular face. Only a conservative 2D footprint is previewed.
/// Neither the caster-to-origin range nor the circle's radius establishes
/// the cylinder's height. Absolute altitude, creature height, vertical cover,
/// line of effect, damage and saving throws are NOT evaluated or committed.
class SrdCylinderAreaRules {
  const SrdCylinderAreaRules._();

  /// Requires independent spell-effect confirmation before calculating a
  /// horizontal preview, and validates casting range to the chosen origin.
  static SrdCylinderAreaPreview previewConfirmedSpell({
    required SrdSpellDefinition spell,
    required SrdSpellGridTargetRequest gridTarget,
    required bool cylinderShapeVerifiedFromEffect,
    required int verifiedEffectRadiusFeet,
    required int verifiedEffectHeightFeet,
    required SrdCylinderOriginFace originFace,
  }) {
    if (!cylinderShapeVerifiedFromEffect) {
      throw const FormatException(
        'Zylinderform, Radius, Höhe und Ursprungsfläche müssen '
        'aus dem Zaubereffekt bestätigt sein.',
      );
    }
    SrdSpellGridTargetRules.validateOrigin(spell, gridTarget);
    return preview(
      map: gridTarget.map,
      origin: gridTarget.origin,
      radiusFeet: verifiedEffectRadiusFeet,
      heightFeet: verifiedEffectHeightFeet,
      originFace: originFace,
    );
  }

  /// Standalone, read-only geometric preview on an explicitly surveyed map.
  ///
  /// The circle is the same horizontal projection as a sphere's central
  /// section, so reuse its conservative square-intersection/cover witness.
  /// Supported measurements are a deliberate implementation bound, not a
  /// claim that all SRD cylinder dimensions fit these limits.
  static SrdCylinderAreaPreview preview({
    required SrdSpellGridMap map,
    required SrdGridCell origin,
    required int radiusFeet,
    required int heightFeet,
    required SrdCylinderOriginFace originFace,
  }) {
    if (heightFeet < 5 || heightFeet > 300 || heightFeet % 5 != 0) {
      throw const FormatException(
        'Zylinderhöhe benötigt bestätigte 5-Fuß-Schritte (5–300 Fuß).',
      );
    }
    final disk = SrdSphereAreaRules.preview(
      map: map,
      origin: origin,
      radiusFeet: radiusFeet,
    );
    return SrdCylinderAreaPreview(
      origin: origin,
      radiusFeet: radiusFeet,
      heightFeet: heightFeet,
      originFace: originFace,
      candidates: [
        for (final item in disk.candidates)
          SrdCylinderCellCandidate(
            cell: item.cell,
            centerWithinBase: item.centerWithinRadius,
            centerRay: item.centerRay,
          ),
      ],
    );
  }
}
