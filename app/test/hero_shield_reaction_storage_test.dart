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
  final demo = GameEngine().createDemo();
  final before = demo.copyWith(
    hero: HeroCharacter(
      id: 'hero',
      name: 'Runa',
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
    ),
    encounter: const Encounter(
      id: 'shield-storage',
      enemyName: 'Prüfgegner',
      enemyHitPoints: 30,
      enemyMaxHitPoints: 30,
      enemyAttackBonus: 2,
    ),
  );
  await repo.saveCampaign(before, events: before.events);
  return before;
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('Schildreaktion und Wurfergebnis überleben SQLite-Neustart', () async {
    final dir = await Directory.systemTemp.createTemp('hero-shield-');
    final path = p.join(dir.path, 'game.sqlite');
    var repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    var controller = GameController(
      repository: repo,
      engine: GameEngine(dice: DiceEngine(random: _FixedDie())),
    );
    try {
      final original = await _seed(repo);
      await controller.openCampaign(original.id);
      await controller.endTurnWithShield(
        campaignId: original.id,
        expectedRevision: original.revision,
        plan: _plan,
      );
      expect(controller.error, isNull);
      final after = controller.currentCampaign!;
      expect(after.hero.spentSpellSlots, {'1': 1});
      expect(after.hero.hitPoints, 20);
      expect(after.events.last.payload['shieldReactionTriggered'], isTrue);

      await controller.endTurnWithShield(
        campaignId: original.id,
        expectedRevision: original.revision,
        plan: _plan,
      );
      expect(controller.error, isNotNull);
      expect(controller.currentCampaign!.toJson(), after.toJson());

      controller.dispose();
      await repo.close();
      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      controller = GameController(repository: repo);
      await controller.openCampaign(original.id);
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.toJson(), after.toJson());
    } finally {
      controller.dispose();
      await repo.close();
      await dir.delete(recursive: true);
    }
  });
}
