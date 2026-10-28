import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_ranger_tireless_rules.dart';

class _MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({
  int rangerLevel = 10,
  int exhaustion = 2,
  int hitPoints = 12,
  int spentDice = 0,
  bool multiclass = false,
  bool ranger = true,
}) => HeroCharacter(
  id: 'tireless-ranger',
  name: 'Alva',
  className: multiclass || !ranger ? 'Kämpfer' : 'Waldläufer',
  secondaryClassName: multiclass ? 'Waldläufer' : '',
  secondaryClassLevel: multiclass ? rangerLevel : 0,
  level: rangerLevel + (multiclass ? 2 : 0),
  abilities: const {
    'strength': 12,
    'dexterity': 14,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 16,
    'charisma': 10,
  },
  exhaustionLevel: exhaustion,
  hitPoints: hitPoints,
  maxHitPoints: 20,
  temporaryHitPoints: 4,
  speed: 9,
  armorClass: 14,
  weaponDamage: '1d8',
  spentHitDice: {
    if (spentDice > 0) 'd10': spentDice,
  },
);

GameEngine _engine() => GameEngine(
  dice: DiceEngine(random: _MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 28),
);

void main() {
  group('SRD 5.2.1 Waldläufer 10: Unermüdlich, Erschöpfung', () {
    test('nur ab Waldläufer-Klassenstufe 10', () {
      expect(
        SrdRangerTirelessRules.canReduceExhaustion(
          _hero(rangerLevel: 9),
        ),
        isFalse,
      );
      expect(
        SrdRangerTirelessRules.canReduceExhaustion(_hero()),
        isTrue,
      );
      expect(
        SrdRangerTirelessRules.afterShortRest(
          _hero(rangerLevel: 9),
        ).exhaustionLevel,
        2,
      );
      expect(
        SrdRangerTirelessRules.afterShortRest(_hero()).exhaustionLevel,
        1,
      );
    });

    test('Mehrklasse erfordert zehn Waldläufer-, nicht Gesamtstufen', () {
      final before = _hero(rangerLevel: 9, multiclass: true);
      final after = _hero(rangerLevel: 10, multiclass: true);
      expect(before.level, 11);
      expect(after.level, 12);
      expect(
        SrdRangerTirelessRules.afterShortRest(before).exhaustionLevel,
        2,
      );
      expect(
        SrdRangerTirelessRules.afterShortRest(after).exhaustionLevel,
        1,
      );
      expect(
        SrdRangerTirelessRules.afterShortRest(
          _hero(ranger: false),
        ).exhaustionLevel,
        2,
      );
    });

    test('genau ein Level pro Rast, niemals unter null', () {
      final once = SrdRangerTirelessRules.afterShortRest(
        _hero(exhaustion: 3),
      );
      expect(once.exhaustionLevel, 2);
      expect(
        SrdRangerTirelessRules.afterShortRest(once).exhaustionLevel,
        1,
      );
      final rested = _hero(exhaustion: 0);
      expect(
        SrdRangerTirelessRules.afterShortRest(rested).toJson(),
        rested.toJson(),
      );
    });

    test('Tod, HP, temporäre HP und gespeicherte Originalwerte', () {
      final dead = _hero(exhaustion: 6);
      expect(SrdRangerTirelessRules.canReduceExhaustion(dead), isFalse);
      final fresh = _hero(exhaustion: 2);
      final original = fresh.toJson();
      final result = SrdRangerTirelessRules.afterShortRest(fresh);
      expect(result.hitPoints, fresh.hitPoints);
      expect(result.temporaryHitPoints, fresh.temporaryHitPoints);
      expect(fresh.toJson(), original);
      expect(HeroCharacter.fromJson(result.toJson()).exhaustionLevel, 1);
    });

    test('bewusstlos ohne Trefferpunkte bekommt keinen Rastbonus', () {
      final hero = _hero(hitPoints: 0);
      expect(SrdRangerTirelessRules.canReduceExhaustion(hero), isFalse);
      expect(
        SrdRangerTirelessRules.afterShortRest(hero).exhaustionLevel,
        2,
      );
    });

    test('Klassenressourcen-Rastpfad nutzt denselben Effekt einmal', () {
      final fresh = _hero();
      final result = ClassResourceRules.afterShortRest(fresh);
      expect(result.exhaustionLevel, 1);
      expect(fresh.exhaustionLevel, 2);
    });

    test('ausgegebene Trefferwürfel verursachen nur eine Senkung', () {
      final fresh = _hero();
      final rest = RestRules.shortRest(
        fresh,
        dice: DiceEngine(random: _MinimumRandom()),
      );
      expect(rest.hero.exhaustionLevel, 1);
      expect(rest.hero.hitPoints, 14);
      expect(rest.hero.spentHitDice['d10'], 1);
    });

    test('volle HP und sonst keine Ressourcenkosten erlauben kurze Rast', () {
      final engine = _engine();
      final base = engine.createDemo();
      final camp = base.copyWith(
        hero: _hero(hitPoints: 20).copyWith(id: base.hero.id),
      );
      final done = engine.act(camp, 'Ich mache eine kurze Rast.');
      expect(done.events.single.type, 'character.shortRest');
      expect(done.campaign.hero.exhaustionLevel, 1);
      expect(done.campaign.hero.spentHitDice, isEmpty);
      expect(done.events.single.payload['count'], 0);
      expect(done.events.single.payload['exhaustionBefore'], 2);
      expect(done.events.single.payload['exhaustionAfter'], 1);
      expect(
        Campaign.fromJson(done.campaign.toJson()).hero.exhaustionLevel,
        1,
      );
    });

    test('verwundet ohne verbleibende Trefferwürfel: reine Rast', () {
      final engine = _engine();
      final base = engine.createDemo();
      final hero = _hero(spentDice: 10).copyWith(id: base.hero.id);
      final done = engine.act(
        base.copyWith(hero: hero),
        'Ich mache eine kurze Rast.',
      );
      expect(done.events.single.type, 'character.shortRest');
      expect(done.campaign.hero.hitPoints, 12);
      expect(done.campaign.hero.spentHitDice['d10'], 10);
      expect(done.campaign.hero.exhaustionLevel, 1);
      expect(done.events.single.payload['count'], 0);
    });

    test('ohne Tireless keine automatische Erschöpfungsreduktion', () {
      final engine = _engine();
      final base = engine.createDemo();
      final hero = _hero(
        rangerLevel: 9,
        hitPoints: 20,
      ).copyWith(id: base.hero.id);
      final blocked = engine.act(
        base.copyWith(hero: hero),
        'Ich mache eine kurze Rast.',
      );
      expect(blocked.events.single.type, 'rules.blocked');
      expect(blocked.campaign.hero.exhaustionLevel, 2);
    });

    test('lange Rast behält ihre eigene Erschöpfungsregel', () {
      final hero = _hero(exhaustion: 3);
      final restored = RestRules.longRest(hero);
      expect(restored.exhaustionLevel, 2);
      expect(restored.hitPoints, 20);
    });
  });
}
