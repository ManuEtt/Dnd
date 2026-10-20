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

class _FixedRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

Future<Campaign> _seed(SqliteCampaignRepository db) async {
  final initial = GameEngine().createDemo();
  final campaign = initial.copyWith(
    hero: initial.hero.copyWith(
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
      id: 'shield-event',
      enemyName: 'Gegner',
      enemyHitPoints: 80,
      enemyMaxHitPoints: 80,
    ),
  );
  await db.saveCampaign(campaign, events: campaign.events);
  return campaign;
}

Future<void> _cast(GameController ctrl, Campaign current) =>
    ctrl.castMagicMissile(
      campaignId: current.id,
      expectedRevision: current.revision,
      castingClass: 'Magier',
      slotLevel: 1,
      pactMagic: false,
      targetVisibleConfirmed: true,
      targetWithinRangeConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      noProtectionConfirmed: false,
      confirmedForceDefense: EnemyForceDefense.normal,
      shieldReactionConfirmed: true,
      shieldPreparedAndComponentsConfirmed: true,
      confirmedEnemyShieldSlots: 2,
    );

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'Bestätigte Gegnerreaktion überlebt SQLite-Neustart und Revisionskonflikt',
    () async {
      final dir = await Directory.systemTemp.createTemp('enemy-shield-db-');
      final path = p.join(dir.path, 'game.sqlite');
      var db = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var ctrl = GameController(
        repository: db,
        engine: GameEngine(dice: DiceEngine(random: _FixedRandom())),
      );
      try {
        final start = await _seed(db);
        await ctrl.openCampaign(start.id);
        await _cast(ctrl, start);
        expect(ctrl.error, isNull);
        final result = ctrl.currentCampaign!;
        expect(result.encounter!.enemyShieldSlotsRemaining, 1);
        expect(result.encounter!.enemyShieldActive, isTrue);
        expect(result.encounter!.enemyShieldReactionUsed, isTrue);
        expect(result.encounter!.enemyHitPoints, 80);
        expect(result.hero.spentSpellSlots, {'1': 1});
        expect(result.events.last.payload['shieldBlocked'], isTrue);
        await _cast(ctrl, start);
        expect(ctrl.error, isNotNull);
        expect(ctrl.currentCampaign!.toJson(), result.toJson());
        ctrl.dispose();
        await db.close();
        db = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        ctrl = GameController(repository: db);
        await ctrl.openCampaign(start.id);
        expect(ctrl.error, isNull);
        expect(ctrl.currentCampaign!.toJson(), result.toJson());
      } finally {
        ctrl.dispose();
        await db.close();
        await dir.delete(recursive: true);
      }
    },
  );
}
