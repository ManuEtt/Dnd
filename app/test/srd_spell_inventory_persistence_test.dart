import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_inventory_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_target_rules.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

const _materials = [
  SrdConsumedMaterial(inventoryId: 'water-confirmed', quantity: 1),
];

HeroCharacter _hero() => HeroCharacter(
  id: 'caster-one',
  name: 'Talia',
  className: 'Kleriker',
  level: 5,
  spells: const ['Protection from Evil and Good'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 18,
    'charisma': 10,
  },
  hitPoints: 25,
  maxHitPoints: 25,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d4',
  inventory: const [
    InventoryItem(
      id: 'water-confirmed',
      name: 'Bestätigtes Weihwasser',
      quantity: 2,
    ),
    InventoryItem(id: 'travel-rope', name: 'Seil'),
  ],
);

Campaign _campaign() => Campaign(
  id: 'srd-resource-campaign',
  name: 'SRD Materialprüfung',
  world: 'Testwelt',
  sessionId: 'spell-session',
  hero: _hero(),
  scene: 'Außerhalb des Kampfes.',
);

SrdSpellCastPlan _plan(HeroCharacter hero, SrdSpellDefinition spell) =>
    SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: 'Kleriker',
      slotLevel: 1,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: true,
      gridTarget: SrdSpellGridTargetRequest(
        map: SrdSpellGridMap(
          width: 4,
          height: 4,
          fullBlockers: const [],
          fullBlockersSurveyedConfirmed: true,
        ),
        caster: const SrdGridCell(0, 0),
        origin: const SrdGridCell(0, 1),
        withinTouchReachConfirmed: true,
      ),
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      materialComponentConfirmed: true,
      costlyComponentAvailableConfirmed: true,
      consumedComponentReservedConfirmed: true,
      slotTurnLimitConfirmed: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository repository;
  late SrdSpellDefinition spell;

  setUpAll(() async {
    final catalog = await SrdSpellCatalogLoader.load();
    spell = catalog.find('Protection from Evil and Good')!;
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('srd-spell-commit-');
    databasePath = paths.join(directory.path, 'campaign.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test(
    'single controller commit persists slot, material, journal and replay',
    () async {
      final initial = _campaign();
      await repository.saveCampaign(initial);
      final controller = GameController(repository: repository);
      try {
        await controller.openCampaign(initial.id);
        final approved = _plan(controller.currentCampaign!.hero, spell);
        await controller.commitConfirmedSpellMaterialCast(
          campaignId: initial.id,
          expectedRevision: 0,
          plan: approved,
          effectResolvedSeparatelyConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: _materials,
        );
        expect(controller.error, isNull);
        final changed = controller.currentCampaign!;
        expect(changed.revision, 1);
        expect(changed.hero.spentSpellSlots, {'1': 1});
        expect(changed.hero.inventory.first.quantity, 1);
        expect(changed.hero.inventory.last.id, 'travel-rope');
        expect(changed.hero.concentratingOn, spell.name);
        expect(changed.events, hasLength(1));
        expect(changed.events.single.type, 'spell.materialsCommitted');
        expect(changed.events.single.payload['spell'], spell.name);
        expect(changed.events.single.payload['slotLevel'], 1);
        expect(changed.events.single.payload['targetRange'], 'Touch');
        expect(changed.events.single.payload['targetOriginMode'], 'touched');
        expect(changed.events.single.payload['consumedMaterials'], [
          {'inventoryId': 'water-confirmed', 'quantity': 1},
        ]);

        final durable = (await repository.getCampaign(initial.id))!;
        expect(durable.toJson(), changed.toJson());
        final replayed = await repository.reconstructCampaign(
          initial.id,
          revision: 1,
        );
        expect(replayed!.toJson(), changed.toJson());

        await controller.commitConfirmedSpellMaterialCast(
          campaignId: initial.id,
          expectedRevision: 0,
          plan: approved,
          effectResolvedSeparatelyConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: _materials,
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), changed.toJson());
        expect(
          (await repository.getCampaign(initial.id))!.toJson(),
          changed.toJson(),
        );
      } finally {
        controller.dispose();
      }
    },
  );

  test('state and journal survive SQLite close and reopen', () async {
    final initial = _campaign();
    await repository.saveCampaign(initial);
    final controller = GameController(repository: repository);
    await controller.openCampaign(initial.id);
    await controller.commitConfirmedSpellMaterialCast(
      campaignId: initial.id,
      expectedRevision: 0,
      plan: _plan(initial.hero, spell),
      effectResolvedSeparatelyConfirmed: true,
      materialIdentityAndQuantityConfirmed: true,
      consumedMaterials: _materials,
    );
    expect(controller.error, isNull);
    final snapshot = controller.currentCampaign!.toJson();
    controller.dispose();
    await repository.close();

    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    final loaded = await repository.getCampaign(initial.id);
    expect(loaded!.toJson(), snapshot);
    expect(loaded.events, hasLength(1));
  });

  test(
    'missing resources or unverified effect never commit a partial event',
    () async {
      final initial = _campaign();
      await repository.saveCampaign(initial);
      final controller = GameController(repository: repository);
      try {
        await controller.openCampaign(initial.id);
        final approved = _plan(initial.hero, spell);
        await controller.commitConfirmedSpellMaterialCast(
          campaignId: initial.id,
          expectedRevision: 0,
          plan: approved,
          effectResolvedSeparatelyConfirmed: false,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: _materials,
        );
        expect(controller.error, isNotNull);
        await controller.commitConfirmedSpellMaterialCast(
          campaignId: initial.id,
          expectedRevision: 0,
          plan: approved,
          effectResolvedSeparatelyConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: const [
            SrdConsumedMaterial(inventoryId: 'water-confirmed', quantity: 3),
          ],
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), initial.toJson());
        expect(
          (await repository.getCampaign(initial.id))!.toJson(),
          initial.toJson(),
        );
        expect(
          await repository.reconstructCampaign(initial.id, revision: 1),
          isNull,
        );
      } finally {
        controller.dispose();
      }
    },
  );

  test(
    'concurrent stale SQLite writer cannot overwrite latest revision',
    () async {
      final initial = _campaign();
      await repository.saveCampaign(initial);
      final controller = GameController(repository: repository);
      try {
        await controller.openCampaign(initial.id);
        final approved = _plan(initial.hero, spell);
        await repository.saveCampaign(
          initial.copyWith(revision: 1, scene: 'Anderer bestätigter Zug.'),
        );
        await controller.commitConfirmedSpellMaterialCast(
          campaignId: initial.id,
          expectedRevision: 0,
          plan: approved,
          effectResolvedSeparatelyConfirmed: true,
          materialIdentityAndQuantityConfirmed: true,
          consumedMaterials: _materials,
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.revision, 0);
        final durable = (await repository.getCampaign(initial.id))!;
        expect(durable.revision, 1);
        expect(durable.scene, 'Anderer bestätigter Zug.');
        expect(durable.hero.spentSpellSlots, isEmpty);
        expect(durable.hero.inventory.first.quantity, 2);
        expect(durable.events, isEmpty);
      } finally {
        controller.dispose();
      }
    },
  );

  test('boolean-only target confirmation cannot persist spell resources', () {
    final engine = GameEngine();
    final base = _campaign();
    final legacyPlan = SrdSpellPreflightRules.preflight(
      base.hero,
      spell: spell,
      castingClass: 'Kleriker',
      slotLevel: 1,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      materialComponentConfirmed: true,
      costlyComponentAvailableConfirmed: true,
      consumedComponentReservedConfirmed: true,
      slotTurnLimitConfirmed: true,
    );
    expect(legacyPlan.targetAssessment, isNull);
    expect(
      () => engine.commitConfirmedSpellMaterialCast(
        base,
        plan: legacyPlan,
        effectResolvedSeparatelyConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: _materials,
      ),
      throwsFormatException,
    );
    expect(base.hero.spentSpellSlots, isEmpty);
    expect(base.hero.inventory.first.quantity, 2);
    expect(base.revision, 0);
    expect(base.events, isEmpty);
  });

  test('open dice and combat state reject generic material booking', () {
    final engine = GameEngine();
    final base = _campaign();
    final approved = _plan(base.hero, spell);
    final fight = base.copyWith(
      encounter: const Encounter(
        id: 'active-foe',
        enemyName: 'Gegner',
        enemyHitPoints: 10,
        enemyMaxHitPoints: 10,
        enemyAttackBonus: 2,
        enemyDamage: '1d4',
      ),
    );
    expect(
      () => engine.commitConfirmedSpellMaterialCast(
        fight,
        plan: approved,
        effectResolvedSeparatelyConfirmed: true,
        materialIdentityAndQuantityConfirmed: true,
        consumedMaterials: _materials,
      ),
      throwsFormatException,
    );
    expect(base.hero.inventory.first.quantity, 2);
    expect(base.hero.spentSpellSlots, isEmpty);
  });
}
