import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_cylinder_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const origin = SrdGridCell(10, 10);

SrdCylinderAreaPreview preview({
  Iterable<SrdGridCell> blockers = const [],
  SrdCylinderOriginFace face = SrdCylinderOriginFace.bottom,
}) => SrdCylinderAreaRules.preview(
  map: SrdSpellGridMap(
    width: 40,
    height: 40,
    fullBlockers: blockers,
    fullBlockersSurveyedConfirmed: true,
  ),
  origin: origin,
  radiusFeet: 10,
  heightFeet: 40,
  originFace: face,
);

void main() {
  test('clear centers are inside the circular base', () {
    final cylinder = preview();
    expect(cylinder.clearCenterCells, contains(origin));
    expect(cylinder.clearCenterCells, contains(const SrdGridCell(11, 10)));
    expect(cylinder.coverReviewCount, 0);
    for (final cell in cylinder.clearCenterCells) {
      expect(cylinder.at(cell)!.centerWithinBase, isTrue);
      expect(cylinder.at(cell)!.centerRay, SrdSphereCenterRay.clear);
    }
  });

  test('blocked center rays are counted for review', () {
    final cylinder = preview(blockers: [const SrdGridCell(11, 10)]);
    final flagged = cylinder.candidates
        .where((candidate) =>
            candidate.centerRay == SrdSphereCenterRay.requiresCoverReview)
        .toList();
    expect(flagged, isNotEmpty);
    expect(cylinder.coverReviewCount, flagged.length);
    expect(cylinder.at(const SrdGridCell(11, 10)), isNull);
  });

  test('top and bottom faces preserve horizontal summary', () {
    final bottom = preview();
    final top = preview(face: SrdCylinderOriginFace.top);
    expect(top.clearCenterCells.toSet(), bottom.clearCenterCells.toSet());
    expect(top.minVerticalOffsetFeet, -40);
    expect(bottom.maxVerticalOffsetFeet, 40);
  });

  test('summary leaves candidate list unchanged', () {
    final cylinder = preview();
    final before = cylinder.candidates.toList();
    cylinder.clearCenterCells.toList();
    expect(cylinder.candidates, orderedEquals(before));
  });
}
