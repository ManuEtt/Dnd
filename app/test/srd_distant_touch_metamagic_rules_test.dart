import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_distant_touch_metamagic_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

HeroCharacter _hero({
  String first = 'Zauberer',
  String second = '',
  int level = 2,
  int secondLevel = 0,
  List<String> spells = const ['Chill Touch'],
  Map<String, int> used = const {},
  int? hp = 18,
}) => HeroCharacter(
  id: 'distant-sorcerer',
  name: 'Yara',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  level: level,
  spells: spells,
  hitPoints: hp,
  maxHitPoints: 22,
  spentClassResources: used,
);

SrdSpellGridTargetRequest _grid(
  int distanceInSquares, {
  Iterable<SrdGridCell> blockers = const [],
  bool surveyed = true,
}) => SrdSpellGridTargetRequest(
  map: SrdSpellGridMap(
    width: 30,
    height: 30,
    fullBlockers: blockers,
    fullBlockersSurveyedConfirmed: surveyed,
  ),
  caster: const SrdGridCell(1, 1),
  origin: SrdGridCell(1 + distanceInSquares, 1),
);

SrdDistantTouchPlan _preview(
  HeroCharacter hero,
  SrdSpellCatalog catalog, {
  String spellName = 'Chill Touch',
  String castingClass = 'Sorcerer',
  int distance = 6,
  bool choice = true,
  bool ownership = true,
  bool target = true,
  bool combination = true,
  SrdSpellGridTargetRequest? grid,
}) => SrdDistantTouchMetamagicRules.preview(
  hero: hero,
  catalog: catalog,
  spellName: spellName,
  castingClass: castingClass,
  gridTarget: grid ?? _grid(distance),
  distantSpellChoiceConfirmed: choice,
  preparedForCastingClassConfirmed: ownership,
  targetRulesConfirmed: target,
  metamagicCombinationAllowedConfirmed: combination,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('Sorcerer level 2 permits Touch at exact 30ft and staging 1 point', () {
    final hero = _hero();
    final initial = hero.toJson();
    final plan = _preview(hero, catalog);
    expect(plan.distanceFeet, 30);
    expect(plan.maximumRangeFeet, 30);
    expect(plan.sorceryPointCost, 1);
    expect(plan.spellName, 'Chill Touch');
    expect(plan.castingClass, 'Zauberer');
    plan.verifyUnchanged(hero);
    expect(hero.toJson(), initial);
    expect(hero.spentClassResources, isEmpty);
    expect(
      () => plan.stageSorceryPointCost(
        hero,
        castingCostsAndEffectResolvedSeparatelyConfirmed: false,
      ),
      throwsFormatException,
    );
    final staged = plan.stageSorceryPointCost(
      hero,
      castingCostsAndEffectResolvedSeparatelyConfirmed: true,
    );
    expect(staged.spentClassResources['sorceryPoints'], 1);
    expect(hero.spentClassResources, isEmpty);
    expect(
      () => plan.stageSorceryPointCost(
        staged,
        castingCostsAndEffectResolvedSeparatelyConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  test('own and 5-30ft squares pass, more than 30ft fails', () {
    final hero = _hero();
    for (var n = 0; n <= 6; n++) {
      expect(_preview(hero, catalog, distance: n).distanceFeet, 5 * n);
    }
    for (final distance in [7, 8, 20]) {
      expect(
        () => _preview(hero, catalog, distance: distance),
        throwsFormatException,
      );
    }
    expect(hero.spentClassResources, isEmpty);
  });

  test('metamagic choice, source, targets and combination are independent', () {
    final hero = _hero();
    for (final flags in [
      [false, true, true, true],
      [true, false, true, true],
      [true, true, false, true],
      [true, true, true, false],
    ]) {
      expect(
        () => _preview(
          hero,
          catalog,
          choice: flags[0],
          ownership: flags[1],
          target: flags[2],
          combination: flags[3],
        ),
        throwsFormatException,
      );
    }
    // Freeform notes never replace the Sorcerer-2 level requirement.
    final fake = _hero(first: 'Kleriker', level: 5);
    fake.copyWith(features: const ['Distant Spell']);
    expect(
      () => _preview(fake, catalog),
      throwsFormatException,
    );
  });

  test('no Sorcerer 2, invalid class aliases or malformed levels fail closed', () {
    final invalid = [
      _hero(level: 1),
      _hero(first: 'Wizard', level: 5),
      _hero(first: 'Unknown', level: 5),
      _hero(first: 'Zauberer', second: 'Sorcerer', level: 5, secondLevel: 2),
      _hero(first: 'Zauberer', second: 'Unknown', level: 5, secondLevel: 2),
      _hero(first: 'Zauberer', level: 21),
      _hero(first: 'Zauberer', second: 'Kleriker', level: 3, secondLevel: 3),
    ];
    for (final hero in invalid) {
      expect(
        () => _preview(hero, catalog),
        throwsFormatException,
        reason: hero.classSummary,
      );
    }
    expect(
      _preview(_hero(first: 'Sorcerer'), catalog).castingClass,
      'Zauberer',
    );
  });

  test('multiclass touch spell belongs to its actual casting class', () {
    final multiclass = _hero(
      first: 'Kleriker',
      second: 'Zauberer',
      level: 5,
      secondLevel: 2,
      spells: const ['Cure Wounds'],
    );
    final plan = _preview(
      multiclass,
      catalog,
      spellName: 'Cure Wounds',
      castingClass: 'Cleric',
    );
    expect(plan.castingClass, 'Kleriker');
    expect(plan.distanceFeet, 30);
    expect(
      () => _preview(
        multiclass,
        catalog,
        spellName: 'Cure Wounds',
        castingClass: 'Zauberer',
      ),
      throwsFormatException,
    );
    expect(
      () => _preview(
        multiclass,
        catalog,
        spellName: 'Cure Wounds',
        castingClass: 'Wizard',
      ),
      throwsFormatException,
    );
  });

  test('unknown, unprepared, non-Touch and higher-grade spells fail', () {
    final hero = _hero(spells: const ['Chill Touch', 'Magic Missile', 'Fly']);
    for (final name in [
      'Not a spell',
      'Magic Missile',
      'Fly',
      ' Chill Touch',
    ]) {
      expect(
        () => _preview(hero, catalog, spellName: name),
        throwsFormatException,
      );
    }
    expect(
      () => _preview(
        _hero(spells: const []),
        catalog,
      ),
      throwsFormatException,
    );
  });

  test('no resources, malformed resource counters and defeated hero fail', () {
    final empty = _hero(used: const {'sorceryPoints': 2});
    expect(() => _preview(empty, catalog), throwsStateError);
    final invalid = _hero(used: const {'sorceryPoints': 3});
    expect(() => _preview(invalid, catalog), throwsFormatException);
    expect(() => _preview(_hero(hp: 0), catalog), throwsStateError);
    expect(() => _preview(_hero(hp: null), catalog), throwsStateError);
    expect(
      _preview(
        _hero(level: 4, used: const {'sorceryPoints': 3}),
        catalog,
      ).sorceryPointCost,
      1,
    );
  });

  test('unsurveyed map, cover and invalid coordinates fail without spending', () {
    final hero = _hero();
    for (final request in [
      _grid(6, surveyed: false),
      _grid(6, blockers: const [SrdGridCell(4, 1)]),
      _grid(6, blockers: const [SrdGridCell(7, 1)]),
      _grid(6, blockers: const [SrdGridCell(1, 1)]),
      _grid(29),
    ]) {
      expect(
        () => _preview(hero, catalog, grid: request),
        throwsFormatException,
      );
    }
    expect(hero.spentClassResources, isEmpty);
  });

  test('revalidated plans reject stale snapshot before any point staging', () {
    final hero = _hero();
    final plan = _preview(hero, catalog);
    final altered = hero.copyWith(hitPoints: 17);
    expect(() => plan.verifyUnchanged(altered), throwsFormatException);
    expect(
      () => plan.stageSorceryPointCost(
        altered,
        castingCostsAndEffectResolvedSeparatelyConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(hero.toJson(), HeroCharacter.fromJson(hero.toJson()).toJson());
  });

  test('SQLite restart stages once and stale revision cannot spend again', () async {
    final directory = await Directory.systemTemp.createTemp('distant-touch-');
    final path = '${directory.path}/campaign.sqlite';
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = Campaign(
        id: 'distant-touch-campaign',
        name: 'Metamagie',
        world: 'Test',
        sessionId: 'session',
        scene: 'Anfang',
        hero: _hero(),
      );
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final loaded = (await repository.getCampaign(campaign.id))!;
      final source = loaded.toJson();
      final plan = _preview(loaded.hero, catalog);
      expect((await repository.getCampaign(campaign.id))!.toJson(), source);
      final staged = plan.stageSorceryPointCost(
        loaded.hero,
        castingCostsAndEffectResolvedSeparatelyConfirmed: true,
      );
      final committed = loaded.copyWith(revision: 1, hero: staged);
      await repository.saveCampaign(committed, expectedRevision: 0);
      await repository.saveCampaign(committed, expectedRevision: 0);
      await expectLater(
        repository.saveCampaign(
          loaded.copyWith(revision: 1, hero: loaded.hero),
          expectedRevision: 0,
        ),
        throwsA(isA<CampaignConflictException>()),
      );
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final reloaded = (await repository.getCampaign(campaign.id))!;
      expect(reloaded.revision, 1);
      expect(reloaded.hero.spentClassResources['sorceryPoints'], 1);
      expect(
        () => plan.stageSorceryPointCost(
          reloaded.hero,
          castingCostsAndEffectResolvedSeparatelyConfirmed: true,
        ),
        throwsFormatException,
      );
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
