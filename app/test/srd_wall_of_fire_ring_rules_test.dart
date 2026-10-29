import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_wall_of_fire_ring_rules.dart';

const center = SrdGridCell(10, 10);

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

SrdWallOfFireRingPreview _preview({
  SrdSpellGridMap? map,
  SrdGridCell origin = center,
  int diameter = 20,
  int height = 20,
}) => SrdWallOfFireRingRules.preview(
  map: map ?? _map(),
  center: origin,
  outerDiameterFeet: diameter,
  heightFeet: height,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ring retains partial tiles but excludes its empty center', () {
    final ring = _preview();
    expect(ring.outerDiameterFeet, 20);
    expect(ring.heightFeet, 20);
    expect(ring.thicknessFeet, 1);
    expect(ring.at(center), isNull);
    expect(ring.at(const SrdGridCell(12, 10))!.centerWithinWall, isTrue);
    expect(ring.at(const SrdGridCell(11, 11))!.centerWithinWall, isFalse);
    expect(ring.at(const SrdGridCell(13, 10)), isNull);
    expect(ring.at(const SrdGridCell(12, 12)), isNull);
    expect(() => ring.candidates.clear(), throwsUnsupportedError);
    expect(ring.at(const SrdGridCell(-1, 0)), isNull);
  });

  test('small ring clips to map edges without guessing damage', () {
    final ring = _preview(
      map: _map(width: 3, height: 3),
      origin: const SrdGridCell(0, 0),
      diameter: 10,
      height: 5,
    );
    expect(ring.candidates, isNotEmpty);
    expect(ring.at(const SrdGridCell(1, 0)), isNotNull);
    expect(ring.at(const SrdGridCell(0, 0)), isNull);
    expect(ring.heightFeet, 5);
    expect(
      ring.candidates.every(
        (tile) =>
            tile.cell.column >= 0 &&
            tile.cell.row >= 0 &&
            tile.cell.column < 3 &&
            tile.cell.row < 3,
      ),
      isTrue,
    );
  });

  test('blockers remain candidates flagged for separate review', () {
    final blocked = _preview(map: _map(blockers: const [SrdGridCell(12, 10)]));
    final wallTile = blocked.at(const SrdGridCell(12, 10))!;
    expect(wallTile.fullBlockerRequiresReview, isTrue);
    expect(wallTile.centerRay, SrdSphereCenterRay.requiresCoverReview);

    final behind = _preview(map: _map(blockers: const [SrdGridCell(11, 10)]));
    final remoteTile = behind.at(const SrdGridCell(12, 10))!;
    expect(remoteTile.fullBlockerRequiresReview, isFalse);
    expect(remoteTile.centerRay, SrdSphereCenterRay.requiresCoverReview);
    expect(
      behind.at(const SrdGridCell(10, 12))!.centerRay,
      SrdSphereCenterRay.clear,
    );
  });

  test('unconfirmed map and invalid geometry fail closed', () {
    for (final diameter in [0, -5, 4, 7, 25]) {
      expect(() => _preview(diameter: diameter), throwsFormatException);
    }
    for (final height in [0, -5, 4, 7, 25]) {
      expect(() => _preview(height: height), throwsFormatException);
    }
    expect(() => _preview(map: _map(surveyed: false)), throwsFormatException);
    expect(
      () => _preview(map: _map(blockers: const [center])),
      throwsFormatException,
    );
    expect(
      () => _preview(origin: const SrdGridCell(40, 0)),
      throwsFormatException,
    );
  });

  test('Wall of Fire requires an explicitly verified ring', () async {
    final catalog = await SrdSpellCatalogLoader.load();
    final fire = catalog.find('Wall of Fire')!;
    expect(fire.range, '120 feet');

    final request = SrdSpellGridTargetRequest(
      map: _map(),
      caster: const SrdGridCell(0, 10),
      origin: const SrdGridCell(24, 10),
    );
    SrdWallOfFireRingPreview preview({
      bool shape = true,
      bool diameter = true,
      bool surface = true,
      SrdSpellGridTargetRequest? target,
    }) => SrdWallOfFireRingRules.previewConfirmedSpell(
      spell: fire,
      gridTarget: target ?? request,
      ringShapeVerifiedFromEffect: shape,
      outerDiameterConventionConfirmed: diameter,
      solidSurfaceConfirmed: surface,
      verifiedOuterDiameterFeet: 20,
      verifiedHeightFeet: 20,
    );
    final ring = preview();
    expect(ring.center, const SrdGridCell(24, 10));
    expect(ring.at(const SrdGridCell(26, 10)), isNotNull);
    expect(() => preview(shape: false), throwsFormatException);
    expect(() => preview(diameter: false), throwsFormatException);
    expect(() => preview(surface: false), throwsFormatException);
    expect(
      () => preview(
        target: SrdSpellGridTargetRequest(
          map: _map(),
          caster: const SrdGridCell(0, 10),
          origin: const SrdGridCell(25, 10),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => preview(
        target: SrdSpellGridTargetRequest(
          map: _map(blockers: const [SrdGridCell(12, 10)]),
          caster: const SrdGridCell(0, 10),
          origin: const SrdGridCell(24, 10),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => SrdWallOfFireRingRules.previewConfirmedSpell(
        spell: catalog.find('Fireball')!,
        gridTarget: request,
        ringShapeVerifiedFromEffect: true,
        outerDiameterConventionConfirmed: true,
        solidSurfaceConfirmed: true,
        verifiedOuterDiameterFeet: 20,
        verifiedHeightFeet: 20,
      ),
      throwsFormatException,
    );
  });
}
