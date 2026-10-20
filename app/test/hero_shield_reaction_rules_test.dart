import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/hero_shield_reaction_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _FixedDie implements Random {
  _FixedDie(this.natural);
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

HeroCharacter _wizard({
  String className = 'Magier',
  List<String> spells = const ['Schild'],
}) => HeroCharacter(
  id: 'test-mage',
  name: 'Magierin',
  className: className,
  level: 5,
  spells: spells,
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

Campaign _campaign(GameEngine engine, {HeroCharacter? hero, Encounter? foe}) {
  final original = engine.createDemo();
  return original.copyWith(
    hero: hero ?? _wizard(),
    encounter:
        foe ??
        const Encounter(
          id: 'shield-test',
          enemyName: 'Gegner',
          enemyHitPoints: 40,
          enemyMaxHitPoints: 40,
          enemyAttackBonus: 2,
          enemyDamage: '1d4',
        ),
  );
}

const plan = HeroShieldReactionPlan(
  castingClass: 'Magier',
  slotLevel: 1,
  pactMagic: false,
  verbalConfirmed: true,
  somaticConfirmed: true,
);

void main() {
  test('Wenn +5 RK den Treffer verhindert, werden die Ressourcen gebucht', () {
    final random = _FixedDie(13); // 13+2=15 trifft RK14, nicht RK19
    final engine = GameEngine(dice: DiceEngine(random: random));
    final before = _campaign(engine);
    final update = engine.endHeroTurn(before, shieldPlan: plan);
    final after = update.campaign;
    expect(after.hero.hitPoints, 20);
    expect(after.hero.spentSpellSlots, {'1': 1});
    expect(after.encounter!.round, 2);
    expect(after.encounter!.activeParticipant, 'hero');
    expect(after.encounter!.reactionUsed, isFalse); // new hero turn
    expect(update.events.single.payload['shieldReactionTriggered'], isTrue);
    expect(update.events.single.payload['shieldBonusAc'], 5);
    expect(update.events.single.payload['hit'], isFalse);
    expect(update.events.single.payload['effectiveHeroArmorClass'], 19);
    expect(random.calls, 1); // no damage die
    expect(before.hero.spentSpellSlots, isEmpty);
    expect(Campaign.fromJson(after.toJson()).toJson(), after.toJson());
  });

  test('Verfehlt der Gegner, wird Schild nicht gewirkt', () {
    final random = _FixedDie(3);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final result = engine.endHeroTurn(_campaign(engine), shieldPlan: plan);
    expect(result.campaign.hero.spentSpellSlots, isEmpty);
    expect(result.events.single.payload['shieldReactionTriggered'], isFalse);
    expect(random.calls, 1);
  });

  test(
    'Nicht abwendbarer Treffer löst keine automatische Schildreaktion aus',
    () {
      final random = _FixedDie(19); // 21 ist größer als 19
      final engine = GameEngine(dice: DiceEngine(random: random));
      final result = engine.endHeroTurn(_campaign(engine), shieldPlan: plan);
      expect(result.campaign.hero.spentSpellSlots, isEmpty);
      expect(result.campaign.hero.hitPoints, lessThan(20));
      expect(result.events.single.payload['shieldReactionTriggered'], isFalse);
    },
  );

  test('Kritischer Treffer bleibt Treffer trotz des RK-Bonus', () {
    final random = _FixedDie(20);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final result = engine.endHeroTurn(_campaign(engine), shieldPlan: plan);
    expect(result.campaign.hero.spentSpellSlots, isEmpty);
    expect(result.events.single.payload['shieldReactionTriggered'], isFalse);
    expect(result.events.single.payload['hit'], isTrue);
  });

  test('Voraussetzungen werden vor dem Gegnerwurf geprüft', () {
    final random = _FixedDie(13);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final initial = _campaign(engine);
    final badPlans = [
      const HeroShieldReactionPlan(
        castingClass: 'Magier',
        slotLevel: 1,
        pactMagic: false,
        verbalConfirmed: false,
        somaticConfirmed: true,
      ),
      const HeroShieldReactionPlan(
        castingClass: 'Magier',
        slotLevel: 9,
        pactMagic: false,
        verbalConfirmed: true,
        somaticConfirmed: true,
      ),
    ];
    for (final invalid in badPlans) {
      expect(
        () => engine.endHeroTurn(initial, shieldPlan: invalid),
        throwsFormatException,
      );
    }
    expect(
      () => engine.endHeroTurn(
        _campaign(engine, hero: _wizard(spells: const [])),
        shieldPlan: plan,
      ),
      throwsFormatException,
    );
    expect(
      () => engine.endHeroTurn(
        _campaign(engine, foe: initial.encounter!.copyWith(reactionUsed: true)),
        shieldPlan: plan,
      ),
      throwsFormatException,
    );
    expect(random.calls, 0);
    expect(initial.hero.spentSpellSlots, isEmpty);
  });

  test('Zauberer und englischer Name werden anerkannt', () {
    final hero = _wizard(className: 'Sorcerer', spells: ['Shield']);
    expect(HeroShieldReactionRules.preparedName(hero), 'Shield');
    expect(HeroShieldReactionRules.castingClasses(hero), contains('Zauberer'));
    expect(HeroShieldReactionRules.slots(hero).first.level, 1);
  });

  test('Ohne Schild-Plan bleibt der bestehende Gegnerzug unverändert', () {
    final engine = GameEngine(dice: DiceEngine(random: _FixedDie(13)));
    final result = engine.endHeroTurn(_campaign(engine));
    expect(result.campaign.hero.spentSpellSlots, isEmpty);
    expect(result.campaign.hero.hitPoints, lessThan(20));
    expect(result.events.single.payload['shieldReactionAuthorized'], isFalse);
  });
}
