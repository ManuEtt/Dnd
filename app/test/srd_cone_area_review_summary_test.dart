import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_cone_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const origin = SrdGridCell(15, 15);

SrdConeAreaPreview _preview({
  Iterable<SrdGridCell> blockers = const [],
  bool includeOrigin = false,
}) => SrdConeAreaRules.preview(
  map: SrdSpellGridMap(
    width: 40,
    height: 40,
    fullBlockers: blockers,
    fullBlockersSurveyedConfirmed: true,
  ),
  origin: origin,
  lengthFeet: 15,
  direction: SrdConeDirection.east,
  includeOriginPointConfirmed: includeOrigin,
);

void main() {
  test('clear center cells exclude origin unless explicitly included', () {
    final preview = _preview();
    expect(preview.clearCenterCells, contains(const SrdGridCell(16, 15)));
    expect(preview.clearCenterCells, isNot(contains(origin)));
    expect(preview.coverReviewCount, 0);
    expect(_preview(includeOrigin: true).clearCenterCells, contains(origin));
  });

  test('review count follows blocked rays without claiming total cover', () {
    final preview = _preview(blockers: [const SrdGridCell(16, 15)]);
    final reviewCandidates = preview.candidates
        .where((c) => c.centerRay == SrdSphereCenterRay.requiresCoverReview)
        .toList();
    expect(reviewCandidates, isNotEmpty);
    expect(preview.coverReviewCount, reviewCandidates.length);
    for (final cell in preview.clearCenterCells) {
      expect(preview.at(cell)!.centerRay, SrdSphereCenterRay.clear);
      expect(preview.at(cell)!.centerWithinCone, isTrue);
    }
    expect(preview.at(const SrdGridCell(16, 15)), isNull);
  });

  test('candidate collection stays unchanged after filtering', () {
    final preview = _preview();
    final before = preview.candidates.toList();
    preview.clearCenterCells.toList();
    expect(preview.candidates, orderedEquals(before));
  });
}
