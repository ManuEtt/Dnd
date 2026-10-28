import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_cylinder_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const origin = SrdGridCell(10, 10);

SrdSpellGridMap _map({
  int width = 40,
  int height = 40,
  bool surveyed = true,
  Iterable<SrdGridCell> blockers = const [],
}) => SrdSpellGridMap(
  width: width,
  height: height,
  fullBlockers: blockers,
  fullBlockersSurveyedConfirmed: surveyed,
);

SrdCylinderAreaPreview _preview({
  SrdSpellGridMap? grid,
  SrdGridCell center = origin,
  int radius = 10,
  int height = 40,
  SrdCylinderOriginFace face = SrdCylinderOriginFace.bottom,
}) => SrdCylinderAreaRules.preview(
  map: grid ?? _map(),
  origin: center,
  radiusFeet: radius,
  heightFeet: height,
  originFace: face,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'confirmed circular base includes partial border, not automatic hits',
    () {
      final result = _preview();
      expect(result.radiusFeet, 10);
      expect(result.heightFeet, 40);
      expect(result.candidates, hasLength(21));
      expect(result.at(origin)!.centerWithinBase, isTrue);
      expect(result.at(const SrdGridCell(12, 11))!.centerWithinBase, isFalse);
      expect(result.at(const SrdGridCell(12, 12)), isNull);
      expect(
        result.at(const SrdGridCell(11, 10))!.centerRay,
        SrdSphereCenterRay.clear,
      );
      expect(() => result.candidates.clear(), throwsUnsupportedError);
    },
  );

  test('top and bottom originate opposite vertical spans without altitude', () {
    final bottom = _preview();
    final top = _preview(face: SrdCylinderOriginFace.top);
    expect(bottom.minVerticalOffsetFeet, 0);
    expect(bottom.maxVerticalOffsetFeet, 40);
    expect(top.minVerticalOffsetFeet, -40);
    expect(top.maxVerticalOffsetFeet, 0);
    expect(
      top.candidates.map((item) => item.cell).toSet(),
      bottom.candidates.map((item) => item.cell).toSet(),
    );
    expect(_preview(radius: 5, height: 5).candidates, hasLength(9));
  });

  test('full blockers cause review, not fabricated total-cover immunity', () {
    final result = _preview(
      grid: _map(blockers: const [SrdGridCell(11, 10)]),
      radius: 15,
    );
    expect(result.at(const SrdGridCell(11, 10)), isNull);
    expect(
      result.at(const SrdGridCell(12, 10))!.centerRay,
      SrdSphereCenterRay.requiresCoverReview,
    );
    expect(
      result.at(const SrdGridCell(10, 12))!.centerRay,
      SrdSphereCenterRay.clear,
    );
  });

  test('invalid dimensions, uncertain map and invalid origin fail closed', () {
    for (final height in [-5, 0, 4, 7, 305]) {
      expect(() => _preview(height: height), throwsFormatException);
    }
    for (final radius in [-5, 0, 4, 7, 125]) {
      expect(() => _preview(radius: radius), throwsFormatException);
    }
    expect(() => _preview(grid: _map(surveyed: false)), throwsFormatException);
    expect(
      () => _preview(grid: _map(blockers: const [origin])),
      throwsFormatException,
    );
    expect(
      () => _preview(center: const SrdGridCell(-1, 10)),
      throwsFormatException,
    );
    expect(
      () => _preview(center: const SrdGridCell(40, 10)),
      throwsFormatException,
    );
  });

  test('Flame Strike checks its 60-foot casting range separately', () async {
    final catalog = await SrdSpellCatalogLoader.load();
    final spell = catalog.find('Flame Strike')!;
    expect(spell.range, '60 feet');
    final request = SrdSpellGridTargetRequest(
      map: _map(),
      caster: const SrdGridCell(0, 10),
      origin: const SrdGridCell(12, 10),
    );
    SrdCylinderAreaPreview valid() =>
        SrdCylinderAreaRules.previewConfirmedSpell(
          spell: spell,
          gridTarget: request,
          cylinderShapeVerifiedFromEffect: true,
          verifiedEffectRadiusFeet: 10,
          verifiedEffectHeightFeet: 40,
          originFace: SrdCylinderOriginFace.top,
        );
    final result = valid();
    expect(result.origin, const SrdGridCell(12, 10));
    expect(result.minVerticalOffsetFeet, -40);
    expect(result.maxVerticalOffsetFeet, 0);
    expect(result.at(const SrdGridCell(12, 10)), isNotNull);

    expect(
      () => SrdCylinderAreaRules.previewConfirmedSpell(
        spell: spell,
        gridTarget: request,
        cylinderShapeVerifiedFromEffect: false,
        verifiedEffectRadiusFeet: 10,
        verifiedEffectHeightFeet: 40,
        originFace: SrdCylinderOriginFace.top,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdCylinderAreaRules.previewConfirmedSpell(
        spell: spell,
        gridTarget: SrdSpellGridTargetRequest(
          map: _map(),
          caster: const SrdGridCell(0, 10),
          origin: const SrdGridCell(13, 10),
        ),
        cylinderShapeVerifiedFromEffect: true,
        verifiedEffectRadiusFeet: 10,
        verifiedEffectHeightFeet: 40,
        originFace: SrdCylinderOriginFace.bottom,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdCylinderAreaRules.previewConfirmedSpell(
        spell: spell,
        gridTarget: SrdSpellGridTargetRequest(
          map: _map(blockers: const [SrdGridCell(6, 10)]),
          caster: const SrdGridCell(0, 10),
          origin: const SrdGridCell(12, 10),
        ),
        cylinderShapeVerifiedFromEffect: true,
        verifiedEffectRadiusFeet: 10,
        verifiedEffectHeightFeet: 40,
        originFace: SrdCylinderOriginFace.bottom,
      ),
      throwsFormatException,
    );
  });
}
