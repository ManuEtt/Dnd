import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_perfect_focus.dart';

class MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter monk({int level = 15, int spent = 13, bool multiclass = false}) =>
    HeroCharacter(
      id: 'monk',
      name: 'Liora',
      className: multiclass ? 'Kämpfer' : 'Mönch',
      secondaryClassName: multiclass ? 'Mönch' : '',
      secondaryClassLevel: multiclass ? level : 0,
      level: level + (multiclass ? 3 : 0),
      hitPoints: 35,
      maxHitPoints: 40,
      armorClass: 16,
      speed: 9,
      weaponDamage: '1d8',
      weaponProficient: true,
      abilities: const {
        'strength': 12,
        'dexterity': 16,
        'constitution': 14,
        'intelligence': 10,
        'wisdom': 16,
        'charisma': 10,
      },
      spentClassResources: {'focusPoints': spent},
    );
GameEngine gm() => GameEngine(
  dice: DiceEngine(random: MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 16),
);

void main() {
  group('SRD 5.2.1: Mönch 15 Perfekter Fokus', () {
    test('Füllt bei Initiative maximal auf vier Punkte auf', () {
      final hero = monk(spent: 13); // 2 of 15 remaining
      final result = MonkPerfectFocus.onInitiative(hero);
      expect(result.recovered, 2);
      expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 4);
      expect(result.hero.spentClassResources['focusPoints'], 11);
    });
    test('Vier oder mehr Punkte werden nie verändert', () {
      for (final spent in [0, 3, 11]) {
        final result = MonkPerfectFocus.onInitiative(monk(spent: spent));
        expect(result.recovered, 0);
        expect(result.hero.spentClassResources['focusPoints'], spent);
      }
    });
    test('Unter Stufe 15 und bei Uncanny Metabolism kein Nachfüllen', () {
      final low = monk(level: 14, spent: 13);
      expect(MonkPerfectFocus.onInitiative(low).recovered, 0);
      final result = MonkPerfectFocus.onInitiative(
        monk(),
        uncannyMetabolismUsed: true,
      );
      expect(result.recovered, 0);
    });
    test('Mehrklassenstufen und Save-Roundtrip bleiben korrekt', () {
      final hero = monk(level: 15, spent: 14, multiclass: true);
      final result = MonkPerfectFocus.onInitiative(hero);
      expect(result.recovered, 3);
      expect(
        ClassResourceRules.remaining(
          HeroCharacter.fromJson(result.hero.toJson()),
          'focusPoints',
        ),
        4,
      );
    });
    test('Neuer Kampf löst Auffüllung aus, keine Folgerunde', () {
      final engine = gm();
      var campaign = engine.createDemo();
      campaign = campaign.copyWith(hero: monk().copyWith(id: campaign.hero.id));
      final start = engine.act(campaign, 'Ich gehe zum Waldschrein.');
      expect(start.events.single.type, 'combat.started');
      expect(start.events.single.payload['focusRecoveredAtInitiative'], 2);
      expect(
        ClassResourceRules.remaining(start.campaign.hero, 'focusPoints'),
        4,
      );
      final turn = engine.act(start.campaign, 'Ich beende meinen Zug.');
      expect(
        ClassResourceRules.remaining(turn.campaign.hero, 'focusPoints'),
        4,
      );
    });
  });
}
