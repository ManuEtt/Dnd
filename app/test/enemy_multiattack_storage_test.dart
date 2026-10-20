import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/hero_shield_reaction_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

class _Roll implements Random {
  _Roll(this.natural);
  final int natural;
  @override
  int nextInt(int max) => max == 20 ? natural - 1 : 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

const _plan = HeroShieldReactionPlan(
  castingClass: 'Magier',
  slotLevel: 1,
  pactMagic: false,
  verbalConfirmed: true,
  somaticConfirmed: true,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test('SQLite-Neustart mitten im Mehrfachzug erhält Schild und Ressourcen', () async {
    final dir = await Directory.systemTemp.createTemp('multiattack-storage-');
    final path = p.join(dir.path, 'game.db');
    var db = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var controller = GameController(
      repository: db,
      engine: GameEngine(dice: DiceEngine(random: _Roll(13))),
    );
    try {
      final demo = GameEngine().createDemo();
      final started = demo.copyWith(
        hero: demo.hero.copyWith(
          className: 'Magier',
          level: 5,
          spells: ['Schild'],
          abilities: const {
            'strength': 10,
            'dexterity': 12,
            'constitution': 14,
            'intelligence': 16,
            'wisdom': 12,
            'charisma': 14,
          },
          hitPoints: 20,
          maxHitPoints: 20,
          armorClass: 14,
          speed: 9,
        ),
        encounter: const Encounter(
          id: 'multi-save',
          enemyName: 'Kampfg egner',
          enemyHitPoints: 80,
          enemyMaxHitPoints: 80,
          enemyAttacksPerTurn: 2,
          enemyDamage: '1d4',
        ),
      );
      await db.saveCampaign(started, events: started.events);
      await controller.openCampaign(started.id);
      final offer = GameEngine(dice: DiceEngine(random: _Roll(13)))
          .endHeroTurn(started);
      await db.saveCampaign(offer.campaign, events: offer.events);
      await controller.openCampaign(started.id);
      final pending = controller.currentCampaign!;
      expect(pending.pendingEnemyShieldHit, isNotNull);
      await controller.resolveEnemyShieldHit(
        campaignId: pending.id,
        expectedRevision: pending.revision,
        plan: _plan,
      );
      expect(controller.error, isNull);
      final shielded = controller.currentCampaign!;
      expect(shielded.encounter!.heroShieldActive, isTrue);
      expect(shielded.encounter!.enemyAttacksRemaining, 1);
      expect(shielded.hero.spentSpellSlots, {'1': 1});

      controller.dispose();
      await db.close();
      db = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(
        repository: db,
        engine: GameEngine(dice: DiceEngine(random: _Roll(16))),
      );
      await controller.openCampaign(started.id);
      expect(controller.currentCampaign!.toJson(), shielded.toJson());
      final staleRevision = started.revision;
      await controller.act(
        campaignId: started.id,
        expectedRevision: staleRevision,
        input: 'Gegnerangriff fortsetzen',
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), shielded.toJson());
      await controller.act(
        campaignId: started.id,
        expectedRevision: shielded.revision,
        input: 'Gegnerangriff fortsetzen',
      );
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.encounter!.activeParticipant, 'hero');
      expect(controller.currentCampaign!.encounter!.round, 2);
      expect(controller.currentCampaign!.encounter!.heroShieldActive, isFalse);
      expect(controller.currentCampaign!.hero.spentSpellSlots, {'1': 1});
    } finally {
      controller.dispose();
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
