import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'support/legacy_campaign_fixture.dart';

AbilityGenerationResult standardSoldier() =>
    AbilityAllocation(
      method: AbilityGenerationMethod.standardArray,
      baseScores: const {
        'strength': 15,
        'dexterity': 14,
        'constitution': 13,
        'intelligence': 12,
        'wisdom': 10,
        'charisma': 8,
      },
    ).compose(
      backgroundBoost: BackgroundAbilityBoost(
        background: SrdBackground.soldier,
        increases: const {'strength': 2, 'constitution': 1},
      ),
    );

AbilityGenerationResult pointBuyCriminal() =>
    AbilityAllocation(
      method: AbilityGenerationMethod.pointBuy,
      baseScores: const {
        'strength': 15,
        'dexterity': 15,
        'constitution': 15,
        'intelligence': 8,
        'wisdom': 8,
        'charisma': 8,
      },
    ).compose(
      backgroundBoost: BackgroundAbilityBoost(
        background: SrdBackground.criminal,
        increases: const {'dexterity': 1, 'constitution': 1, 'intelligence': 1},
      ),
    );

StartingAbilityOrigin _rolledSoldierOrigin() => StartingAbilityOrigin.confirmed(
  method: 'randomRoll',
  baseScores: const {
    'strength': 18,
    'dexterity': 15,
    'constitution': 12,
    'intelligence': 9,
    'wisdom': 6,
    'charisma': 3,
  },
  background: 'Soldat',
  increases: const {'strength': 1, 'dexterity': 1, 'constitution': 1},
  diceRolls: const [
    [6, 6, 6, 1],
    [5, 5, 5, 1],
    [4, 4, 4, 1],
    [3, 3, 3, 1],
    [2, 2, 2, 1],
    [1, 1, 1, 1],
  ],
);

HeroCharacter _withOrigin(HeroCharacter hero, StartingAbilityOrigin origin) =>
    HeroCharacter.fromJson(
      hero
          .copyWith(
            abilities: origin.startingScores,
            background: origin.background,
            startingAbilityOrigin: origin,
          )
          .toJson(),
    );

Future<Map<String, Object>> _storedTables(Database database) async => {
  'campaigns': await database.query('campaigns', orderBy: 'id'),
  'campaign_revisions': await database.query(
    'campaign_revisions',
    orderBy: 'campaign_id, revision',
  ),
  'game_events': await database.query('game_events', orderBy: 'id'),
  'characters': await database.query('characters', orderBy: 'id'),
  'settings': await database.query('settings', orderBy: 'id'),
};

String _visibleCharacterState(GameController controller) => jsonEncode({
  'active': controller.currentCampaign?.toJson(),
  'campaigns': [for (final campaign in controller.campaigns) campaign.toJson()],
  'characters': [for (final hero in controller.characters) hero.toJson()],
});

void expectAbilities(
  HeroCharacter hero,
  Map<String, int> scores,
  Map<String, int> modifiers,
) {
  expect(hero.abilities, scores);
  expect({
    for (final key in abilityNames)
      key: RulesEngine.abilityModifier(hero.abilities[key]!),
  }, modifiers);
}

/// Character editing may add its event and GM acknowledgement, but does not
/// change the scene, NPCs, quests, confirmed facts, equipment or combat state.
void expectWorldUnchanged(Campaign before, Campaign after) {
  for (final key in [
    'id',
    'name',
    'world',
    'sessionId',
    'scene',
    'facts',
    'quests',
    'npcs',
    'places',
    'encounter',
  ]) {
    expect(after.toJson()[key], before.toJson()[key], reason: key);
  }
  expect(
    after.hero
        .copyWith(
          abilities: before.hero.abilities,
          background: before.hero.background,
        )
        .toJson(),
    before.hero.toJson(),
  );
  expect(
    after.events.take(before.events.length).map((event) => event.toJson()),
    before.events.map((event) => event.toJson()),
  );
  expect(
    after.messages
        .take(before.messages.length)
        .map((message) => message.toJson()),
    before.messages.map((message) => message.toJson()),
  );
  expect(after.revision, before.revision + 1);
  expect(after.events, hasLength(before.events.length + 1));
  expect(after.events.last.type, 'character.updated');
}

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository repository;
  late GameController controller;

  Future<void> restartController() async {
    controller.dispose();
    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    controller = GameController(repository: repository);
    await controller.initialize();
    expect(controller.error, isNull);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('living-gm-abilities-');
    databasePath = paths.join(directory.path, 'abilities.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
    controller = GameController(repository: repository);
    await controller.initialize();
    expect(controller.error, isNull);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
    await directory.delete(recursive: true);
  });

  test(
    'explicit standard array and background survive campaign restart and import',
    () async {
      await controller.createDemo();
      final generated = standardSoldier();
      await controller.saveHero(
        controller.currentCampaign!.hero.copyWith(
          abilities: generated.finalScores,
          background: SrdBackground.soldier.label,
        ),
      );
      expect(controller.error, isNull);
      final confirmed = controller.currentCampaign!;
      const scores = {
        'strength': 17,
        'dexterity': 14,
        'constitution': 14,
        'intelligence': 12,
        'wisdom': 10,
        'charisma': 8,
      };
      const modifiers = {
        'strength': 3,
        'dexterity': 2,
        'constitution': 2,
        'intelligence': 1,
        'wisdom': 0,
        'charisma': -1,
      };
      expectAbilities(confirmed.hero, scores, modifiers);
      await restartController();
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expectAbilities(controller.currentCampaign!.hero, scores, modifiers);

      final source = controller.exportCampaign();
      await controller.deleteCampaign(confirmed.id);
      await controller.importCampaign(source);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expectAbilities(controller.currentCampaign!.hero, scores, modifiers);
      expect(
        (await repository.reconstructCampaign(confirmed.id))!.toJson(),
        confirmed.toJson(),
      );
    },
  );

  test(
    'explicit point buy persists standalone scores and character export exactly',
    () async {
      final generated = pointBuyCriminal();
      final hero = HeroCharacter(id: 'point-buy-hero', name: 'Selene').copyWith(
        abilities: generated.finalScores,
        background: SrdBackground.criminal.label,
      );
      await controller.saveStandaloneHero(hero);
      expect(controller.error, isNull);
      await restartController();
      final restored = controller.characters.single;
      expect(restored.toJson(), hero.toJson());
      const scores = {
        'strength': 15,
        'dexterity': 16,
        'constitution': 16,
        'intelligence': 9,
        'wisdom': 8,
        'charisma': 8,
      };
      const modifiers = {
        'strength': 2,
        'dexterity': 3,
        'constitution': 3,
        'intelligence': -1,
        'wisdom': -1,
        'charisma': -1,
      };
      expectAbilities(restored, scores, modifiers);
      expect(restored.hitPoints, isNull);
      expect(restored.armorClass, isNull);
      final source = controller.exportHero(restored);
      await controller.deleteCharacter(hero.id);
      expect(controller.characters, isEmpty);
      await controller.importHero(source);
      expect(controller.error, isNull);
      expect(controller.characters.single.toJson(), hero.toJson());
      expectAbilities(controller.characters.single, scores, modifiers);
    },
  );

  test(
    'saving final values again never reapplies background increases',
    () async {
      await controller.createDemo();
      final generated = standardSoldier();
      await controller.saveHero(
        controller.currentCampaign!.hero.copyWith(
          abilities: generated.finalScores,
          background: SrdBackground.soldier.label,
        ),
      );
      expect(controller.error, isNull);
      final first = controller.currentCampaign!;
      await controller.saveHero(first.hero);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.hero.toJson(), first.hero.toJson());
      expect(controller.currentCampaign!.hero.abilities['strength'], 17);
      expect(controller.currentCampaign!.hero.abilities['constitution'], 14);
      expect(controller.currentCampaign!.revision, first.revision + 1);
      await restartController();
      expect(controller.currentCampaign!.hero.toJson(), first.hero.toJson());
    },
  );

  test(
    'Arescan completion retains unverified history and still blocks new attacks',
    () async {
      await importLegacyArescan(controller);
      final initial = controller.currentCampaign!;
      final history = initial.events.single.toJson();
      final generated = pointBuyCriminal();
      await controller.saveHero(
        initial.hero.copyWith(
          abilities: generated.finalScores,
          background: SrdBackground.criminal.label,
        ),
      );
      expect(controller.error, isNull);
      final edited = controller.currentCampaign!;
      expectWorldUnchanged(initial, edited);
      expect(edited.events.first.toJson(), history);
      expect(edited.events.first.payload['attackTotal'], 19);
      expect(edited.events.first.payload['narratedDamage'], 14);
      expect(edited.events.first.payload['naturalRoll'], isNull);
      expect(edited.events.first.payload['mechanicallyVerified'], false);
      expect(edited.events.first.payload['unverifiedDexterityModifier'], 7);
      expect(edited.hero.unverifiedNotes, initial.hero.unverifiedNotes);
      expect(edited.hero.unverifiedNotes.join(' '), contains('+7'));
      expect(edited.hero.hitPoints, isNull);
      expect(edited.hero.maxHitPoints, isNull);
      expect(edited.hero.armorClass, isNull);
      expect(edited.hero.speed, isNull);
      expect(edited.hero.weaponDamage, isEmpty);
      expect(edited.hero.inventory, isEmpty);
      expect(edited.hero.isComplete, false);
      expect(RulesEngine.initiativeBonus(edited.hero), 3);
      await restartController();
      expect(controller.currentCampaign!.toJson(), edited.toJson());

      await controller.sendAction('Ich greife den Schattenritter an');
      expect(controller.error, isNull);
      final blocked = controller.currentCampaign!;
      expect(blocked.pendingRoll, isNull);
      expect(blocked.encounter, isNull);
      expect(blocked.events.last.type, 'rules.blocked');
      expect(blocked.events.first.toJson(), history);
      expect(blocked.hero.toJson(), edited.hero.toJson());
      expect(blocked.facts, edited.facts);
      expect(
        (await repository.getCampaign(blocked.id))!.toJson(),
        blocked.toJson(),
      );
    },
  );

  test(
    'confirmed inventory and world remain unchanged when generated stats commit',
    () async {
      await controller.createDemo();
      await controller.sendAction('Ich untersuche den Brunnen');
      expect(controller.error, isNull);
      final before = controller.currentCampaign!;
      expect(before.hero.inventory.any((item) => item.id == 'brass-key'), true);
      expect(before.facts['keyFound'], 'true');
      final generated = standardSoldier();
      await controller.saveHero(
        before.hero.copyWith(
          abilities: generated.finalScores,
          background: SrdBackground.soldier.label,
        ),
      );
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expectWorldUnchanged(before, after);
      expect(after.hero.abilities, generated.finalScores);
      expect(
        (await repository.reconstructCampaign(after.id))!.toJson(),
        after.toJson(),
      );
    },
  );

  test(
    'generated scores cancel cached rolls and subsequent rolls use new modifier',
    () async {
      await controller.createDemo();
      await controller.sendAction('Ich untersuche meine Umgebung');
      expect(controller.error, isNull);
      final before = controller.currentCampaign!;
      final oldModifier = before.pendingRoll!.modifier;
      final generated = pointBuyCriminal();
      await controller.saveHero(
        before.hero.copyWith(
          abilities: generated.finalScores,
          background: SrdBackground.criminal.label,
        ),
      );
      expect(controller.error, isNull);
      final edited = controller.currentCampaign!;
      expect(edited.pendingRoll, isNull);
      await controller.resolveRoll(natural: 10);
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), edited.toJson());
      await restartController();
      expect(controller.currentCampaign!.pendingRoll, isNull);

      await controller.sendAction('Ich untersuche meine Umgebung');
      expect(controller.error, isNull);
      final pending = controller.currentCampaign!.pendingRoll!;
      expect(pending.id, isNot(before.pendingRoll!.id));
      expect(pending.modifier, isNot(oldModifier));
      // Wisdom 8 supplies -1; the retained Perception proficiency adds +2 once.
      expect(pending.modifier, 1);
      await controller.resolveRoll(natural: 10);
      expect(controller.error, isNull);
      final resolved = controller.currentCampaign!;
      expect(resolved.pendingRoll, isNull);
      expect(resolved.events.last.payload['roll']['natural'], 10);
      expect(resolved.events.last.payload['roll']['modifier'], 1);
      expect(resolved.events.last.payload['roll']['total'], 11);
    },
  );

  test(
    'late SQLite failure rolls back generated scores, checkpoint and UI state',
    () async {
      await controller.createDemo();
      final confirmed = controller.currentCampaign!;
      // Reuse the repository's open database without owning/closing its handle.
      final database = await databaseFactoryFfi.openDatabase(databasePath);
      await database.execute('''
CREATE TRIGGER reject_generated_character
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"character.updated"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled character write rejection');
END
''');
      final generated = standardSoldier();
      final candidate = confirmed.hero.copyWith(
        abilities: generated.finalScores,
        background: SrdBackground.soldier.label,
      );
      await controller.saveHero(candidate);
      expect(controller.error, isNotNull);
      expect(controller.busy, false);
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(
        (await repository.getCampaign(confirmed.id))!.toJson(),
        confirmed.toJson(),
      );
      expect(
        await repository.reconstructCampaign(confirmed.id, revision: 1),
        isNull,
      );
      await database.execute('DROP TRIGGER reject_generated_character');
      await restartController();
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      await controller.saveHero(candidate);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.hero.toJson(), candidate.toJson());
      expect(controller.currentCampaign!.revision, 1);
      expect(controller.currentCampaign!.events, hasLength(1));
    },
  );

  test(
    'confirmed 4W6 provenance survives SQLite restart and JSON export',
    () async {
      const throws = <List<int>>[
        [6, 6, 6, 1],
        [5, 5, 5, 1],
        [4, 4, 4, 1],
        [3, 3, 3, 1],
        [2, 2, 2, 1],
        [1, 1, 1, 1],
      ];
      final origin = StartingAbilityOrigin.confirmed(
        method: 'randomRoll',
        baseScores: {
          'strength': 18,
          'dexterity': 15,
          'constitution': 12,
          'intelligence': 9,
          'wisdom': 6,
          'charisma': 3,
        },
        background: 'Soldat',
        increases: {'strength': 1, 'dexterity': 1, 'constitution': 1},
        diceRolls: throws,
      );
      final hero = HeroCharacter(
        id: 'provenance-hero',
        name: 'Würfelheld',
        background: 'Soldat',
        abilities: origin.startingScores,
        startingAbilityOrigin: origin,
      );
      await controller.saveStandaloneHero(hero);
      expect(controller.error, isNull);
      await restartController();
      final saved = controller.characters.single;
      expect(saved.startingAbilityOrigin!.diceRolls, throws);
      expect(saved.startingAbilityOrigin!.baseScores['strength'], 18);
      expect(saved.abilities['strength'], 19);
      final exported = controller.exportHero(saved);
      await controller.deleteCharacter(hero.id);
      await controller.importHero(exported);
      expect(controller.error, isNull);
      expect(controller.characters.single.toJson(), hero.toJson());
    },
  );

  test(
    'active campaign journals initial dice evidence and later edits never reapply it',
    () async {
      await controller.createDemo();
      final before = controller.currentCampaign!;
      final origin = _rolledSoldierOrigin();
      final expectedOrigin = jsonDecode(jsonEncode(origin.toJson()));
      final candidate = _withOrigin(before.hero, origin);

      await controller.saveHero(candidate);
      expect(controller.error, isNull);
      final confirmed = controller.currentCampaign!;
      expect(confirmed.hero.toJson(), candidate.toJson());
      expect(confirmed.hero.abilities['strength'], 19);
      expect(confirmed.hero.startingAbilityOrigin!.toJson(), expectedOrigin);
      // The shared helper excludes only the explicitly edited origin field.
      expectWorldUnchanged(
        before,
        confirmed.copyWith(
          hero: confirmed.hero.copyWith(
            startingAbilityOrigin: before.hero.startingAbilityOrigin,
          ),
        ),
      );
      final event = confirmed.events.last;
      expect(event.type, 'character.updated');
      expect(event.payload['revision'], confirmed.revision);
      final checkpoint = Campaign.fromJson(
        Map<String, dynamic>.from(event.payload['stateAfter'] as Map),
      );
      expect(checkpoint.hero.toJson(), confirmed.hero.toJson());
      expect(checkpoint.revision, confirmed.revision);
      expect(checkpoint.events, isEmpty);

      final database = await databaseFactoryFfi.openDatabase(databasePath);
      final storedEvent = await database.query(
        'game_events',
        where: 'id = ?',
        whereArgs: [event.id],
      );
      expect(storedEvent, hasLength(1));
      expect(
        jsonDecode(storedEvent.single['event_json'] as String),
        event.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(
          confirmed.id,
          revision: confirmed.revision,
        ))!.toJson(),
        confirmed.toJson(),
      );
      expect(
        (await repository.loadCharacters())
            .singleWhere((hero) => hero.id == candidate.id)
            .toJson(),
        candidate.toJson(),
      );

      await restartController();
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      await controller.saveHero(
        controller.currentCampaign!.hero.copyWith(
          abilities: {...candidate.abilities, 'strength': 20},
        ),
      );
      expect(controller.error, isNull);
      final edited = controller.currentCampaign!;
      expect(edited.revision, confirmed.revision + 1);
      expect(edited.hero.abilities['strength'], 20);
      expect(edited.hero.startingAbilityOrigin!.startingScores['strength'], 19);
      expect(edited.hero.startingAbilityOrigin!.baseScores['strength'], 18);
      expect(edited.hero.startingAbilityOrigin!.toJson(), expectedOrigin);
      expect(edited.events.first.toJson(), confirmed.events.first.toJson());
      expect(
        (await repository.reconstructCampaign(
          confirmed.id,
          revision: confirmed.revision,
        ))!.toJson(),
        confirmed.toJson(),
      );
      expect(
        (await repository.reconstructCampaign(edited.id))!.toJson(),
        edited.toJson(),
      );

      await restartController();
      expect(controller.currentCampaign!.toJson(), edited.toJson());
      final exported = controller.exportCampaign();
      await controller.deleteCampaign(edited.id);
      await controller.importCampaign(exported);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), edited.toJson());
      expect(controller.currentCampaign!.hero.abilities['strength'], 20);
      expect(
        controller.currentCampaign!.hero.startingAbilityOrigin!.toJson(),
        expectedOrigin,
      );
    },
  );

  test(
    'late event rejection rolls back origin, archive and every visible snapshot',
    () async {
      await controller.createDemo();
      await controller.saveHero(
        _withOrigin(controller.currentCampaign!.hero, _rolledSoldierOrigin()),
      );
      expect(controller.error, isNull);
      final confirmed = controller.currentCampaign!;
      final database = await databaseFactoryFfi.openDatabase(databasePath);
      final stored = await _storedTables(database);
      final visible = _visibleCharacterState(controller);
      final origin = confirmed.hero.startingAbilityOrigin!.toJson();
      final generated = standardSoldier();
      final replacement = StartingAbilityOrigin.confirmed(
        method: 'standardArray',
        baseScores: generated.baseScores,
        background: generated.backgroundBoost!.background.label,
        increases: generated.backgroundBoost!.increases,
      );
      final candidate = _withOrigin(
        confirmed.hero,
        replacement,
      ).copyWith(name: 'Nicht bestätigter Entwurf');

      // This fails after SQLite has updated the campaign and inserted its
      // revision, so checking all tables detects a partial transaction.
      await database.execute('''
CREATE TRIGGER reject_origin_event
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"character.updated"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled origin event rejection');
END
''');
      final observed = <String>[];
      void observe() => observed.add(_visibleCharacterState(controller));
      controller.addListener(observe);
      try {
        await controller.saveHero(candidate);
      } finally {
        controller.removeListener(observe);
      }

      expect(controller.error, isNotNull);
      expect(controller.busy, isFalse);
      expect(observed, isNotEmpty);
      expect(observed, everyElement(visible));
      expect(_visibleCharacterState(controller), visible);
      expect(await _storedTables(database), stored);
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(
        controller.currentCampaign!.hero.startingAbilityOrigin!.toJson(),
        origin,
      );
      expect(
        (await repository.getCampaign(confirmed.id))!.toJson(),
        confirmed.toJson(),
      );
      expect(
        await repository.reconstructCampaign(
          confirmed.id,
          revision: confirmed.revision + 1,
        ),
        isNull,
      );

      await database.execute('DROP TRIGGER reject_origin_event');
      await restartController();
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(
        controller.characters
            .singleWhere((hero) => hero.id == confirmed.hero.id)
            .toJson(),
        confirmed.hero.toJson(),
      );
      await controller.saveHero(candidate);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.hero.toJson(), candidate.toJson());
      expect(controller.currentCampaign!.revision, confirmed.revision + 1);
    },
  );

  test(
    'invalid origin hero and campaign imports leave existing SQLite data intact',
    () async {
      await controller.createDemo();
      await controller.saveHero(
        _withOrigin(controller.currentCampaign!.hero, _rolledSoldierOrigin()),
      );
      expect(controller.error, isNull);
      final confirmed = controller.currentCampaign!;
      final database = await databaseFactoryFfi.openDatabase(databasePath);
      final stored = await _storedTables(database);
      final visible = _visibleCharacterState(controller);
      final exportedHero = controller.exportHero(confirmed.hero);
      final corruptions = <void Function(Map<String, dynamic>)>[
        (record) => record['version'] = 1.0,
        (record) => (record['diceRolls'] as List).first[0] = 0,
        (record) => (record['baseScores'] as Map)['strength'] = 17,
      ];
      for (final corrupt in corruptions) {
        final hero = jsonDecode(exportedHero) as Map<String, dynamic>;
        corrupt(hero['startingAbilityOrigin'] as Map<String, dynamic>);
        await controller.importHero(jsonEncode(hero));
        expect(controller.error, isNotNull);
        expect(controller.busy, isFalse);
        expect(_visibleCharacterState(controller), visible);
        expect(await _storedTables(database), stored);
      }

      // A new campaign ID would otherwise be a valid import: failure must
      // result from the origin rather than an existing-campaign conflict.
      final importCandidate = Campaign.fromJson({
        ...confirmed.toJson(),
        'id': 'rejected-origin-campaign',
        'revision': 0,
        'events': <dynamic>[],
      });
      final json =
          jsonDecode(jsonEncode(importCandidate.toJson()))
              as Map<String, dynamic>;
      Campaign.fromJson(json);
      (json['hero']['startingAbilityOrigin']['diceRolls'] as List).first[0] = 7;
      await controller.importCampaign(jsonEncode(json));
      expect(controller.error, isNotNull);
      expect(_visibleCharacterState(controller), visible);
      expect(await _storedTables(database), stored);
      expect(await repository.getCampaign(importCandidate.id), isNull);

      await restartController();
      expect(controller.currentCampaign!.toJson(), confirmed.toJson());
      expect(
        controller.characters
            .singleWhere((hero) => hero.id == confirmed.hero.id)
            .toJson(),
        confirmed.hero.toJson(),
      );
    },
  );
}
