import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_line_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const origin = SrdGridCell(10, 10);

SrdSpellGridMap map({
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

SrdLineAreaPreview east(
  SrdSpellGridMap grid, {
  int length = 15,
  int width = 5,
  bool includeOrigin = false,
}) => SrdLineAreaRules.preview(
  map: grid,
  origin: origin,
  lengthFeet: length,
  widthFeet: width,
  direction: SrdLineDirection.east,
  includeOriginPointConfirmed: includeOrigin,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('length and width distinguish center and marginal candidates', () {
    final line = east(map());
    expect(line.lengthFeet, 15);
    expect(line.widthFeet, 5);
    expect(line.at(origin)!.originCellRequiresReview, isTrue);
    expect(line.at(origin)!.centerWithinLine, isFalse);
    expect(east(map(), includeOrigin: true).at(origin)!.centerWithinLine, isTrue);
    expect(line.at(const SrdGridCell(13, 10))!.centerWithinLine, isTrue);
    expect(line.at(const SrdGridCell(11, 9))!.centerWithinLine, isFalse);
    expect(line.at(const SrdGridCell(14, 10)), isNull);
    expect(line.at(const SrdGridCell(9, 10)), isNull);

    final wider = east(map(), width: 15);
    expect(line.at(const SrdGridCell(12, 11))!.centerWithinLine, isFalse);
    expect(wider.at(const SrdGridCell(12, 11))!.centerWithinLine, isTrue);
    expect(wider.at(const SrdGridCell(12, 12))!.centerWithinLine, isFalse);
    expect(wider.at(const SrdGridCell(12, 13)), isNull);
    expect(wider.candidates.length, greaterThan(line.candidates.length));
  });

  test('opposite and diagonal directions do not face east', () {
    SrdLineAreaPreview line(SrdLineDirection direction) =>
        SrdLineAreaRules.preview(
          map: map(),
          origin: origin,
          lengthFeet: 15,
          widthFeet: 5,
          direction: direction,
        );
    final north = line(SrdLineDirection.north);
    expect(north.at(const SrdGridCell(10, 8))!.centerWithinLine, isTrue);
    expect(north.at(const SrdGridCell(10, 12)), isNull);
    final west = line(SrdLineDirection.west);
    expect(west.at(const SrdGridCell(8, 10))!.centerWithinLine, isTrue);
    expect(west.at(const SrdGridCell(12, 10)), isNull);
    final southeast = line(SrdLineDirection.southEast);
    expect(southeast.at(const SrdGridCell(12, 12))!.centerWithinLine, isTrue);
    expect(southeast.at(const SrdGridCell(12, 8)), isNull);
    expect(
      southeast.candidates.map((item) => item.cell).toSet().length,
      southeast.candidates.length,
    );
  });

  test('blocked center ray requests cover review, never immunity', () {
    final line = east(
      map(blockers: const [SrdGridCell(11, 10)]),
      length: 25,
    );
    expect(line.at(const SrdGridCell(11, 10)), isNull);
    expect(
      line.at(const SrdGridCell(12, 10))!.centerRay,
      SrdSphereCenterRay.requiresCoverReview,
    );
    expect(
      line.at(const SrdGridCell(10, 11))!.centerRay,
      SrdSphereCenterRay.clear,
    );
    expect(line.at(const SrdGridCell(12, 10))!.centerWithinLine, isTrue);
  });

  test('unknown map and invalid measurements fail closed', () {
    expect(() => east(map(confirmed: false)), throwsFormatException);
    expect(() => east(map(blockers: const [origin])), throwsFormatException);
    for (final length in [-5, 0, 4, 6, 305]) {
      expect(() => east(map(), length: length), throwsFormatException);
    }
    for (final width in [-5, 0, 4, 6, 65]) {
      expect(() => east(map(), width: width), throwsFormatException);
    }
    expect(() => east(map(width: 2)), throwsFormatException);
  });

  test('clip to map edges; candidate collection immutable', () {
    final line = SrdLineAreaRules.preview(
      map: map(width: 3, height: 3),
      origin: const SrdGridCell(0, 0),
      lengthFeet: 15,
      widthFeet: 10,
      direction: SrdLineDirection.southEast,
    );
    expect(line.candidates, isNotEmpty);
    expect(
      line.candidates.every(
        (item) =>
            item.cell.column >= 0 &&
            item.cell.row >= 0 &&
            item.cell.column < 3 &&
            item.cell.row < 3,
      ),
      isTrue,
    );
    expect(() => line.candidates.clear(), throwsUnsupportedError);
    expect(line.at(const SrdGridCell(-1, 0)), isNull);
  });

  test('Lightning Bolt checks Self origin separately from verified line size', () async {
    final catalog = await SrdSpellCatalogLoader.load();
    final bolt = catalog.find('Lightning Bolt')!;
    expect(bolt.range, 'Self');
    final request = SrdSpellGridTargetRequest(
      map: map(),
      caster: origin,
      origin: origin,
    );
    final line = SrdLineAreaRules.previewConfirmedSpell(
      spell: bolt,
      gridTarget: request,
      lineShapeVerifiedFromEffect: true,
      verifiedEffectLengthFeet: 100,
      verifiedEffectWidthFeet: 5,
      direction: SrdLineDirection.east,
    );
    expect(line.lengthFeet, 100);
    expect(line.widthFeet, 5);
    expect(line.at(const SrdGridCell(29, 10))!.centerWithinLine, isTrue);
    expect(
      () => SrdLineAreaRules.previewConfirmedSpell(
        spell: bolt,
        gridTarget: request,
        lineShapeVerifiedFromEffect: false,
        verifiedEffectLengthFeet: 100,
        verifiedEffectWidthFeet: 5,
        direction: SrdLineDirection.east,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdLineAreaRules.previewConfirmedSpell(
        spell: bolt,
        gridTarget: SrdSpellGridTargetRequest(
          map: map(),
          caster: origin,
          origin: const SrdGridCell(11, 10),
        ),
        lineShapeVerifiedFromEffect: true,
        verifiedEffectLengthFeet: 100,
        verifiedEffectWidthFeet: 5,
        direction: SrdLineDirection.east,
      ),
      throwsFormatException,
    );
  });
}
