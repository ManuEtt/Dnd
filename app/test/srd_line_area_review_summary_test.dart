import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_line_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const origin = SrdGridCell(10, 10);

SrdLineAreaPreview preview({
  Iterable<SrdGridCell> blockers = const [],
  bool includeOrigin = false,
}) => SrdLineAreaRules.preview(
  map: SrdSpellGridMap(
    width: 40,
    height: 40,
    fullBlockers: blockers,
    fullBlockersSurveyedConfirmed: true,
  ),
  origin: origin,
  lengthFeet: 15,
  widthFeet: 5,
  direction: SrdLineDirection.east,
  includeOriginPointConfirmed: includeOrigin,
);

void main() {
  test('clear centers exclude origin until expressly confirmed', () {
    final line = preview();
    expect(line.clearCenterCells, contains(const SrdGridCell(11, 10)));
    expect(line.clearCenterCells, isNot(contains(origin)));
    expect(line.coverReviewCount, 0);
    expect(preview(includeOrigin: true).clearCenterCells, contains(origin));
  });

  test('obstructed rays require review rather than an automatic hit', () {
    final line = preview(blockers: [const SrdGridCell(11, 10)]);
    final flagged = line.candidates
        .where((c) => c.centerRay == SrdSphereCenterRay.requiresCoverReview)
        .toList();
    expect(flagged, isNotEmpty);
    expect(line.coverReviewCount, flagged.length);
    expect(line.at(const SrdGridCell(11, 10)), isNull);
    for (final cell in line.clearCenterCells) {
      expect(line.at(cell)!.centerRay, SrdSphereCenterRay.clear);
      expect(line.at(cell)!.centerWithinLine, isTrue);
    }
  });

  test('read-only summary does not mutate candidates', () {
    final line = preview();
    final before = line.candidates.toList();
    line.clearCenterCells.toList();
    expect(line.candidates, orderedEquals(before));
  });
}
