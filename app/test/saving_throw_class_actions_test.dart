import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';

class FixedRandom implements Random {
  FixedRandom(this.natural);
  final int natural;
  @override int nextInt(int max) => (natural - 1) % max;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

HeroCharacter hero(String className, int level,
    {int spent = 0, bool multiclass = false}) {
  final fighter = className == 'Kämpfer';
  return HeroCharacter(
    id: 'save-hero', name: 'Liora',
    className: multiclass ? 'Paladin' : className,
    level: level + (multiclass ? 3 : 0),
    secondaryClassName: multiclass ? className : '',
    secondaryClassLevel: multiclass ? level : 0,
    abilities: const {'strength': 14, 'dexterity': 16,
      'constitution': 12, 'intelligence': 10,
      'wisdom': 12, 'charisma': 10},
    savingThrowProficiencies: const ['strength'],
    hitPoints: 25, maxHitPoints: 30, armorClass: 15, speed: 9,
    weaponDamage: '1d8', weaponProficient: true,
    spentClassResources: {
      if (spent > 0) (fighter ? 'indomitable' : 'focusPoints'): spent,
    },
  );
}

void main() {
  group('SRD 5.2.1: Klassen-Rettungswurf-Wiederholungen', () {
    test('Kämpferstufe 9 addiert die Kämpferstufe zum neuen Rettungswurf', () {
      final h = hero('Kämpfer', 9);
      final result = SavingThrowClassActions.rerollFailed(
        hero: h, dice: DiceEngine(random: FixedRandom(1)),
        ability: 'strength', difficulty: 18, originalTotal: 8,
        feature: SavingThrowRerollFeature.indomitable);
      expect(result.fighterLevelBonus, 9);
      // Nat 1 + STR 2 + proficiency 4 + fighter level 9 = 16.
      expect(result.roll.total, 16);
      expect(result.passed, isFalse);
      expect(ClassResourceRules.remaining(result.hero, 'indomitable'), 0);
      expect(() => SavingThrowClassActions.rerollFailed(
        hero: result.hero, dice: DiceEngine(random: FixedRandom(20)),
        ability: 'strength', difficulty: 18, originalTotal: 8,
        feature: SavingThrowRerollFeature.indomitable), throwsStateError);
    });

    test('Kämpferressourcen skalieren 9/13/17 und nur lange Rast erneuert', () {
      for (final (level, max) in [(9, 1), (13, 2), (17, 3)]) {
        expect(ClassResourceRules.maximum(hero('Kämpfer', level),
            'indomitable'), max);
      }
      final used = ClassResourceRules.spend(hero('Kämpfer', 13),
          'indomitable');
      expect(ClassResourceRules.remaining(
          ClassResourceRules.afterShortRest(used), 'indomitable'), 1);
      expect(ClassResourceRules.remaining(
          ClassResourceRules.afterLongRest(used), 'indomitable'), 2);
    });

    test('Mönch 14 verbraucht Fokus und muss das neue Resultat behalten', () {
      final result = SavingThrowClassActions.rerollFailed(
        hero: hero('Mönch', 14, multiclass: true),
        dice: DiceEngine(random: FixedRandom(1)),
        ability: 'wisdom', difficulty: 20, originalTotal: 11,
        feature: SavingThrowRerollFeature.disciplinedSurvivor);
      // 1 + Wis 1 + total-level proficiency 6 = 8.
      expect(result.roll.total, 8);
      expect(result.passed, isFalse);
      expect(result.fighterLevelBonus, 0);
      expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 13);
    });

    test('Keine Wiederholung eines bereits gelungenen Wurfs', () {
      final h = hero('Kämpfer', 9);
      expect(() => SavingThrowClassActions.rerollFailed(
        hero: h, dice: DiceEngine(random: FixedRandom(20)),
        ability: 'strength', difficulty: 12, originalTotal: 12,
        feature: SavingThrowRerollFeature.indomitable), throwsStateError);
      expect(() => SavingThrowClassActions.rerollFailed(
        hero: h, dice: DiceEngine(random: FixedRandom(20)),
        ability: 'strength', difficulty: 0, originalTotal: -1,
        feature: SavingThrowRerollFeature.indomitable), throwsRangeError);
      expect(SavingThrowClassActions.available(hero('Kämpfer', 8),
        SavingThrowRerollFeature.indomitable), isFalse);
    });

    test('Manueller Rettungswurf und unmittelbare Wiederholung im Spiel', () {
      final engine = GameEngine(dice: DiceEngine(random: FixedRandom(1)),
          clock: () => DateTime.utc(2026, 10, 16));
      var campaign = engine.createDemo();
      campaign = campaign.copyWith(hero: hero('Kämpfer', 9)
          .copyWith(id: campaign.hero.id));
      final saved = engine.act(campaign, 'Rettungswurf: Stärke SG 18');
      expect(saved.events.single.type, 'saving.roll');
      expect(saved.events.single.payload['failed'], true);
      expect(saved.events.single.payload['manualDifficulty'], true);
      final rerolled = engine.act(saved.campaign,
          'Rettungswurf wiederholen: Unbeugsam');
      expect(rerolled.events.single.type, 'saving.rerolled');
      expect(rerolled.events.single.payload['fighterLevelBonus'], 9);
      expect(rerolled.campaign.hero.spentClassResources['indomitable'], 1);
      expect(Campaign.fromJson(rerolled.campaign.toJson())
          .hero.spentClassResources['indomitable'], 1);
      // No second use on the already-rerolled save.
      final blocked = engine.act(rerolled.campaign,
          'Rettungswurf wiederholen: Unbeugsam');
      expect(blocked.events.single.type, 'rules.blocked');
    });

    test('Frei erfundene oder überhöhte SG werden blockiert', () {
      final engine = GameEngine(dice: DiceEngine(random: FixedRandom(1)));
      var campaign = engine.createDemo();
      campaign = campaign.copyWith(hero: hero('Mönch', 14));
      final denied = engine.act(campaign, 'Rettungswurf: Weisheit SG 50');
      expect(denied.events.single.type, 'rules.blocked');
      expect(denied.campaign.hero.spentClassResources, isEmpty);
    });
  });
}
