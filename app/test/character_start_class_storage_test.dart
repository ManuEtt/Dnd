import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_initiate_choice.dart';
import 'package:lebendiger_spielleiter/domain/starting_class_choice.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

HeroCharacter _confirmedHero({bool takeGold = true}) {
  final choice = StartingClassChoice.confirmed(
    className: 'Barbar',
    skills: const ['Athletik', 'Wahrnehmung'],
    kitIndex: takeGold ? 1 : 0,
  );
  final kit = choice.selection.startingKit!;
  var sequence = 0;
  // Build the already confirmed state once, just as the editor does. The
  // historical record itself is never an instruction to grant this kit again.
  return choice.selection
      .applyTo(
        HeroCharacter(
          id: 'class-start-hero',
          name: 'Liora',
          className: 'Barbar',
          abilities: {for (final ability in abilityNames) ability: 12},
          hitPoints: 13,
          maxHitPoints: 13,
          armorClass: 12,
          speed: 9,
          experience: 0,
        ),
      )
      .copyWith(
        startingClassChoice: choice,
        gold: kit.gold,
        inventory: [
          for (final item in kit.items)
            StartingEquipmentImport.fromStartingItem(
              item,
              'class-item-${sequence++}',
            ),
        ],
      );
}

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository repository;
  late GameController controller;

  Future<void> restart() async {
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

  Future<Map<String, List<Map<String, Object?>>>> tables() async {
    final database = await databaseFactoryFfi.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      return {
        for (final table in const [
          'campaigns',
          'campaign_revisions',
          'game_events',
          'characters',
          'settings',
          'pending_player_actions',
        ])
          table: await database.query(table, orderBy: 'rowid'),
      };
    } finally {
      await database.close();
    }
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('class-start-storage-');
    databasePath = paths.join(directory.path, 'campaign.sqlite');
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
    'Editor-CAS bewahrt Klassen-, Attribut- und Talentbelege ohne erneute Startgaben',
    () async {
      final abilityOrigin = StartingAbilityOrigin.confirmed(
        method: 'standardArray',
        baseScores: const {
          'strength': 15,
          'dexterity': 14,
          'constitution': 13,
          'intelligence': 12,
          'wisdom': 10,
          'charisma': 8,
        },
        background: 'Weiser',
        increases: const {'intelligence': 2, 'constitution': 1},
      );
      final featChoice = SrdMagicInitiateChoice(
        background: SrdBackground.sage,
        cantrips: const ['Fire Bolt', 'Light'],
        levelOneSpell: 'Magic Missile',
        castingAbility: 'intelligence',
      );
      final backgroundChoice = SrdBackgroundPackageChoice(
        background: SrdBackground.sage,
        takeGold: true,
      );
      final hero = backgroundChoice
          .applyTo(
            _confirmedHero(takeGold: false).copyWith(
              background: 'Weiser',
              abilities: abilityOrigin.startingScores,
              startingAbilityOrigin: abilityOrigin,
              hitPoints: 14,
              maxHitPoints: 14,
            ),
            nextId: () =>
                throw StateError('The selected gold option has no items.'),
          )
          .copyWith(startingMagicInitiate: featChoice);
      expect(hero.gold, 65);
      expect(hero.inventory, hasLength(3));
      expect(hero.spells, isEmpty);
      await controller.newCampaign(hero);
      expect(controller.error, isNull);
      await restart();
      final opened = controller.currentCampaign!;
      expect(opened.hero.toJson(), hero.toJson());
      expect(
        opened.hero.startingAbilityOrigin!.toJson(),
        abilityOrigin.toJson(),
      );
      expect(opened.hero.startingMagicInitiate!.toJson(), featChoice.toJson());
      final other = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
        singleInstance: false,
      );
      try {
        // Another writer confirms a purchase/sale after this editor opened.
        final winner = opened.copyWith(
          revision: opened.revision + 1,
          hero: opened.hero.copyWith(
            gold: 4,
            inventory: opened.hero.inventory.skip(1).toList(),
          ),
        );
        await other.saveCampaign(winner, expectedRevision: opened.revision);
        final beforeRejectedSave = await tables();
        await controller.saveHero(
          opened.hero.copyWith(backstory: 'Veralteter Entwurf'),
          expectedCampaignId: opened.id,
          expectedRevision: opened.revision,
        );
        expect(controller.error, contains('geändert'));
        expect(await tables(), beforeRejectedSave);
        expect((await other.getCampaign(opened.id))!.toJson(), winner.toJson());
      } finally {
        await other.close();
      }
      await restart();
      final current = controller.currentCampaign!;
      expect(
        current.hero.startingAbilityOrigin!.toJson(),
        abilityOrigin.toJson(),
      );
      expect(current.hero.startingMagicInitiate!.toJson(), featChoice.toJson());
      expect(current.hero.abilities, abilityOrigin.startingScores);
      expect(current.hero.spells, isEmpty);
      expect(current.hero.gold, 4);
      expect(current.hero.inventory, hasLength(2));
      expect(
        current.hero.startingClassChoice!.toJson(),
        hero.startingClassChoice!.toJson(),
      );
      await controller.saveHero(
        current.hero.copyWith(backstory: 'Frisch bestätigte Vorgeschichte'),
        expectedCampaignId: current.id,
        expectedRevision: current.revision,
      );
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.hero.gold, 4);
      expect(
        controller.currentCampaign!.hero.startingAbilityOrigin!.toJson(),
        abilityOrigin.toJson(),
      );
      expect(
        controller.currentCampaign!.hero.startingMagicInitiate!.toJson(),
        featChoice.toJson(),
      );
      expect(
        controller.currentCampaign!.hero.abilities,
        abilityOrigin.startingScores,
      );
      expect(controller.currentCampaign!.hero.spells, isEmpty);
      expect(
        controller.currentCampaign!.hero.inventory
            .map((item) => item.toJson())
            .toList(),
        current.hero.inventory.map((item) => item.toJson()).toList(),
      );
      expect(
        controller.currentCampaign!.hero.startingClassChoice!.toJson(),
        hero.startingClassChoice!.toJson(),
      );
    },
  );

  test(
    'Klassenstartnachweis überlebt Archiv, Revision, Neustart und beide JSON-Importe',
    () async {
      final hero = _confirmedHero();
      final proof = hero.startingClassChoice!.toJson();
      expect(hero.gold, 75);
      expect(hero.inventory, isEmpty);
      await controller.saveStandaloneHero(hero);
      expect(controller.error, isNull);
      await controller.newCampaign(controller.characters.single);
      expect(controller.error, isNull);
      await controller.saveHero(
        controller.currentCampaign!.hero.copyWith(
          backstory: 'Bestätigte Vorgeschichte.',
        ),
      );
      expect(controller.error, isNull);
      final campaign = controller.currentCampaign!;
      expect(campaign.events.last.type, 'character.updated');
      expect(
        (await repository.reconstructCampaign(
          campaign.id,
          revision: campaign.revision,
        ))!.hero.startingClassChoice!.toJson(),
        proof,
      );

      await restart();
      expect(controller.currentCampaign!.toJson(), campaign.toJson());
      expect(controller.characters.single.startingClassChoice!.toJson(), proof);
      final heroExport = controller.exportHero(controller.characters.single);
      final campaignExport = controller.exportCampaign();
      await controller.deleteCampaign(campaign.id);
      await controller.deleteCharacter(hero.id);
      await controller.importHero(heroExport);
      expect(controller.error, isNull);
      expect(controller.characters.single.startingClassChoice!.toJson(), proof);
      expect(controller.characters.single.gold, 75);
      await controller.importCampaign(campaignExport);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), campaign.toJson());
      expect(controller.currentCampaign!.hero.gold, 75);
    },
  );

  test(
    'spätere Klassen-, Attribut- und Ausrüstungsänderungen erhalten den historischen Beleg',
    () async {
      final initial = _confirmedHero(takeGold: false);
      final proof = jsonEncode(initial.startingClassChoice!.toJson());
      expect(initial.inventory, hasLength(3));
      expect(initial.inventory[1].quantity, 4);
      await controller.newCampaign(initial);
      expect(controller.error, isNull);
      final initialCampaign = controller.currentCampaign!;
      await controller.saveHero(
        initial.copyWith(
          className: 'Magier',
          level: 5,
          experience: 6500,
          abilities: {...initial.abilities, 'intelligence': 20},
          inventory: const [],
          gold: 3,
          hitPoints: 25,
          maxHitPoints: 25,
        ),
      );
      expect(controller.error, isNull);
      await restart();
      final hero = controller.currentCampaign!.hero;
      expect(hero.className, 'Magier');
      expect(hero.level, 5);
      expect(hero.abilities['intelligence'], 20);
      expect(hero.gold, 3);
      expect(hero.inventory, isEmpty);
      expect(jsonEncode(hero.startingClassChoice!.toJson()), proof);
      expect(hero.startingClassChoice!.className, 'Barbar');
      final first = (await repository.reconstructCampaign(
        initialCampaign.id,
        revision: initialCampaign.revision,
      ))!;
      expect(first.hero.toJson(), initial.toJson());
      final roundTrip = HeroCharacter.fromJson(
        jsonDecode(controller.exportHero(hero)) as Map<String, dynamic>,
      );
      expect(roundTrip.toJson(), hero.toJson());
    },
  );

  test(
    'Altcharakter erhält bei Speicherung und Import keinen Klassenbeleg',
    () async {
      final legacy = _confirmedHero().copyWith(startingClassChoice: null);
      expect(legacy.toJson(), isNot(contains('startingClassChoice')));
      await controller.saveStandaloneHero(legacy);
      expect(controller.error, isNull);
      await restart();
      final restored = controller.characters.single;
      expect(restored.toJson(), legacy.toJson());
      expect(restored.startingClassChoice, isNull);
      final exported = controller.exportHero(restored);
      await controller.deleteCharacter(restored.id);
      await controller.importHero(exported);
      expect(controller.error, isNull);
      expect(controller.characters.single.toJson(), legacy.toJson());
      expect(controller.characters.single.startingClassChoice, isNull);
    },
  );

  test(
    'manipulierte Klassenbeleg-Importe ändern keine gespeicherten Daten',
    () async {
      await controller.newCampaign(_confirmedHero());
      expect(controller.error, isNull);
      final original = controller.currentCampaign!;
      final before = await tables();
      final mutations = <void Function(Map<String, dynamic>)>[
        (choice) => choice['version'] = 3,
        (choice) => choice['version'] = 1.0,
        (choice) => choice['skills'] = ['Athletik', 'Athletik'],
        (choice) => choice['skills'] = ['Arkane Kunde', 'Geschichte'],
        (choice) => choice['kitIndex'] = 99,
        (choice) =>
            choice['equipmentChoices'] = {'fremdes Paket': 'weapon-dagger'},
      ];
      for (final mutate in mutations) {
        final heroData =
            jsonDecode(jsonEncode(original.hero.toJson()))
                as Map<String, dynamic>;
        mutate(heroData['startingClassChoice'] as Map<String, dynamic>);
        await controller.importHero(jsonEncode(heroData));
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), original.toJson());
        expect(await tables(), before);

        final campaignData =
            jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
        campaignData['id'] = 'invalid-class-import';
        for (final event in campaignData['events'] as List) {
          (event as Map<String, dynamic>)['campaignId'] = campaignData['id'];
          event['id'] = 'import-${event['id']}';
        }
        // The surrounding campaign must be valid; its rejection must come
        // from the forged class evidence, not a mismatched event/campaign ID.
        expect(Campaign.fromJson(campaignData).id, 'invalid-class-import');
        (campaignData['hero'] as Map<String, dynamic>)['startingClassChoice'] =
            heroData['startingClassChoice'];
        await controller.importCampaign(jsonEncode(campaignData));
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), original.toJson());
        expect(await tables(), before);
      }
    },
  );

  test(
    'identischer SQLite-Retry vergibt das Klassenstartpaket nicht erneut',
    () async {
      await controller.newCampaign(_confirmedHero(takeGold: false));
      expect(controller.error, isNull);
      final initial = controller.currentCampaign!;
      final update = controller.engine.updateHero(
        initial,
        initial.hero.copyWith(backstory: 'Ausdrücklich bestätigt.'),
      );
      await repository.saveCampaign(
        update.campaign,
        events: update.events,
        expectedRevision: initial.revision,
      );
      final confirmed = await tables();
      await repository.saveCampaign(
        update.campaign,
        events: update.events,
        expectedRevision: initial.revision,
      );
      expect(await tables(), confirmed);
      final restored = (await repository.getCampaign(initial.id))!;
      expect(restored.hero.gold, 15);
      expect(restored.hero.inventory, hasLength(3));
      expect(restored.hero.inventory[1].quantity, 4);
      expect(
        restored.hero.startingClassChoice!.toJson(),
        initial.hero.startingClassChoice!.toJson(),
      );
      final stale = controller.engine.updateHero(
        initial,
        initial.hero.copyWith(gold: 999),
      );
      await expectLater(
        repository.saveCampaign(
          stale.campaign,
          events: stale.events,
          expectedRevision: initial.revision,
        ),
        throwsA(isA<CampaignConflictException>()),
      );
      expect(await tables(), confirmed);
      await restart();
      expect(controller.currentCampaign!.toJson(), restored.toJson());
      expect(controller.characters.single.toJson(), restored.hero.toJson());
    },
  );

  test(
    'später SQLite-Archivfehler rollt Hero, Beleg, Revision und Events zurück',
    () async {
      await controller.newCampaign(_confirmedHero());
      expect(controller.error, isNull);
      final original = controller.currentCampaign!;
      final before = await tables();
      final database = await databaseFactoryFfi.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      try {
        await database.execute('''
CREATE TRIGGER reject_class_archive_insert BEFORE INSERT ON characters
BEGIN SELECT RAISE(ABORT, 'class archive write rejected'); END
''');
        await controller.saveHero(
          original.hero.copyWith(backstory: 'Nicht bestätigt.'),
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), original.toJson());
        expect(await tables(), before);
        expect(
          await repository.reconstructCampaign(
            original.id,
            revision: original.revision + 1,
          ),
          isNull,
        );
      } finally {
        await database.execute(
          'DROP TRIGGER IF EXISTS reject_class_archive_insert',
        );
        await database.close();
      }
      await restart();
      expect(controller.currentCampaign!.toJson(), original.toJson());
      expect(controller.characters.single.toJson(), original.hero.toJson());
    },
  );

  HeroCharacter symbolHero(
    String className,
    String symbolId, {
    bool legacy = false,
  }) {
    final klass = findSrdClass(className)!;
    final proof = legacy
        ? StartingClassChoice.fromJson({
            'version': 1,
            'className': className,
            'skills': klass.skillChoices.take(klass.skillCount).toList(),
            'kitIndex': 0,
            'equipmentChoices': <String, String>{},
          })
        : StartingClassChoice.confirmed(
            className: className,
            skills: klass.skillChoices.take(klass.skillCount),
            kitIndex: 0,
            equipmentChoices: {'Heiliges Symbol': symbolId},
          );
    var next = 0;
    return proof.selection
        .applyTo(
          HeroCharacter(
            id: 'symbol-hero',
            name: 'Liora',
            abilities: {for (final ability in abilityNames) ability: 12},
            hitPoints: className == 'Kleriker' ? 9 : 11,
            maxHitPoints: className == 'Kleriker' ? 9 : 11,
            armorClass: 10,
            speed: 9,
            experience: 0,
          ),
        )
        .copyWith(
          startingClassChoice: proof,
          gold: proof.selection.startingKit!.gold,
          inventory: [
            for (final item in proof.selection.startingKit!.items)
              StartingEquipmentImport.fromSelectedStartingItem(
                item,
                'symbol-item-${next++}',
                selectedCatalogId: proof.equipmentChoices[item.name],
                choiceVersion: proof.version,
              ),
          ],
        );
  }

  for (final className in ['Kleriker', 'Paladin']) {
    for (final suffix in ['amulet', 'emblem', 'reliquary']) {
      test(
        '$className $suffix: SQLite-Neustart, Archiv und beide JSON-Importe',
        () async {
          final symbolId = 'item-holy-symbol-$suffix';
          final hero = symbolHero(className, symbolId);
          await controller.saveStandaloneHero(hero);
          expect(controller.error, isNull);
          await controller.newCampaign(controller.characters.single);
          expect(controller.error, isNull);
          final saved = controller.currentCampaign!;
          final before = await tables();
          await restart();
          expect(await tables(), before);
          expect(controller.currentCampaign!.toJson(), saved.toJson());
          expect(controller.characters.single.toJson(), hero.toJson());
          final exportHero = controller.exportHero(
            controller.characters.single,
          );
          final exportCampaign = controller.exportCampaign();
          await controller.deleteCampaign(saved.id);
          await controller.deleteCharacter(hero.id);
          await controller.importHero(exportHero);
          expect(controller.error, isNull);
          expect(controller.characters.single.toJson(), hero.toJson());
          await controller.importCampaign(exportCampaign);
          expect(controller.error, isNull);
          expect(controller.currentCampaign!.toJson(), saved.toJson());
          expect(
            controller.currentCampaign!.hero.inventory.where(
              (item) => item.catalogId == symbolId,
            ),
            hasLength(1),
          );
          // A normal revision and an exact repository retry cannot grant the kit twice.
          final update = controller.engine.updateHero(
            saved,
            saved.hero.copyWith(backstory: 'Bestätigt.'),
          );
          await repository.saveCampaign(
            update.campaign,
            events: update.events,
            expectedRevision: saved.revision,
          );
          final committed = await tables();
          await repository.saveCampaign(
            update.campaign,
            events: update.events,
            expectedRevision: saved.revision,
          );
          expect(await tables(), committed);
          final stale = controller.engine.updateHero(
            saved,
            saved.hero.copyWith(gold: 999),
          );
          await expectLater(
            repository.saveCampaign(
              stale.campaign,
              events: stale.events,
              expectedRevision: saved.revision,
            ),
            throwsA(isA<CampaignConflictException>()),
          );
          expect(await tables(), committed);
          await restart();
          expect(controller.currentCampaign!.hero.gold, hero.gold);
          expect(
            controller.currentCampaign!.hero.inventory
                .map((i) => i.toJson())
                .toList(),
            hero.inventory.map((i) => i.toJson()).toList(),
          );
          expect(
            controller.currentCampaign!.hero.startingClassChoice!.toJson(),
            hero.startingClassChoice!.toJson(),
          );
        },
      );
    }
    test(
      '$className v1: historischer Symbolplatzhalter bleibt beim Neustart und Editieren erhalten',
      () async {
        final hero = symbolHero(className, '', legacy: true);
        await controller.newCampaign(hero);
        expect(controller.error, isNull);
        final initial = controller.currentCampaign!;
        final before = await tables();
        await restart();
        expect(await tables(), before);
        expect(controller.currentCampaign!.toJson(), initial.toJson());
        await controller.saveHero(
          controller.currentCampaign!.hero.copyWith(
            backstory: 'Historisch bearbeitet.',
          ),
        );
        expect(controller.error, isNull);
        await restart();
        final restored = controller.currentCampaign!.hero;
        expect(restored.startingClassChoice!.version, 1);
        expect(restored.startingClassChoice!.equipmentChoices, isEmpty);
        expect(
          restored.inventory.map((i) => i.toJson()).toList(),
          hero.inventory.map((i) => i.toJson()).toList(),
        );
        expect(
          restored.inventory
              .singleWhere((i) => i.name == 'Heiliges Symbol')
              .stats,
          isNull,
        );
        expect(restored.gold, hero.gold);
        final exported = controller.exportHero(restored);
        await controller.importHero(exported);
        expect(controller.error, isNull);
        expect(
          controller.characters.single.startingClassChoice!.toJson(),
          hero.startingClassChoice!.toJson(),
        );
        expect(
          controller.characters.single.inventory
              .map((i) => i.toJson())
              .toList(),
          hero.inventory.map((i) => i.toJson()).toList(),
        );
      },
    );
  }

  test(
    'Ungültige v2-Symbolimporte ändern keine der sechs SQLite-Tabellen',
    () async {
      await controller.newCampaign(
        symbolHero('Kleriker', 'item-holy-symbol-amulet'),
      );
      expect(controller.error, isNull);
      final campaign = controller.currentCampaign!;
      final before = await tables();
      for (final choices in <Map<String, String>>[
        {},
        {'Heiliges Symbol': 'item-arcane-focus-crystal'},
        {'Heiliges Symbol': 'item-nonexistent'},
      ]) {
        final heroJson =
            jsonDecode(controller.exportHero(campaign.hero))
                as Map<String, dynamic>;
        (heroJson['startingClassChoice']
                as Map<String, dynamic>)['equipmentChoices'] =
            choices;
        await controller.importHero(jsonEncode(heroJson));
        expect(controller.error, isNotNull);
        expect(await tables(), before);
        final campaignJson =
            jsonDecode(controller.exportCampaign()) as Map<String, dynamic>;
        (campaignJson['hero'] as Map<String, dynamic>)['startingClassChoice'] =
            heroJson['startingClassChoice'];
        await controller.importCampaign(jsonEncode(campaignJson));
        expect(controller.error, isNotNull);
        expect(await tables(), before);
        expect(controller.currentCampaign!.toJson(), campaign.toJson());
      }
    },
  );
}
