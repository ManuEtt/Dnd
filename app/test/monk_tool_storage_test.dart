import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/starting_class_choice.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';
import 'package:lebendiger_spielleiter/domain/tool_proficiency_rules.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

HeroCharacter _monk(String tool, {bool gold = false, int version = 3}) {
  final proof = StartingClassChoice.fromJson({
    'version': version,
    'className': 'Mönch',
    'skills': ['Akrobatik', 'Athletik'],
    'kitIndex': gold ? 1 : 0,
    'equipmentChoices': {
      if (!gold) StartingEquipmentImport.monkToolLabel: tool,
    },
    if (version >= 3) 'toolProficiencyCatalogId': tool,
  });
  var id = 0;
  final kit = proof.selection.startingKit!;
  return proof.selection
      .applyTo(
        HeroCharacter(
          id: 'monk',
          name: 'Liora',
          abilities: {for (final ability in abilityNames) ability: 14},
          hitPoints: 10,
          maxHitPoints: 10,
          armorClass: 14,
          speed: 9,
          experience: 0,
        ),
      )
      .copyWith(
        startingClassChoice: proof,
        gold: kit.gold,
        inventory: [
          for (final item in kit.items)
            StartingEquipmentImport.fromSelectedStartingItem(
              item,
              'item-${id++}',
              selectedCatalogId: proof.equipmentChoices[item.name],
              choiceVersion: version,
            ),
        ],
      );
}

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String path;
  late SqliteCampaignRepository repository;
  late GameController controller;
  Future<void> restart() async {
    controller.dispose();
    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    controller = GameController(repository: repository);
    await controller.initialize();
    expect(controller.error, isNull);
  }

  Future<Map<String, List<Map<String, Object?>>>> tables() async {
    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      return {
        for (final table in [
          'campaigns',
          'campaign_revisions',
          'game_events',
          'characters',
          'settings',
          'pending_player_actions',
        ])
          table: await db.query(table, orderBy: 'rowid'),
      };
    } finally {
      await db.close();
    }
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('monk-tool-');
    path = '${directory.path}/campaign.sqlite';
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
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

  for (final tool in ['item-lute', 'item-smith-s-tools']) {
    for (final gold in [false, true]) {
      test(
        '$tool gold=$gold: Archiv, Neustart und Hero-/Kampagnenimport bewahren Quelle und Boni',
        () async {
          final hero = _monk(tool, gold: gold);
          await controller.saveStandaloneHero(hero);
          expect(controller.error, isNull);
          await controller.newCampaign(hero);
          expect(controller.error, isNull);
          final original = controller.currentCampaign!;
          final before = await tables();
          await restart();
          expect(await tables(), before);
          expect(controller.currentCampaign!.toJson(), original.toJson());
          expect(controller.characters.single.toJson(), hero.toJson());
          expect(
            ToolProficiencyRules.catalogIds(controller.currentCampaign!.hero),
            {tool},
          );
          expect(
            CharacterRuleEngine.toolCheck(
              controller.currentCampaign!.hero,
              'dexterity',
              toolCatalogId: tool,
            ).modifier,
            4,
          );
          final exportedHero = controller.exportHero(hero),
              exportedCampaign = controller.exportCampaign();
          await controller.deleteCampaign(original.id);
          await controller.deleteCharacter(hero.id);
          await controller.importHero(exportedHero);
          expect(controller.error, isNull);
          expect(controller.characters.single.toJson(), hero.toJson());
          await controller.importCampaign(exportedCampaign);
          expect(controller.error, isNull);
          expect(controller.currentCampaign!.toJson(), original.toJson());
          expect(controller.currentCampaign!.hero.gold, gold ? 50 : 11);
          expect(
            controller.currentCampaign!.hero.inventory.where(
              (i) => i.catalogId == tool,
            ),
            hasLength(gold ? 0 : 1),
          );
          // Duplicate import/restart reads never grant equipment or a second PB.
          await restart();
          expect(controller.currentCampaign!.hero.toJson(), hero.toJson());
          expect(
            CharacterRuleEngine.toolCheck(
              controller.currentCampaign!.hero,
              'dexterity',
              toolCatalogId: tool,
            ).modifier,
            4,
          );
        },
      );
    }
  }

  test(
    'Veralteter Editor wird atomar abgewiesen; Verkauf entfernt erlernte Übung nicht',
    () async {
      final hero = _monk('item-lute');
      await controller.newCampaign(hero);
      expect(controller.error, isNull);
      final opened = controller.currentCampaign!;
      final other = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
        singleInstance: false,
      );
      try {
        final winner = opened.copyWith(
          revision: opened.revision + 1,
          hero: hero.copyWith(inventory: [], gold: 1),
        );
        await other.saveCampaign(winner, expectedRevision: opened.revision);
        final before = await tables();
        await controller.saveHero(
          hero.copyWith(backstory: 'Veraltete Änderung'),
          expectedCampaignId: opened.id,
          expectedRevision: opened.revision,
        );
        expect(controller.error, isNotNull);
        expect(await tables(), before);
      } finally {
        await other.close();
      }
      await restart();
      final current = controller.currentCampaign!;
      expect(current.hero.inventory, isEmpty);
      expect(current.hero.gold, 1);
      expect(ToolProficiencyRules.catalogIds(current.hero), {'item-lute'});
      expect(
        CharacterRuleEngine.toolCheck(
          current.hero,
          'charisma',
          toolCatalogId: 'item-lute',
        ).modifier,
        4,
      );
      await controller.saveHero(
        current.hero.copyWith(backstory: 'Frisch bestätigt.'),
        expectedCampaignId: current.id,
        expectedRevision: current.revision,
      );
      expect(controller.error, isNull);
      await restart();
      expect(controller.currentCampaign!.hero.inventory, isEmpty);
      expect(controller.currentCampaign!.hero.gold, 1);
      expect(
        controller.currentCampaign!.hero.startingClassChoice!.toJson(),
        hero.startingClassChoice!.toJson(),
      );
    },
  );

  for (final version in [1, 2]) {
    test(
      'v$version: Besitz/Freitext bleiben historisch, ohne Werkzeugübung oder Nachtrag',
      () async {
        final hero = _monk(
          'item-lute',
          version: version,
        ).copyWith(features: ['Werkzeugübung: Laute']);
        await controller.newCampaign(hero);
        expect(controller.error, isNull);
        final before = await tables();
        await restart();
        expect(await tables(), before);
        expect(controller.currentCampaign!.hero.toJson(), hero.toJson());
        expect(
          ToolProficiencyRules.catalogIds(controller.currentCampaign!.hero),
          isEmpty,
        );
        await controller.saveHero(
          controller.currentCampaign!.hero.copyWith(
            backstory: 'Historischer Nachtrag.',
          ),
        );
        expect(controller.error, isNull);
        await restart();
        expect(
          controller.currentCampaign!.hero.startingClassChoice!.toJson(),
          hero.startingClassChoice!.toJson(),
        );
        expect(
          controller.currentCampaign!.hero.inventory
              .map((i) => i.toJson())
              .toList(),
          hero.inventory.map((i) => i.toJson()).toList(),
        );
        expect(controller.currentCampaign!.hero.gold, 11);
        expect(
          ToolProficiencyRules.catalogIds(controller.currentCampaign!.hero),
          isEmpty,
        );
        final exported = controller.exportHero(
          controller.currentCampaign!.hero,
        );
        await controller.importHero(exported);
        expect(controller.error, isNull);
        expect(
          controller.characters.single.startingClassChoice!.version,
          version,
        );
      },
    );
  }

  test(
    'Manipulierte Quellen ändern beim Hero-/Kampagnenimport keine der sechs Tabellen',
    () async {
      await controller.newCampaign(_monk('item-lute'));
      expect(controller.error, isNull);
      final original = controller.currentCampaign!;
      final before = await tables();
      for (final mutate in <void Function(Map<String, dynamic>)>[
        (p) => p.remove('toolProficiencyCatalogId'),
        (p) => p['toolProficiencyCatalogId'] = 'item-thieves-tools',
        (p) => p['toolProficiencyCatalogId'] = 'item-flute',
        (p) => p['toolProficiencyCatalogId'] = true,
        (p) => p['version'] = 2,
        (p) => p['version'] = 4,
      ]) {
        final heroJson =
            jsonDecode(controller.exportHero(original.hero))
                as Map<String, dynamic>;
        mutate(heroJson['startingClassChoice'] as Map<String, dynamic>);
        await controller.importHero(jsonEncode(heroJson));
        expect(controller.error, isNotNull);
        expect(await tables(), before);
        final campaign =
            jsonDecode(controller.exportCampaign()) as Map<String, dynamic>;
        campaign['hero'] = heroJson;
        await controller.importCampaign(jsonEncode(campaign));
        expect(controller.error, isNotNull);
        expect(await tables(), before);
        expect(controller.currentCampaign!.toJson(), original.toJson());
      }
    },
  );
}
