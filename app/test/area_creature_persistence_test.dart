import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/acid_splash_rules.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _SequenceRandom implements Random {
  _SequenceRandom(this.values);
  final List<int> values;
  int calls = 0;
  @override
  int nextInt(int max) {
    final next = values[calls % values.length];
    calls++;
    return next % max;
  }

  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

HeroCharacter _mage() => HeroCharacter(
  id: 'caster',
  name: 'Aria',
  className: 'Magier',
  level: 5,
  spells: const ['Säurespritzer'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 13,
  speed: 9,
  weaponDamage: '1d4',
);

const Encounter _fight = Encounter(
  id: 'foe',
  enemyName: 'Hauptgegner',
  enemyHitPoints: 25,
  enemyMaxHitPoints: 25,
  enemyArmorClass: 12,
);

Campaign _campaign(GameEngine engine) =>
    engine.createDemo().copyWith(hero: _mage(), encounter: _fight);

GameUpdate _track(
  GameEngine engine,
  Campaign campaign,
  String id, {
  int hp = 20,
  int max = 20,
}) => engine.trackAreaCreature(
  campaign,
  creatureId: id,
  creatureName: id,
  hitPoints: hp,
  maxHitPoints: max,
  valuesConfirmed: true,
);

AcidSplashTarget _target(
  TrackedAreaCreature c, {
  int modifier = 0,
  CoverLevel cover = CoverLevel.none,
  bool opposite = false,
  bool confirmed = true,
}) => AcidSplashTarget(
  id: c.id,
  name: c.name,
  hitPoints: c.hitPoints,
  maxHitPoints: c.maxHitPoints,
  dexteritySaveModifier: modifier,
  cover: cover,
  sourceOppositeCover: opposite,
  coverRelationshipConfirmed: confirmed,
  inSphereConfirmed: confirmed,
  effectPathConfirmed: confirmed,
  noAcidDamageAdjustmentConfirmed: confirmed,
  saveCircumstancesConfirmed: confirmed,
);

GameUpdate _cast(
  GameEngine engine,
  Campaign campaign, {
  required List<AcidSplashTarget> extras,
  bool all = true,
  bool only = false,
}) => engine.castAcidSplash(
  campaign,
  castingClass: 'Magier',
  confirmedTargetDexteritySaveModifier: 0,
  originWithin60FeetConfirmed: true,
  currentEnemyIsOnlyCreatureInSphereConfirmed: only,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noUnmodelledDcModifiersConfirmed: true,
  targetSaveCircumstancesConfirmed: true,
  targetCoverRelationshipConfirmed: true,
  effectPathConfirmed: true,
  noAcidDamageAdjustmentConfirmed: true,
  additionalTargets: extras,
  allCreaturesInSphereAccountedForConfirmed: all,
);

void main() {
  test('Old schema-1 campaign without extra creatures survives roundtrip', () {
    final engine = GameEngine();
    final before = _campaign(engine);
    final json = before.toJson();
    expect(json.containsKey('trackedAreaCreatures'), false);
    final loaded = Campaign.fromJson(json);
    expect(loaded.trackedAreaCreatures, isEmpty);
    expect(loaded.toJson(), json);
  });

  test('Can store additional HP with stable IDs and immutable lists', () {
    final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 20));
    final game = _campaign(engine);
    final first = _track(engine, game, 'goblin-2');
    expect(first.events.single.type, 'combat.areaCreatureTracked');
    expect(first.campaign.trackedAreaCreatures.single.hitPoints, 20);
    expect(first.campaign.revision, game.revision + 1);
    final second = _track(engine, first.campaign, 'friend', hp: 9, max: 12);
    expect(second.campaign.trackedAreaCreatures, hasLength(2));
    expect(
      () => second.campaign.trackedAreaCreatures.add(
        const TrackedAreaCreature(
          id: 'injected',
          name: 'injected',
          hitPoints: 1,
          maxHitPoints: 1,
        ),
      ),
      throwsUnsupportedError,
    );
    final loaded = Campaign.fromJson(second.campaign.toJson());
    expect(loaded.toJson(), second.campaign.toJson());
  });

  test('Persist primary foe and two secondary HP with ONE damage roll', () {
    // Saves: primary 1 fail, goblin 1 fail, friend 20 succeeds.
    // Damage 2d6 = 4 + 5 = 9 applied to both failing targets.
    final rng = _SequenceRandom([0, 0, 19, 3, 4]);
    final engine = GameEngine(
      dice: DiceEngine(random: rng),
      clock: () => DateTime.utc(2026, 10, 20),
    );
    final initial = _campaign(engine);
    var game = _track(engine, initial, 'goblin', hp: 12).campaign;
    game = _track(engine, game, 'friend', hp: 12).campaign;
    final before = game.trackedAreaCreatures;
    final after = _cast(
      engine,
      game,
      extras: [_target(before[0]), _target(before[1])],
    );
    expect(after.events.single.type, 'spell.acidSplash');
    expect(after.campaign.encounter!.enemyHitPoints, 16);
    expect(after.campaign.trackedAreaCreatures[0].hitPoints, 3);
    expect(after.campaign.trackedAreaCreatures[1].hitPoints, 12);
    expect(before[0].hitPoints, 12);
    expect(after.events.single.payload['targetResolutions'], hasLength(3));
    expect(after.events.single.payload['targetIds'], [
      'foe',
      'goblin',
      'friend',
    ]);
    expect(after.events.single.payload['totalDamage'], 18);
    expect(after.events.single.payload['damageRoll']['expression'], '2d6');
    expect(after.campaign.encounter!.actionUsed, true);
    expect(after.campaign.hero.spentSpellSlots, isEmpty);
    expect(after.campaign.revision, game.revision + 1);
    expect(rng.calls, 5);
    expect(
      Campaign.fromJson(after.campaign.toJson()).toJson(),
      after.campaign.toJson(),
    );
  });

  test('Defeated main foe does not erase surviving tracked area creatures', () {
    final rng = _SequenceRandom([0, 19, 5, 5]);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    var game = _campaign(
      engine,
    ).copyWith(encounter: _fight.copyWith(enemyHitPoints: 4));
    game = _track(engine, game, 'bystander').campaign;
    final cast = _cast(
      engine,
      game,
      extras: [_target(game.trackedAreaCreatures.single)],
    );
    expect(cast.campaign.trackedAreaCreatures.single.hitPoints, 20);
    expect(cast.campaign.trackedAreaCreatures.single.id, 'bystander');
    // The demo encounter is allowed to finish; tracked HP survive.
    expect(
      Campaign.fromJson(
        cast.campaign.toJson(),
      ).trackedAreaCreatures.single.hitPoints,
      20,
    );
  });

  test(
    'Stale/unregistered, duplicate or inconsistent targets reject before RNG',
    () {
      final rng = _SequenceRandom([0]);
      final engine = GameEngine(dice: DiceEngine(random: rng));
      var game = _track(engine, _campaign(engine), 'goblin').campaign;
      final target = _target(game.trackedAreaCreatures.single);
      expect(
        () => _cast(engine, game, extras: [target], all: false),
        throwsFormatException,
      );
      expect(
        () => _cast(engine, game, extras: [target], only: true),
        throwsFormatException,
      );
      expect(
        () => _cast(engine, game, extras: [target, target]),
        throwsFormatException,
      );
      final invalid = AcidSplashTarget(
        id: 'goblin',
        name: 'goblin',
        hitPoints: 19, // stale; actual HP is 20
        maxHitPoints: 20,
        dexteritySaveModifier: 0,
        cover: CoverLevel.none,
        sourceOppositeCover: false,
        coverRelationshipConfirmed: true,
        inSphereConfirmed: true,
        effectPathConfirmed: true,
        noAcidDamageAdjustmentConfirmed: true,
        saveCircumstancesConfirmed: true,
      );
      expect(
        () => _cast(engine, game, extras: [invalid]),
        throwsFormatException,
      );
      expect(
        () => _cast(
          engine,
          game,
          extras: [
            _target(
              const TrackedAreaCreature(
                id: 'nonexistent',
                name: 'unknown',
                hitPoints: 20,
                maxHitPoints: 20,
              ),
            ),
          ],
        ),
        throwsFormatException,
      );
      expect(rng.calls, 0);
      expect(game.trackedAreaCreatures.single.hitPoints, 20);
    },
  );

  test('Reject invalid creature ID, duplicate, HP and tampered save files', () {
    final engine = GameEngine();
    final original = _campaign(engine);
    expect(
      () => engine.trackAreaCreature(
        original,
        creatureId: 'foe',
        creatureName: 'collision',
        hitPoints: 5,
        maxHitPoints: 5,
        valuesConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(
      () => engine.trackAreaCreature(
        original,
        creatureId: 'invalid',
        creatureName: 'invalid',
        hitPoints: 11,
        maxHitPoints: 10,
        valuesConfirmed: true,
      ),
      throwsFormatException,
    );
    var game = _track(engine, original, 'goblin').campaign;
    expect(() => _track(engine, game, 'goblin'), throwsFormatException);
    final corrupt = game.toJson();
    (corrupt['trackedAreaCreatures'] as List).add(
      Map<String, dynamic>.from(
        (corrupt['trackedAreaCreatures'] as List).single as Map,
      ),
    );
    expect(() => Campaign.fromJson(corrupt), throwsFormatException);
    game = game.copyWith(trackedAreaCreatures: const []);
    expect(game.trackedAreaCreatures, isEmpty);
  });
}
