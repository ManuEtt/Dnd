import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_eldritch_blast_rules.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _Rolls implements Random {
  _Rolls(this.values);
  final List<int> values;
  int calls = 0;

  @override
  int nextInt(int max) {
    final value = values[calls++];
    if (value < 0 || value >= max) {
      throw RangeError.value(value, 'roll');
    }
    return value;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({int level = 5}) => HeroCharacter(
  id: 'eb-hero',
  name: 'Arkan',
  className: 'Hexenmeister',
  level: level,
  spells: const ['Eldritch Blast'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 10,
    'charisma': 18,
  },
  hitPoints: 22,
  maxHitPoints: 22,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d4',
);

Encounter _encounter({
  int hp = 50,
  CoverLevel cover = CoverLevel.none,
  EnemyForceDefense defense = EnemyForceDefense.normal,
  bool actionUsed = false,
}) => Encounter(
  id: 'eb-foe',
  enemyName: 'Gegner',
  enemyHitPoints: hp,
  enemyMaxHitPoints: 50,
  enemyArmorClass: 14,
  enemyCover: cover,
  enemyForceDefense: defense,
  actionUsed: actionUsed,
);

Campaign _campaign(GameEngine engine, {Encounter? encounter}) =>
    engine.createDemo().copyWith(
      hero: _hero(),
      encounter: encounter ?? _encounter(),
    );

List<SrdEldritchBlastTarget> _targets({
  String targetId = 'eb-foe',
  int count = 2,
  int ac = 14,
  CoverLevel cover = CoverLevel.none,
  int distanceFeet = 40,
}) => [
  for (var i = 0; i < count; i++)
    SrdEldritchBlastTarget(
      targetId: targetId,
      distanceFeet: distanceFeet,
      baseArmorClass: ac,
      cover: cover,
      creatureOrObjectConfirmed: true,
      clearPathConfirmed: true,
      coverCircumstancesConfirmed: true,
      attackCircumstancesConfirmed: true,
      sourceOppositeCover: true,
    ),
];

GameUpdate _cast(
  GameEngine engine,
  Campaign campaign, {
  List<SrdEldritchBlastTarget>? declaredBeams,
  bool singleEnemyConfirmed = true,
  bool verbal = true,
  bool somatic = true,
  bool modifiersConfirmed = true,
  bool shieldCleared = true,
  bool circumstancesConfirmed = true,
}) => engine.castEldritchBlastSingleEnemy(
  campaign,
  declaredBeams: declaredBeams ?? _targets(),
  currentEnemyIsOnlyTargetConfirmed: singleEnemyConfirmed,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
  noUnmodelledAttackOrDamageModifiersConfirmed: modifiersConfirmed,
  noUnresolvedShieldReactionConfirmed: shieldCleared,
  situationalAttackConditionsConfirmed: circumstancesConfirmed,
);

Future<void> _controllerCast(
  GameController controller,
  Campaign campaign, {
  List<SrdEldritchBlastTarget>? beams,
}) => controller.castEldritchBlastSingleEnemy(
  campaignId: campaign.id,
  expectedRevision: campaign.revision,
  declaredBeams: beams ?? _targets(),
  currentEnemyIsOnlyTargetConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noUnmodelledAttackOrDamageModifiersConfirmed: true,
  noUnresolvedShieldReactionConfirmed: true,
  situationalAttackConditionsConfirmed: true,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test('two beams resolve once, spend one action and no spell slots', () {
    final rng = _Rolls([9, 3, 2]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final before = _campaign(engine);
    final update = _cast(engine, before);
    expect(update.events, hasLength(1));
    expect(update.events.single.type, 'spell.eldritchBlast');
    final payload = update.events.single.payload;
    expect(payload['beamCount'], 2);
    expect(payload['beams'], hasLength(2));
    expect(payload['beams'][0]['attackRoll']['natural'], 10);
    expect(payload['beams'][0]['appliedForceDamage'], 4);
    expect(payload['beams'][1]['attackRoll']['natural'], 3);
    expect(payload['beams'][1]['damageRoll'], isNull);
    expect(payload['damage'], 4);
    expect(update.campaign.encounter!.enemyHitPoints, 46);
    expect(update.campaign.encounter!.actionUsed, isTrue);
    expect(
      update.campaign.encounter!.spellSlotExpendedThisTurn,
      isFalse,
    );
    expect(update.campaign.hero.spentSpellSlots, before.hero.spentSpellSlots);
    expect(update.campaign.hero.spentPactSlots, before.hero.spentPactSlots);
    expect(update.campaign.revision, before.revision + 1);
    expect(
      Campaign.fromJson(update.campaign.toJson()).toJson(),
      update.campaign.toJson(),
    );
    expect(rng.calls, 3);
    expect(() => _cast(engine, update.campaign), throwsFormatException);
  });

  test('force resistance rounds separately for each hit beam', () {
    final rng = _Rolls([14, 2, 14, 2]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final before = _campaign(
      engine,
      encounter: _encounter(defense: EnemyForceDefense.resistant),
    );
    final update = _cast(engine, before);
    final payload = update.events.single.payload;
    expect(payload['rawForceDamage'], 6);
    expect(payload['damage'], 2);
    expect(payload['beams'][0]['appliedForceDamage'], 1);
    expect(payload['beams'][1]['appliedForceDamage'], 1);
    expect(update.campaign.encounter!.enemyHitPoints, 48);
    expect(rng.calls, 4);
  });

  test('uncertain defenses and stale target IDs fail before rolling', () {
    final rng = _Rolls([19]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final normal = _campaign(engine);
    expect(
      () => _cast(
        engine,
        _campaign(
          engine,
          encounter: _encounter(defense: EnemyForceDefense.unknown),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => _cast(
        engine,
        normal,
        declaredBeams: _targets(targetId: 'another-enemy'),
      ),
      throwsFormatException,
    );
    expect(
      () => _cast(engine, normal, declaredBeams: _targets(ac: 15)),
      throwsFormatException,
    );
    expect(
      () => _cast(
        engine,
        normal,
        declaredBeams: _targets(cover: CoverLevel.half),
      ),
      throwsFormatException,
    );
    expect(rng.calls, 0);
  });

  test('blocked action, missing confirmation and cover fail closed', () {
    final rng = _Rolls([19]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final game = _campaign(engine);
    expect(
      () => _cast(engine, game.copyWith(encounter: _encounter(actionUsed: true))),
      throwsFormatException,
    );
    expect(
      () => _cast(engine, game, singleEnemyConfirmed: false),
      throwsFormatException,
    );
    expect(() => _cast(engine, game, verbal: false), throwsFormatException);
    expect(() => _cast(engine, game, somatic: false), throwsFormatException);
    expect(
      () => _cast(engine, game, modifiersConfirmed: false),
      throwsFormatException,
    );
    expect(
      () => _cast(engine, game, shieldCleared: false),
      throwsFormatException,
    );
    expect(
      () => _cast(engine, game, circumstancesConfirmed: false),
      throwsFormatException,
    );
    final covered = _campaign(
      engine,
      encounter: _encounter(cover: CoverLevel.total),
    );
    expect(
      () => _cast(
        engine,
        covered,
        declaredBeams: _targets(cover: CoverLevel.total),
      ),
      throwsFormatException,
    );
    expect(rng.calls, 0);
  });

  test('SQLite restart persists all beams; stale replay never repeats', () async {
    final directory = await Directory.systemTemp.createTemp('eb-sqlite-');
    final dbPath = p.join(directory.path, 'game.sqlite');
    var repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: dbPath,
    );
    var controller = GameController(
      repository: repo,
      engine: GameEngine(dice: DiceEngine(random: _Rolls([9, 3, 2]))),
    );
    try {
      final before = _campaign(GameEngine());
      await repo.saveCampaign(before, events: before.events);
      await controller.openCampaign(before.id);
      await _controllerCast(controller, before);
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(after.encounter!.enemyHitPoints, 46);
      expect(after.encounter!.actionUsed, isTrue);
      expect(after.events.last.type, 'spell.eldritchBlast');
      expect(after.events.last.payload['beams'], hasLength(2));
      await _controllerCast(controller, before);
      expect(controller.error, contains('erneut öffnen'));
      expect(controller.currentCampaign!.toJson(), after.toJson());
      expect((await repo.getCampaign(before.id))!.toJson(), after.toJson());

      controller.dispose();
      await repo.close();
      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      controller = GameController(repository: repo);
      await controller.openCampaign(before.id);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), after.toJson());
    } finally {
      controller.dispose();
      await repo.close();
      await directory.delete(recursive: true);
    }
  });

  test('SQLite journal failure rolls back action and enemy HP', () async {
    final directory = await Directory.systemTemp.createTemp('eb-rollback-');
    final dbPath = p.join(directory.path, 'game.sqlite');
    final repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: dbPath,
    );
    final controller = GameController(
      repository: repo,
      engine: GameEngine(dice: DiceEngine(random: _Rolls([9, 3, 2]))),
    );
    try {
      final before = _campaign(GameEngine());
      await repo.saveCampaign(before, events: before.events);
      await controller.openCampaign(before.id);
      final database = await databaseFactoryFfi.openDatabase(dbPath);
      try {
        await database.execute('''
CREATE TRIGGER reject_eldritch_blast
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"spell.eldritchBlast"') > 0
BEGIN
  SELECT RAISE(ABORT, 'blocked eldritch journal');
END
''');
        await _controllerCast(controller, before);
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), before.toJson());
        expect((await repo.getCampaign(before.id))!.toJson(), before.toJson());
      } finally {
        await database.close();
      }
    } finally {
      controller.dispose();
      await repo.close();
      await directory.delete(recursive: true);
    }
  });
}
