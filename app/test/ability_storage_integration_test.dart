import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
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
}
