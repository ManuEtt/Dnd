import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

GameEngine _engine() => GameEngine(
  dice: DiceEngine(random: _MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 24),
);

HeroCharacter _hero({required bool daggerPrimary, bool daggerOffhand = true}) =>
    HeroCharacter(
      id: 'weapon-context-rogue',
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
      weaponDamage: daggerPrimary ? '1d4' : '1d6',
      weaponAbility: daggerPrimary ? 'dexterity' : 'strength',
      weaponProficient: true,
      equippedWeaponId: 'main',
      features: const ['Kampfstil: Kampf mit zwei Waffen'],
      inventory: [
        InventoryItem(
          id: 'main',
          name: daggerPrimary ? 'Hauptdolch' : 'Haupthandaxt',
          catalogId: daggerPrimary ? 'weapon-dagger' : 'weapon-handaxe',
        ),
        InventoryItem(
          id: 'offhand',
          name: daggerOffhand ? 'Nebendolch' : 'Nebenhandaxt',
          catalogId: daggerOffhand ? 'weapon-dagger' : 'weapon-handaxe',
        ),
      ],
    );

Campaign _battle(GameEngine engine, HeroCharacter hero) => engine
    .createDemo(hero: hero)
    .copyWith(
      encounter: const Encounter(
        id: 'weapon-context-target',
        enemyName: 'Übungsgegner',
        enemyHitPoints: 100,
        enemyMaxHitPoints: 100,
        enemyArmorClass: 12,
        movementRemaining: 9,
      ),
    );

// An explicit previously confirmed advantage is part of the saved roll.
// This fixture does not invent a new advantage-producing UI/class action.
Campaign _advantage(Campaign campaign, {bool disadvantage = false}) {
  final data = campaign.toJson();
  final pending = Map<String, dynamic>.from(data['pendingRoll'] as Map);
  pending['advantage'] = true;
  if (disadvantage) pending['disadvantage'] = true;
  data['pendingRoll'] = pending;
  return Campaign.fromJson(data);
}

Campaign _offhandAfterPrimaryMiss(
  GameEngine engine,
  HeroCharacter hero, {
  bool disadvantage = false,
}) {
  final start = _battle(engine, hero);
  final primary = engine.act(start, 'Ich greife an.').campaign;
  expect(primary.pendingRoll!.type, 'attack');
  final miss = engine.resolveRoll(primary, natural: 1).campaign;
  expect(miss.encounter!.lightAttackAvailable, isTrue);
  expect(miss.encounter!.sneakAttackUsedThisTurn, isFalse);
  final offhand = engine.act(miss, 'Nebenhandangriff: offhand').campaign;
  expect(offhand.pendingRoll!.type, 'offhandAttack');
  expect(offhand.pendingRoll!.weaponId, 'offhand');
  expect(offhand.pendingRoll!.sneakAttackAlly, isNull);
  return _advantage(offhand, disadvantage: disadvantage);
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('Finesse primary cannot grant Sneak Attack to an offhand handaxe', () {
    final engine = _engine();
    final waiting = _offhandAfterPrimaryMiss(
      engine,
      _hero(daggerPrimary: true, daggerOffhand: false),
    );
    final result = engine.resolveRoll(waiting, natural: 15);
    expect(result.events.single.payload['offhandWeaponId'], 'offhand');
    expect(
      result.events.single.payload.containsKey('sneakAttackRoll'),
      isFalse,
    );
    expect(result.events.single.payload['damage'], 3);
    expect(result.campaign.encounter!.enemyHitPoints, 97);
  });

  test('Offhand dagger qualifies despite a non-Finesse primary handaxe', () {
    final engine = _engine();
    final waiting = _offhandAfterPrimaryMiss(
      engine,
      _hero(daggerPrimary: false),
    );
    final result = engine.resolveRoll(waiting, natural: 15);
    expect(result.events.single.payload['sneakAttackRoll']['rolls'], [1, 1]);
    expect(result.events.single.payload['damage'], 5);
    expect(result.campaign.encounter!.enemyHitPoints, 95);
    expect(result.campaign.encounter!.round, waiting.encounter!.round + 1);
  });

  test('Critical offhand dagger doubles its weapon and Sneak Attack dice', () {
    final engine = _engine();
    final waiting = _offhandAfterPrimaryMiss(
      engine,
      _hero(daggerPrimary: false),
    );
    final result = engine.resolveRoll(waiting, natural: 20);
    expect(result.events.single.payload['damageRoll']['rolls'], [1]);
    expect(result.events.single.payload['criticalExtra']['rolls'], [1]);
    expect(result.events.single.payload['sneakAttackRoll']['rolls'], [
      1,
      1,
      1,
      1,
    ]);
    expect(result.events.single.payload['damage'], 8);
    expect(result.campaign.encounter!.enemyHitPoints, 92);
  });

  test('Critical offhand handaxe still has no Sneak Attack dice', () {
    final engine = _engine();
    final waiting = _offhandAfterPrimaryMiss(
      engine,
      _hero(daggerPrimary: true, daggerOffhand: false),
    );
    final result = engine.resolveRoll(waiting, natural: 20);
    expect(result.events.single.payload['criticalExtra']['rolls'], [1]);
    expect(
      result.events.single.payload.containsKey('sneakAttackRoll'),
      isFalse,
    );
    expect(result.events.single.payload['damage'], 4);
    expect(result.campaign.encounter!.enemyHitPoints, 96);
  });

  test('Miss and cancelled advantage never add offhand Sneak Attack', () {
    final engine = _engine();
    final waiting = _offhandAfterPrimaryMiss(
      engine,
      _hero(daggerPrimary: false),
    );
    final miss = engine.resolveRoll(waiting, natural: 1);
    expect(miss.events.single.payload.containsKey('sneakAttackRoll'), isFalse);
    expect(miss.events.single.payload.containsKey('damage'), isFalse);
    expect(miss.campaign.encounter!.enemyHitPoints, 100);

    final cancelled = _offhandAfterPrimaryMiss(
      engine,
      _hero(daggerPrimary: false),
      disadvantage: true,
    );
    final hit = engine.resolveRoll(cancelled, natural: 15);
    expect(hit.events.single.payload.containsKey('sneakAttackRoll'), isFalse);
    expect(hit.events.single.payload['damage'], 3);
    expect(hit.campaign.encounter!.enemyHitPoints, 97);
  });

  test('Main and offhand share one Sneak Attack use until the next turn', () {
    final engine = _engine();
    final start = _battle(engine, _hero(daggerPrimary: true));
    final primary = _advantage(engine.act(start, 'Ich greife an.').campaign);
    final first = engine.resolveRoll(primary, natural: 15);
    expect(first.events.single.payload['sneakAttackRoll']['rolls'], [1, 1]);
    expect(first.campaign.encounter!.sneakAttackUsedThisTurn, isTrue);
    expect(first.campaign.encounter!.enemyHitPoints, 95);
    final offhand = _advantage(
      engine.act(first.campaign, 'Nebenhandangriff: offhand').campaign,
    );
    final second = engine.resolveRoll(offhand, natural: 15);
    expect(
      second.events.single.payload.containsKey('sneakAttackRoll'),
      isFalse,
    );
    expect(second.events.single.payload['damage'], 3);
    expect(second.campaign.encounter!.enemyHitPoints, 92);
    expect(second.campaign.encounter!.sneakAttackUsedThisTurn, isFalse);
    final nextPrimary = _advantage(
      engine.act(second.campaign, 'Ich greife an.').campaign,
    );
    final nextTurn = engine.resolveRoll(nextPrimary, natural: 15);
    expect(nextTurn.events.single.payload['sneakAttackRoll']['rolls'], [1, 1]);
    expect(nextTurn.campaign.encounter!.enemyHitPoints, 87);
  });

  for (final daggerOffhand in [false, true]) {
    test('Stored offhand ${daggerOffhand ? 'dagger' : 'handaxe'} keeps weapon '
        'eligibility after SQLite reopen and JSON export', () async {
      final engine = _engine();
      final directory = await Directory.systemTemp.createTemp('sneak-weapon-');
      final path = '${directory.path}/campaign.sqlite';
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      GameController? controller;
      try {
        // Model a legacy initial save with an already confirmed pending roll.
        final waiting = _offhandAfterPrimaryMiss(
          engine,
          _hero(daggerPrimary: !daggerOffhand, daggerOffhand: daggerOffhand),
        ).copyWith(revision: 0, events: const []);
        await repository.importCampaign(jsonEncode(waiting.toJson()));
        await repository.saveSettings({'lastCampaignId': waiting.id});
        final exported = await repository.exportCampaign(waiting.id);
        final restoredJson = Campaign.fromJson(
          Map<String, dynamic>.from(jsonDecode(exported)['campaign'] as Map),
        );
        expect(restoredJson.pendingRoll!.weaponId, 'offhand');
        expect(restoredJson.pendingRoll!.advantage, isTrue);
        expect(restoredJson.toJson(), waiting.toJson());
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        controller = GameController(repository: repository, engine: engine);
        await controller.initialize();
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.toJson(), waiting.toJson());
        await controller.resolveRoll(natural: 15);
        expect(controller.error, isNull);
        final saved = (await repository.getCampaign(waiting.id))!;
        expect(saved.revision, 1);
        expect(saved.pendingRoll, isNull);
        expect(saved.events, hasLength(1));
        expect(saved.events.single.payload['offhandWeaponId'], 'offhand');
        expect(
          saved.events.single.payload.containsKey('sneakAttackRoll'),
          daggerOffhand,
        );
        expect(saved.encounter!.enemyHitPoints, daggerOffhand ? 95 : 97);
        expect(controller.currentCampaign!.toJson(), saved.toJson());
        expect(
          (await repository.reconstructCampaign(
            waiting.id,
            revision: 1,
          ))!.toJson(),
          saved.toJson(),
        );
        await controller.resolveRoll(natural: 15);
        expect(controller.error, isNotNull);
        expect(
          (await repository.getCampaign(waiting.id))!.toJson(),
          saved.toJson(),
        );
      } finally {
        controller?.dispose();
        await repository.close();
        await directory.delete(recursive: true);
      }
    });
  }
}
