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
import 'package:lebendiger_spielleiter/story/story_rule_boundary.dart';

class _MinimumRandom implements Random {
  var calls = 0;
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

HeroCharacter _rogue({
  String catalogId = 'weapon-dagger',
  List<String> conditions = const [],
}) => HeroCharacter(
  id: 'rogue',
  name: 'Nara',
  className: 'Schurke',
  level: 8,
  secondaryClassName: 'Kämpfer',
  secondaryClassLevel: 5,
  abilities: {
    for (final ability in abilityNames)
      ability: ability == 'dexterity' ? 16 : 14,
  },
  hitPoints: 40,
  maxHitPoints: 40,
  armorClass: 15,
  speed: 9,
  weaponDamage: '1d4',
  weaponAbility: 'dexterity',
  weaponProficient: true,
  equippedWeaponId: 'dagger',
  conditions: conditions,
  inventory: [
    InventoryItem(id: 'dagger', name: 'Bestätigte Waffe', catalogId: catalogId),
  ],
);

Campaign _baseGame(GameEngine engine, {HeroCharacter? hero}) => engine
    .createDemo(hero: hero ?? _rogue())
    .copyWith(
      encounter: const Encounter(
        id: 'rogue-fight',
        enemyName: 'Übungsgegner',
        enemyHitPoints: 100,
        enemyMaxHitPoints: 100,
        enemyArmorClass: 12,
        movementRemaining: 9,
      ),
    );

Campaign _waiting(GameEngine engine, {HeroCharacter? hero}) =>
    engine.act(_baseGame(engine, hero: hero), 'Ich greife an.').campaign;

Future<Campaign> _storedWaiting(
  GameEngine engine,
  SqliteCampaignRepository repository,
) async {
  final initial = _baseGame(engine);
  await repository.saveCampaign(initial, events: initial.events);
  final request = engine.act(initial, 'Ich greife an.');
  await repository.saveCampaign(
    request.campaign,
    events: request.events,
    expectedRevision: initial.revision,
  );
  return request.campaign;
}

GameUpdate _prepare(
  GameEngine engine,
  Campaign campaign, {
  String name = 'Liora',
  bool near = true,
  bool canAct = true,
}) => engine.confirmSneakAttackAlly(
  campaign,
  rollId: campaign.pendingRoll!.id,
  allyName: name,
  withinFiveFeetOfTargetConfirmed: near,
  notIncapacitatedConfirmed: canAct,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test('confirmation changes only this pending request and rolls no dice', () {
    final random = _MinimumRandom();
    final engine = GameEngine(dice: DiceEngine(random: random));
    final waiting = _waiting(engine);
    final priorCalls = random.calls;
    final update = _prepare(engine, waiting, name: '  Liora  ');
    expect(random.calls, priorCalls);
    expect(update.campaign.hero.toJson(), waiting.hero.toJson());
    expect(update.campaign.encounter!.toJson(), waiting.encounter!.toJson());
    expect(update.campaign.pendingRoll!.id, waiting.pendingRoll!.id);
    expect(update.campaign.pendingRoll!.sneakAttackAlly!.allyName, 'Liora');
    expect(update.events.single.type, 'combat.sneakAttackAllyConfirmed');
    expect(update.events.single.payload['rollId'], waiting.pendingRoll!.id);
  });

  test('confirmed ally gives real extra damage once per own turn', () {
    final engine = GameEngine(dice: DiceEngine(random: _MinimumRandom()));
    final prepared = _prepare(engine, _waiting(engine)).campaign;
    final hit = engine.resolveRoll(prepared, natural: 15);
    expect(hit.events.single.payload['sneakAttackRoll']['rolls'], [1, 1]);
    expect(hit.events.single.payload['damage'], 6); // weapon1 + Dex3 + Sneak2.
    expect(hit.campaign.encounter!.enemyHitPoints, 94);
    expect(hit.campaign.encounter!.sneakAttackUsedThisTurn, isTrue);
    expect(hit.campaign.pendingRoll, isNull);
    expect(hit.events.single.payload['sneakAttackAlly']['allyName'], 'Liora');
    final second = engine.act(hit.campaign, 'Ich greife an.').campaign;
    expect(second.pendingRoll!.sneakAttackAlly, isNull);
    expect(SneakAttackAllyRules.canPrepare(second), isFalse);
    expect(() => _prepare(engine, second), throwsFormatException);
    final secondHit = engine.resolveRoll(second, natural: 15);
    expect(
      secondHit.events.single.payload.containsKey('sneakAttackRoll'),
      isFalse,
    );
  });

  test(
    'critical doubles Sneak Attack dice; miss consumes no feature and no confirmation survives',
    () {
      final engine = GameEngine(dice: DiceEngine(random: _MinimumRandom()));
      final waiting = _waiting(engine);
      final critical = engine.resolveRoll(
        _prepare(engine, waiting).campaign,
        natural: 20,
      );
      expect(critical.events.single.payload['sneakAttackRoll']['rolls'], [
        1,
        1,
        1,
        1,
      ]);
      expect(critical.events.single.payload['damage'], 9);
      final miss = engine.resolveRoll(
        _prepare(engine, waiting).campaign,
        natural: 1,
      );
      expect(miss.campaign.encounter!.sneakAttackUsedThisTurn, isFalse);
      expect(
        miss.events.single.payload.containsKey('sneakAttackRoll'),
        isFalse,
      );
      final nextAttack = engine.act(miss.campaign, 'Ich greife an.').campaign;
      expect(nextAttack.pendingRoll!.sneakAttackAlly, isNull);
      expect(nextAttack.pendingRoll!.id, isNot(waiting.pendingRoll!.id));
      expect(SneakAttackAllyRules.canPrepare(nextAttack), isTrue);
    },
  );

  test(
    'clearing a confirmation keeps the pending roll and prevents ally damage',
    () {
      final engine = GameEngine(dice: DiceEngine(random: _MinimumRandom()));
      final prepared = _prepare(engine, _waiting(engine)).campaign;
      final cleared = engine.clearSneakAttackAlly(
        prepared,
        rollId: prepared.pendingRoll!.id,
      );
      expect(cleared.campaign.pendingRoll!.sneakAttackAlly, isNull);
      final hit = engine.resolveRoll(cleared.campaign, natural: 15);
      expect(hit.events.single.payload['damage'], 4);
      expect(hit.events.single.payload.containsKey('sneakAttackRoll'), isFalse);
      expect(
        () => engine.clearSneakAttackAlly(
          cleared.campaign,
          rollId: prepared.pendingRoll!.id,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'missing observations, invalid source and stale roll are rejected before randomness',
    () {
      final random = _MinimumRandom();
      final engine = GameEngine(dice: DiceEngine(random: random));
      final waiting = _waiting(engine);
      final priorCalls = random.calls;
      for (final facts in [
        (near: false, canAct: true),
        (near: true, canAct: false),
        (near: false, canAct: false),
      ]) {
        expect(
          () =>
              _prepare(engine, waiting, near: facts.near, canAct: facts.canAct),
          throwsFormatException,
        );
      }
      for (final name in ['', ' ', 'Liora\nNara', 'x' * 121]) {
        expect(
          () => _prepare(engine, waiting, name: name),
          throwsFormatException,
        );
      }
      expect(
        () => engine.confirmSneakAttackAlly(
          waiting,
          rollId: 'old-roll',
          allyName: 'Liora',
          withinFiveFeetOfTargetConfirmed: true,
          notIncapacitatedConfirmed: true,
        ),
        throwsFormatException,
      );
      expect(random.calls, priorCalls);
    },
  );

  test(
    'unknown weapons, non-Rogues, disadvantage, wrong turn and death cannot prepare',
    () {
      final engine = GameEngine(dice: DiceEngine(random: _MinimumRandom()));
      final waiting = _waiting(engine);
      for (final campaign in [
        _waiting(engine, hero: _rogue(catalogId: 'weapon-club')),
        _waiting(engine, hero: _rogue(conditions: ['vergiftet'])),
        waiting.copyWith(
          hero: waiting.hero.copyWith(
            className: 'Kämpfer',
            secondaryClassName: '',
            secondaryClassLevel: 0,
          ),
        ),
        waiting.copyWith(
          encounter: waiting.encounter!.copyWith(activeParticipant: 'enemy'),
        ),
        waiting.copyWith(hero: waiting.hero.copyWith(hitPoints: 0)),
        waiting.copyWith(pendingRoll: null),
      ]) {
        expect(SneakAttackAllyRules.canPrepare(campaign), isFalse);
        expect(
          () => engine.confirmSneakAttackAlly(
            campaign,
            rollId: waiting.pendingRoll!.id,
            allyName: 'Liora',
            withinFiveFeetOfTargetConfirmed: true,
            notIncapacitatedConfirmed: true,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'old pending JSON stays unchanged; forged binding, turn and observation imports fail closed',
    () {
      final engine = GameEngine();
      final old = _waiting(engine);
      expect(
        Campaign.fromJson(old.toJson()).pendingRoll!.toJson(),
        old.pendingRoll!.toJson(),
      );
      final prepared = _prepare(engine, old).campaign;
      expect(
        Campaign.fromJson(prepared.toJson()).pendingRoll!.toJson(),
        prepared.pendingRoll!.toJson(),
      );
      for (final forged in [
        {'campaignId': 'other'},
        {'rollId': 'other'},
        {'targetId': 'other'},
        {'withinFiveFeetOfTargetConfirmed': false},
        {'notIncapacitatedConfirmed': null},
        {'schemaVersion': 2},
        {'bonusDamage': 999},
      ]) {
        final json = prepared.toJson();
        final pending = json['pendingRoll'] as Map<String, dynamic>;
        pending['sneakAttackAlly'] = {
          ...pending['sneakAttackAlly'] as Map<String, dynamic>,
          ...forged,
        };
        expect(
          () => Campaign.fromJson(json),
          throwsFormatException,
          reason: '$forged',
        );
      }
      final consumed = prepared.copyWith(
        encounter: prepared.encounter!.copyWith(sneakAttackUsedThisTurn: true),
      );
      expect(() => Campaign.fromJson(consumed.toJson()), throwsFormatException);
      final random = _MinimumRandom();
      expect(
        () => GameEngine(
          dice: DiceEngine(random: random),
        ).resolveRoll(consumed, natural: 15),
        throwsFormatException,
      );
      expect(random.calls, 0);
    },
  );

  test('narration and story boundary never confirm ally facts', () {
    final engine = GameEngine();
    final waiting = _waiting(engine);
    final story = engine.act(
      waiting,
      'Liora steht neben dem Ziel und ist nicht handlungsunfähig.',
    );
    expect(story.campaign.pendingRoll!.sneakAttackAlly, isNull);
    expect(
      () => StoryRuleBoundary.ensureRuleStateUnchanged(
        waiting,
        _prepare(engine, waiting).campaign,
      ),
      throwsFormatException,
    );
  });

  test(
    'multiclass Archery pending attack survives authoritative bonus validation',
    () {
      final engine = GameEngine();
      final hero = _rogue(
        catalogId: 'weapon-longbow',
      ).copyWith(weaponDamage: '1d8', features: ['Kampfstil: Bogenschießen']);
      final waiting = _waiting(engine, hero: hero);
      expect(
        waiting.pendingRoll!.modifier,
        8,
      ); // Dex3 + proficiency3 + Archery2.
      expect(Campaign.fromJson(waiting.toJson()).pendingRoll!.modifier, 8);
      expect(
        Campaign.fromJson(
          _prepare(engine, waiting).campaign.toJson(),
        ).pendingRoll!.sneakAttackAlly,
        isNotNull,
      );
    },
  );

  test(
    'SQLite restart, backup and event reconstruction retain one-shot confirmation',
    () async {
      final directory = await Directory.systemTemp.createTemp('sneak-ally-');
      final path = '${directory.path}/campaign.sqlite';
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var controller = GameController(
        repository: repository,
        engine: GameEngine(dice: DiceEngine(random: _MinimumRandom())),
      );
      addTearDown(() async {
        controller.dispose();
        await repository.close();
        await directory.delete(recursive: true);
      });
      final game = await _storedWaiting(controller.engine, repository);
      await controller.openCampaign(game.id);
      final before = controller.currentCampaign!;
      await controller.confirmSneakAttackAlly(
        campaignId: before.id,
        expectedRevision: before.revision,
        rollId: before.pendingRoll!.id,
        allyName: 'Liora',
        withinFiveFeetOfTargetConfirmed: true,
        notIncapacitatedConfirmed: true,
      );
      expect(controller.error, isNull);
      final prepared = controller.currentCampaign!;
      await controller.confirmSneakAttackAlly(
        campaignId: before.id,
        expectedRevision: before.revision,
        rollId: before.pendingRoll!.id,
        allyName: 'Andere',
        withinFiveFeetOfTargetConfirmed: true,
        notIncapacitatedConfirmed: true,
      );
      expect(controller.error, contains('geändert'));
      expect(controller.currentCampaign!.toJson(), prepared.toJson());
      final backup = await repository.exportCampaign(game.id);
      final importedRepo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      addTearDown(importedRepo.close);
      expect(
        (await importedRepo.importCampaign(backup)).pendingRoll!.toJson(),
        prepared.pendingRoll!.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(game.id))!.pendingRoll!.toJson(),
        prepared.pendingRoll!.toJson(),
      );
      controller.dispose();
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(
        repository: repository,
        engine: GameEngine(dice: DiceEngine(random: _MinimumRandom())),
      );
      await controller.openCampaign(game.id);
      expect(
        controller.currentCampaign!.pendingRoll!.sneakAttackAlly!.allyName,
        'Liora',
      );
      await controller.resolveRoll(natural: 15);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.encounter!.enemyHitPoints, 94);
      expect(controller.currentCampaign!.pendingRoll, isNull);
      expect(
        (await repository.getCampaign(
          game.id,
        ))!.events.last.payload['sneakAttackRoll']['rolls'],
        [1, 1],
      );
    },
  );

  test(
    'late event storage failure rolls back confirmation and controller state',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'sneak-rollback-',
      );
      final path = '${directory.path}/campaign.sqlite';
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final controller = GameController(repository: repository);
      final diagnostic = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(() async {
        controller.dispose();
        await diagnostic.close();
        await repository.close();
        await directory.delete(recursive: true);
      });
      final game = await _storedWaiting(controller.engine, repository);
      await controller.openCampaign(game.id);
      final before = controller.currentCampaign!;
      await diagnostic.execute(
        "CREATE TRIGGER reject_sneak_event BEFORE INSERT ON game_events BEGIN SELECT RAISE(ABORT, 'test storage failure'); END",
      );
      await controller.confirmSneakAttackAlly(
        campaignId: before.id,
        expectedRevision: before.revision,
        rollId: before.pendingRoll!.id,
        allyName: 'Liora',
        withinFiveFeetOfTargetConfirmed: true,
        notIncapacitatedConfirmed: true,
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), before.toJson());
      expect(
        (await repository.getCampaign(before.id))!.toJson(),
        before.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(
          before.id,
        ))!.pendingRoll!.sneakAttackAlly,
        isNull,
      );
      await diagnostic.execute('DROP TRIGGER reject_sneak_event');
      await controller.confirmSneakAttackAlly(
        campaignId: before.id,
        expectedRevision: before.revision,
        rollId: before.pendingRoll!.id,
        allyName: 'Liora',
        withinFiveFeetOfTargetConfirmed: true,
        notIncapacitatedConfirmed: true,
      );
      expect(controller.error, isNull);
    },
  );
}
