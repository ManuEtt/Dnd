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

class _FixedDie implements Random {
  @override
  int nextInt(int max) => max == 20 ? 12 : 0;
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

Future<Campaign> _seed(SqliteCampaignRepository repo) async {
  final initial = GameEngine().createDemo();
  final hero = HeroCharacter(
    id: 'mage',
    name: 'Mage',
    className: 'Magier',
    level: 5,
    spells: const ['Schild'],
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
    weaponDamage: '1d4',
  );
  final c = initial.copyWith(
    hero: hero,
    encounter: const Encounter(
      id: 'pending-shield-db',
      enemyName: 'Test',
      enemyHitPoints: 25,
      enemyMaxHitPoints: 25,
      enemyAttackBonus: 2,
      enemyDamage: '1d4',
    ),
  );
  await repo.saveCampaign(c, events: c.events);
  return c;
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('SQLite speichert offenen W20, Neustart und Revision ohne zweiten Angriffswurf', () async {
    final dir = await Directory.systemTemp.createTemp('pending-hit-');
    final path = p.join(dir.path, 'game.sqlite');
    var repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var ctrl = GameController(
      repository: repo,
      engine: GameEngine(dice: DiceEngine(random: _FixedDie())),
    );
    try {
      final first = await _seed(repo);
      await ctrl.openCampaign(first.id);
      // Calling the real game engine once, then writing its already-rolled
      // pending attack to the same repository transaction.
      final update = GameEngine(dice: DiceEngine(random: _FixedDie()))
          .endHeroTurn(first);
      await repo.saveCampaign(update.campaign, events: update.events);
      await ctrl.openCampaign(first.id);
      final waiting = ctrl.currentCampaign!;
      expect(waiting.pendingEnemyShieldHit!.total, 15);

      await ctrl.resolveEnemyShieldHit(
        campaignId: waiting.id,
        expectedRevision: waiting.revision,
        plan: _plan,
      );
      expect(ctrl.error, isNull);
      final after = ctrl.currentCampaign!;
      expect(after.pendingEnemyShieldHit, isNull);
      expect(after.hero.spentSpellSlots, {'1': 1});
      expect(after.events.last.payload['choice'], 'cast');
      expect(after.hero.hitPoints, 20);
      await ctrl.resolveEnemyShieldHit(
        campaignId: waiting.id,
        expectedRevision: waiting.revision,
      );
      expect(ctrl.error, isNotNull);
      expect(ctrl.currentCampaign!.toJson(), after.toJson());

      ctrl.dispose();
      await repo.close();
      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      ctrl = GameController(repository: repo);
      await ctrl.openCampaign(first.id);
      expect(ctrl.error, isNull);
      expect(ctrl.currentCampaign!.toJson(), after.toJson());
    } finally {
      ctrl.dispose();
      await repo.close();
      await dir.delete(recursive: true);
    }
  });
}
