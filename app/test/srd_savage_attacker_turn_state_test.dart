import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_savage_attacker_rules.dart';

class _FixedDie implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

const fight = Encounter(
  id: 'savage-fight',
  enemyName: 'Skelett',
  enemyHitPoints: 40,
  enemyMaxHitPoints: 40,
  enemyAttackBonus: 0,
  enemyDamage: '1d4',
);

HeroCharacter soldier() => HeroCharacter(
  id: 'soldier',
  name: 'Tala',
  className: 'Kämpfer',
  background: SrdBackground.soldier.label,
  level: 1,
  hitPoints: 25,
  maxHitPoints: 25,
  armorClass: 18,
  speed: 9,
  weaponDamage: '1d6',
  abilities: const {
    'strength': 14,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 14,
    'wisdom': 14,
    'charisma': 14,
  },
  startingBackgroundPackage: SrdBackgroundPackageChoice(
    background: SrdBackground.soldier,
    takeGold: true,
    gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
  ),
);

void main() {
  test('old encounter JSON omits the new optional boolean', () {
    final old = fight.toJson();
    expect(old.containsKey('savageAttackerUsedThisTurn'), false);
    final restored = Encounter.fromJson(old);
    expect(restored.savageAttackerUsedThisTurn, false);
    expect(restored.toJson(), old);
  });

  test('spent flag is persisted, strict and immutable across copies', () {
    final spent = fight.copyWith(savageAttackerUsedThisTurn: true);
    expect(fight.savageAttackerUsedThisTurn, false);
    expect(spent.toJson()['savageAttackerUsedThisTurn'], true);
    expect(Encounter.fromJson(spent.toJson()).toJson(), spent.toJson());
    for (final invalid in [1, 'true', null]) {
      if (invalid == null) continue;
      expect(
        () => Encounter.fromJson({
          ...fight.toJson(),
          'savageAttackerUsedThisTurn': invalid,
        }),
        throwsFormatException,
      );
    }
    expect(SrdSavageAttackerRules.canOfferOnTurn(soldier(), spent), false);
    expect(SrdSavageAttackerRules.canOfferOnTurn(soldier(), fight), true);
  });

  test('no feat, enemy turn, finished encounter and KO block offer', () {
    final hero = soldier();
    expect(
      SrdSavageAttackerRules.canOfferOnTurn(
        hero.copyWith(startingBackgroundPackage: null),
        fight,
      ),
      false,
    );
    expect(
      SrdSavageAttackerRules.canOfferOnTurn(
        hero,
        fight.copyWith(activeParticipant: 'enemy'),
      ),
      false,
    );
    expect(
      SrdSavageAttackerRules.canOfferOnTurn(
        hero,
        fight.copyWith(enemyHitPoints: 0),
      ),
      false,
    );
    expect(
      SrdSavageAttackerRules.canOfferOnTurn(hero.copyWith(hitPoints: 0), fight),
      false,
    );
    expect(
      SrdSavageAttackerRules.canOfferOnTurn(
        hero.copyWith(hitPoints: null),
        fight,
      ),
      false,
    );
    expect(
      SrdSavageAttackerRules.canOfferOnTurn(
        hero.copyWith(weaponDamage: ''),
        fight,
      ),
      false,
    );
    expect(SrdSavageAttackerRules.canOfferOnTurn(hero, null), false);
  });

  test('turn end resets spent use only on next hero turn', () {
    final engine = GameEngine(
      dice: DiceEngine(random: _FixedDie()),
      clock: () => DateTime.utc(2026, 10, 27),
    );
    final campaign = engine.createDemo().copyWith(
      hero: soldier(),
      encounter: fight.copyWith(
        actionUsed: true,
        savageAttackerUsedThisTurn: true,
      ),
    );
    final saved = Campaign.fromJson(campaign.toJson());
    expect(saved.encounter!.savageAttackerUsedThisTurn, true);
    final update = engine.endHeroTurn(saved);
    expect(update.campaign.encounter!.activeParticipant, 'hero');
    expect(update.campaign.encounter!.savageAttackerUsedThisTurn, false);
    expect(
      SrdSavageAttackerRules.canOfferOnTurn(
        update.campaign.hero,
        update.campaign.encounter,
      ),
      true,
    );
    expect(saved.encounter!.savageAttackerUsedThisTurn, true);
    expect(
      Campaign.fromJson(update.campaign.toJson()).toJson(),
      update.campaign.toJson(),
    );
  });

  test('another hit on same hero turn never clears a spent flag', () {
    final spent = fight.copyWith(
      actionUsed: true,
      attacksRemaining: 1,
      savageAttackerUsedThisTurn: true,
    );
    expect(
      spent.copyWith(attacksRemaining: 0).savageAttackerUsedThisTurn,
      true,
    );
    expect(
      spent
          .copyWith(bonusActionUsed: true, sneakAttackUsedThisTurn: true)
          .savageAttackerUsedThisTurn,
      true,
    );
  });
}
