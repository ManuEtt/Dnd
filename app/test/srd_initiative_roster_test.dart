import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_initiative_roster_rules.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'hero-1',
  name: 'Aria',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 14,
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

const _encounter = Encounter(
  id: 'main-foe',
  enemyName: 'Wächter',
  enemyHitPoints: 30,
  enemyMaxHitPoints: 30,
  enemyArmorClass: 12,
  heroInitiative: 15,
  enemyInitiative: 12,
);

Campaign _game(GameEngine engine) => engine.createDemo().copyWith(
  hero: _hero(),
  encounter: _encounter,
);

TrackedAreaCreature _extra(String id, {
  int? initiative,
  String? control,
  int hp = 20,
}) => TrackedAreaCreature(
  id: id,
  name: id,
  hitPoints: hp,
  maxHitPoints: 20,
  initiativeTotal: initiative,
  initiativeController: control,
);

void main() {
  test('Old optional initiative fields are absent in legacy saves', () {
    final game = _game(GameEngine()).copyWith(
      trackedAreaCreatures: [_extra('skeleton')],
    );
    final json = game.toJson();
    expect(
      (json['trackedAreaCreatures'] as List).single
          .containsKey('initiativeTotal'),
      false,
    );
    expect(Campaign.fromJson(json).toJson(), json);
    expect(Campaign.fromJson(json).trackedAreaCreatures.single.initiativeTotal,
        isNull);
  });

  test('Confirmed initiatives serialize with signed 0 and preserve HP', () {
    final engine = GameEngine(
      clock: () => DateTime.utc(2026, 10, 20),
    );
    final initial = _game(engine).copyWith(
      trackedAreaCreatures: [_extra('goblin')],
    );
    final result = engine.confirmAreaCreatureInitiative(
      initial,
      creatureId: 'goblin',
      initiativeTotal: 0,
      initiativeController: 'gm',
      initiativeConfirmed: true,
    );
    final creature = result.campaign.trackedAreaCreatures.single;
    expect(creature.hitPoints, 20);
    expect(creature.initiativeTotal, 0);
    expect(creature.initiativeController, 'gm');
    expect(result.events.single.type, 'combat.areaCreatureInitiativeConfirmed');
    expect(result.campaign.revision, initial.revision + 1);
    expect(
      Campaign.fromJson(result.campaign.toJson()).toJson(),
      result.campaign.toJson(),
    );
    final updatedHp = creature.copyWith(hitPoints: 5);
    expect(updatedHp.initiativeTotal, 0);
    expect(updatedHp.initiativeController, 'gm');
    expect(initial.trackedAreaCreatures.single.initiativeTotal, isNull);
  });

  test('Ordered initiative is descending and names are never tie-breakers', () {
    final game = _game(GameEngine()).copyWith(
      trackedAreaCreatures: [
        _extra('zombie', initiative: 18, control: 'gm'),
        _extra('ally', initiative: 13, control: 'player'),
        _extra('goblin', initiative: 11, control: 'gm'),
      ],
    );
    final roster = SrdInitiativeRosterRules.preview(
      game,
      baseInitiativeConfirmed: true,
    );
    expect(roster.groups.map((x) => x.total), [18, 15, 13, 12, 11]);
    expect(roster.groups.first.entries.single.name, 'zombie');
    expect(roster.missing, isEmpty);
    expect(roster.hasUnresolvedTies, false);
    expect(roster.readyForManualAdjudication, true);
  });

  test('Explicit tie remains unresolved for GM/player choice', () {
    final game = _game(GameEngine()).copyWith(
      trackedAreaCreatures: [
        _extra('goblin', initiative: 15, control: 'gm'),
        _extra('archer', initiative: 15, control: 'gm'),
      ],
    );
    final roster = SrdInitiativeRosterRules.preview(
      game,
      baseInitiativeConfirmed: true,
    );
    expect(roster.groups.first.total, 15);
    expect(roster.groups.first.entries, hasLength(3));
    expect(roster.groups.first.hasUnresolvedTie, true);
    expect(roster.readyForManualAdjudication, false);
  });

  test('Missing initiative and legacy base uncertainty block readiness', () {
    final game = _game(GameEngine()).copyWith(
      trackedAreaCreatures: [
        _extra('unknown'),
        _extra('defeated', hp: 0),
      ],
    );
    final roster = SrdInitiativeRosterRules.preview(
      game,
      baseInitiativeConfirmed: false,
    );
    expect(roster.missing.map((x) => x.id), ['unknown']);
    expect(roster.readyForManualAdjudication, false);
    expect(
      SrdInitiativeRosterRules.preview(
        game.copyWith(trackedAreaCreatures: const []),
        baseInitiativeConfirmed: false,
      ).readyForManualAdjudication,
      false,
    );
  });

  test('Invalid initiative, actor ownership or contradictory file rejects', () {
    final engine = GameEngine();
    final game = _game(engine).copyWith(
      trackedAreaCreatures: [_extra('goblin')],
    );
    for (final combination in [
      (-31, 'gm'),
      (101, 'gm'),
      (15, 'unowned'),
    ]) {
      expect(
        () => engine.confirmAreaCreatureInitiative(
          game,
          creatureId: 'goblin',
          initiativeTotal: combination.$1,
          initiativeController: combination.$2,
          initiativeConfirmed: true,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => engine.confirmAreaCreatureInitiative(
        game,
        creatureId: 'goblin',
        initiativeTotal: 5,
        initiativeController: 'gm',
        initiativeConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => engine.confirmAreaCreatureInitiative(
        game,
        creatureId: 'unknown',
        initiativeTotal: 5,
        initiativeController: 'gm',
        initiativeConfirmed: true,
      ),
      throwsFormatException,
    );
    for (final invalid in [
      {'initiativeTotal': 12},
      {'initiativeController': 'gm'},
      {'initiativeTotal': 5, 'initiativeController': 'invalid'},
      {'initiativeTotal': -31, 'initiativeController': 'gm'},
      {'initiativeTotal': 101, 'initiativeController': 'gm'},
    ]) {
      expect(
        () => TrackedAreaCreature.fromJson({
          'id': 'a',
          'name': 'A',
          'hitPoints': 2,
          'maxHitPoints': 3,
          ...invalid,
        }),
        throwsFormatException,
      );
    }
    expect(game.trackedAreaCreatures.single.initiativeTotal, isNull);
  });

  test('Changing HP and save/load retains initiative across rounds', () {
    final engine = GameEngine();
    final before = _game(engine).copyWith(
      trackedAreaCreatures: [_extra('goblin', initiative: 9, control: 'gm')],
      encounter: _encounter.copyWith(round: 4),
    );
    final after = before.copyWith(
      trackedAreaCreatures: [
        before.trackedAreaCreatures.single.copyWith(hitPoints: 5),
      ],
      encounter: _encounter.copyWith(round: 5),
    );
    final roundtrip = Campaign.fromJson(after.toJson());
    expect(roundtrip.trackedAreaCreatures.single.initiativeTotal, 9);
    expect(roundtrip.encounter!.round, 5);
    expect(roundtrip.trackedAreaCreatures.single.hitPoints, 5);
  });
}
