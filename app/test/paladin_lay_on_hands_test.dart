import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/paladin_lay_on_hands.dart';

class MinimumRandom implements Random {
  @override int nextInt(int max) => 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

HeroCharacter paladin({int paladinLevel = 3, bool multiclass = false,
    int hitPoints = 12, int maxHitPoints = 30,
    List<String> conditions = const [], Map<String, int> spent = const {}}) =>
    HeroCharacter(
      id: 'paladin', name: 'Liora',
      className: multiclass ? 'Kämpfer' : 'Paladin',
      secondaryClassName: multiclass ? 'Paladin' : '',
      secondaryClassLevel: multiclass ? paladinLevel : 0,
      level: paladinLevel + (multiclass ? 4 : 0),
      hitPoints: hitPoints, maxHitPoints: maxHitPoints,
      armorClass: 15, speed: 9, weaponDamage: '1d8',
      weaponProficient: true,
      abilities: const {'strength': 14, 'dexterity': 12,
        'constitution': 14, 'intelligence': 10, 'wisdom': 12,
        'charisma': 16},
      conditions: conditions, spentClassResources: spent,
    );

GameEngine gm() => GameEngine(dice: DiceEngine(random: MinimumRandom()),
    clock: () => DateTime.utc(2026, 10, 16));

void main() {
  group('SRD 5.2.1: Paladin Handauflegen', () {
    test('Heilung kostet genau gewählte Punkte, nicht geheilten Überschuss', () {
      final result = PaladinLayOnHands.useOnSelf(paladin(), healing: 10);
      expect(result.pointsSpent, 10);
      expect(result.hitPointsRestored, 10);
      expect(result.hero.hitPoints, 22);
      expect(PaladinLayOnHands.remaining(result.hero), 5);
      final capped = PaladinLayOnHands.useOnSelf(
          paladin(hitPoints: 29), healing: 10);
      expect(capped.hero.hitPoints, 30);
      expect(capped.hitPointsRestored, 1);
      expect(PaladinLayOnHands.remaining(capped.hero), 5);
    });

    test('Vergiftung entfernen kostet fünf Punkte, heilt keine TP', () {
      final result = PaladinLayOnHands.useOnSelf(
          paladin(conditions: ['vergiftet', 'blind']),
          removePoisoned: true);
      expect(result.pointsSpent, 5);
      expect(result.hitPointsRestored, 0);
      expect(result.hero.conditions, ['blind']);
      expect(result.hero.hitPoints, 12);
      expect(PaladinLayOnHands.remaining(result.hero), 10);
    });

    test('Unterstützt eine bewusste Kombination aus Heilung und Entgiftung', () {
      final result = PaladinLayOnHands.useOnSelf(
          paladin(conditions: ['vergiftet']), healing: 3,
          removePoisoned: true);
      expect(result.pointsSpent, 8);
      expect(result.hitPointsRestored, 3);
      expect(result.hero.conditions, isEmpty);
      expect(PaladinLayOnHands.remaining(result.hero), 7);
    });

    test('Sperrt illegale Klasse, fehlende Werte, zu viele Punkte', () {
      expect(() => PaladinLayOnHands.useOnSelf(
          paladin(paladinLevel: 1), healing: 6), throwsStateError);
      expect(() => PaladinLayOnHands.useOnSelf(
          paladin(conditions: ['blind']), removePoisoned: true),
          throwsStateError);
      expect(() => PaladinLayOnHands.useOnSelf(
          paladin(), healing: 0), throwsStateError);
      expect(() => PaladinLayOnHands.useOnSelf(
          paladin(), healing: -1), throwsRangeError);
      expect(() => PaladinLayOnHands.useOnSelf(
          paladin(hitPoints: 0), healing: 1), throwsStateError);
      expect(() => PaladinLayOnHands.useOnSelf(
          paladin().copyWith(className: 'Magier'), healing: 1),
          throwsStateError);
    });

    test('Mehrklassenstufen, Speicherung und Rast-Regeneration', () {
      final original = paladin(paladinLevel: 2, multiclass: true);
      expect(PaladinLayOnHands.remaining(original), 10);
      final result = PaladinLayOnHands.useOnSelf(original, healing: 7);
      final loaded = HeroCharacter.fromJson(result.hero.toJson());
      expect(loaded.spentClassResources['layOnHands'], 7);
      expect(PaladinLayOnHands.remaining(loaded), 3);
      expect(PaladinLayOnHands.remaining(
        ClassResourceRules.afterShortRest(loaded)), 3);
      expect(PaladinLayOnHands.remaining(
        ClassResourceRules.afterLongRest(loaded)), 10);
    });

    test('Kampfaktion benötigt freie Bonusaktion und wird protokolliert', () {
      final engine = gm();
      var campaign = engine.createDemo();
      campaign = campaign.copyWith(
        hero: paladin().copyWith(id: campaign.hero.id));
      campaign = engine.act(campaign, 'Ich gehe zum Waldschrein.').campaign;
      expect(campaign.encounter, isNotNull);
      final first = engine.act(campaign, 'Handauflegen: 5');
      expect(first.events.single.type, 'class.layOnHands');
      expect(first.campaign.hero.hitPoints, 17);
      expect(first.campaign.encounter!.bonusActionUsed, isTrue);
      expect(first.events.single.payload['pointsSpent'], 5);
      final blocked = engine.act(first.campaign, 'Handauflegen: 1');
      expect(blocked.events.single.type, 'rules.blocked');
      expect(blocked.campaign.hero.spentClassResources['layOnHands'], 5);
      final loaded = Campaign.fromJson(first.campaign.toJson());
      expect(loaded.encounter!.bonusActionUsed, isTrue);
    });

    test('Handauflegen ist außerhalb des Kampfes ausdrücklich möglich', () {
      final engine = gm();
      var campaign = engine.createDemo();
      campaign = campaign.copyWith(
        hero: paladin(conditions: ['vergiftet']).copyWith(id: campaign.hero.id));
      final event = engine.act(campaign, 'Handauflegen: Vergiftung');
      expect(event.events.single.type, 'class.layOnHands');
      expect(event.campaign.hero.conditions, isEmpty);
      expect(PaladinLayOnHands.remaining(event.campaign.hero), 10);
    });

    test('Unzulässige Heilung verändert weder Ressourcen noch Kampfzustand', () {
      final engine = gm();
      final campaign = engine.createDemo().copyWith(hero: paladin());
      final blocked = engine.act(campaign, 'Handauflegen: 99');
      expect(blocked.events.single.type, 'rules.blocked');
      expect(blocked.campaign.hero.spentClassResources, isEmpty);
    });
  });
}
