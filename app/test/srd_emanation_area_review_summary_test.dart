import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_emanation_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const source = SrdGridCell(10, 10);

SrdEmanationAreaPreview preview({
  Iterable<SrdGridCell> blockers = const [],
  bool includeSource = false,
}) => SrdEmanationAreaRules.preview(
  map: SrdSpellGridMap(
    width: 40,
    height: 40,
    fullBlockers: blockers,
    fullBlockersSurveyedConfirmed: true,
  ),
  origin: source,
  distanceFeet: 15,
  sourceKind: SrdEmanationSourceKind.creature,
  motion: SrdEmanationMotion.followsSource,
  sourceCenterAndSingleCellConfirmed: true,
  includeSourceByChoice: includeSource,
);

void main() {
  test('clear centers describe squares, not source inclusion', () {
    final excluded = preview();
    final included = preview(includeSource: true);
    expect(excluded.includeSourceByChoice, isFalse);
    expect(included.includeSourceByChoice, isTrue);
    expect(excluded.clearCenterCells, contains(source));
    expect(included.clearCenterCells.toSet(), excluded.clearCenterCells.toSet());
    expect(excluded.coverReviewCount, 0);
  });

  test('blocked rays count as cover review without confirming cover', () {
    final area = preview(blockers: [const SrdGridCell(11, 10)]);
    final flagged = area.candidates
        .where((c) => c.centerRay == SrdSphereCenterRay.requiresCoverReview)
        .toList();
    expect(flagged, isNotEmpty);
    expect(area.coverReviewCount, flagged.length);
    expect(area.at(const SrdGridCell(11, 10)), isNull);
    for (final cell in area.clearCenterCells) {
      expect(area.at(cell)!.centerWithinDistance, isTrue);
      expect(area.at(cell)!.centerRay, SrdSphereCenterRay.clear);
    }
  });

  test('read-only queries preserve candidate snapshots', () {
    final area = preview();
    final before = area.candidates.toList();
    area.clearCenterCells.toList();
    expect(area.candidates, orderedEquals(before));
  });
}
