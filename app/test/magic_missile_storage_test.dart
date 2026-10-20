import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _Random implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

Future<void> cast(GameController controller, Campaign c) =>
    controller.castMagicMissile(
      campaignId: c.id,
      expectedRevision: c.revision,
      castingClass: 'Magier',
      slotLevel: 1,
      pactMagic: false,
      targetVisibleConfirmed: true,
      targetWithinRangeConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      noProtectionConfirmed: true,
    );

Future<Campaign> seed(SqliteCampaignRepository repository) async {
  final start = GameEngine().createDemo();
  final hero = start.hero.copyWith(
    className: 'Magier',
    level: 5,
    spells: ['Magisches Geschoss'],
    abilities: const {
      'strength': 10,
      'dexterity': 12,
      'constitution': 14,
      'intelligence': 16,
      'wisdom': 12,
      'charisma': 14,
    },
  );
  final before = start.copyWith(
    hero: hero,
    encounter: const Encounter(
      id: 'missile-storage',
      enemyName: 'Gegner',
      enemyHitPoints: 80,
      enemyMaxHitPoints: 80,
    ),
  );
  await repository.saveCampaign(before, events: before.events);
  return before;
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('SQLite-Neustart, Event-Journal und Revisionsschutz', () async {
    final directory = await Directory.systemTemp.createTemp('missile-db-');
    final path = p.join(directory.path, 'game.sqlite');
    var repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var controller = GameController(
      repository: repo,
      engine: GameEngine(dice: DiceEngine(random: _Random())),
    );
    try {
      final before = await seed(repo);
      await controller.openCampaign(before.id);
      await cast(controller, before);
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(after.encounter!.enemyHitPoints, 74);
      expect(after.hero.spentSpellSlots, {'1': 1});
      expect(after.events.last.type, 'spell.magicMissile');

      await cast(controller, before);
      expect(controller.error, contains('erneut öffnen'));
      expect(controller.currentCampaign!.toJson(), after.toJson());
      controller.dispose();
      await repo.close();

      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
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

  test(
    'Fehler im Event-Insert rollt Gegner-TP und Zauberplatz zurück',
    () async {
      final directory = await Directory.systemTemp.createTemp('missile-fail-');
      final path = p.join(directory.path, 'game.sqlite');
      final repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final controller = GameController(
        repository: repo,
        engine: GameEngine(dice: DiceEngine(random: _Random())),
      );
      try {
        final before = await seed(repo);
        await controller.openCampaign(before.id);
        final database = await databaseFactoryFfi.openDatabase(path);
        try {
          await database.execute('''
CREATE TRIGGER reject_missile
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"spell.magicMissile"') > 0
BEGIN
  SELECT RAISE(ABORT, 'blocked missile journal');
END
''');
          await cast(controller, before);
          expect(controller.error, isNotNull);
          expect(controller.currentCampaign!.toJson(), before.toJson());
          expect(
            (await repo.getCampaign(before.id))!.toJson(),
            before.toJson(),
          );
        } finally {
          await database.close();
        }
      } finally {
        controller.dispose();
        await repo.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
