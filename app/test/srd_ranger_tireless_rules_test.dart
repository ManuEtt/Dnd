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
  spentHitDice: {if (spentDice > 0) 'd10': spentDice},
);

GameEngine _engine() => GameEngine(
  dice: DiceEngine(random: _MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 28),
);

void main() {
  group('SRD 5.2.1 Waldläufer 10: Unermüdlich, Erschöpfung', () {
    test('nur ab Waldläufer-Klassenstufe 10', () {
      expect(
        SrdRangerTirelessRules.canReduceExhaustion(_hero(rangerLevel: 9)),
        isFalse,
      );
      expect(SrdRangerTirelessRules.canReduceExhaustion(_hero()), isTrue);
      expect(
        SrdRangerTirelessRules.afterShortRest(
          _hero(rangerLevel: 9),
        ).exhaustionLevel,
        2,
      );
      expect(SrdRangerTirelessRules.afterShortRest(_hero()).exhaustionLevel, 1);
    });

    test('Mehrklasse erfordert zehn Waldläufer-, nicht Gesamtstufen', () {
      final before = _hero(rangerLevel: 9, multiclass: true);
      final after = _hero(rangerLevel: 10, multiclass: true);
      expect(before.level, 11);
      expect(after.level, 12);
      expect(SrdRangerTirelessRules.afterShortRest(before).exhaustionLevel, 2);
      expect(SrdRangerTirelessRules.afterShortRest(after).exhaustionLevel, 1);
      expect(
        SrdRangerTirelessRules.afterShortRest(
          _hero(ranger: false),
        ).exhaustionLevel,
        2,
      );
    });

    test('genau ein Level pro Rast, niemals unter null', () {
      final once = SrdRangerTirelessRules.afterShortRest(_hero(exhaustion: 3));
      expect(once.exhaustionLevel, 2);
      expect(SrdRangerTirelessRules.afterShortRest(once).exhaustionLevel, 1);
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
      expect(SrdRangerTirelessRules.afterShortRest(hero).exhaustionLevel, 2);
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
      expect(Campaign.fromJson(done.campaign.toJson()).hero.exhaustionLevel, 1);
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

  group('SRD 5.2.1 Waldläufer 10: Unermüdlich, temporäre TP', () {
    test('Stufe, Mehrklasse und bestätigte Weisheit begrenzen Nutzungen', () {
      expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(_hero()), 3);
      expect(
        SrdRangerTirelessRules.maximumTemporaryHitPointUses(
          _hero(rangerLevel: 9),
        ),
        0,
      );
      expect(
        SrdRangerTirelessRules.maximumTemporaryHitPointUses(
          _hero(rangerLevel: 9, multiclass: true),
        ),
        0,
      );
      expect(
        SrdRangerTirelessRules.maximumTemporaryHitPointUses(
          _hero(multiclass: true),
        ),
        3,
      );
      final missing = _hero().copyWith(
        abilities: {..._hero().abilities, 'wisdom': null},
      );
      expect(SrdRangerTirelessRules.maximumTemporaryHitPointUses(missing), 0);
      expect(
        () => SrdRangerTirelessRules.useTemporaryHitPoints(
          missing,
          DiceEngine(random: _MinimumRandom()),
        ),
        throwsStateError,
      );
    });

    test('1W8 + Weisheit, Minimum 1, gespeicherter Rohwurf', () {
      final hero = _hero().copyWith(temporaryHitPoints: 0);
      final previous = hero.toJson();
      final result = SrdRangerTirelessRules.useTemporaryHitPoints(
        hero,
        DiceEngine(random: _MinimumRandom()),
      );
      expect(result.roll.rolls, [1]);
      expect(result.roll.total, 1);
      expect(result.wisdomModifier, 3);
      expect(result.rolledTemporaryHitPoints, 4);
      expect(result.hero.temporaryHitPoints, 4);
      expect(result.usesRemaining, 2);
      expect(
        result.hero.spentClassResources[SrdRangerTirelessRules.resourceKey],
        1,
      );
      expect(hero.toJson(), previous);
      final veryLowWisdom = hero.copyWith(
        abilities: {...hero.abilities, 'wisdom': 1},
      );
      final low = SrdRangerTirelessRules.useTemporaryHitPoints(
        veryLowWisdom,
        DiceEngine(random: _MinimumRandom()),
      );
      expect(low.wisdomModifier, -5);
      expect(low.rolledTemporaryHitPoints, 1);
      expect(low.hero.temporaryHitPoints, 1);
      expect(low.usesRemaining, 0);
    });

    test(
      'temporäre Trefferpunkte werden nicht addiert oder implizit ersetzt',
      () {
        final hero = _hero().copyWith(temporaryHitPoints: 12);
        final rolled = SrdRangerTirelessRules.useTemporaryHitPoints(
          hero,
          DiceEngine(random: _MinimumRandom()),
        );
        expect(rolled.rolledTemporaryHitPoints, 4);
        expect(rolled.previousTemporaryHitPoints, 12);
        expect(rolled.hero.temporaryHitPoints, 12);
        expect(rolled.usesRemaining, 2);
        final replaced = SrdRangerTirelessRules.useTemporaryHitPoints(
          hero,
          DiceEngine(random: _MinimumRandom()),
          replaceExisting: true,
        );
        expect(replaced.hero.temporaryHitPoints, 4);
        expect(replaced.usesRemaining, 2);
      },
    );

    test('Nutzungen werden begrenzt und bei langer Rast regeneriert', () {
      final dice = DiceEngine(random: _MinimumRandom());
      var hero = _hero().copyWith(temporaryHitPoints: 0);
      for (final left in [2, 1, 0]) {
        final result = SrdRangerTirelessRules.useTemporaryHitPoints(hero, dice);
        hero = HeroCharacter.fromJson(result.hero.toJson());
        expect(result.usesRemaining, left);
        expect(
          ClassResourceRules.remaining(
            hero,
            SrdRangerTirelessRules.resourceKey,
          ),
          left,
        );
      }
      expect(
        () => SrdRangerTirelessRules.useTemporaryHitPoints(hero, dice),
        throwsStateError,
      );
      expect(
        ClassResourceRules.afterShortRest(
          hero,
        ).spentClassResources[SrdRangerTirelessRules.resourceKey],
        3,
      );
      final rested = RestRules.longRest(hero);
      expect(SrdRangerTirelessRules.remainingTemporaryHitPointUses(rested), 3);
      expect(rested.temporaryHitPoints, 0);
    });

    test('Manipulierte Einträge werden beim Laden abgefangen', () {
      final original = _hero().toJson();
      final key = SrdRangerTirelessRules.resourceKey;
      expect(
        () => HeroCharacter.fromJson({
          ...original,
          'spentClassResources': {key: 4},
        }),
        throwsFormatException,
      );
      expect(
        () => SrdRangerTirelessRules.remainingTemporaryHitPointUses(
          _hero().copyWith(spentClassResources: {key: -1}),
        ),
        throwsFormatException,
      );
    });

    test('Bewusstlosigkeit verhindert Ressourcenausgabe und Würfelwurf', () {
      final character = _hero(hitPoints: 0);
      expect(
        () => SrdRangerTirelessRules.useTemporaryHitPoints(
          character,
          DiceEngine(random: _MinimumRandom()),
        ),
        throwsStateError,
      );
      final dead = _hero(exhaustion: 6);
      expect(
        () => SrdRangerTirelessRules.useTemporaryHitPoints(
          dead,
          DiceEngine(random: _MinimumRandom()),
        ),
        throwsStateError,
      );
    });

    test('expliziter Befehl außerhalb des Kampfes ändert nur Regelzustand', () {
      final engine = _engine();
      final start = engine.createDemo();
      final original = start.copyWith(
        hero: _hero().copyWith(id: start.hero.id, temporaryHitPoints: 0),
      );
      final result = engine.act(
        original,
        'Unermüdlich: temporäre Trefferpunkte',
      );
      expect(result.events.single.type, 'class.tirelessTemporaryHitPoints');
      expect(result.campaign.hero.temporaryHitPoints, 4);
      expect(result.events.single.payload['rolledTemporaryHitPoints'], 4);
      expect(result.events.single.payload['wisdomModifier'], 3);
      expect(result.events.single.payload['actionConsumed'], isFalse);
      expect(
        SrdRangerTirelessRules.remainingTemporaryHitPointUses(
          Campaign.fromJson(result.campaign.toJson()).hero,
        ),
        2,
      );
      expect(original.hero.temporaryHitPoints, 0);
    });

    test('ungültiger Befehl und fehlende Stufe kosten nichts', () {
      final engine = _engine();
      final start = engine.createDemo();
      final original = start.copyWith(
        hero: _hero(rangerLevel: 9).copyWith(id: start.hero.id),
      );
      final malformed = engine.act(original, 'Unermüdlich: irgendetwas');
      expect(malformed.events.single.type, 'rules.blocked');
      final blocked = engine.act(
        original,
        'Unermüdlich: temporäre Trefferpunkte',
      );
      expect(blocked.events.single.type, 'rules.blocked');
      expect(blocked.campaign.hero.toJson(), original.hero.toJson());
    });

    test('Kampf verbraucht eine Aktion und verhindert doppelten Einsatz', () {
      final engine = _engine();
      final start = engine.createDemo();
      final campaign = start.copyWith(
        hero: _hero().copyWith(id: start.hero.id, temporaryHitPoints: 0),
      );
      final fight = engine.act(campaign, 'Ich gehe zum Waldschrein.').campaign;
      expect(fight.encounter, isNotNull);
      final action = engine.act(fight, 'Unermüdlich: temporäre Trefferpunkte');
      expect(action.events.single.type, 'class.tirelessTemporaryHitPoints');
      expect(action.events.single.payload['actionConsumed'], isTrue);
      expect(action.campaign.encounter!.actionUsed, isTrue);
      expect(action.campaign.hero.temporaryHitPoints, 4);
      final denied = engine.act(
        action.campaign,
        'Unermüdlich: temporäre Trefferpunkte',
      );
      expect(denied.events.single.type, 'rules.blocked');
      expect(
        denied.campaign.hero.spentClassResources,
        action.campaign.hero.spentClassResources,
      );
    });

    test('offener Würfelwurf sperrt neue Magieaktion', () {
      final engine = _engine();
      final start = engine.createDemo();
      final campaign = start.copyWith(
        hero: _hero().copyWith(id: start.hero.id),
      );
      final fight = engine.act(campaign, 'Ich gehe zum Waldschrein.').campaign;
      final attack = engine.act(fight, 'Ich greife den Wächter an.');
      expect(attack.campaign.pendingRoll, isNotNull);
      final denied = engine.act(
        attack.campaign,
        'Unermüdlich: temporäre Trefferpunkte',
      );
      expect(denied.events.single.type, 'rules.blocked');
      expect(
        denied.campaign.hero.spentClassResources,
        attack.campaign.hero.spentClassResources,
      );
    });
  });
}
