import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_cube_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

void main() {
  test('confirmed 10-foot square previews four candidate tiles', () {
    final map = SrdSpellGridMap(
      width: 5,
      height: 5,
      fullBlockers: const [],
      fullBlockersSurveyedConfirmed: true,
    );
    final preview = SrdCubeAreaRules.preview(
      map: map,
      origin: const SrdGridCell(1, 1),
      sideFeet: 10,
      axisAlignedFootprintConfirmed: true,
    );
    expect(preview.candidates, hasLength(4));
    expect(
      preview.candidates.every(
        (entry) => entry.centerRay == SrdSphereCenterRay.clear,
      ),
      isTrue,
    );
    expect(() => preview.candidates.clear(), throwsUnsupportedError);
  });

  test('wall requires separate cover ruling for squares behind it', () {
    final map = SrdSpellGridMap(
      width: 5,
      height: 5,
      fullBlockers: const [SrdGridCell(1, 2)],
      fullBlockersSurveyedConfirmed: true,
    );
    final preview = SrdCubeAreaRules.preview(
      map: map,
      origin: const SrdGridCell(1, 1),
      sideFeet: 15,
      axisAlignedFootprintConfirmed: true,
    );
    expect(preview.candidates, hasLength(8));
    expect(
      preview.candidates.any((entry) => entry.cell == const SrdGridCell(1, 2)),
      isFalse,
    );
    expect(
      preview.candidates.any(
        (entry) => entry.centerRay == SrdSphereCenterRay.requiresCoverReview,
      ),
      isTrue,
    );
  });

  test('unverified geometry, invalid radius and map fail closed', () {
    final map = SrdSpellGridMap(
      width: 3,
      height: 3,
      fullBlockers: const [],
      fullBlockersSurveyedConfirmed: true,
    );
    expect(
      () => SrdCubeAreaRules.preview(
        map: map,
        origin: const SrdGridCell(0, 0),
        sideFeet: 10,
        axisAlignedFootprintConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdCubeAreaRules.preview(
        map: map,
        origin: const SrdGridCell(0, 0),
        sideFeet: 7,
        axisAlignedFootprintConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdCubeAreaRules.preview(
        map: map,
        origin: const SrdGridCell(4, 0),
        sideFeet: 10,
        axisAlignedFootprintConfirmed: true,
      ),
      throwsFormatException,
    );
  });
}
