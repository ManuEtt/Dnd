import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';

class MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter wounded({int hp = 3, int maxHp = 15, int constitution = 14}) =>
    HeroCharacter.fromJson({
      'schemaVersion': 1,
      'id': 'fighter-rest',
      'name': 'Liora',
      'species': 'Mensch',
      'className': 'Kämpfer',
      'level': 2,
      'abilities': {
        'strength': 16,
        'dexterity': 12,
        'constitution': constitution,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 8,
      },
      'hitPoints': hp,
      'maxHitPoints': maxHp,
      'armorClass': 15,
      'speed': 9,
      'weaponDamage': '1d8',
    });

void main() {
  group('SRD 5.2.1 Trefferwürfel und Rast', () {
    test('alte Spielstände erhalten einen unverbrauchten Trefferwürfelpool', () {
      final hero = wounded();
      expect(hero.spentHitDice, isEmpty);
      expect(RestRules.availableHitDice(hero), {'d10': 2});
      final restored = HeroCharacter.fromJson(hero.toJson());
      expect(restored.spentHitDice, isEmpty);
      expect(restored.level, 2);
    });

    test('kurze Rast verbraucht echte Würfel und addiert Konstitution einmal', () {
      final hero = wounded();
      final result = RestRules.shortRest(hero,
          dice: DiceEngine(random: MinimumRandom()), count: 2);
      expect(result.dieType, 'd10');
      expect(result.dice.map((r) => r.rolls.single), [1, 1]);
      expect(result.constitutionBonus, 2);
      expect(result.recovered, 6);
      expect(result.hero.hitPoints, 9);
      expect(result.hero.spentHitDice, {'d10': 2});
      expect(hero.spentHitDice, isEmpty); // never mutate old snapshot
      expect(HeroCharacter.fromJson(result.hero.toJson()).spentHitDice,
          {'d10': 2});
      expect(() => RestRules.shortRest(result.hero,
          dice: DiceEngine(random: MinimumRandom())), throwsStateError);
    });

    test('Heilung hat Mindestwert 1 pro Trefferwürfel und HP-Grenze', () {
      final lowCon = wounded(hp: 14, maxHp: 15, constitution: 3);
      final result = RestRules.shortRest(lowCon,
          dice: DiceEngine(random: MinimumRandom()));
      expect(result.hero.hitPoints, 15);
      expect(result.recovered, 1);
      expect(result.hero.spentHitDice, {'d10': 1});
      final full = RestRules.shortRest(result.hero,
          dice: DiceEngine(random: MinimumRandom()));
      expect(full.recovered, 0);
      expect(full.hero.spentHitDice, {'d10': 2});
    });

    test('Mehrklassen führen getrennte Trefferwürfel nach Typ', () {
      final hero = wounded().copyWith(
          level: 3, secondaryClassName: 'Magier', secondaryClassLevel: 1);
      expect(RestRules.availableHitDice(hero), {'d10': 2, 'd6': 1});
      final result = RestRules.shortRest(hero,
          dieSides: 6, dice: DiceEngine(random: MinimumRandom()));
      expect(result.dieType, 'd6');
      expect(result.hero.spentHitDice, {'d6': 1});
      expect(RestRules.availableHitDice(result.hero), {'d10': 2, 'd6': 0});
      expect(() => RestRules.shortRest(result.hero, dieSides: 6,
          dice: DiceEngine(random: MinimumRandom())), throwsStateError);
      expect(() => RestRules.shortRest(result.hero, dieSides: 12,
          dice: DiceEngine(random: MinimumRandom())), throwsStateError);
    });

    test('lange Rast stellt HP und verbrauchte Würfel wieder her', () {
      final hero = wounded().copyWith(spentHitDice: {'d10': 1});
      final result = RestRules.longRest(hero);
      expect(result.hitPoints, 15);
      expect(result.spentHitDice, isEmpty);
      expect(RestRules.availableHitDice(result), {'d10': 2});
      expect(hero.hitPoints, 3);
      expect(hero.spentHitDice, {'d10': 1});
    });

    test('bewusstlos und tot dürfen keine Rast ausführen', () {
      final zero = wounded(hp: 0);
      expect(() => RestRules.longRest(zero), throwsStateError);
      expect(() => RestRules.shortRest(zero,
          dice: DiceEngine(random: MinimumRandom())), throwsStateError);
      final dead = wounded().copyWith(conditions: ['tot']);
      expect(() => RestRules.longRest(dead), throwsStateError);
    });

    test('Manipulierte Hit-Dice-Speicherdaten werden abgewiesen', () {
      final json = wounded().toJson();
      for (final invalid in [
        {'d10': -1},
        {'d10': 3},
        {'d6': 1, 'd10': 2},
        {'w100': 1},
        {'d10': '2'},
      ]) {
        expect(() => HeroCharacter.fromJson({...json,
          'spentHitDice': invalid}), throwsFormatException);
      }
      final excessive = wounded().copyWith(spentHitDice: {'d6': 1});
      expect(() => RestRules.availableHitDice(excessive), throwsFormatException);
    });

    test('Spielhandlungen speichern die kurze Rast und das Würfelprotokoll', () {
      final engine = GameEngine(
          dice: DiceEngine(random: MinimumRandom()),
          clock: () => DateTime.utc(2026, 10, 15));
      var campaign = engine.createDemo();
      campaign = campaign.copyWith(hero: campaign.hero.copyWith(
          level: 2, hitPoints: 3, maxHitPoints: 15));
      final short = engine.act(campaign, 'Ich mache eine kurze Rast 2W10.');
      expect(short.events.single.type, 'character.shortRest');
      expect(short.campaign.hero.hitPoints, 9);
      expect(short.campaign.hero.spentHitDice, {'d10': 2});
      expect(short.events.single.payload['count'], 2);
      expect(short.events.single.payload['rolls'], hasLength(2));
      final reloaded = Campaign.fromJson(short.campaign.toJson());
      expect(reloaded.hero.spentHitDice, {'d10': 2});
      final blocked = engine.act(reloaded, 'Ich mache eine kurze Rast.');
      expect(blocked.events.single.type, 'rules.blocked');
      expect(blocked.campaign.hero.spentHitDice, {'d10': 2});
      final long = engine.act(reloaded, 'Ich mache eine lange Rast.');
      expect(long.events.single.type, 'character.longRest');
      expect(long.campaign.hero.hitPoints, 15);
      expect(long.campaign.hero.spentHitDice, isEmpty);
    });

    test('Rast im Kampf und unklare Rast ändern keine Trefferpunkte', () {
      final engine = GameEngine(
          dice: DiceEngine(random: MinimumRandom()),
          clock: () => DateTime.utc(2026, 10, 15));
      var game = engine.createDemo();
      game = game.copyWith(hero: game.hero.copyWith(hitPoints: 5));
      final ambiguous = engine.act(game, 'Ich raste.');
      expect(ambiguous.events.single.type, 'rules.blocked');
      expect(ambiguous.campaign.hero.hitPoints, 5);
      final encounter = engine.act(game, 'Ich gehe zum Waldschrein.').campaign;
      expect(encounter.encounter, isNotNull);
      final stopped = engine.act(encounter, 'Ich mache eine lange Rast.');
      expect(stopped.events.single.type, 'rules.blocked');
      expect(stopped.campaign.hero.hitPoints, encounter.hero.hitPoints);
    });
  });
}
