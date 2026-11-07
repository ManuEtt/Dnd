import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_wall_of_fire_catalog_identity.dart';
import 'package:lebendiger_spielleiter/domain/srd_wall_of_fire_heat_side_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_wall_of_fire_ring_rules.dart';

SrdSpellDefinition _copy(
  SrdSpellDefinition source, {
  String? id,
  String? name,
  int? level,
  String? school,
  List<String>? classes,
  String? castingTime,
  String? range,
  String? components,
  String? duration,
  bool? verbal,
  bool? somatic,
  bool? material,
  bool? concentration,
  bool? ritual,
}) => SrdSpellDefinition(
  id: id ?? source.id,
  name: name ?? source.name,
  level: level ?? source.level,
  school: school ?? source.school,
  classes: classes ?? source.classes,
  castingTime: castingTime ?? source.castingTime,
  range: range ?? source.range,
  components: components ?? source.components,
  duration: duration ?? source.duration,
  verbal: verbal ?? source.verbal,
  somatic: somatic ?? source.somatic,
  material: material ?? source.material,
  concentration: concentration ?? source.concentration,
  ritual: ritual ?? source.ritual,
);

SrdWallOfFireHeatSideAssessment _heat(SrdSpellDefinition spell) =>
    SrdWallOfFireHeatSideRules.previewConfirmedTrigger(
      SrdWallOfFireHeatSideRequest(
        spell: spell,
        topology: SrdWallOfFireTopology.straight,
        selectedHotSide: SrdWallOfFireHotSide.straightLeft,
        hotSideSelectedAtCastConfirmed: true,
        targetRegion: SrdWallOfFireTargetRegion.straightLeft,
        targetRegionConfirmed: true,
        distanceToWallFaceFeet: 10,
        distanceConfirmed: true,
        wallStillActiveConfirmed: true,
        trigger: SrdWallOfFireHeatTrigger.endTurn,
      ),
    );

SrdWallOfFireRingPreview _ring(SrdSpellDefinition spell) =>
    SrdWallOfFireRingRules.previewConfirmedSpell(
      spell: spell,
      gridTarget: SrdSpellGridTargetRequest(
        map: SrdSpellGridMap(
          width: 40,
          height: 40,
          fullBlockers: const [],
          fullBlockersSurveyedConfirmed: true,
        ),
        caster: const SrdGridCell(0, 10),
        origin: const SrdGridCell(24, 10),
      ),
      ringShapeVerifiedFromEffect: true,
      outerDiameterConventionConfirmed: true,
      solidSurfaceConfirmed: true,
      verifiedOuterDiameterFeet: 20,
      verifiedHeightFeet: 20,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellDefinition fire;

  setUpAll(() async {
    final catalog = await SrdSpellCatalogLoader.load();
    fire = catalog.find('Wall of Fire')!;
  });

  test('unaltered SRD catalogue entry works for both previews', () {
    expect(() => SrdWallOfFireCatalogIdentity.validate(fire), returnsNormally);
    expect(_heat(fire).requiresDamageReview, isTrue);
    expect(_ring(fire).outerDiameterFeet, 20);
  });

  test('every altered metadata field is rejected by both previews', () {
    final variants = <String, SrdSpellDefinition>{
      'id': _copy(fire, id: 'spell-wall-of-force'),
      'name': _copy(fire, name: 'Wall of Force'),
      'level': _copy(fire, level: 5),
      'school': _copy(fire, school: 'Abjuration'),
      'classes missing': _copy(fire, classes: ['Druid', 'Wizard']),
      'classes reordered': _copy(
        fire,
        classes: ['Wizard', 'Sorcerer', 'Druid'],
      ),
      'classes duplicated': _copy(
        fire,
        classes: ['Druid', 'Sorcerer', 'Sorcerer'],
      ),
      'casting time': _copy(fire, castingTime: 'Bonus Action'),
      'range padding': _copy(fire, range: '120 feet '),
      'components': _copy(
        fire,
        components: 'V, S, M (a piece of sulfur)',
      ),
      'duration': _copy(fire, duration: 'Instantaneous'),
      'verbal': _copy(fire, verbal: false),
      'somatic': _copy(fire, somatic: false),
      'material': _copy(fire, material: false),
      'concentration': _copy(fire, concentration: false),
      'ritual': _copy(fire, ritual: true),
    };

    for (final variant in variants.entries) {
      expect(
        () => SrdWallOfFireCatalogIdentity.validate(variant.value),
        throwsFormatException,
        reason: variant.key,
      );
      expect(
        () => _heat(variant.value),
        throwsFormatException,
        reason: variant.key,
      );
      expect(
        () => _ring(variant.value),
        throwsFormatException,
        reason: variant.key,
      );
    }

    // An untrusted clone must not modify the original catalogue snapshot.
    expect(_heat(fire).requiresDamageReview, isTrue);
    expect(_ring(fire).heightFeet, 20);
  });
}
