import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_emanation_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sphere_area_rules.dart';

const source = SrdGridCell(10, 10);

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

SrdEmanationAreaPreview _preview({
  SrdSpellGridMap? map,
  SrdGridCell origin = source,
  int distance = 15,
  SrdEmanationSourceKind kind = SrdEmanationSourceKind.creature,
  SrdEmanationMotion motion = SrdEmanationMotion.followsSource,
  bool confirmed = true,
  bool includeSource = false,
}) => SrdEmanationAreaRules.preview(
  map: map ?? _map(),
  origin: origin,
  distanceFeet: distance,
  sourceKind: kind,
  motion: motion,
  sourceCenterAndSingleCellConfirmed: confirmed,
  includeSourceByChoice: includeSource,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('15-foot Emanation previews marginal squares without hits', () {
    final result = _preview();
    expect(result.distanceFeet, 15);
    expect(result.sourceKind, SrdEmanationSourceKind.creature);
    expect(result.at(source)!.originSquareRequiresReview, isTrue);
    expect(result.at(source)!.centerWithinDistance, isTrue);
    expect(result.at(const SrdGridCell(13, 11)), isNotNull);
    expect(
      result.at(const SrdGridCell(13, 11))!.centerWithinDistance,
      isFalse,
    );
    expect(result.at(const SrdGridCell(14, 10)), isNull);
    expect(result.at(const SrdGridCell(10, 12))!.centerRay, SrdSphereCenterRay.clear);
    expect(() => result.candidates.clear(), throwsUnsupportedError);
  });

  test('source exclusion is independent from occupied origin square', () {
    final defaultPreview = _preview();
    final included = _preview(includeSource: true);
    expect(defaultPreview.includeSourceByChoice, isFalse);
    expect(included.includeSourceByChoice, isTrue);
    expect(defaultPreview.at(source), isNotNull);
    expect(included.at(source), isNotNull);
    expect(
      defaultPreview.candidates.map((item) => item.cell).toSet(),
      included.candidates.map((item) => item.cell).toSet(),
    );
    expect(defaultPreview.needsRepreviewAfterMovement, isTrue);
  });

  test('source motion and origin kind remain explicit metadata', () {
    final stationary = _preview(
      kind: SrdEmanationSourceKind.object,
      motion: SrdEmanationMotion.stationary,
    );
    final instant = _preview(motion: SrdEmanationMotion.instantaneous);
    expect(stationary.sourceKind, SrdEmanationSourceKind.object);
    expect(stationary.needsRepreviewAfterMovement, isFalse);
    expect(instant.needsRepreviewAfterMovement, isFalse);

    final shifted = _preview(origin: const SrdGridCell(11, 10));
    expect(shifted.at(const SrdGridCell(11, 10))!.originSquareRequiresReview, isTrue);
    expect(shifted.origin, const SrdGridCell(11, 10));
    expect(defaultEmanation().origin, source);
  });

  test('obstacle evidence stays a cover review, never an immunity', () {
    final result = _preview(
      map: _map(blockers: const [SrdGridCell(11, 10)]),
    );
    expect(result.at(const SrdGridCell(11, 10)), isNull);
    expect(
      result.at(const SrdGridCell(12, 10))!.centerRay,
      SrdSphereCenterRay.requiresCoverReview,
    );
    expect(result.at(const SrdGridCell(10, 12))!.centerRay, SrdSphereCenterRay.clear);
  });

  test('unverified origin, map and unsupported extents fail closed', () {
    expect(() => _preview(confirmed: false), throwsFormatException);
    expect(() => _preview(map: _map(surveyed: false)), throwsFormatException);
    expect(
      () => _preview(map: _map(blockers: const [source])),
      throwsFormatException,
    );
    expect(() => _preview(origin: const SrdGridCell(-1, 0)), throwsFormatException);
    expect(() => _preview(origin: const SrdGridCell(40, 10)), throwsFormatException);
    for (final invalid in [-5, 0, 4, 7, 125]) {
      expect(() => _preview(distance: invalid), throwsFormatException);
    }
    final edge = _preview(
      map: _map(width: 3, height: 3),
      origin: const SrdGridCell(0, 0),
      distance: 5,
    );
    expect(edge.candidates, hasLength(4));
  });

  test('Spirit Guardians requires Self origin and effect confirmation', () async {
    final catalog = await SrdSpellCatalogLoader.load();
    final spell = catalog.find('Spirit Guardians')!;
    expect(spell.range, 'Self');
    final request = SrdSpellGridTargetRequest(
      map: _map(),
      caster: source,
      origin: source,
    );
    SrdEmanationAreaPreview preflight({
      SrdSpellGridTargetRequest? target,
      bool verified = true,
      int distance = 15,
    }) => SrdEmanationAreaRules.previewConfirmedSpell(
      spell: spell,
      gridTarget: target ?? request,
      emanationShapeVerifiedFromEffect: verified,
      verifiedEffectDistanceFeet: distance,
      sourceKind: SrdEmanationSourceKind.creature,
      motion: SrdEmanationMotion.followsSource,
      sourceCenterAndSingleCellConfirmed: true,
    );

    final result = preflight();
    expect(result.origin, source);
    expect(result.distanceFeet, 15);
    expect(result.includeSourceByChoice, isFalse);
    expect(() => preflight(verified: false), throwsFormatException);
    expect(() => preflight(distance: 14), throwsFormatException);
    expect(
      () => preflight(
        target: SrdSpellGridTargetRequest(
          map: _map(),
          caster: source,
          origin: const SrdGridCell(11, 10),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => preflight(
        target: SrdSpellGridTargetRequest(
          map: _map(blockers: const [source]),
          caster: source,
          origin: source,
        ),
      ),
      throwsFormatException,
    );
  });
}

SrdEmanationAreaPreview defaultEmanation() => _preview();
