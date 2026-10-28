import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_sorcerous_restoration_rules.dart';

class _MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _sorcerer({
  int classLevel = 5,
  int pointsSpent = 4,
  int restorationSpent = 0,
  int hp = 12,
  int hitDiceSpent = 0,
  bool multiclass = false,
  bool sorcerer = true,
}) => HeroCharacter(
  id: 'sorcerous-hero',
  name: 'Ela',
  className: multiclass || !sorcerer ? 'Kämpfer' : 'Zauberer',
  secondaryClassName: multiclass ? 'Zauberer' : '',
  secondaryClassLevel: multiclass ? classLevel : 0,
  level: classLevel + (multiclass ? 2 : 0),
  hitPoints: hp,
  maxHitPoints: 20,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d6',
  abilities: const {
    'strength': 10,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 12,
    'charisma': 16,
  },
  spentClassResources: {
    if (pointsSpent > 0) 'sorceryPoints': pointsSpent,
    if (restorationSpent > 0)
      SrdSorcerousRestorationRules.resourceKey: restorationSpent,
  },
  spentHitDice: {if (hitDiceSpent > 0) 'd6': hitDiceSpent},
);

GameEngine _engine() => GameEngine(
  dice: DiceEngine(random: _MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 28),
);

void main() {
  group('SRD 5.2.1 Sorcerer 5 – Sorcerous Restoration', () {
    test('Klassenschwelle 5, nicht Summe der Mehrklassenstufen', () {
      expect(
        SrdSorcerousRestorationRules.maximumUses(
          _sorcerer(classLevel: 4, pointsSpent: 2),
        ),
        0,
      );
      expect(SrdSorcerousRestorationRules.maximumUses(_sorcerer()), 1);
      expect(
        SrdSorcerousRestorationRules.maximumUses(
          _sorcerer(classLevel: 4, pointsSpent: 2, multiclass: true),
        ),
        0,
      );
      expect(
        SrdSorcerousRestorationRules.maximumUses(_sorcerer(multiclass: true)),
        1,
      );
      expect(
        SrdSorcerousRestorationRules.maximumUses(
          _sorcerer(sorcerer: false, pointsSpent: 0),
        ),
        0,
      );
    });

    test('Hälfte abrunden: Stufen 5, 9 und 20', () {
      expect(
        SrdSorcerousRestorationRules.maximumRecoveredPoints(_sorcerer()),
        2,
      );
      expect(
        SrdSorcerousRestorationRules.maximumRecoveredPoints(
          _sorcerer(classLevel: 9),
        ),
        4,
      );
      expect(
        SrdSorcerousRestorationRules.maximumRecoveredPoints(
          _sorcerer(classLevel: 20),
        ),
        10,
      );
    });

    test('Zwei von vier verbrauchten Punkten regenerieren', () {
      final before = _sorcerer();
      final snapshot = before.toJson();
      final used = SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
        before,
      );
      expect(used.recoveredPoints, 2);
      expect(used.spentBefore, 4);
      expect(used.spentAfter, 2);
      expect(used.usesRemaining, 0);
      expect(used.hero.spentClassResources['sorceryPoints'], 2);
      expect(
        used.hero.spentClassResources[SrdSorcerousRestorationRules.resourceKey],
        1,
      );
      expect(before.toJson(), snapshot);
      expect(
        HeroCharacter.fromJson(used.hero.toJson()).toJson(),
        used.hero.toJson(),
      );
    });

    test('Nur tatsächlich verbrauchte Punkte werden erstattet', () {
      final used = SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
        _sorcerer(pointsSpent: 1),
      );
      expect(used.recoveredPoints, 1);
      expect(used.spentAfter, 0);
    });

    test(
      'Mehrklasse wiederhergestellt aus Sorcerer-, nicht Charakterlevel',
      () {
        final hero = _sorcerer(multiclass: true);
        expect(hero.level, 7);
        final used =
            SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(hero);
        expect(used.recoveredPoints, 2);
        expect(used.hero.secondaryClassName, 'Zauberer');
      },
    );

    test('Stufe vier, voller Pool und zweimalige Nutzung abgelehnt', () {
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          _sorcerer(classLevel: 4, pointsSpent: 2),
        ),
        throwsStateError,
      );
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          _sorcerer(pointsSpent: 0),
        ),
        throwsStateError,
      );
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          _sorcerer(restorationSpent: 1),
        ),
        throwsStateError,
      );
    });

    test('Manipulatoren, Tod und fehlende Trefferpunkte werden gesperrt', () {
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          _sorcerer(pointsSpent: 6),
        ),
        throwsFormatException,
      );
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          _sorcerer(restorationSpent: 2),
        ),
        throwsFormatException,
      );
      expect(
        () => SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
          _sorcerer(hp: 0),
        ),
        throwsStateError,
      );
    });

    test('Normale kurze Rast verbraucht die optionale Fähigkeit nicht', () {
      final hero = _sorcerer();
      final dice = DiceEngine(random: _MinimumRandom());
      final rest = RestRules.shortRest(hero, dice: dice);
      expect(rest.hero.spentClassResources['sorceryPoints'], 4);
      expect(
        rest.hero.spentClassResources[SrdSorcerousRestorationRules.resourceKey],
        isNull,
      );
      expect(rest.hero.spentHitDice['d6'], 1);
    });

    test('Gewählte kurze Rast mit Trefferwürfel regeneriert Punkte', () {
      final hero = _sorcerer();
      final dice = DiceEngine(random: _MinimumRandom());
      final rest = RestRules.shortRest(
        hero,
        dice: dice,
        restoreSorceryPoints: true,
      );
      expect(rest.hero.spentClassResources['sorceryPoints'], 2);
      expect(
        rest.hero.spentClassResources[SrdSorcerousRestorationRules.resourceKey],
        1,
      );
      expect(rest.hero.spentHitDice['d6'], 1);
      expect(rest.hero.hitPoints, 15);
    });

    test('Kurze Rast setzt Nutzungsgrenze nicht zurück, lange Rast schon', () {
      final once = SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(
        _sorcerer(),
      ).hero;
      expect(
        ClassResourceRules.afterShortRest(
          once,
        ).spentClassResources[SrdSorcerousRestorationRules.resourceKey],
        1,
      );
      final afterLong = RestRules.longRest(once);
      expect(
        ClassResourceRules.remaining(
          afterLong,
          SrdSorcerousRestorationRules.resourceKey,
        ),
        1,
      );
      expect(afterLong.spentClassResources['sorceryPoints'], isNull);
    });

    test('End-to-End: optionale kurze Rast mit vollen Trefferpunkten', () {
      final engine = _engine();
      final base = engine.createDemo();
      final start = base.copyWith(
        hero: _sorcerer(hp: 20).copyWith(id: base.hero.id),
      );
      final update = engine.act(
        start,
        'Ich mache eine kurze Rast mit Zauberkraftregeneration.',
      );
      expect(update.events.single.type, 'character.shortRest');
      expect(update.events.single.payload['sorceryPointsRecovered'], 2);
      expect(update.events.single.payload['sorcerousRestorationUsed'], true);
      expect(update.events.single.payload['count'], 0);
      expect(update.campaign.hero.spentClassResources['sorceryPoints'], 2);
      final loaded = Campaign.fromJson(update.campaign.toJson());
      final duplicate = engine.act(
        loaded,
        'Ich mache eine kurze Rast mit Zauberkraftregeneration.',
      );
      expect(duplicate.events.single.type, 'rules.blocked');
      expect(duplicate.campaign.hero.spentClassResources['sorceryPoints'], 2);
    });

    test('End-to-End: ohne Trefferwürfel, optionaler Befehl bleibt sicher', () {
      final engine = _engine();
      final base = engine.createDemo();
      final hero = _sorcerer(hitDiceSpent: 5).copyWith(id: base.hero.id);
      final result = engine.act(
        base.copyWith(hero: hero),
        'Kurze Rast mit Zauberkraftregeneration',
      );
      expect(result.events.single.type, 'character.shortRest');
      expect(result.events.single.payload['count'], 0);
      expect(result.events.single.payload['sorceryPointsRecovered'], 2);
      expect(result.campaign.hero.spentHitDice['d6'], 5);
      expect(result.campaign.hero.spentClassResources['sorceryPoints'], 2);
    });

    test('Gewöhnliche Rast und Fehlversuch verändern keine Fähigkeit', () {
      final engine = _engine();
      final base = engine.createDemo();
      final start = base.copyWith(
        hero: _sorcerer(hp: 20).copyWith(id: base.hero.id),
      );
      final ordinary = engine.act(start, 'Ich mache eine kurze Rast.');
      expect(ordinary.events.single.type, 'character.shortRest');
      expect(ordinary.events.single.payload['sorceryPointsRecovered'], 0);
      expect(ordinary.campaign.hero.spentClassResources['sorceryPoints'], 4);
      final empty = start.copyWith(
        hero: _sorcerer(hp: 20, pointsSpent: 0).copyWith(id: base.hero.id),
      );
      final rejected = engine.act(
        empty,
        'Kurze Rast mit Zauberkraftregeneration',
      );
      expect(rejected.events.single.type, 'rules.blocked');
      expect(rejected.campaign.hero.spentClassResources, isEmpty);
    });
  });
}
