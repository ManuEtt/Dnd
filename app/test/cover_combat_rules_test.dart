import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_flurry_rules.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.natural);
  final int natural;
  @override
  int nextInt(int max) => (natural - 1).clamp(0, max - 1);
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

GameEngine engine({int natural = 7}) => GameEngine(
  dice: DiceEngine(random: _FixedRandom(natural)),
  clock: () => DateTime.utc(2026, 10, 19),
);

Encounter encounter({
  CoverLevel heroCover = CoverLevel.none,
  CoverLevel enemyCover = CoverLevel.none,
}) => Encounter(
  id: 'foe',
  enemyName: 'Skelettwächter',
  enemyHitPoints: 90,
  enemyMaxHitPoints: 90,
  enemyArmorClass: 12,
  enemyAttackBonus: 3,
  enemyDamage: '1d6',
  heroCover: heroCover,
  enemyCover: enemyCover,
);

Campaign withFight(GameEngine gm, {HeroCharacter? hero}) {
  final c = gm.createDemo(hero: hero);
  return c.copyWith(encounter: encounter());
}

void main() {
  group('Deckung nach deutschem D&D-Einsteigerset, Kapitel 2, S. 12', () {
    test('Halbe und Dreivierteldeckung: RK +2/+5, nur bester Wert', () {
      expect(CoverRules.armorClass(15, CoverLevel.none), 15);
      expect(CoverRules.armorClass(15, CoverLevel.half), 17);
      expect(CoverRules.armorClass(15, CoverLevel.threeQuarters), 20);
      expect(
        CoverRules.strongest([
          CoverLevel.half,
          CoverLevel.threeQuarters,
          CoverLevel.half,
        ]),
        CoverLevel.threeQuarters,
      );
      expect(
        CoverRules.getBonus(
          CoverRules.strongest([CoverLevel.half, CoverLevel.half]),
        ),
        2,
      );
      expect(CoverRules.armorClass(100, CoverLevel.threeQuarters), 100);
    });

    test('Vollständige Deckung verhindert das direkte Angreifen', () {
      expect(CoverRules.canTargetDirectly(CoverLevel.total), isFalse);
      expect(
        () => CoverRules.armorClass(15, CoverLevel.total),
        throwsFormatException,
      );
      expect(CoverRules.canTargetDirectly(CoverLevel.threeQuarters), isTrue);
    });

    test('Geschicklichkeitsrettung nur relativ zum bestätigten Angreifer', () {
      expect(
        CoverRules.savingThrowBonus(
          CoverLevel.half,
          ability: 'dexterity',
          sourceOppositeCover: true,
        ),
        2,
      );
      expect(
        CoverRules.savingThrowBonus(
          CoverLevel.threeQuarters,
          ability: 'dexterity',
          sourceOppositeCover: true,
        ),
        5,
      );
      expect(
        CoverRules.savingThrowBonus(
          CoverLevel.half,
          ability: 'wisdom',
          sourceOppositeCover: true,
        ),
        0,
      );
      expect(
        CoverRules.savingThrowBonus(
          CoverLevel.half,
          ability: 'dexterity',
          sourceOppositeCover: false,
        ),
        0,
      );
      // An area effect can reach around total cover; never auto-succeed it.
      expect(
        CoverRules.savingThrowBonus(
          CoverLevel.total,
          ability: 'dexterity',
          sourceOppositeCover: true,
        ),
        0,
      );
    });

    test('Alte Spielstände ohne Deckungsfeld und falsche Werte', () {
      final original = encounter();
      final legacy = original.toJson();
      expect(legacy.containsKey('heroCover'), isFalse);
      expect(legacy.containsKey('enemyCover'), isFalse);
      final restored = Encounter.fromJson(legacy);
      expect(restored.heroCover, CoverLevel.none);
      expect(restored.enemyCover, CoverLevel.none);
      expect(restored.toJson(), legacy);
      final protected = encounter(
        heroCover: CoverLevel.half,
        enemyCover: CoverLevel.threeQuarters,
      );
      expect(
        Encounter.fromJson(protected.toJson()).toJson(),
        protected.toJson(),
      );
      expect(
        () => Encounter.fromJson({...legacy, 'enemyCover': 'sevenEighths'}),
        throwsFormatException,
      );
      expect(
        () => Encounter.fromJson({...legacy, 'heroCover': 2}),
        throwsFormatException,
      );
    });
  });

  group('Deckung im echten Offline-Kampf', () {
    test('Bestätigung ist protokolliert und kostet keine Kampfaktion', () {
      final gm = engine();
      var campaign = withFight(gm);
      final updated = gm.act(campaign, 'Deckung: Gegner dreiviertel');
      campaign = updated.campaign;
      expect(updated.events.single.type, 'combat.coverConfirmed');
      expect(updated.events.single.payload['armorBonus'], 5);
      expect(campaign.encounter!.enemyCover, CoverLevel.threeQuarters);
      expect(campaign.encounter!.actionUsed, isFalse);
      expect(campaign.encounter!.bonusActionUsed, isFalse);
      final status = gm.act(campaign, 'Deckungsstatus');
      expect(status.events.single.type, 'combat.coverStatus');
      expect(
        status.campaign.messages.last.text,
        contains('Dreivierteldeckung'),
      );
      expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    });

    test('Angriff und Nebenhandversuch berücksichtigen Ziel-RK', () {
      final gm = engine();
      var campaign = withFight(gm);
      campaign = gm.act(campaign, 'Deckung: Gegner halb').campaign;
      final action = gm.act(campaign, 'Ich greife an').campaign;
      expect(action.pendingRoll?.type, 'attack');
      expect(action.pendingRoll?.difficulty, 14);
      expect(Campaign.fromJson(action.toJson()).pendingRoll?.difficulty, 14);
      final miss = gm.resolveRoll(action, total: 13);
      expect(miss.campaign.encounter?.enemyHitPoints, 90);
      expect(miss.events.single.payload['effectiveTargetArmorClass'], 14);
      expect(miss.events.single.payload['targetCover'], 'half');
    });

    test('Manipulierte Angriffsschwierigkeit wird beim Laden abgelehnt', () {
      final gm = engine();
      var campaign = withFight(gm);
      campaign = gm.act(campaign, 'Deckung: Gegner dreiviertel').campaign;
      campaign = gm.act(campaign, 'Ich greife an').campaign;
      final original = campaign.toJson();
      final pending = Map<String, dynamic>.from(original['pendingRoll'] as Map);
      pending['difficulty'] = 12;
      original['pendingRoll'] = pending;
      expect(() => Campaign.fromJson(original), throwsFormatException);
    });

    test(
      'Vollständige Deckung lässt Angriffe nicht starten oder W20 nutzen',
      () {
        final gm = engine();
        var campaign = withFight(gm);
        campaign = gm.act(campaign, 'Deckung: Gegner voll').campaign;
        final blocked = gm.act(campaign, 'Ich greife an');
        expect(blocked.events.single.type, 'rules.blocked');
        expect(blocked.campaign.pendingRoll, isNull);
        expect(blocked.campaign.encounter!.actionUsed, isFalse);
        expect(blocked.campaign.encounter!.enemyHitPoints, 90);
        final reset = gm.act(campaign, 'Deckung: Gegner keine');
        expect(reset.campaign.encounter!.enemyCover, CoverLevel.none);
        expect(
          gm.act(reset.campaign, 'Ich greife an').campaign.pendingRoll?.type,
          'attack',
        );
      },
    );

    test('Gegner darf Held mit vollständiger Deckung nicht angreifen', () {
      final gm = engine(natural: 20);
      var campaign = withFight(gm);
      campaign = gm.act(campaign, 'Deckung: Held voll').campaign;
      final hp = campaign.hero.hitPoints;
      final turn = gm.act(campaign, 'Zug beenden');
      expect(turn.events.single.type, 'combat.turnCompleted');
      expect(turn.events.single.payload['blockedByTotalCover'], true);
      expect(turn.campaign.hero.hitPoints, hp);
      expect(turn.campaign.encounter!.round, 2);
      expect(turn.campaign.encounter!.heroCover, CoverLevel.total);
      expect(
        Campaign.fromJson(turn.campaign.toJson()).toJson(),
        turn.campaign.toJson(),
      );
    });

    test('Halbe Deckung erhöht Gegnerziel-RK um zwei', () {
      final gm = engine(natural: 11);
      var campaign = withFight(gm);
      campaign = gm.act(campaign, 'Deckung: Held halb').campaign;
      final turn = gm.act(campaign, 'Zug beenden');
      expect(turn.events.single.payload['effectiveHeroArmorClass'], 18);
      expect(turn.events.single.payload['heroCover'], 'half');
    });

    test('Bestätigte Bewegung entfernt die bisherige Heldenposition', () {
      final gm = engine();
      var campaign = withFight(gm);
      campaign = gm.act(campaign, 'Deckung: Held dreiviertel').campaign;
      final moved = gm.act(campaign, 'Ich gehe 3 Meter').campaign;
      expect(moved.encounter!.heroCover, CoverLevel.none);
      expect(moved.encounter!.movementRemaining, 6);
      expect(moved.encounter!.enemyCover, CoverLevel.none);
    });

    test('Eine offene Probe sperrt Deckungsänderungen bis zur Auflösung', () {
      final gm = engine();
      final campaign = gm.act(withFight(gm), 'Ich greife an').campaign;
      final update = gm.act(campaign, 'Deckung: Gegner voll');
      expect(update.campaign.pendingRoll?.id, campaign.pendingRoll?.id);
      expect(update.campaign.encounter!.enemyCover, CoverLevel.none);
    });

    test(
      'Rettungswürfe nur gegen konkret bestätigten Gegner verwenden Deckung',
      () {
        final gm = engine(natural: 7);
        var campaign = withFight(gm);
        campaign = gm.act(campaign, 'Deckung: Held dreiviertel').campaign;
        final covered = gm.act(
          campaign,
          'Rettungswurf: Geschicklichkeit SG 20 vom Gegner',
        );
        expect(covered.events.single.type, 'saving.roll');
        expect(covered.events.single.payload['coverBonus'], 5);
        expect(covered.events.single.payload['fromEnemyCover'], true);
        expect(covered.events.single.payload['roll']['modifier'], 7);
        final otherSource = gm.act(
          campaign,
          'Rettungswurf: Geschicklichkeit SG 20',
        );
        expect(
          otherSource.events.single.payload.containsKey('coverBonus'),
          isFalse,
        );
        expect(otherSource.events.single.payload['roll']['modifier'], 2);
        final wisdom = gm.act(
          campaign,
          'Rettungswurf: Weisheit SG 20 vom Gegner',
        );
        expect(wisdom.events.single.payload['coverBonus'], 0);
        expect(wisdom.events.single.payload['roll']['modifier'], 1);
      },
    );

    test('Klassen-Wiederholungswurf bewahrt den bestätigten Deckungsbonus', () {
      final gm = engine(natural: 1);
      final fighter = gm.createDemo().hero.copyWith(level: 9);
      var campaign = withFight(gm, hero: fighter);
      campaign = gm.act(campaign, 'Deckung: Held halb').campaign;
      final save = gm.act(
        campaign,
        'Rettungswurf: Geschicklichkeit SG 30 vom Gegner',
      );
      expect(save.events.single.type, 'saving.roll');
      expect(save.events.single.payload['failed'], isTrue);
      expect(save.events.single.payload['coverBonus'], 2);
      final reroll = gm.act(
        save.campaign,
        'Rettungswurf wiederholen: Unbeugsam',
      );
      expect(reroll.events.single.type, 'saving.rerolled');
      expect(reroll.events.single.payload['coverBonus'], 2);
      // DEX +2, cover +2, Fighter 9 (Indomitable) +9.
      expect(reroll.events.single.payload['roll']['modifier'], 13);
    });
  });

  test('Schlaghagel berücksichtigt Deckung vor Ressourcenverbrauch', () {
    final monk = HeroCharacter(
      id: 'monk',
      name: 'Liora',
      className: 'Mönch',
      level: 2,
      abilities: const {'strength': 12, 'dexterity': 16, 'wisdom': 14},
      hitPoints: 25,
      maxHitPoints: 25,
      armorClass: 15,
      speed: 9,
    );
    final dice = DiceEngine(random: _FixedRandom(9));
    final covered = encounter(enemyCover: CoverLevel.total);
    final before = ClassResourceRules.remaining(monk, 'focusPoints');
    expect(() => MonkFlurryRules.use(monk, covered, dice), throwsStateError);
    expect(ClassResourceRules.remaining(monk, 'focusPoints'), before);
    expect(MonkFlurryRules.canUse(monk, covered), isFalse);
    expect(
      MonkFlurryRules.canUse(
        monk,
        encounter(enemyCover: CoverLevel.threeQuarters),
      ),
      isTrue,
    );
    final partial = MonkFlurryRules.use(
      monk,
      encounter(enemyCover: CoverLevel.threeQuarters),
      dice,
    );
    expect(partial.strikes.every((strike) => !strike.hit), isTrue);
    expect(partial.encounter.enemyHitPoints, 90);
  });
}
