import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_target_rules.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _caster = SrdGridCell(4, 4);

SrdSpellGridMap _map({
  Iterable<SrdGridCell> blockers = const [],
  bool surveyed = true,
}) => SrdSpellGridMap(
  width: 25,
  height: 25,
  fullBlockers: blockers,
  fullBlockersSurveyedConfirmed: surveyed,
);

SrdSpellGridTargetRequest _request(
  SrdGridCell origin, {
  SrdSpellGridMap? map,
  bool touchConfirmed = true,
}) => SrdSpellGridTargetRequest(
  map: map ?? _map(),
  caster: _caster,
  origin: origin,
  withinTouchReachConfirmed: touchConfirmed,
);

HeroCharacter _hero() => HeroCharacter(
  id: 'touch-cleric',
  name: 'Klara',
  className: 'Kleriker',
  level: 3,
  spells: const ['Wunden heilen'],
  hitPoints: 18,
  maxHitPoints: 25,
);

SrdSpellCastPlan _preflight(
  HeroCharacter hero,
  SrdSpellDefinition spell,
  SrdSpellGridTargetRequest request,
) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: 'Cleric',
  slotLevel: 1,
  gridTarget: request,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  slotTurnLimitConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);
  late SrdSpellCatalog catalog;
  late SrdSpellDefinition heal;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
    heal = catalog.find('Cure Wounds')!;
    expect(heal.range, 'Touch');
  });

  test('Touch works on own tile and all eight adjacent grid tiles', () {
    final map = _map();
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        final origin = SrdGridCell(_caster.column + dx, _caster.row + dy);
        final facts = SrdSpellGridTargetRules.factsFor(
          heal,
          _request(origin, map: map),
        );
        expect(facts.mode, SrdSpellOriginMode.touched);
        expect(facts.withinTouchReachConfirmed, isTrue);
        expect(
          SrdSpellGridTargetRules.validateOrigin(
            heal,
            _request(origin, map: map),
          ).range,
          'Touch',
        );
        expect(
          SrdSpellGridTargetRules.distanceFeet(_caster, origin),
          dx == 0 && dy == 0 ? 0 : 5,
        );
      }
    }
  });

  test('touch approval cannot override a surveyed distance of 10 to 100 ft', () {
    final map = _map();
    for (final origin in [
      const SrdGridCell(6, 4),
      const SrdGridCell(4, 6),
      const SrdGridCell(6, 6),
      const SrdGridCell(9, 9),
      const SrdGridCell(24, 4),
    ]) {
      final before = SrdSpellGridTargetRules.distanceFeet(_caster, origin);
      expect(before, greaterThan(5));
      expect(
        () => SrdSpellGridTargetRules.factsFor(
          heal,
          _request(origin, map: map, touchConfirmed: true),
        ),
        throwsFormatException,
        reason: 'Known distance $before feet must defeat a boolean approval',
      );
      expect(
        () => SrdSpellGridTargetRules.validateOrigin(
          heal,
          _request(origin, map: map),
        ),
        throwsFormatException,
      );
    }
  });

  test('adjacent touch without player approval and unsurveyed cover fail', () {
    for (final request in [
      _request(const SrdGridCell(5, 4), touchConfirmed: false),
      _request(const SrdGridCell(5, 4), map: _map(surveyed: false)),
      _request(
        const SrdGridCell(5, 4),
        map: _map(blockers: const [SrdGridCell(5, 4)]),
      ),
    ]) {
      expect(
        () => SrdSpellGridTargetRules.validateOrigin(heal, request),
        throwsFormatException,
      );
    }
  });

  test('ranged and self origins retain their own independent range checks', () {
    final missile = catalog.find('Magic Missile')!;
    final cone = catalog.find('Burning Hands')!;
    final distant = _request(const SrdGridCell(14, 4));
    expect(
      SrdSpellGridTargetRules.validateOrigin(
        missile,
        distant,
      ).originDistanceFeet,
      50,
    );
    expect(
      SrdSpellGridTargetRules.validateOrigin(
        cone,
        _request(_caster),
      ).mode,
      SrdSpellOriginMode.caster,
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(cone, distant),
      throwsFormatException,
    );
  });

  test('confirmed spell preflight rejects distant Touch without slot spending', () {
    final hero = _hero();
    final before = hero.toJson();
    for (final origin in [
      const SrdGridCell(6, 4),
      const SrdGridCell(4, 15),
    ]) {
      expect(
        () => _preflight(hero, heal, _request(origin)),
        throwsFormatException,
      );
    }
    expect(hero.toJson(), before);
    expect(hero.spentSpellSlots, isEmpty);
    final nearby = _preflight(hero, heal, _request(const SrdGridCell(5, 5)));
    expect(nearby.castingClass, 'Kleriker');
    expect(nearby.targetAssessment!.range, 'Touch');
    expect(hero.toJson(), before);
  });

  test('legacy JSON and SQLite restart retain a rejected distant target', () async {
    final hero = _hero();
    final sourceJson = hero.toJson();
    expect(sourceJson.containsKey('preparedSpellRecord'), isFalse);
    expect(HeroCharacter.fromJson(sourceJson).toJson(), sourceJson);
    final directory = await Directory.systemTemp.createTemp('grid-touch-');
    final path = '${directory.path}/save.sqlite';
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = Campaign(
        id: 'grid-touch-campaign',
        name: 'Berührungsreichweite',
        world: 'Test',
        sessionId: 'touch-session',
        scene: 'Start',
        hero: hero,
      );
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(campaign.id))!;
      final snapshot = restored.toJson();
      expect(
        () => _preflight(
          restored.hero,
          heal,
          _request(const SrdGridCell(12, 12)),
        ),
        throwsFormatException,
      );
      expect((await repository.getCampaign(campaign.id))!.toJson(), snapshot);
      // An unrelated confirmed state change follows normal optimistic
      // concurrency; neither a retry nor a stale editor can book the failed
      // spell through this read-only target check.
      final committed = restored.copyWith(
        revision: 1,
        hero: restored.hero.copyWith(hitPoints: 17),
      );
      await repository.saveCampaign(committed, expectedRevision: 0);
      await repository.saveCampaign(committed, expectedRevision: 0);
      await expectLater(
        repository.saveCampaign(
          restored.copyWith(
            revision: 1,
            hero: restored.hero.copyWith(hitPoints: 16),
          ),
          expectedRevision: 0,
        ),
        throwsA(isA<CampaignConflictException>()),
      );
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final finalSave = (await repository.getCampaign(campaign.id))!;
      expect(finalSave.revision, 1);
      expect(finalSave.hero.hitPoints, 17);
      expect(finalSave.hero.spentSpellSlots, isEmpty);
      expect(finalSave.hero.spells, ['Wunden heilen']);
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
