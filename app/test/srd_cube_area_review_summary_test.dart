import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_cube_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const origin = SrdGridCell(5, 5);

SrdCubeAreaPreview _preview({
  Iterable<SrdGridCell> blockers = const [],
}) => SrdCubeAreaRules.preview(
  map: SrdSpellGridMap(
    width: 15,
    height: 15,
    fullBlockers: blockers,
    fullBlockersSurveyedConfirmed: true,
  ),
  origin: origin,
  sideFeet: 15,
  axisAlignedFootprintConfirmed: true,
);

void main() {
  test('clear square centers are read-only candidates', () {
    final preview = _preview();
    final before = preview.candidates.toList();
    expect(preview.candidates.length, 9);
    expect(preview.coverReviewCount, 0);
    expect(preview.clearCenterCells.toSet().length, 9);
    expect(preview.at(origin), isNotNull);
    expect(preview.at(const SrdGridCell(8, 8)), isNull);
    expect(preview.candidates, orderedEquals(before));
  });

  test('blocker is excluded while obscured rays remain reviewable', () {
    final blocked = const SrdGridCell(6, 5);
    final preview = _preview(blockers: [blocked]);
    expect(preview.at(blocked), isNull);
    final reviews = preview.candidates
        .where((candidate) =>
            candidate.centerRay == SrdSphereCenterRay.requiresCoverReview)
        .toList();
    expect(preview.coverReviewCount, reviews.length);
    expect(reviews, isNotEmpty);
    for (final cell in preview.clearCenterCells) {
      expect(preview.at(cell)!.centerRay, SrdSphereCenterRay.clear);
    }
  });

  test('unconfirmed footprint still rejects preview', () {
    expect(
      () => SrdCubeAreaRules.preview(
        map: SrdSpellGridMap(
          width: 15,
          height: 15,
          fullBlockers: const [],
          fullBlockersSurveyedConfirmed: true,
        ),
        origin: origin,
        sideFeet: 15,
        axisAlignedFootprintConfirmed: false,
      ),
      throwsFormatException,
    );
  });
}
