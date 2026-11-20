import 'srd_sphere_area_rules.dart';

/// Read-only summary of the already computed 2D sphere candidates.
/// No candidate is promoted to a confirmed target or affected creature.
class SrdSphereCoverageSummary {
  const SrdSphereCoverageSummary({
    required this.centeredClear,
    required this.centeredCoverReview,
    required this.marginalClear,
    required this.marginalCoverReview,
  });

  final int centeredClear;
  final int centeredCoverReview;
  final int marginalClear;
  final int marginalCoverReview;

  int get centeredCandidates => centeredClear + centeredCoverReview;
  int get marginalCandidates => marginalClear + marginalCoverReview;
  int get totalCandidates => centeredCandidates + marginalCandidates;
  int get coverReviewCount => centeredCoverReview + marginalCoverReview;
  bool get requiresCoverAdjudication => coverReviewCount > 0;
}

/// Distinguishes square centers inside the radius from squares that only
/// potentially overlap its boundary. Both remain advisory: 3D geometry,
/// creature occupancy, square-coverage rulings and cover require adjudication.
class SrdSphereCoverageSummaryRules {
  const SrdSphereCoverageSummaryRules._();

  static SrdSphereCoverageSummary summarize(SrdSphereAreaPreview preview) {
    var centeredClear = 0;
    var centeredReview = 0;
    var marginalClear = 0;
    var marginalReview = 0;
    for (final candidate in preview.candidates) {
      if (candidate.centerWithinRadius) {
        if (candidate.centerRay == SrdSphereCenterRay.clear) {
          centeredClear++;
        } else {
          centeredReview++;
        }
      } else {
        if (candidate.centerRay == SrdSphereCenterRay.clear) {
          marginalClear++;
        } else {
          marginalReview++;
        }
      }
    }
    return SrdSphereCoverageSummary(
      centeredClear: centeredClear,
      centeredCoverReview: centeredReview,
      marginalClear: marginalClear,
      marginalCoverReview: marginalReview,
    );
  }
}
