import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/two_weapon_fighting_rules.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _CountingMinimumRandom implements Random {
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

GameEngine _engine([_CountingMinimumRandom? random]) => GameEngine(
  dice: DiceEngine(random: random ?? _CountingMinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 24),
);

HeroCharacter _hero({
  bool fighter = false,
  bool style = false,
  int strength = 12,
  bool daggerPrimary = false,
  bool handaxeOffhand = false,
}) => HeroCharacter(
  id: 'light-rule-hero',
  name: 'Nara',
  className: fighter ? 'Kämpfer' : 'Schurke',
  level: fighter ? 1 : 3,
  abilities: {
    'strength': strength,
    'dexterity': 18,
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
  features: style ? const ['Kampfstil: Kampf mit zwei Waffen'] : const [],
  inventory: [
    InventoryItem(
      id: 'main',
      name: daggerPrimary ? 'Hauptdolch' : 'Haupthandaxt',
      catalogId: daggerPrimary ? 'weapon-dagger' : 'weapon-handaxe',
    ),
    InventoryItem(
      id: 'offhand',
      name: handaxeOffhand ? 'Nebenhandaxt' : 'Nebendolch',
      catalogId: handaxeOffhand ? 'weapon-handaxe' : 'weapon-dagger',
    ),
  ],
);

Campaign _battle(GameEngine engine, {HeroCharacter? hero}) => engine
    .createDemo(hero: hero ?? _hero())
    .copyWith(
      encounter: const Encounter(
        id: 'light-rule-target',
        enemyName: 'Übungsgegner',
        enemyHitPoints: 100,
        enemyMaxHitPoints: 100,
        enemyArmorClass: 12,
        movementRemaining: 9,
      ),
    );

Campaign _ready(GameEngine engine, {HeroCharacter? hero}) {
  final before = _battle(engine, hero: hero);
  final attack = engine.act(before, 'Ich greife an.').campaign;
  expect(attack.pendingRoll!.type, 'attack');
  final missed = engine.resolveRoll(attack, natural: 1).campaign;
  expect(missed.encounter!.round, before.encounter!.round);
  expect(missed.encounter!.lightAttackAvailable, isTrue);
  expect(missed.encounter!.bonusActionUsed, isFalse);
  expect(TwoWeaponFightingRules.canPrepare(missed), isTrue);
  return missed;
}

GameUpdate _prepare(
  GameEngine engine,
  Campaign campaign, {
  String weaponId = 'offhand',
  String attackAbility = 'dexterity',
  bool proficient = true,
  bool held = true,
  bool approved = true,
}) => engine.prepareOffhandAttack(
  campaign,
  weaponId: weaponId,
  attackAbility: attackAbility,
  weaponProficient: proficient,
  weaponsHeldConfirmed: held,
  playerConfirmed: approved,
);

Future<void> _prepareStored(
  GameController controller,
  Campaign before, {
  bool proficient = true,
  bool held = true,
  bool approved = true,
}) => controller.prepareOffhandAttack(
  campaignId: before.id,
  expectedRevision: before.revision,
  weaponId: 'offhand',
  attackAbility: 'dexterity',
  weaponProficient: proficient,
  weaponsHeldConfirmed: held,
  playerConfirmed: approved,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test('A Rogue gets the Light bonus attack without a Fighter style', () {
    final engine = _engine();
    final before = _ready(engine);
    final prepared = _prepare(engine, before);
    final pending = prepared.campaign.pendingRoll!;
    expect(pending.type, 'offhandAttack');
    expect(pending.weaponId, 'offhand');
    expect(pending.modifier, 6); // Dex4 plus confirmed proficiency2.
    expect(pending.toJson()['offhandAttackAbility'], 'dexterity');
    expect(pending.toJson()['offhandWeaponProficient'], isTrue);
    expect(pending.toJson()['offhandWeaponsHeldConfirmed'], isTrue);
    expect(prepared.campaign.encounter!.bonusActionUsed, isTrue);
    expect(prepared.campaign.hero.toJson(), before.hero.toJson());
    expect(prepared.campaign.encounter!.enemyHitPoints, 100);
    expect(TwoWeaponFightingRules.canPrepare(prepared.campaign), isFalse);

    final hit = engine.resolveRoll(prepared.campaign, natural: 15);
    expect(hit.events.single.payload['offhandWeaponId'], 'offhand');
    expect(hit.events.single.payload['damage'], 1); // No positive damage bonus.
    expect(hit.campaign.encounter!.enemyHitPoints, 99);
    expect(hit.campaign.encounter!.round, before.encounter!.round + 1);
    expect(hit.campaign.encounter!.lightAttackAvailable, isFalse);
  });

  test(
    'Finesse choice and explicit proficiency are independent of primary',
    () {
      final engine = _engine();
      final before = _ready(engine);
      expect(before.hero.weaponAbility, 'strength');
      final untrained = _prepare(engine, before, proficient: false).campaign;
      final strength = _prepare(
        engine,
        before,
        attackAbility: 'strength',
        proficient: true,
      ).campaign;
      expect(untrained.pendingRoll!.modifier, 4);
      expect(
        untrained.pendingRoll!.toJson()['offhandWeaponProficient'],
        isFalse,
      );
      expect(strength.pendingRoll!.modifier, 3);
      expect(
        Campaign.fromJson(untrained.toJson()).pendingRoll!.toJson(),
        untrained.pendingRoll!.toJson(),
      );
      expect(
        engine
            .resolveRoll(untrained, natural: 15)
            .events
            .single
            .payload['damage'],
        1,
      );
      expect(before.hero.weaponAbility, 'strength');
    },
  );

  test('Light critical doubles dice but omits a positive ability bonus', () {
    final engine = _engine();
    final waiting = _prepare(engine, _ready(engine)).campaign;
    final critical = engine.resolveRoll(waiting, natural: 20);
    expect(critical.events.single.payload['damageRoll']['rolls'], [1]);
    expect(critical.events.single.payload['criticalExtra']['rolls'], [1]);
    expect(critical.events.single.payload['damage'], 2);
    expect(critical.campaign.encounter!.enemyHitPoints, 98);
  });

  test('Negative ability modifier is retained once, including a critical', () {
    final engine = _engine();
    final before = _ready(engine, hero: _hero(strength: 8));
    final waiting = _prepare(
      engine,
      before,
      attackAbility: 'strength',
    ).campaign;
    expect(waiting.pendingRoll!.modifier, 1);
    final hit = engine.resolveRoll(waiting, natural: 15);
    expect(hit.events.single.payload['damage'], 0);
    expect(hit.campaign.encounter!.enemyHitPoints, 100);
    final critical = engine.resolveRoll(waiting, natural: 20);
    expect(critical.events.single.payload['damage'], 1);
    expect(critical.campaign.encounter!.enemyHitPoints, 99);
  });

  test('Fighter style adds the selected ability once to Light damage', () {
    final engine = _engine();
    final before = _ready(engine, hero: _hero(fighter: true, style: true));
    final waiting = _prepare(engine, before).campaign;
    final hit = engine.resolveRoll(waiting, natural: 15);
    expect(hit.events.single.payload['damage'], 5);
    final critical = engine.resolveRoll(waiting, natural: 20);
    expect(critical.events.single.payload['damage'], 6);
    expect(critical.campaign.encounter!.enemyHitPoints, 94);
  });

  test('Dexterity offhand never borrows Rage from a Strength primary', () {
    final engine = _engine();
    final barbarian = _hero(strength: 14).copyWith(
      className: 'Barbar',
      level: 4,
      secondaryClassName: 'Schurke',
      secondaryClassLevel: 1,
      spentClassResources: const {'rage': 1},
    );
    final before = _ready(engine, hero: barbarian);
    // Previously confirmed Rage persists into a turn with a free Bonus Action.
    final raging = before.copyWith(
      encounter: before.encounter!.copyWith(
        rageStartedRound: before.encounter!.round,
        rageUntilRound: before.encounter!.round + 1,
      ),
    );
    expect(raging.hero.weaponAbility, 'strength');
    final waiting = _prepare(engine, raging).campaign;
    expect(waiting.pendingRoll!.toJson()['offhandAttackAbility'], 'dexterity');
    final hit = engine.resolveRoll(waiting, natural: 15);
    expect(hit.events.single.payload.containsKey('rageDamageBonus'), isFalse);
    expect(hit.events.single.payload['damage'], 1);
    expect(hit.campaign.encounter!.enemyHitPoints, 99);
  });

  test('Strength offhand receives Rage despite a Dexterity primary', () {
    final engine = _engine();
    final barbarian =
        _hero(strength: 14, daggerPrimary: true, handaxeOffhand: true).copyWith(
          className: 'Barbar',
          level: 4,
          secondaryClassName: 'Schurke',
          secondaryClassLevel: 1,
          spentClassResources: const {'rage': 1},
        );
    final before = _ready(engine, hero: barbarian);
    final raging = before.copyWith(
      encounter: before.encounter!.copyWith(
        rageStartedRound: before.encounter!.round,
        rageUntilRound: before.encounter!.round + 1,
      ),
    );
    expect(raging.hero.weaponAbility, 'dexterity');
    final waiting = _prepare(
      engine,
      raging,
      attackAbility: 'strength',
    ).campaign;
    expect(waiting.pendingRoll!.modifier, 4);
    final hit = engine.resolveRoll(waiting, natural: 15);
    expect(hit.events.single.payload['rageDamageBonus'], 2);
    expect(hit.events.single.payload['damage'], 3);
    expect(hit.campaign.encounter!.enemyHitPoints, 97);
  });

  test('Negative Light damage is floored after Rage, including a critical', () {
    for (final natural in [15, 20]) {
      final engine = _engine();
      final hero = _hero(
        strength: 4,
      ).copyWith(className: 'Barbar', spentClassResources: const {'rage': 1});
      final before = _ready(engine, hero: hero);
      final raging = before.copyWith(
        encounter: before.encounter!.copyWith(
          rageStartedRound: before.encounter!.round,
          rageUntilRound: before.encounter!.round + 1,
        ),
      );
      final waiting = _prepare(
        engine,
        raging,
        attackAbility: 'strength',
      ).campaign;
      final hit = engine.resolveRoll(waiting, natural: natural);
      expect(hit.events.single.payload['rageDamageBonus'], 2);
      expect(hit.events.single.payload['damage'], natural == 20 ? 1 : 0);
      expect(hit.campaign.encounter!.enemyHitPoints, natural == 20 ? 99 : 100);
    }
  });

  test('Negative subtotal includes Sneak dice before the zero floor', () {
    for (final offhand in [false, true]) {
      final engine = _engine();
      final hero = _hero(
        strength: 4,
        daggerPrimary: true,
      ).copyWith(weaponAbility: 'strength');
      final waiting = offhand
          ? _prepare(
              engine,
              _ready(engine, hero: hero),
              attackAbility: 'strength',
            ).campaign
          : engine.act(_battle(engine, hero: hero), 'Ich greife an.').campaign;
      final confirmed = engine
          .confirmSneakAttackAlly(
            waiting,
            rollId: waiting.pendingRoll!.id,
            allyName: 'Bestätigter Verbündeter',
            withinFiveFeetOfTargetConfirmed: true,
            notIncapacitatedConfirmed: true,
          )
          .campaign;
      final hit = engine.resolveRoll(confirmed, natural: 15);
      expect(hit.events.single.payload['sneakAttackRoll']['rolls'], [1, 1]);
      expect(hit.events.single.payload['damage'], 0);
      expect(hit.campaign.encounter!.enemyHitPoints, 100);
    }
  });

  test('Miss consumes the bonus opportunity but deals no damage', () {
    final engine = _engine();
    final before = _ready(engine);
    final waiting = _prepare(engine, before).campaign;
    final missed = engine.resolveRoll(waiting, natural: 1);
    expect(missed.events.single.payload.containsKey('damage'), isFalse);
    expect(missed.campaign.encounter!.enemyHitPoints, 100);
    expect(TwoWeaponFightingRules.canPrepare(missed.campaign), isFalse);
    expect(() => _prepare(engine, waiting), throwsFormatException);
    expect(() => _prepare(engine, missed.campaign), throwsFormatException);
    final nextPrimary = engine.act(missed.campaign, 'Ich greife an.').campaign;
    final nextMiss = engine.resolveRoll(nextPrimary, natural: 1).campaign;
    expect(nextMiss.encounter!.round, missed.campaign.encounter!.round);
    expect(nextMiss.encounter!.lightAttackAvailable, isTrue);
    expect(TwoWeaponFightingRules.canPrepare(nextMiss), isTrue);
  });

  test('Refused or incomplete consent never reserves a bonus or rolls', () {
    final random = _CountingMinimumRandom();
    final engine = _engine(random);
    final before = _ready(engine);
    final snapshot = jsonEncode(before.toJson());
    final calls = random.calls;
    expect(() => _prepare(engine, before, held: false), throwsFormatException);
    expect(
      () => _prepare(engine, before, approved: false),
      throwsFormatException,
    );
    expect(
      () => _prepare(engine, before, weaponId: 'main'),
      throwsFormatException,
    );
    expect(
      () => _prepare(engine, before, weaponId: 'missing'),
      throwsFormatException,
    );
    expect(
      () => _prepare(engine, before, attackAbility: 'wisdom'),
      throwsFormatException,
    );
    expect(random.calls, calls);
    expect(jsonEncode(before.toJson()), snapshot);
    expect(before.encounter!.bonusActionUsed, isFalse);
  });

  test('Invalid turn, resources, known health or weapon cannot prepare', () {
    final random = _CountingMinimumRandom();
    final engine = _engine(random);
    final before = _ready(engine);
    final calls = random.calls;
    for (final invalid in [
      before.copyWith(
        encounter: before.encounter!.copyWith(activeParticipant: 'enemy'),
      ),
      before.copyWith(
        encounter: before.encounter!.copyWith(bonusActionUsed: true),
      ),
      before.copyWith(
        encounter: before.encounter!.copyWith(lightAttackAvailable: false),
      ),
      before.copyWith(encounter: before.encounter!.copyWith(actionUsed: false)),
      before.copyWith(
        encounter: before.encounter!.copyWith(attacksRemaining: 1),
      ),
      before.copyWith(
        encounter: before.encounter!.copyWith(surgeReserved: true),
      ),
      before.copyWith(encounter: before.encounter!.copyWith(enemyHitPoints: 0)),
      before.copyWith(hero: before.hero.copyWith(hitPoints: 0)),
      before.copyWith(hero: before.hero.copyWith(hitPoints: null)),
      before.copyWith(
        hero: before.hero.copyWith(conditions: ['handlungsunfähig']),
      ),
      before.copyWith(hero: before.hero.copyWith(equippedShieldId: 'shield')),
      before.copyWith(
        hero: before.hero.copyWith(inventory: [before.hero.inventory.first]),
      ),
    ]) {
      expect(TwoWeaponFightingRules.canPrepare(invalid), isFalse);
      expect(() => _prepare(engine, invalid), throwsFormatException);
    }
    final axe = _ready(engine, hero: _hero(handaxeOffhand: true));
    expect(() => _prepare(engine, axe), throwsFormatException);
    expect(random.calls, calls);
  });

  test('Pure Rogue Light attack composes with explicit ally Sneak Attack', () {
    final engine = _engine();
    final waiting = _prepare(engine, _ready(engine)).campaign;
    final confirmed = engine
        .confirmSneakAttackAlly(
          waiting,
          rollId: waiting.pendingRoll!.id,
          allyName: 'Mira',
          withinFiveFeetOfTargetConfirmed: true,
          notIncapacitatedConfirmed: true,
        )
        .campaign;
    final hit = engine.resolveRoll(confirmed, natural: 15);
    expect(hit.events.single.payload['sneakAttackRoll']['rolls'], [1, 1]);
    expect(hit.events.single.payload['damage'], 3);
    expect(hit.campaign.encounter!.enemyHitPoints, 97);
  });

  test(
    'New context fails closed and legacy Fighter pending remains readable',
    () {
      final engine = _engine();
      final waiting = _prepare(
        engine,
        _ready(engine),
        proficient: false,
      ).campaign;
      for (final patch in [
        {'offhandAttackAbility': null},
        {'offhandWeaponProficient': null},
        {'offhandWeaponsHeldConfirmed': null},
        {'offhandWeaponProficient': 'true'},
        {'offhandWeaponsHeldConfirmed': false},
        {'offhandAttackAbility': 'intelligence'},
        {'modifier': 90},
        {'weaponId': 'main'},
        {'weaponId': 'missing'},
        {'targetId': 'other-target'},
      ]) {
        final data = waiting.toJson();
        final pending = data['pendingRoll'] as Map<String, dynamic>;
        pending.addAll(patch);
        expect(
          () => Campaign.fromJson(data),
          throwsFormatException,
          reason: '$patch',
        );
      }
      final original = _prepare(
        engine,
        _ready(engine, hero: _hero(fighter: true, style: true)),
        attackAbility: 'strength',
      ).campaign;
      final old = original.toJson();
      final pending = old['pendingRoll'] as Map<String, dynamic>;
      pending.remove('offhandAttackAbility');
      pending.remove('offhandWeaponProficient');
      pending.remove('offhandWeaponsHeldConfirmed');
      final restored = Campaign.fromJson(old);
      expect(restored.pendingRoll!.modifier, 3);
      expect(
        engine
            .resolveRoll(restored, natural: 15)
            .events
            .single
            .payload['damage'],
        2,
      );

      final forgedLegacy = waiting.toJson();
      final legacy = forgedLegacy['pendingRoll'] as Map<String, dynamic>;
      legacy.remove('offhandAttackAbility');
      legacy.remove('offhandWeaponProficient');
      legacy.remove('offhandWeaponsHeldConfirmed');
      expect(() => Campaign.fromJson(forgedLegacy), throwsFormatException);
    },
  );

  test('A stale pending modifier is rejected before drawing random damage', () {
    final random = _CountingMinimumRandom();
    final engine = _engine(random);
    final waiting = _prepare(engine, _ready(engine)).campaign;
    final pending = PendingRoll.fromJson({
      ...waiting.pendingRoll!.toJson(),
      'modifier': 17,
    });
    final forged = waiting.copyWith(pendingRoll: pending);
    final calls = random.calls;
    expect(() => engine.resolveRoll(forged), throwsFormatException);
    expect(random.calls, calls);
    expect(waiting.encounter!.enemyHitPoints, 100);
  });

  test(
    'Explicit context survives backup, SQLite reopen and reconstruction',
    () async {
      final directory = await Directory.systemTemp.createTemp('light-bonus-');
      final path = '${directory.path}/campaign.sqlite';
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final engine = _engine();
      GameController? controller;
      try {
        final ready = _ready(engine).copyWith(revision: 0, events: const []);
        await repository.importCampaign(jsonEncode(ready.toJson()));
        controller = GameController(repository: repository, engine: engine);
        await controller.openCampaign(ready.id);
        final before = controller.currentCampaign!;
        await _prepareStored(controller, before, proficient: false);
        expect(controller.error, isNull);
        final prepared = controller.currentCampaign!;
        expect(prepared.revision, before.revision + 1);
        expect(prepared.pendingRoll!.modifier, 4);
        expect(
          prepared.pendingRoll!.toJson()['offhandWeaponProficient'],
          isFalse,
        );
        final exported = await repository.exportCampaign(before.id);
        final imported = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        );
        try {
          expect(
            (await imported.importCampaign(exported)).pendingRoll!.toJson(),
            prepared.pendingRoll!.toJson(),
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
        expect(
          controller.currentCampaign!.pendingRoll!.toJson(),
          prepared.pendingRoll!.toJson(),
        );
        await controller.resolveRoll(natural: 15);
        expect(controller.error, isNull);
        final saved = (await repository.getCampaign(before.id))!;
        expect(saved.revision, before.revision + 2);
        expect(saved.pendingRoll, isNull);
        expect(saved.encounter!.enemyHitPoints, 99);
        expect(saved.events.last.payload['damage'], 1);
        expect(
          (await repository.reconstructCampaign(before.id))!.toJson(),
          saved.toJson(),
        );
        await controller.resolveRoll(natural: 15);
        expect(controller.error, isNotNull);
        expect(
          (await repository.getCampaign(before.id))!.toJson(),
          saved.toJson(),
        );
      } finally {
        controller?.dispose();
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'Stale controller cannot reserve the same Light opportunity twice',
    () async {
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      final engine = _engine();
      final first = GameController(repository: repository, engine: engine);
      final second = GameController(repository: repository, engine: engine);
      try {
        final ready = _ready(engine).copyWith(revision: 0, events: const []);
        await repository.importCampaign(jsonEncode(ready.toJson()));
        await first.openCampaign(ready.id);
        await second.openCampaign(ready.id);
        final old = second.currentCampaign!;
        await _prepareStored(first, first.currentCampaign!);
        expect(first.error, isNull);
        final saved = (await repository.getCampaign(ready.id))!;
        await _prepareStored(second, old);
        expect(second.error, isNotNull);
        expect(
          (await repository.getCampaign(ready.id))!.toJson(),
          saved.toJson(),
        );
        expect(saved.events, hasLength(1));
        expect(saved.encounter!.bonusActionUsed, isTrue);
        expect(saved.pendingRoll!.weaponId, 'offhand');
      } finally {
        first.dispose();
        second.dispose();
        await repository.close();
      }
    },
  );

  test(
    'Late event failure rolls back pending context and bonus reservation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'light-rollback-',
      );
      final path = '${directory.path}/campaign.sqlite';
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final engine = _engine();
      final controller = GameController(repository: repository, engine: engine);
      final diagnostic = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        final ready = _ready(engine).copyWith(revision: 0, events: const []);
        await repository.importCampaign(jsonEncode(ready.toJson()));
        await controller.openCampaign(ready.id);
        final before = controller.currentCampaign!;
        await diagnostic.execute(
          "CREATE TRIGGER reject_light_bonus BEFORE INSERT ON game_events BEGIN SELECT RAISE(ABORT, 'test storage failure'); END",
        );
        await _prepareStored(controller, before);
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect(
          (await repository.getCampaign(before.id))!.toJson(),
          before.toJson(),
        );
        final reconstructed = (await repository.reconstructCampaign(
          before.id,
        ))!;
        expect(reconstructed.pendingRoll, isNull);
        expect(reconstructed.encounter!.bonusActionUsed, isFalse);
        await diagnostic.execute('DROP TRIGGER reject_light_bonus');
        await _prepareStored(controller, before);
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.pendingRoll!.weaponId, 'offhand');
        expect(controller.currentCampaign!.revision, before.revision + 1);
      } finally {
        controller.dispose();
        await diagnostic.close();
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
