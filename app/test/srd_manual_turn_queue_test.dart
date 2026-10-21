import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_initiative_roster_rules.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'hero',
  name: 'Aria',
  className: 'Magier',
  level: 5,
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
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d4',
);

const _foe = Encounter(
  id: 'foe',
  enemyName: 'Wächter',
  enemyHitPoints: 20,
  enemyMaxHitPoints: 20,
  enemyArmorClass: 12,
  heroInitiative: 15,
  enemyInitiative: 12,
);

TrackedAreaCreature _creature(String id, int initiative, {int hp = 10}) =>
    TrackedAreaCreature(
      id: id,
      name: id,
      hitPoints: hp,
      maxHitPoints: 10,
      initiativeTotal: initiative,
      initiativeController: 'gm',
    );

Campaign _game(GameEngine engine) => engine.createDemo().copyWith(
  hero: _hero(),
  encounter: _foe,
  trackedAreaCreatures: [
    _creature('orc', 17),
    _creature('goblin', 15),
    _creature('wolf', 10),
  ],
);

void main() {
  test('Old save files do not acquire advisory queue on serialization', () {
    final original = _game(GameEngine());
    final json = original.toJson();
    expect(json.containsKey('manualTurnQueue'), isFalse);
    expect(Campaign.fromJson(json).toJson(), json);
  });

  test('Tie order requires explicit confirmation, only equal rolls swap', () {
    final game = _game(GameEngine());
    final expected = ['orc', 'goblin', 'hero', 'foe', 'wolf'];
    expect(
      () => SrdInitiativeRosterRules.createManualQueue(
        game,
        orderedActorIds: expected,
        baseInitiativeConfirmed: true,
        tiedOrderConfirmed: false,
      ),
      throwsFormatException,
    );
    final queue = SrdInitiativeRosterRules.createManualQueue(
      game,
      orderedActorIds: expected,
      baseInitiativeConfirmed: true,
      tiedOrderConfirmed: true,
    );
    expect(queue.actorIds, expected);
    expect(queue.activeActorId, 'orc');
    expect(queue.round, 1);
    expect(queue.activeIndex, 0);
    expect(
      SrdInitiativeRosterRules.createManualQueue(
        game,
        orderedActorIds: ['orc', 'hero', 'goblin', 'foe', 'wolf'],
        baseInitiativeConfirmed: true,
        tiedOrderConfirmed: true,
      ).actorIds[1],
      'hero',
    );
    for (final wrong in [
      ['orc', 'hero', 'foe', 'goblin', 'wolf'],
      ['hero', 'orc', 'goblin', 'foe', 'wolf'],
      ['orc', 'goblin', 'hero', 'foe', 'foe'],
      ['orc', 'goblin', 'hero', 'foe'],
    ]) {
      expect(
        () => SrdInitiativeRosterRules.createManualQueue(
          game,
          orderedActorIds: wrong,
          baseInitiativeConfirmed: true,
          tiedOrderConfirmed: true,
        ),
        throwsFormatException,
      );
    }
  });

  test('Manual cursor persists and wraps round without performing attacks', () {
    final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 21));
    final game = _game(engine);
    final start = engine.establishManualTurnQueue(
      game,
      orderedActorIds: ['orc', 'goblin', 'hero', 'foe', 'wolf'],
      baseInitiativeConfirmed: true,
      tiedOrderConfirmed: true,
    );
    expect(start.events.single.type, 'combat.manualTurnQueueEstablished');
    expect(start.campaign.encounter!.enemyHitPoints, 20);
    expect(start.campaign.hero.hitPoints, 20);
    expect(start.campaign.revision, game.revision + 1);
    expect(start.campaign.manualTurnQueue!.activeActorId, 'orc');
    var current = start.campaign;
    for (final id in ['goblin', 'hero', 'foe', 'wolf', 'orc']) {
      final update = engine.advanceManualTurnQueue(current);
      expect(update.events.single.type, 'combat.manualTurnQueueAdvanced');
      current = update.campaign;
      expect(current.manualTurnQueue!.activeActorId, id);
      expect(current.encounter!.activeParticipant, 'hero');
      expect(current.encounter!.round, 1);
      expect(current.encounter!.enemyHitPoints, 20);
      expect(current.hero.hitPoints, 20);
    }
    expect(current.manualTurnQueue!.round, 2);
    expect(current.manualTurnQueue!.activeIndex, 0);
    final restored = Campaign.fromJson(current.toJson());
    expect(restored.toJson(), current.toJson());
  });

  test('Downed HP-only creatures are skipped; cursors remain explicit', () {
    final engine = GameEngine();
    var game = _game(engine);
    game = engine
        .establishManualTurnQueue(
          game,
          orderedActorIds: ['orc', 'goblin', 'hero', 'foe', 'wolf'],
          baseInitiativeConfirmed: true,
          tiedOrderConfirmed: true,
        )
        .campaign;
    game = game.copyWith(
      trackedAreaCreatures: [
        _creature('orc', 17, hp: 0),
        _creature('goblin', 15, hp: 0),
        _creature('wolf', 10),
      ],
    );
    final next = engine.advanceManualTurnQueue(game);
    expect(next.campaign.manualTurnQueue!.activeActorId, 'hero');
    expect(next.campaign.manualTurnQueue!.round, 1);
  });

  test(
    'Open decisions, missing init, added creatures and stale queue block',
    () {
      final engine = GameEngine();
      final game = _game(engine);
      expect(
        () => engine.establishManualTurnQueue(
          game,
          orderedActorIds: ['orc', 'goblin', 'hero', 'foe', 'wolf'],
          baseInitiativeConfirmed: false,
          tiedOrderConfirmed: true,
        ),
        throwsFormatException,
      );
      expect(
        () => engine.establishManualTurnQueue(
          game.copyWith(
            trackedAreaCreatures: [
              _creature('orc', 17),
              _creature('goblin', 15),
              const TrackedAreaCreature(
                id: 'wolf',
                name: 'wolf',
                hitPoints: 10,
                maxHitPoints: 10,
              ),
            ],
          ),
          orderedActorIds: ['orc', 'goblin', 'hero', 'foe'],
          baseInitiativeConfirmed: true,
          tiedOrderConfirmed: true,
        ),
        throwsFormatException,
      );
      final queued = engine
          .establishManualTurnQueue(
            game,
            orderedActorIds: ['orc', 'goblin', 'hero', 'foe', 'wolf'],
            baseInitiativeConfirmed: true,
            tiedOrderConfirmed: true,
          )
          .campaign;
      final changed = queued.copyWith(
        trackedAreaCreatures: [
          _creature('orc', 17),
          _creature('goblin', 15),
          _creature('wolf', 19),
        ],
      );
      expect(
        () => engine.advanceManualTurnQueue(changed),
        throwsFormatException,
      );
    },
  );

  test(
    'Initiative changes and registrations invalidate active manual queue',
    () {
      final engine = GameEngine();
      final game = _game(engine);
      final queued = engine
          .establishManualTurnQueue(
            game,
            orderedActorIds: ['orc', 'goblin', 'hero', 'foe', 'wolf'],
            baseInitiativeConfirmed: true,
            tiedOrderConfirmed: true,
          )
          .campaign;
      final changed = engine.confirmAreaCreatureInitiative(
        queued,
        creatureId: 'wolf',
        initiativeTotal: 11,
        initiativeController: 'gm',
        initiativeConfirmed: true,
      );
      expect(changed.campaign.manualTurnQueue, isNull);
      expect(changed.campaign.trackedAreaCreatures.last.initiativeTotal, 11);
      final added = engine.trackAreaCreature(
        queued,
        creatureId: 'new',
        creatureName: 'New',
        hitPoints: 5,
        maxHitPoints: 5,
        valuesConfirmed: true,
      );
      expect(added.campaign.manualTurnQueue, isNull);
    },
  );

  test('Victory or new encounter clears optional queue automatically', () {
    final engine = GameEngine();
    final game = _game(engine);
    final queued = engine
        .establishManualTurnQueue(
          game,
          orderedActorIds: ['orc', 'goblin', 'hero', 'foe', 'wolf'],
          baseInitiativeConfirmed: true,
          tiedOrderConfirmed: true,
        )
        .campaign;
    expect(queued.copyWith(encounter: null).manualTurnQueue, isNull);
    expect(
      queued
          .copyWith(
            encounter: const Encounter(
              id: 'other',
              enemyName: 'New foe',
              enemyHitPoints: 10,
              enemyMaxHitPoints: 10,
            ),
          )
          .manualTurnQueue,
      isNull,
    );
    expect(queued.copyWith(scene: 'new').manualTurnQueue, isNotNull);
  });

  test('Tampered manual queue files are rejected and list is immutable', () {
    final engine = GameEngine();
    final game = _game(engine);
    final queued = engine
        .establishManualTurnQueue(
          game,
          orderedActorIds: ['orc', 'goblin', 'hero', 'foe', 'wolf'],
          baseInitiativeConfirmed: true,
          tiedOrderConfirmed: true,
        )
        .campaign;
    expect(
      () => queued.manualTurnQueue!.actorIds.add('malicious'),
      throwsUnsupportedError,
    );
    for (final raw in [
      {
        'encounterId': 'different',
        'actorIds': ['orc', 'goblin', 'hero', 'foe', 'wolf'],
        'activeIndex': 0,
        'round': 1,
      },
      {
        'encounterId': 'foe',
        'actorIds': ['orc', 'orc', 'hero'],
        'activeIndex': 0,
        'round': 1,
      },
      {
        'encounterId': 'foe',
        'actorIds': ['hero', 'foe'],
        'activeIndex': 3,
        'round': 1,
      },
      {
        'encounterId': 'foe',
        'actorIds': ['hero', 'foe', 'unregistered'],
        'activeIndex': 0,
        'round': 1,
      },
    ]) {
      final data = queued.toJson();
      data['manualTurnQueue'] = raw;
      expect(() => Campaign.fromJson(data), throwsFormatException);
    }
  });
}
