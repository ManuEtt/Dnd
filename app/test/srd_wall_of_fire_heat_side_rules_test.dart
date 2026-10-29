import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_wall_of_fire_heat_side_rules.dart';

SrdWallOfFireHeatSideRequest _facts(
  SrdSpellDefinition spell, {
  SrdWallOfFireTopology topology = SrdWallOfFireTopology.straight,
  SrdWallOfFireHotSide hotSide = SrdWallOfFireHotSide.straightLeft,
  SrdWallOfFireTargetRegion region =
      SrdWallOfFireTargetRegion.straightLeft,
  SrdWallOfFireHeatTrigger trigger = SrdWallOfFireHeatTrigger.endTurn,
  double distance = 10,
  bool hotSideConfirmed = true,
  bool regionConfirmed = true,
  bool distanceConfirmed = true,
  bool wallActiveConfirmed = true,
  bool firstEntryConfirmed = false,
}) => SrdWallOfFireHeatSideRequest(
  spell: spell,
  topology: topology,
  selectedHotSide: hotSide,
  hotSideSelectedAtCastConfirmed: hotSideConfirmed,
  targetRegion: region,
  targetRegionConfirmed: regionConfirmed,
  distanceToWallFaceFeet: distance,
  distanceConfirmed: distanceConfirmed,
  wallStillActiveConfirmed: wallActiveConfirmed,
  trigger: trigger,
  firstWallEntryOnTurnConfirmed: firstEntryConfirmed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  late SrdSpellDefinition fire;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
    fire = catalog.find('Wall of Fire')!;
  });

  test('end-turn band includes exactly ten feet, not beyond', () {
    final atEdge = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(fire),
    );
    expect(atEdge.insideWall, isFalse);
    expect(atEdge.withinTenFeetOfHotSide, isTrue);
    expect(atEdge.requiresDamageReview, isTrue);

    final beyond = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(fire, distance: 10.01),
    );
    expect(beyond.withinTenFeetOfHotSide, isFalse);
    expect(beyond.requiresDamageReview, isFalse);
  });

  test('cold side never inherits the hot-side band', () {
    final cold = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(
        fire,
        region: SrdWallOfFireTargetRegion.straightRight,
        distance: 0,
      ),
    );
    expect(cold.insideWall, isFalse);
    expect(cold.withinTenFeetOfHotSide, isFalse);
    expect(cold.requiresDamageReview, isFalse);

    final rightHot = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(
        fire,
        hotSide: SrdWallOfFireHotSide.straightRight,
        region: SrdWallOfFireTargetRegion.straightRight,
        distance: 5,
      ),
    );
    expect(rightHot.requiresDamageReview, isTrue);
  });

  test('ring requires inside or outside selection at cast', () {
    final interior = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(
        fire,
        topology: SrdWallOfFireTopology.ring,
        hotSide: SrdWallOfFireHotSide.ringInside,
        region: SrdWallOfFireTargetRegion.ringInside,
        distance: 9,
      ),
    );
    expect(interior.requiresDamageReview, isTrue);
    final exteriorCold = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(
        fire,
        topology: SrdWallOfFireTopology.ring,
        hotSide: SrdWallOfFireHotSide.ringInside,
        region: SrdWallOfFireTargetRegion.ringOutside,
        distance: 0,
      ),
    );
    expect(exteriorCold.requiresDamageReview, isFalse);
  });

  test('wall entry and wall end-turn are separate review triggers', () {
    final endTurn = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(fire, region: SrdWallOfFireTargetRegion.onWall, distance: 0),
    );
    expect(endTurn.insideWall, isTrue);
    expect(endTurn.withinTenFeetOfHotSide, isFalse);
    expect(endTurn.requiresDamageReview, isTrue);

    final entry = SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      _facts(
        fire,
        region: SrdWallOfFireTargetRegion.onWall,
        distance: 0,
        trigger: SrdWallOfFireHeatTrigger.firstWallEntryOnTurn,
        firstEntryConfirmed: true,
      ),
    );
    expect(entry.trigger, SrdWallOfFireHeatTrigger.firstWallEntryOnTurn);
    expect(entry.requiresDamageReview, isTrue);
    expect(
      () => SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
        _facts(
          fire,
          region: SrdWallOfFireTargetRegion.onWall,
          distance: 0,
          trigger: SrdWallOfFireHeatTrigger.firstWallEntryOnTurn,
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
        _facts(
          fire,
          trigger: SrdWallOfFireHeatTrigger.firstWallEntryOnTurn,
          firstEntryConfirmed: true,
        ),
      ),
      throwsFormatException,
    );
  });

  test('unknown facts and impossible distance fail closed', () {
    for (final distance in [-1.0, double.nan, double.infinity]) {
      expect(
        () => SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
          _facts(fire, distance: distance),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
        _facts(
          fire,
          region: SrdWallOfFireTargetRegion.onWall,
          distance: 1,
        ),
      ),
      throwsFormatException,
    );
    for (final request in [
      _facts(fire, hotSideConfirmed: false),
      _facts(fire, regionConfirmed: false),
      _facts(fire, distanceConfirmed: false),
      _facts(fire, wallActiveConfirmed: false),
    ]) {
      expect(
        () => SrdWallOfFireHeatSideRules.previewConfirmedTrigger(request),
        throwsFormatException,
      );
    }
  });

  test('wall shape and spell identity cannot be exchanged', () {
    for (final request in [
      _facts(
        fire,
        topology: SrdWallOfFireTopology.ring,
      ),
      _facts(
        fire,
        topology: SrdWallOfFireTopology.ring,
        hotSide: SrdWallOfFireHotSide.ringInside,
      ),
      _facts(
        fire,
        hotSide: SrdWallOfFireHotSide.ringOutside,
      ),
      _facts(catalog.find('Fireball')!),
    ]) {
      expect(
        () => SrdWallOfFireHeatSideRules.previewConfirmedTrigger(request),
        throwsFormatException,
      );
    }
  });
}
