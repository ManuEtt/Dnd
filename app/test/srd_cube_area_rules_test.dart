import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
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

  test(
    'Thunderwave cube validates Self origin before previewing candidates',
    () async {
      final catalog = await SrdSpellCatalogLoader.load();
      final thunderwave = catalog.find('Thunderwave')!;
      expect(thunderwave.range, 'Self');
      const caster = SrdGridCell(2, 2);
      final grid = SrdSpellGridMap(
        width: 10,
        height: 10,
        fullBlockers: const [],
        fullBlockersSurveyedConfirmed: true,
      );
      final target = SrdSpellGridTargetRequest(
        map: grid,
        caster: caster,
        origin: caster,
      );
      final preview = SrdCubeAreaRules.previewConfirmedSpell(
        spell: thunderwave,
        gridTarget: target,
        cubeShapeVerifiedFromEffect: true,
        verifiedEffectSideFeet: 15,
        axisAlignedFootprintConfirmed: true,
      );
      expect(preview.origin, caster);
      expect(preview.sideFeet, 15);
      expect(preview.candidates, hasLength(9));
      expect(
        preview.candidates.any(
          (entry) => entry.cell == const SrdGridCell(4, 4),
        ),
        isTrue,
      );
      expect(() => preview.candidates.removeLast(), throwsUnsupportedError);
    },
  );

  test(
    'cube spell preflight rejects unverified shape, footprint and origin',
    () async {
      final catalog = await SrdSpellCatalogLoader.load();
      final thunderwave = catalog.find('Thunderwave')!;
      const caster = SrdGridCell(2, 2);
      final grid = SrdSpellGridMap(
        width: 8,
        height: 8,
        fullBlockers: const [],
        fullBlockersSurveyedConfirmed: true,
      );
      SrdSpellGridTargetRequest target(
        SrdSpellGridMap map, {
        SrdGridCell? origin,
      }) {
        return SrdSpellGridTargetRequest(
          map: map,
          caster: caster,
          origin: origin ?? caster,
        );
      }

      SrdCubeAreaPreview preview(
        SrdSpellGridTargetRequest request, {
        bool shape = true,
        bool footprint = true,
        int side = 15,
      }) {
        return SrdCubeAreaRules.previewConfirmedSpell(
          spell: thunderwave,
          gridTarget: request,
          cubeShapeVerifiedFromEffect: shape,
          verifiedEffectSideFeet: side,
          axisAlignedFootprintConfirmed: footprint,
        );
      }

      expect(() => preview(target(grid), shape: false), throwsFormatException);
      expect(
        () => preview(target(grid), footprint: false),
        throwsFormatException,
      );
      expect(() => preview(target(grid), side: 14), throwsFormatException);
      expect(
        () => preview(target(grid, origin: const SrdGridCell(3, 2))),
        throwsFormatException,
        reason: 'Self cannot originate from another square',
      );
      expect(
        () => preview(
          target(
            SrdSpellGridMap(
              width: 8,
              height: 8,
              fullBlockers: const [],
              fullBlockersSurveyedConfirmed: false,
            ),
          ),
        ),
        throwsFormatException,
        reason: 'Unsurveyed terrain must not be assumed clear',
      );
      expect(
        () => preview(
          target(
            SrdSpellGridMap(
              width: 8,
              height: 8,
              fullBlockers: const [caster],
              fullBlockersSurveyedConfirmed: true,
            ),
          ),
        ),
        throwsFormatException,
        reason: 'The caster may not occupy a confirmed full blocker',
      );
      expect(
        () => preview(target(grid, origin: const SrdGridCell(9, 9))),
        throwsFormatException,
        reason: 'Off-grid spell origins fail closed',
      );
    },
  );
}
