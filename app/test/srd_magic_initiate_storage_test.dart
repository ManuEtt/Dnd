import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_initiate_choice.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

void main() {
  sqfliteFfiInit();

  test('Magic Initiate survives SQLite restart, export and import intact',
      () async {
    final directory = await Directory.systemTemp.createTemp(
      'magic-initiate-choices-',
    );
    final dbPath = paths.join(directory.path, 'magic-initiate.sqlite');
    SqliteCampaignRepository? repository;
    GameController? controller;

    Future<void> connect() async {
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: dbPath,
      );
      controller = GameController(repository: repository!);
      await controller!.initialize();
      expect(controller!.error, isNull);
    }

    try {
      await connect();
      final choice = SrdMagicInitiateChoice(
        background: SrdBackground.acolyte,
        cantrips: ['Guidance', 'Sacred Flame'],
        levelOneSpell: 'Bless',
        castingAbility: 'charisma',
      );
      final hero = HeroCharacter(
        id: 'acolyte-hero',
        name: 'Priester',
        background: 'Akolyth',
        startingBackgroundPackage: SrdBackgroundPackageChoice(
          background: SrdBackground.acolyte,
          takeGold: true,
        ),
        startingMagicInitiate: choice,
      );

      await controller!.saveStandaloneHero(hero);
      expect(controller!.error, isNull);
      controller!.dispose();
      await repository!.close();
      await connect();
      final restored = controller!.characters.single;
      expect(restored.toJson(), hero.toJson());
      expect(restored.startingMagicInitiate!.toJson(), choice.toJson());
      expect(restored.spells, isEmpty);

      final exported = controller!.exportHero(restored);
      await controller!.deleteCharacter(hero.id);
      await controller!.importHero(exported);
      expect(controller!.error, isNull);
      expect(controller!.characters.single.toJson(), hero.toJson());
      expect(controller!.characters.single.spells, isEmpty);
    } finally {
      controller?.dispose();
      await repository?.close();
      await directory.delete(recursive: true);
    }
  });
}
