import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _Die implements Random {
  @override
  int nextInt(int max) => max - 1;
  @override
  bool nextBool() => true;
  @override
  double nextDouble() => 0.99;
}

Future<Campaign> _seed(SqliteCampaignRepository repo) async {
  final demo = GameEngine().createDemo();
  final campaign = demo.copyWith(
    hero: demo.hero.copyWith(
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
    ),
    encounter: const Encounter(
      id: 'resistance-db',
      enemyName: 'Kampfgegner',
      enemyHitPoints: 60,
      enemyMaxHitPoints: 60,
    ),
  );
  await repo.saveCampaign(campaign, events: campaign.events);
  return campaign;
}

Future<void> _cast(GameController controller, Campaign campaign) =>
    controller.castMagicMissile(
      campaignId: campaign.id,
      expectedRevision: campaign.revision,
      castingClass: 'Magier',
      slotLevel: 1,
      pactMagic: false,
      targetVisibleConfirmed: true,
      targetWithinRangeConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      noProtectionConfirmed: true,
      confirmedForceDefense: EnemyForceDefense.resistant,
    );

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'Persistierte Resistenz, Schadenswerte und Revisionssperre nach Neustart',
    () async {
      final folder = await Directory.systemTemp.createTemp('force-defense-');
      final path = p.join(folder.path, 'test.sqlite');
      var repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var ctrl = GameController(
        repository: repo,
        engine: GameEngine(dice: DiceEngine(random: _Die())),
      );
      try {
        final original = await _seed(repo);
        await ctrl.openCampaign(original.id);
        await _cast(ctrl, original);
        expect(ctrl.error, isNull);
        final result = ctrl.currentCampaign!;
        expect(
          result.encounter!.enemyForceDefense,
          EnemyForceDefense.resistant,
        );
        expect(result.encounter!.enemyHitPoints, 54);
        expect(result.events.last.payload['appliedMissileDamage'], [2, 2, 2]);
        await _cast(ctrl, original);
        expect(ctrl.error, isNotNull);
        expect(ctrl.currentCampaign!.toJson(), result.toJson());

        ctrl.dispose();
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        ctrl = GameController(repository: repo);
        await ctrl.openCampaign(original.id);
        expect(ctrl.error, isNull);
        expect(ctrl.currentCampaign!.toJson(), result.toJson());
      } finally {
        ctrl.dispose();
        await repo.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
