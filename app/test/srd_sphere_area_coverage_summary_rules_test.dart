import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_coverage_summary_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';

void main() {
  test('separates centered, marginal and cover-review candidates', () {
    final preview = SrdSphereAreaPreview(
      origin: const SrdGridCell(2, 2),
      radiusFeet: 10,
      candidates: const [
        SrdSphereCellCandidate(
          cell: SrdGridCell(2, 2),
          centerWithinRadius: true,
          centerRay: SrdSphereCenterRay.clear,
        ),
        SrdSphereCellCandidate(
          cell: SrdGridCell(3, 2),
          centerWithinRadius: true,
          centerRay: SrdSphereCenterRay.requiresCoverReview,
        ),
        SrdSphereCellCandidate(
          cell: SrdGridCell(4, 3),
          centerWithinRadius: false,
          centerRay: SrdSphereCenterRay.clear,
        ),
        SrdSphereCellCandidate(
          cell: SrdGridCell(4, 4),
          centerWithinRadius: false,
          centerRay: SrdSphereCenterRay.requiresCoverReview,
        ),
      ],
    );
    final result = SrdSphereCoverageSummaryRules.summarize(preview);
    expect(result.centeredClear, 1);
    expect(result.centeredCoverReview, 1);
    expect(result.marginalClear, 1);
    expect(result.marginalCoverReview, 1);
    expect(result.centeredCandidates, 2);
    expect(result.marginalCandidates, 2);
    expect(result.totalCandidates, 4);
    expect(result.coverReviewCount, 2);
    expect(result.requiresCoverAdjudication, isTrue);
  });

  test('empty candidate preview has no confirmed coverage', () {
    final result = SrdSphereCoverageSummaryRules.summarize(
      SrdSphereAreaPreview(
        origin: const SrdGridCell(0, 0),
        radiusFeet: 5,
        candidates: const [],
      ),
    );
    expect(result.totalCandidates, 0);
    expect(result.requiresCoverAdjudication, isFalse);
  });

  test('works with canonical sphere preview without changing it', () {
    final preview = SrdSphereAreaRules.preview(
      map: SrdSpellGridMap(
        width: 7,
        height: 7,
        fullBlockers: const [],
        fullBlockersSurveyedConfirmed: true,
      ),
      origin: const SrdGridCell(3, 3),
      radiusFeet: 5,
    );
    final result = SrdSphereCoverageSummaryRules.summarize(preview);
    expect(result.totalCandidates, preview.candidates.length);
    expect(result.coverReviewCount, preview.coverReviewCount);
    expect(result.centeredClear, greaterThan(0));
  });
}
