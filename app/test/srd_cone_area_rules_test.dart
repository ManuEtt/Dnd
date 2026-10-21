import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_cone_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const _origin = SrdGridCell(15, 15);

SrdSpellGridMap _map({
  int width = 40,
  int height = 40,
  bool confirmed = true,
  Iterable<SrdGridCell> blockers = const [],
}) => SrdSpellGridMap(
  width: width,
  height: height,
  fullBlockers: blockers,
  fullBlockersSurveyedConfirmed: confirmed,
);

SrdConeAreaPreview _east(
  SrdSpellGridMap map, {
  int length = 15,
  bool originIncluded = false,
}) => SrdConeAreaRules.preview(
  map: map,
  origin: _origin,
  lengthFeet: length,
  direction: SrdConeDirection.east,
  includeOriginPointConfirmed: originIncluded,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('cone width grows with distance, center stays out unless requested', () {
    final cone = _east(_map());
    expect(cone.lengthFeet, 15);
    expect(cone.direction, SrdConeDirection.east);
    expect(cone.at(_origin), isNotNull);
    expect(cone.at(_origin)!.originCellRequiresReview, isTrue);
    expect(cone.at(_origin)!.centerWithinCone, isFalse);
    expect(
      _east(_map(), originIncluded: true).at(_origin)!.centerWithinCone,
      isTrue,
    );
    expect(cone.at(const SrdGridCell(16, 15))!.centerWithinCone, isTrue);
    expect(cone.at(const SrdGridCell(17, 16))!.centerWithinCone, isTrue);
    expect(cone.at(const SrdGridCell(18, 16))!.centerWithinCone, isTrue);
    expect(cone.at(const SrdGridCell(18, 17))!.centerWithinCone, isFalse);
    expect(cone.at(const SrdGridCell(19, 15)), isNotNull);
    expect(cone.at(const SrdGridCell(19, 15))!.centerWithinCone, isFalse);
    expect(cone.at(const SrdGridCell(15, 20)), isNull);
    expect(cone.at(const SrdGridCell(13, 15)), isNull);
    expect(cone.at(const SrdGridCell(20, 15)), isNull);
  });

  test('nearby marginal and corner squares are only possible candidates', () {
    final cone = _east(_map(), length: 10);
    final edge = cone.at(const SrdGridCell(17, 16));
    expect(edge, isNotNull);
    expect(edge!.centerWithinCone, isTrue);
    final margin = cone.at(const SrdGridCell(16, 16));
    expect(margin, isNotNull);
    expect(margin!.centerWithinCone, isFalse);
    expect(cone.at(const SrdGridCell(13, 15)), isNull);
    expect(
      cone.candidates.map((c) => c.cell).toSet().length,
      cone.candidates.length,
    );
  });

  test('west, north and diagonal directions are not secretly east', () {
    final map = _map();
    final west = SrdConeAreaRules.preview(
      map: map,
      origin: _origin,
      lengthFeet: 15,
      direction: SrdConeDirection.west,
    );
    expect(west.at(const SrdGridCell(13, 15))!.centerWithinCone, isTrue);
    expect(west.at(const SrdGridCell(17, 15)), isNull);

    final north = SrdConeAreaRules.preview(
      map: map,
      origin: _origin,
      lengthFeet: 15,
      direction: SrdConeDirection.north,
    );
    expect(north.at(const SrdGridCell(15, 13))!.centerWithinCone, isTrue);
    expect(north.at(const SrdGridCell(15, 17)), isNull);

    final northEast = SrdConeAreaRules.preview(
      map: map,
      origin: _origin,
      lengthFeet: 15,
      direction: SrdConeDirection.northEast,
    );
    expect(
      northEast.at(const SrdGridCell(17, 13))!.centerWithinCone,
      isTrue,
    );
    expect(northEast.at(const SrdGridCell(13, 17)), isNull);
    expect(northEast.at(const SrdGridCell(18, 12)), isNotNull);
  });

  test('known obstacles require cover review but never establish immunity', () {
    final map = _map(blockers: const [SrdGridCell(16, 15)]);
    final result = _east(map, length: 20);
    expect(result.at(const SrdGridCell(16, 15)), isNull);
    expect(
      result.at(const SrdGridCell(18, 15))!.centerRay,
      SrdSphereCenterRay.requiresCoverReview,
    );
    expect(
      result.at(const SrdGridCell(16, 16))!.centerRay,
      SrdSphereCenterRay.requiresCoverReview,
    );
    expect(
      result.at(const SrdGridCell(17, 14))!.centerRay,
      SrdSphereCenterRay.clear,
    );
  });

  test('unconfirmed map, blocking origin and invalid length fail closed', () {
    expect(
      () => _east(_map(confirmed: false)),
      throwsFormatException,
    );
    expect(
      () => _east(_map(blockers: const [_origin])),
      throwsFormatException,
    );
    for (final length in [-5, 0, 4, 6, 125]) {
      expect(
        () => _east(_map(), length: length),
        throwsFormatException,
      );
    }
    expect(
      () => SrdConeAreaRules.preview(
        map: _map(width: 10),
        origin: _origin,
        lengthFeet: 15,
        direction: SrdConeDirection.east,
      ),
      throwsFormatException,
    );
  });

  test('boundary clips candidates and output is immutable', () {
    final cone = SrdConeAreaRules.preview(
      map: _map(width: 3, height: 3),
      origin: const SrdGridCell(0, 0),
      lengthFeet: 15,
      direction: SrdConeDirection.southEast,
    );
    expect(cone.candidates, isNotEmpty);
    expect(
      cone.candidates.every(
        (c) => c.cell.column >= 0 && c.cell.row >= 0 &&
            c.cell.column < 3 && c.cell.row < 3,
      ),
      isTrue,
    );
    expect(
      () => cone.candidates.clear(),
      throwsUnsupportedError,
    );
    expect(cone.at(const SrdGridCell(-1, -1)), isNull);
  });

  test('catalogue spell range differs from effect cone length', () {
    final burningHands = catalog.find('Burning Hands')!;
    expect(burningHands.range, 'Self');
    const caster = SrdGridCell(15, 15);
    final request = SrdSpellGridTargetRequest(
      map: _map(),
      caster: caster,
      origin: caster,
    );

    final approved = SrdConeAreaRules.previewConfirmedSpell(
      spell: burningHands,
      gridTarget: request,
      coneShapeVerifiedFromEffect: true,
      verifiedEffectLengthFeet: 15,
      direction: SrdConeDirection.south,
    );
    expect(approved.lengthFeet, 15);
    expect(approved.at(const SrdGridCell(15, 17)), isNotNull);

    expect(
      () => SrdConeAreaRules.previewConfirmedSpell(
        spell: burningHands,
        gridTarget: request,
        coneShapeVerifiedFromEffect: false,
        verifiedEffectLengthFeet: 15,
        direction: SrdConeDirection.south,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdConeAreaRules.previewConfirmedSpell(
        spell: burningHands,
        gridTarget: SrdSpellGridTargetRequest(
          map: _map(),
          caster: caster,
          origin: const SrdGridCell(16, 15),
        ),
        coneShapeVerifiedFromEffect: true,
        verifiedEffectLengthFeet: 15,
        direction: SrdConeDirection.south,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdConeAreaRules.previewConfirmedSpell(
        spell: burningHands,
        gridTarget: SrdSpellGridTargetRequest(
          map: _map(confirmed: false),
          caster: caster,
          origin: caster,
        ),
        coneShapeVerifiedFromEffect: true,
        verifiedEffectLengthFeet: 15,
        direction: SrdConeDirection.south,
      ),
      throwsFormatException,
    );
  });

  test('spell without independently verified cone metadata cannot infer one', () {
    final fireball = catalog.find('Fireball')!;
    final request = SrdSpellGridTargetRequest(
      map: _map(),
      caster: const SrdGridCell(0, 0),
      origin: const SrdGridCell(15, 15),
    );
    expect(
      () => SrdConeAreaRules.previewConfirmedSpell(
        spell: fireball,
        gridTarget: request,
        coneShapeVerifiedFromEffect: false,
        verifiedEffectLengthFeet: 15,
        direction: SrdConeDirection.east,
      ),
      throwsFormatException,
    );
  });
}
