import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/hero_shield_reaction_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _SequenceRandom implements Random {
  _SequenceRandom(this.naturals);
  final List<int> naturals;
  int calls = 0;
  int attacks = 0;
  @override
  int nextInt(int max) {
    calls++;
    if (max == 20) {
      return naturals[attacks++ % naturals.length] - 1;
    }
    return 0;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

const _shield = HeroShieldReactionPlan(
  castingClass: 'Magier',
  slotLevel: 1,
  pactMagic: false,
  verbalConfirmed: true,
  somaticConfirmed: true,
);

Campaign _combat(GameEngine engine, {bool knowsShield = true}) {
  final demo = engine.createDemo();
  return demo.copyWith(
    hero: demo.hero.copyWith(
      className: 'Magier',
      level: 5,
      spells: knowsShield ? ['Schild'] : [],
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
    ),
    encounter: const Encounter(
      id: 'multi',
      enemyName: 'Bestätigter Gegner',
      enemyHitPoints: 40,
      enemyMaxHitPoints: 40,
      enemyAttackBonus: 2,
      enemyDamage: '1d4',
    ),
  );
}

void main() {
  test('Ohne bestätigte Mehrfachangriffe bleibt ein Angriff Standard', () {
    final random = _SequenceRandom([3]);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final campaign = _combat(engine);
    expect(campaign.encounter!.enemyAttacksPerTurn, 1);
    final next = engine.endHeroTurn(campaign).campaign;
    expect(next.encounter!.activeParticipant, 'hero');
    expect(next.encounter!.round, 2);
    expect(next.encounter!.enemyAttacksRemaining, 0);
    expect(random.attacks, 1);
    expect(() => engine.continueEnemyTurn(next), throwsFormatException);
  });

  test('Zwei bestätigte Angriffe: jeder eigene W20, Zug endet erst danach', () {
    final random = _SequenceRandom([3, 15]);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final before = engine
        .configureEnemyAttacks(_combat(engine, knowsShield: false), 2)
        .campaign;
    expect(before.encounter!.enemyAttacksPerTurn, 2);
    expect(before.events.last.type, 'combat.enemyAttackCountConfirmed');
    final first = engine.endHeroTurn(before).campaign;
    expect(first.encounter!.activeParticipant, 'enemy');
    expect(first.encounter!.enemyAttacksRemaining, 1);
    expect(first.encounter!.round, 1);
    expect(first.pendingEnemyShieldHit, isNull);
    expect(random.attacks, 1);
    expect(Campaign.fromJson(first.toJson()).toJson(), first.toJson());
    expect(() => engine.endHeroTurn(first), throwsFormatException);
    final resumed = engine.act(first, 'Gegnerangriff fortsetzen');
    expect(resumed.events.single.type, 'combat.enemyAttackContinued');
    expect(resumed.campaign.encounter!.activeParticipant, 'hero');
    expect(resumed.campaign.encounter!.round, 2);
    expect(resumed.campaign.encounter!.enemyAttacksRemaining, 0);
    expect(resumed.campaign.hero.hitPoints, 19);
    expect(random.attacks, 2);
    expect(
      () => engine.continueEnemyTurn(resumed.campaign),
      throwsFormatException,
    );
  });

  test('Post-Hit Shield bleibt für folgenden Gegnerangriff aktiv', () {
    final random = _SequenceRandom([13, 16]);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final before = engine.configureEnemyAttacks(_combat(engine), 2).campaign;
    final offered = engine.endHeroTurn(before).campaign;
    expect(offered.pendingEnemyShieldHit, isNotNull);
    expect(random.attacks, 1);
    final parried = engine
        .resolvePendingEnemyShieldHit(offered, shieldPlan: _shield)
        .campaign;
    expect(parried.pendingEnemyShieldHit, isNull);
    expect(parried.encounter!.activeParticipant, 'enemy');
    expect(parried.encounter!.enemyAttacksRemaining, 1);
    expect(parried.encounter!.heroShieldActive, isTrue);
    expect(parried.encounter!.reactionUsed, isTrue);
    expect(parried.hero.spentSpellSlots, {'1': 1});
    expect(parried.hero.hitPoints, 20);
    final second = engine.continueEnemyTurn(parried);
    expect(second.campaign.pendingEnemyShieldHit, isNull);
    expect(second.campaign.hero.spentSpellSlots, {'1': 1});
    // 16+2 = 18, blocked by 14+5 without a new slot or Shield prompt.
    expect(second.campaign.hero.hitPoints, 20);
    expect(second.events.single.payload['shieldPreviouslyActive'], isTrue);
    expect(second.events.single.payload['hit'], isFalse);
    expect(second.campaign.encounter!.activeParticipant, 'hero');
    expect(second.campaign.encounter!.heroShieldActive, isFalse);
    expect(second.campaign.encounter!.reactionUsed, isFalse);
    expect(random.attacks, 2);
  });

  test('Schild nach Treffer des zweiten Angriffs weiterhin möglich', () {
    final random = _SequenceRandom([3, 13]);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final before = engine.configureEnemyAttacks(_combat(engine), 2).campaign;
    final first = engine.endHeroTurn(before).campaign;
    expect(first.pendingEnemyShieldHit, isNull);
    final second = engine.continueEnemyTurn(first).campaign;
    expect(second.pendingEnemyShieldHit, isNotNull);
    expect(second.encounter!.activeParticipant, 'enemy');
    expect(random.attacks, 2);
    final result = engine.resolvePendingEnemyShieldHit(
      second,
      shieldPlan: _shield,
    );
    expect(result.campaign.hero.hitPoints, 20);
    expect(result.campaign.hero.spentSpellSlots, {'1': 1});
    expect(result.campaign.encounter!.activeParticipant, 'hero');
    expect(result.campaign.encounter!.round, 2);
    expect(result.campaign.encounter!.heroShieldActive, isFalse);
    expect(random.attacks, 2);
  });

  test('Abbruch bei ungültiger Anzahl, geändertem Zug oder offenen Würfen', () {
    final engine = GameEngine(dice: DiceEngine(random: _SequenceRandom([2])));
    final before = _combat(engine);
    for (final count in [0, 5, 100]) {
      expect(
        () => engine.configureEnemyAttacks(before, count),
        throwsFormatException,
      );
    }
    expect(() => engine.continueEnemyTurn(before), throwsFormatException);
    final blocked = before.copyWith(
      encounter: before.encounter!.copyWith(activeParticipant: 'enemy'),
    );
    expect(
      () => engine.configureEnemyAttacks(blocked, 2),
      throwsFormatException,
    );
    expect(before.encounter!.enemyAttacksPerTurn, 1);
  });

  test('Legacy JSON und manipulierte Runden werden sicher validiert', () {
    final old = const Encounter(
      id: 'old',
      enemyName: 'Altgegner',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
    ).toJson();
    expect(old.containsKey('enemyAttacksPerTurn'), isFalse);
    expect(Encounter.fromJson(old).enemyAttacksPerTurn, 1);
    expect(Encounter.fromJson(old).enemyAttacksRemaining, 0);
    for (final patch in <Map<String, dynamic>>[
      {'enemyAttacksPerTurn': 0},
      {'enemyAttacksPerTurn': 5},
      {'enemyAttacksRemaining': 1},
      {'heroShieldActive': true},
      {'enemyTurnAdvanceRound': true},
      {'enemyAttacksPerTurn': 2, 'enemyAttacksRemaining': 2},
      {'enemyAttacksPerTurn': '2'},
    ]) {
      expect(
        () => Encounter.fromJson({...old, ...patch}),
        throwsFormatException,
      );
    }
  });
}
