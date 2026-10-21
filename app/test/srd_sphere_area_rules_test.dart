import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('5-foot sphere candidates include uncertain diagonal corners', () {
    final result = SrdSphereAreaRules.preview(
      map: _map(),
      origin: const SrdGridCell(10, 10),
      radiusFeet: 5,
    );
    expect(result.candidates, hasLength(9));
    expect(result.radiusFeet, 5);
    expect(result.at(const SrdGridCell(10, 10))!.centerWithinRadius, isTrue);
    expect(result.at(const SrdGridCell(11, 10))!.centerWithinRadius, isTrue);
    final diagonal = result.at(const SrdGridCell(11, 11))!;
    expect(diagonal.centerWithinRadius, isFalse);
    expect(diagonal.centerRay, SrdSphereCenterRay.clear);
    expect(result.at(const SrdGridCell(12, 10)), isNull);
    expect(result.at(const SrdGridCell(12, 12)), isNull);
  });

  test('10-foot circle includes partial boundary squares, not fake hits', () {
    final result = SrdSphereAreaRules.preview(
      map: _map(),
      origin: const SrdGridCell(10, 10),
      radiusFeet: 10,
    );
    expect(result.candidates, hasLength(21));
    final partial = result.at(const SrdGridCell(12, 11))!;
    expect(partial.centerWithinRadius, isFalse);
    expect(result.at(const SrdGridCell(12, 12)), isNull);
    expect(result.at(const SrdGridCell(10, 10)), isNotNull);
    expect(
      result.candidates.every(
        (cell) => cell.centerRay == SrdSphereCenterRay.clear,
      ),
      isTrue,
    );
  });

  test('wall creates cover review, not an invented immunity verdict', () {
    final result = SrdSphereAreaRules.preview(
      map: _map(blockers: const [SrdGridCell(11, 10)]),
      origin: const SrdGridCell(10, 10),
      radiusFeet: 15,
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
    // An exact center-line corner touch is conservative, not Total Cover.
    expect(
      result.at(const SrdGridCell(12, 12))!.centerRay,
      SrdSphereCenterRay.requiresCoverReview,
    );
  });

  test('boundaries limit candidates and results cannot be mutated', () {
    final result = SrdSphereAreaRules.preview(
      map: _map(width: 3, height: 3),
      origin: const SrdGridCell(0, 0),
      radiusFeet: 5,
    );
    expect(result.candidates, hasLength(4));
    expect(result.at(const SrdGridCell(0, 0)), isNotNull);
    expect(result.at(const SrdGridCell(-1, 0)), isNull);
    expect(
      () => result.candidates.clear(),
      throwsUnsupportedError,
    );
  });

  test('invalid radius, unknown map and obstructed origin fail closed', () {
    for (final radius in [0, -5, 4, 6, 125]) {
      expect(
        () => SrdSphereAreaRules.preview(
          map: _map(),
          origin: const SrdGridCell(10, 10),
          radiusFeet: radius,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => SrdSphereAreaRules.preview(
        map: _map(surveyed: false),
        origin: const SrdGridCell(10, 10),
        radiusFeet: 10,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSphereAreaRules.preview(
        map: _map(blockers: const [SrdGridCell(10, 10)]),
        origin: const SrdGridCell(10, 10),
        radiusFeet: 10,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSphereAreaRules.preview(
        map: _map(),
        origin: const SrdGridCell(-1, 10),
        radiusFeet: 10,
      ),
      throwsFormatException,
    );
  });

  test('spell range is separate from sphere effect radius', () {
    final spell = catalog.find('Fireball')!;
    expect(spell.range, '150 feet');
    const caster = SrdGridCell(0, 0);
    const effectOrigin = SrdGridCell(29, 0);
    final map = _map();
    final request = SrdSpellGridTargetRequest(
      map: map,
      caster: caster,
      origin: effectOrigin,
    );

    expect(
      () => SrdSphereAreaRules.previewConfirmedSpell(
        spell: spell,
        gridTarget: request,
        sphereShapeVerifiedFromEffect: false,
        verifiedEffectRadiusFeet: 20,
      ),
      throwsFormatException,
    );
    final result = SrdSphereAreaRules.previewConfirmedSpell(
      spell: spell,
      gridTarget: request,
      sphereShapeVerifiedFromEffect: true,
      verifiedEffectRadiusFeet: 20,
    );
    expect(result.origin, effectOrigin);
    expect(result.radiusFeet, 20);
    expect(result.at(effectOrigin), isNotNull);

    expect(
      () => SrdSphereAreaRules.previewConfirmedSpell(
        spell: spell,
        gridTarget: SrdSpellGridTargetRequest(
          map: map,
          caster: caster,
          origin: const SrdGridCell(31, 0),
        ),
        sphereShapeVerifiedFromEffect: true,
        verifiedEffectRadiusFeet: 20,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSphereAreaRules.previewConfirmedSpell(
        spell: spell,
        gridTarget: SrdSpellGridTargetRequest(
          map: _map(blockers: const [SrdGridCell(10, 0)]),
          caster: caster,
          origin: effectOrigin,
        ),
        sphereShapeVerifiedFromEffect: true,
        verifiedEffectRadiusFeet: 20,
      ),
      throwsFormatException,
    );
  });

  test('Self and non-sphere spells do not silently imply area rules', () {
    final nonSphere = catalog.find('Cure Wounds')!;
    expect(
      () => SrdSphereAreaRules.previewConfirmedSpell(
        spell: nonSphere,
        gridTarget: SrdSpellGridTargetRequest(
          map: _map(),
          caster: const SrdGridCell(0, 0),
          origin: const SrdGridCell(10, 10),
        ),
        sphereShapeVerifiedFromEffect: true,
        verifiedEffectRadiusFeet: 10,
      ),
      throwsFormatException,
    );
  });
}
