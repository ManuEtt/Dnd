import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/sneak_attack_ally_rules.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _LowRoll implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

GameEngine _engine() => GameEngine(
  dice: DiceEngine(random: _LowRoll()),
  clock: () => DateTime.utc(2026, 10, 24),
);

HeroCharacter _hero({bool offhandDagger = true, bool mainDagger = false}) =>
    HeroCharacter(
      id: 'offhand-ally-rogue',
      name: 'Nara',
      className: 'Schurke',
      level: 4,
      secondaryClassName: 'Kämpfer',
      secondaryClassLevel: 1,
      abilities: const {
        'strength': 14,
        'dexterity': 14,
        'constitution': 14,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
      },
      hitPoints: 30,
      maxHitPoints: 30,
      armorClass: 15,
      speed: 9,
      weaponDamage: mainDagger ? '1d4' : '1d6',
      weaponAbility: mainDagger ? 'dexterity' : 'strength',
      weaponProficient: true,
      equippedWeaponId: 'main',
      features: const ['Kampfstil: Kampf mit zwei Waffen'],
      inventory: [
        InventoryItem(
          id: 'main',
          name: mainDagger ? 'Hauptdolch' : 'Haupthandaxt',
          catalogId: mainDagger ? 'weapon-dagger' : 'weapon-handaxe',
        ),
        InventoryItem(
          id: 'offhand',
          name: offhandDagger ? 'Nebendolch' : 'Nebenhandaxt',
          catalogId: offhandDagger ? 'weapon-dagger' : 'weapon-handaxe',
        ),
      ],
    );

Campaign _waiting(GameEngine engine, {HeroCharacter? hero}) {
  final start = engine.createDemo(hero: hero ?? _hero()).copyWith(
    encounter: const Encounter(
      id: 'offhand-ally-target',
      enemyName: 'Übungsgegner',
      enemyHitPoints: 100,
      enemyMaxHitPoints: 100,
      enemyArmorClass: 12,
      movementRemaining: 9,
    ),
  );
  final primary = engine.act(start, 'Ich greife an.').campaign;
  final missed = engine.resolveRoll(primary, natural: 1).campaign;
  final pending = engine.act(missed, 'Nebenhandangriff: offhand').campaign;
  expect(pending.pendingRoll!.type, 'offhandAttack');
  expect(pending.pendingRoll!.weaponId, 'offhand');
  expect(pending.pendingRoll!.advantage, isFalse);
  expect(pending.pendingRoll!.disadvantage, isFalse);
  return pending;
}

Campaign _confirm(GameEngine engine, Campaign pending) =>
    engine.confirmSneakAttackAlly(
      pending,
      rollId: pending.pendingRoll!.id,
      allyName: 'Mira',
      withinFiveFeetOfTargetConfirmed: true,
      notIncapacitatedConfirmed: true,
    ).campaign;

void main() {
  setUpAll(sqfliteFfiInit);

  test('Offhand dagger earns ally-based Sneak Attack without advantage', () {
    final engine = _engine();
    final waiting = _waiting(engine);
    expect(SneakAttackAllyRules.canPrepare(waiting), isTrue);
    final prepared = _confirm(engine, waiting);
    expect(prepared.pendingRoll!.weaponId, 'offhand');
    expect(prepared.pendingRoll!.sneakAttackAlly!.rollId, waiting.pendingRoll!.id);
    expect(prepared.hero.toJson(), waiting.hero.toJson());
    expect(prepared.encounter!.toJson(), waiting.encounter!.toJson());
    expect(Campaign.fromJson(prepared.toJson()).toJson(), prepared.toJson());
    final hit = engine.resolveRoll(prepared, natural: 15);
    expect(hit.events.single.payload['offhandWeaponId'], 'offhand');
    expect(hit.events.single.payload['sneakAttackRoll']['rolls'], [1, 1]);
    expect(hit.events.single.payload['damage'], 5);
    expect(hit.campaign.encounter!.enemyHitPoints, 95);
  });

  test('Non-finesse offhand never inherits main-hand eligibility', () {
    final engine = _engine();
    final waiting = _waiting(
      engine,
      hero: _hero(mainDagger: true, offhandDagger: false),
    );
    expect(SneakAttackAllyRules.canPrepare(waiting), isFalse);
    expect(() => _confirm(engine, waiting), throwsFormatException);
    final ordinaryHit = engine.resolveRoll(waiting, natural: 15);
    expect(ordinaryHit.events.single.payload.containsKey('sneakAttackRoll'), isFalse);
    expect(ordinaryHit.campaign.encounter!.enemyHitPoints, 97);
  });

  test('Disadvantage, stale identity and spent turn all reject confirmation', () {
    final engine = _engine();
    final waiting = _waiting(engine);
    final withDisadvantage = waiting.copyWith(
      pendingRoll: PendingRoll.fromJson({
        ...waiting.pendingRoll!.toJson(),
        'disadvantage': true,
      }),
    );
    expect(SneakAttackAllyRules.canPrepare(withDisadvantage), isFalse);
    expect(() => _confirm(engine, withDisadvantage), throwsFormatException);
    expect(
      () => engine.confirmSneakAttackAlly(
        waiting,
        rollId: 'different-roll',
        allyName: 'Mira',
        withinFiveFeetOfTargetConfirmed: true,
        notIncapacitatedConfirmed: true,
      ),
      throwsFormatException,
    );
    final spent = waiting.copyWith(
      encounter: waiting.encounter!.copyWith(sneakAttackUsedThisTurn: true),
    );
    expect(SneakAttackAllyRules.canPrepare(spent), isFalse);
    expect(() => _confirm(engine, spent), throwsFormatException);
  });

  test('Confirmation can be cleared and cannot grant damage after a miss', () {
    final engine = _engine();
    final prepared = _confirm(engine, _waiting(engine));
    final cleared = engine.clearSneakAttackAlly(
      prepared,
      rollId: prepared.pendingRoll!.id,
    );
    expect(cleared.campaign.pendingRoll!.sneakAttackAlly, isNull);
    expect(cleared.campaign.pendingRoll!.id, prepared.pendingRoll!.id);
    final hit = engine.resolveRoll(cleared.campaign, natural: 15);
    expect(hit.events.single.payload.containsKey('sneakAttackRoll'), isFalse);
    expect(hit.events.single.payload['damage'], 3);
  });

  test('Offhand critical doubles dice; miss does not consume Sneak Attack', () {
    final engine = _engine();
    final waiting = _waiting(engine);
    final critical = engine.resolveRoll(_confirm(engine, waiting), natural: 20);
    expect(critical.events.single.payload['sneakAttackRoll']['rolls'], [
      1,
      1,
      1,
      1,
    ]);
    expect(critical.campaign.encounter!.enemyHitPoints, 92);
    final miss = engine.resolveRoll(_confirm(engine, waiting), natural: 1);
    expect(miss.events.single.payload.containsKey('sneakAttackRoll'), isFalse);
    expect(miss.campaign.encounter!.sneakAttackUsedThisTurn, isFalse);
  });

  test('Tampered JSON bindings and invalid offhand metadata fail closed', () {
    final engine = _engine();
    final prepared = _confirm(engine, _waiting(engine));
    for (final tampering in [
      {'rollId': 'old-roll'},
      {'campaignId': 'other-campaign'},
      {'targetId': 'other-target'},
      {'withinFiveFeetOfTargetConfirmed': false},
      {'notIncapacitatedConfirmed': null},
      {'bonusDamage': 999},
    ]) {
      final json = prepared.toJson();
      final pending = json['pendingRoll'] as Map<String, dynamic>;
      pending['sneakAttackAlly'] = {
        ...pending['sneakAttackAlly'] as Map<String, dynamic>,
        ...tampering,
      };
      expect(() => Campaign.fromJson(json), throwsFormatException);
    }
    final altered = prepared.toJson();
    (altered['pendingRoll'] as Map<String, dynamic>)['weaponId'] = 'missing';
    expect(() => Campaign.fromJson(altered), throwsFormatException);
    final spent = prepared.copyWith(
      encounter: prepared.encounter!.copyWith(sneakAttackUsedThisTurn: true),
    );
    expect(() => Campaign.fromJson(spent.toJson()), throwsFormatException);
  });

  test('SQLite restart, JSON backup and stale revision preserve one use', () async {
    final engine = _engine();
    final directory = await Directory.systemTemp.createTemp('offhand-ally-');
    final path = '${directory.path}/campaign.sqlite';
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    GameController? controller;
    try {
      final waiting = _waiting(engine).copyWith(revision: 0, events: const []);
      await repository.importCampaign(jsonEncode(waiting.toJson()));
      controller = GameController(repository: repository, engine: engine);
      await controller.openCampaign(waiting.id);
      final before = controller.currentCampaign!;
      await controller.confirmSneakAttackAlly(
        campaignId: before.id,
        expectedRevision: before.revision,
        rollId: before.pendingRoll!.id,
        allyName: 'Mira',
        withinFiveFeetOfTargetConfirmed: true,
        notIncapacitatedConfirmed: true,
      );
      expect(controller.error, isNull);
      final confirmed = controller.currentCampaign!;
      expect(confirmed.revision, before.revision + 1);
      await controller.confirmSneakAttackAlly(
        campaignId: before.id,
        expectedRevision: before.revision,
        rollId: before.pendingRoll!.id,
        allyName: 'Falsch',
        withinFiveFeetOfTargetConfirmed: true,
        notIncapacitatedConfirmed: true,
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      final backup = await repository.exportCampaign(before.id);
      final imported = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      try {
        expect(
          (await imported.importCampaign(backup)).pendingRoll!.toJson(),
          confirmed.pendingRoll!.toJson(),
        );
      } finally {
        await imported.close();
      }
      controller.dispose();
      controller = null;
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(repository: repository, engine: engine);
      await controller.openCampaign(before.id);
      expect(controller.currentCampaign!.pendingRoll!.sneakAttackAlly!.allyName, 'Mira');
      await controller.resolveRoll(natural: 15);
      expect(controller.error, isNull);
      final saved = (await repository.getCampaign(before.id))!;
      expect(saved.pendingRoll, isNull);
      expect(saved.events.last.payload['sneakAttackRoll']['rolls'], [1, 1]);
      expect((await repository.reconstructCampaign(before.id))!.toJson(), saved.toJson());
      await controller.resolveRoll(natural: 15);
      expect(controller.error, isNotNull);
      expect((await repository.getCampaign(before.id))!.toJson(), saved.toJson());
    } finally {
      controller?.dispose();
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
