import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

HeroCharacter _heroWithConfirmedBackground() {
  final origin = StartingAbilityOrigin.confirmed(
    method: 'standardArray',
    baseScores: const {
      'strength': 15,
      'dexterity': 14,
      'constitution': 13,
      'intelligence': 12,
      'wisdom': 10,
      'charisma': 8,
    },
    background: 'Akolyth',
    increases: const {'wisdom': 2, 'intelligence': 1},
  );
  final choice = SrdBackgroundPackageChoice(
    background: SrdBackground.acolyte,
    takeGold: true,
  );
  return choice.applyTo(
    HeroCharacter(
      id: 'creation-audit-hero',
      name: 'Elowen',
      className: 'Kämpfer',
      species: 'Mensch',
      background: 'Akolyth',
      abilities: origin.startingScores,
      startingAbilityOrigin: origin,
      hitPoints: 11,
      maxHitPoints: 11,
      armorClass: 12,
      speed: 9,
      experience: 0,
    ),
    nextId: () => throw StateError('Die Goldoption erzeugt keine Gegenstände.'),
  );
}

Map<String, CreationStepStatus> _statuses(HeroCharacter hero) => {
  for (final step in SrdCharacterCreationAudit.inspect(hero))
    step.id: step.status,
};

List<List<String>> _report(HeroCharacter hero) => [
  for (final step in SrdCharacterCreationAudit.inspect(hero))
    [step.id, step.title, step.status.name, step.detail],
];

Future<Map<String, List<Map<String, Object?>>>> _storedTables(
  String databasePath,
) async {
  final database = await databaseFactoryFfi.openDatabase(databasePath);
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

  Future<void> expectAuditReadOnly(HeroCharacter hero) async {
    final beforeHero = jsonEncode(hero.toJson());
    final beforeCampaign = jsonEncode(controller.currentCampaign?.toJson());
    final beforeCharacters = jsonEncode([
      for (final character in controller.characters) character.toJson(),
    ]);
    final stored = await _storedTables(databasePath);
    var notifications = 0;
    void observe() => notifications++;
    controller.addListener(observe);
    try {
      final report = _report(hero);
      for (var repeat = 0; repeat < 3; repeat++) {
        expect(_report(hero), report);
      }
    } finally {
      controller.removeListener(observe);
    }
    expect(notifications, 0);
    expect(jsonEncode(hero.toJson()), beforeHero);
    expect(jsonEncode(controller.currentCampaign?.toJson()), beforeCampaign);
    expect(
      jsonEncode([
        for (final character in controller.characters) character.toJson(),
      ]),
      beforeCharacters,
    );
    expect(await _storedTables(databasePath), stored);
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('creation-audit-');
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
    'bestätigte Teilentscheidungen bleiben über Revision, Neustart und beide JSON-Importe erhalten',
    () async {
      await controller.newCampaign(_heroWithConfirmedBackground());
      expect(controller.error, isNull);
      await controller.saveHero(
        controller.currentCampaign!.hero.copyWith(
          backstory: 'Diese Geschichte hat der Spieler ausdrücklich bestätigt.',
        ),
      );
      expect(controller.error, isNull);
      final campaign = controller.currentCampaign!;
      final report = _report(campaign.hero);
      final status = _statuses(campaign.hero);
      expect(status['abilities.scores'], CreationStepStatus.confirmed);
      expect(status['origin.background'], CreationStepStatus.confirmed);
      expect(status['origin.feat'], CreationStepStatus.notAutomated);
      // Hintergrundgold ist kein bestätigtes Klassen-Startpaket.
      expect(status['class.equipment'], isNot(CreationStepStatus.confirmed));
      expect(campaign.events.last.type, 'character.updated');
      await expectAuditReadOnly(campaign.hero);
      expect(
        (await repository.reconstructCampaign(
          campaign.id,
          revision: campaign.revision,
        ))!.toJson(),
        campaign.toJson(),
      );

      await restart();
      expect(controller.currentCampaign!.toJson(), campaign.toJson());
      expect(_report(controller.currentCampaign!.hero), report);
      await expectAuditReadOnly(controller.currentCampaign!.hero);

      final heroExport = controller.exportHero(
        controller.currentCampaign!.hero,
      );
      final campaignExport = controller.exportCampaign();
      await controller.deleteCampaign(campaign.id);
      await controller.deleteCharacter(campaign.hero.id);
      await controller.importHero(heroExport);
      expect(controller.error, isNull);
      expect(_report(controller.characters.single), report);
      await controller.importCampaign(campaignExport);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), campaign.toJson());
      expect(_report(controller.currentCampaign!.hero), report);
      await expectAuditReadOnly(controller.currentCampaign!.hero);
    },
  );

  test(
    'Altcharakter erhält beim Audit weder Herkunftsnachweis noch gespeicherte Hausregel',
    () async {
      final legacy = _heroWithConfirmedBackground().copyWith(
        startingAbilityOrigin: null,
        startingBackgroundPackage: null,
      );
      await controller.saveStandaloneHero(legacy);
      expect(controller.error, isNull);
      await restart();
      final restored = controller.characters.single;
      expect(restored.toJson(), legacy.toJson());
      expect(restored.toJson(), isNot(contains('startingAbilityOrigin')));
      expect(restored.toJson(), isNot(contains('startingBackgroundPackage')));
      expect(
        _statuses(restored)['abilities.scores'],
        CreationStepStatus.notAutomated,
      );
      expect(
        SrdCharacterCreationAudit.inspect(
          restored,
          manualAbilityHouseRule: true,
        ).singleWhere((step) => step.id == 'abilities.scores').status,
        CreationStepStatus.houseRule,
      );
      expect(
        _statuses(restored)['abilities.scores'],
        CreationStepStatus.notAutomated,
      );
      await expectAuditReadOnly(restored);
      final exported = controller.exportHero(restored);
      await controller.deleteCharacter(restored.id);
      await controller.importHero(exported);
      expect(controller.error, isNull);
      expect(controller.characters.single.toJson(), legacy.toJson());
      await expectAuditReadOnly(controller.characters.single);
    },
  );

  test(
    'spätere Attribute werden nicht mit historischen Startwerten verwechselt',
    () async {
      final initial = _heroWithConfirmedBackground();
      await controller.newCampaign(initial);
      expect(controller.error, isNull);
      await controller.saveHero(
        initial.copyWith(
          level: 5,
          experience: 6500,
          abilities: {...initial.abilities, 'strength': 20},
          hitPoints: 35,
          maxHitPoints: 35,
        ),
      );
      expect(controller.error, isNull);
      await restart();
      final hero = controller.currentCampaign!.hero;
      expect(hero.abilities['strength'], 20);
      expect(hero.startingAbilityOrigin!.startingScores['strength'], 15);
      expect(
        hero.startingAbilityOrigin!.toJson(),
        initial.startingAbilityOrigin!.toJson(),
      );
      expect(
        _statuses(hero)['abilities.scores'],
        CreationStepStatus.notAutomated,
      );
      expect(
        _statuses(hero)['origin.background'],
        isNot(CreationStepStatus.invalid),
      );
      await expectAuditReadOnly(hero);
    },
  );
}
