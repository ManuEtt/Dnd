import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/hero_shield_reaction_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _FixedRoll implements Random {
  _FixedRoll(this.natural);
  final int natural;
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return max == 20 ? natural - 1 : 0;
  }

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

HeroCharacter _hero({bool knowsShield = true}) => HeroCharacter(
  id: 'wizard',
  name: 'Mira',
  className: 'Magier',
  level: 5,
  spells: knowsShield ? const ['Schild'] : const [],
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
);

Campaign _campaign(GameEngine engine, {bool knowsShield = true}) {
  final initial = engine.createDemo();
  return initial.copyWith(
    hero: _hero(knowsShield: knowsShield),
    encounter: const Encounter(
      id: 'enemy-hit',
      enemyName: 'Kämpfer',
      enemyHitPoints: 35,
      enemyMaxHitPoints: 35,
      enemyAttackBonus: 2,
      enemyDamage: '1d4',
    ),
  );
}

void main() {
  test('SRD Shield: nach gewürfeltem Treffer wählen und ohne Neuwurf parieren', () {
    final rng = _FixedRoll(13);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final start = _campaign(engine);
    final offer = engine.endHeroTurn(start).campaign;
    expect(offer.pendingEnemyShieldHit!.natural, 13);
    expect(offer.pendingEnemyShieldHit!.total, 15);
    expect(offer.pendingEnemyShieldHit!.rolls, [13]);
    expect(offer.encounter!.activeParticipant, 'enemy');
    expect(offer.hero.hitPoints, 20);
    expect(offer.hero.spentSpellSlots, isEmpty);
    expect(rng.calls, 1);
    expect(Campaign.fromJson(offer.toJson()).toJson(), offer.toJson());

    final update = engine.resolvePendingEnemyShieldHit(offer, shieldPlan: _plan);
    final done = update.campaign;
    expect(rng.calls, 1);
    expect(done.pendingEnemyShieldHit, isNull);
    expect(done.encounter!.activeParticipant, 'hero');
    expect(done.encounter!.round, 2);
    expect(done.hero.hitPoints, 20);
    expect(done.hero.spentSpellSlots, {'1': 1});
    expect(update.events.single.type, 'combat.shieldHitResolved');
    expect(update.events.single.payload['shieldReactionTriggered'], isTrue);
    expect(update.events.single.payload['shieldBonusAc'], 5);
    expect(update.events.single.payload['hit'], isFalse);
    expect(update.events.single.payload['choice'], 'cast');
    expect(Campaign.fromJson(done.toJson()).toJson(), done.toJson());
    expect(() => engine.resolvePendingEnemyShieldHit(done), throwsFormatException);
  });

  test('Treffer ablehnen würfelt erst danach Schaden, nie einen neuen W20', () {
    final rng = _FixedRoll(13);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final offer = engine.endHeroTurn(_campaign(engine)).campaign;
    expect(rng.calls, 1);
    final update = engine.resolvePendingEnemyShieldHit(offer);
    expect(rng.calls, 2); // original enemy attack + deferred damage die
    expect(update.campaign.hero.hitPoints, 19);
    expect(update.campaign.hero.spentSpellSlots, isEmpty);
    expect(update.events.single.payload['attackRoll']['natural'], 13);
    expect(update.events.single.payload['choice'], 'decline');
  });

  test('Spieler darf Schild auch bei zu hohem Treffer wirken', () {
    final rng = _FixedRoll(19); // total 21 > shield AC 19
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final offer = engine.endHeroTurn(_campaign(engine)).campaign;
    expect(offer.pendingEnemyShieldHit!.total, 21);
    final result = engine.resolvePendingEnemyShieldHit(offer, shieldPlan: _plan);
    expect(result.events.single.payload['shieldReactionTriggered'], isTrue);
    expect(result.events.single.payload['hit'], isTrue);
    expect(result.events.single.payload['effectiveHeroArmorClass'], 19);
    expect(result.campaign.hero.spentSpellSlots, {'1': 1});
    expect(result.campaign.hero.hitPoints, 19);
    expect(rng.calls, 2);
  });

  test('Kritischer Treffer bleibt Treffer, Schild kostet dennoch einen Slot', () {
    final rng = _FixedRoll(20);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final offer = engine.endHeroTurn(_campaign(engine)).campaign;
    final update = engine.resolvePendingEnemyShieldHit(offer, shieldPlan: _plan);
    expect(update.events.single.payload['shieldReactionTriggered'], isTrue);
    expect(update.events.single.payload['hit'], isTrue);
    expect(update.campaign.hero.spentSpellSlots, {'1': 1});
    expect(update.campaign.hero.hitPoints, 18); // critical 2 dice of 1
    expect(rng.calls, 3);
  });

  test('Bei Fehlschlag kein künstliches Reaktionsfenster, alter Zug funktioniert', () {
    final rng = _FixedRoll(3);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final update = engine.endHeroTurn(_campaign(engine));
    expect(update.campaign.pendingEnemyShieldHit, isNull);
    expect(update.campaign.hero.spentSpellSlots, isEmpty);
    expect(update.campaign.hero.hitPoints, 20);
    expect(rng.calls, 1);
  });

  test('Keine ausgerüstete Zauberkenntnis: herkömmlicher Gegnerzug', () {
    final rng = _FixedRoll(13);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final update = engine.endHeroTurn(_campaign(engine, knowsShield: false));
    expect(update.campaign.pendingEnemyShieldHit, isNull);
    expect(update.campaign.hero.hitPoints, 19);
    expect(rng.calls, 2);
  });

  test('Offener Treffer sperrt neue Aktionen und ungültige Reaktionswahl', () {
    final rng = _FixedRoll(13);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final paused = engine.endHeroTurn(_campaign(engine)).campaign;
    expect(() => engine.act(paused, 'Angreifen'), throwsFormatException);
    expect(() => engine.endHeroTurn(paused), throwsFormatException);
    const invalid = HeroShieldReactionPlan(
      castingClass: 'Magier',
      slotLevel: 1,
      pactMagic: false,
      verbalConfirmed: false,
      somaticConfirmed: true,
    );
    expect(
      () => engine.resolvePendingEnemyShieldHit(paused, shieldPlan: invalid),
      throwsFormatException,
    );
    expect(rng.calls, 1);
    expect(paused.hero.spentSpellSlots, isEmpty);
  });

  test('Alte Kampagnen gültig, manipulierte offene Treffer werden verworfen', () {
    final rng = _FixedRoll(13);
    final engine = GameEngine(dice: DiceEngine(random: rng));
    final source = _campaign(engine);
    final legacy = source.toJson();
    expect(legacy.containsKey('pendingEnemyShieldHit'), isFalse);
    expect(Campaign.fromJson(legacy).pendingEnemyShieldHit, isNull);

    final paused = engine.endHeroTurn(source).campaign.toJson();
    final pending = Map<String, dynamic>.from(
      paused['pendingEnemyShieldHit'] as Map<String, dynamic>,
    );
    for (final override in <Map<String, dynamic>>[
      {'natural': 21},
      {'total': 99},
      {'rolls': [99]},
      {'modifier': 30},
      {'encounterId': 'wrong'},
      {'rolls': []},
    ]) {
      expect(
        () => Campaign.fromJson({
          ...paused,
          'pendingEnemyShieldHit': {...pending, ...override},
        }),
        throwsFormatException,
      );
    }
  });
}
