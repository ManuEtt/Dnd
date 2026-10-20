import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/magic_missile_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _FixedRandom implements Random {
  _FixedRandom(this.high);
  final bool high;
  int calls = 0;
  @override
  int nextInt(int max) {
    calls++;
    return high ? max - 1 : 0;
  }

  @override
  bool nextBool() => high;
  @override
  double nextDouble() => high ? 0.99 : 0;
}

HeroCharacter _hero({
  String className = 'Magier',
  int level = 5,
  List<String> spells = const ['Magisches Geschoss'],
}) => HeroCharacter(
  id: 'mage',
  name: 'Arina',
  className: className,
  level: level,
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

const _fight = Encounter(
  id: 'fight',
  enemyName: 'Wächter',
  enemyHitPoints: 50,
  enemyMaxHitPoints: 50,
  enemyArmorClass: 14,
);

MagicMissileResult _cast(
  HeroCharacter hero,
  _FixedRandom random, {
  String castingClass = 'Magier',
  int slotLevel = 1,
  bool pactMagic = false,
  bool visible = true,
  bool range = true,
  bool verbal = true,
  bool somatic = true,
  bool safe = true,
}) => MagicMissileRules.cast(
  hero,
  dice: DiceEngine(random: random),
  castingClass: castingClass,
  slotLevel: slotLevel,
  pactMagic: pactMagic,
  targetVisibleConfirmed: visible,
  targetWithinRangeConfirmed: range,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
  noProtectionConfirmed: safe,
);

GameUpdate _engineCast(
  GameEngine engine,
  Campaign campaign, {
  String castingClass = 'Magier',
  int slotLevel = 1,
  bool pactMagic = false,
  bool safe = true,
}) => engine.castMagicMissile(
  campaign,
  castingClass: castingClass,
  slotLevel: slotLevel,
  pactMagic: pactMagic,
  targetVisibleConfirmed: true,
  targetWithinRangeConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  noProtectionConfirmed: safe,
);

Campaign _campaign(GameEngine engine, {HeroCharacter? hero}) {
  final start = engine.createDemo();
  return start.copyWith(hero: hero ?? _hero(), encounter: _fight);
}

void main() {
  test('Grad 1: drei individuelle W4+1 und exakt 6 Energieschaden', () {
    final random = _FixedRandom(false);
    final before = _hero();
    final result = _cast(before, random);
    expect(result.damage, 6);
    expect(result.rolls.map((r) => r.total), [2, 2, 2]);
    expect(result.rolls.length, 3);
    expect(random.calls, 3);
    expect(result.hero.spentSpellSlots, {'1': 1});
    expect(before.spentSpellSlots, isEmpty);
    expect(result.hero.className, before.className);
  });

  test('Aufstufung auf Grad 3: fünf Geschosse, 25 Schaden', () {
    final random = _FixedRandom(true);
    final result = _cast(_hero(), random, slotLevel: 3);
    expect(result.rolls.length, 5);
    expect(result.damage, 25);
    expect(result.hero.spentSpellSlots, {'3': 1});
    expect(random.calls, 5);
  });

  test('Ungültige Klassen/Zauber und Bestätigungen würfeln nicht', () {
    final random = _FixedRandom(false);
    final invalid = [_hero(spells: const []), _hero(className: 'Kleriker')];
    for (final hero in invalid) {
      expect(() => _cast(hero, random), throwsFormatException);
    }
    for (final flags in [
      [false, true, true, true, true],
      [true, false, true, true, true],
      [true, true, false, true, true],
      [true, true, true, false, true],
      [true, true, true, true, false],
    ]) {
      expect(
        () => _cast(
          _hero(),
          random,
          visible: flags[0],
          range: flags[1],
          verbal: flags[2],
          somatic: flags[3],
          safe: flags[4],
        ),
        throwsFormatException,
      );
    }
    expect(random.calls, 0);
  });

  test('Nur verfügbare Plätze, keine falsche Zauberstufe', () {
    final random = _FixedRandom(false);
    expect(() => _cast(_hero(), random, slotLevel: 9), throwsFormatException);
    expect(() => _cast(_hero(), random, slotLevel: 0), throwsFormatException);
    expect(() => _cast(_hero(), random, slotLevel: 10), throwsFormatException);
    expect(random.calls, 0);
  });

  test('Zauberer und englische Namen sowie Multiklassen-Paktplatz', () {
    final sorcerer = _hero(
      className: 'Sorcerer',
      spells: const ['Magic Missile'],
    );
    final cast = _cast(sorcerer, _FixedRandom(false), castingClass: 'Zauberer');
    expect(cast.hero.className, 'Sorcerer');
    final multi = _hero(
      className: 'Magier',
      level: 4,
    ).copyWith(secondaryClassName: 'Hexenmeister', secondaryClassLevel: 2);
    final result = _cast(multi, _FixedRandom(false), pactMagic: true);
    expect(result.hero.spentPactSlots, 1);
    expect(result.hero.spentSpellSlots, isEmpty);
    expect(result.pactMagic, isTrue);
  });

  test('Aktiver Kampf: Schaden, Ressource, Zugverbrauch und Journal', () {
    final random = _FixedRandom(false);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final before = _campaign(engine);
    final update = _engineCast(engine, before);
    final after = update.campaign;
    expect(after.encounter!.enemyHitPoints, 44);
    expect(after.encounter!.actionUsed, isTrue);
    expect(after.encounter!.spellSlotExpendedThisTurn, isTrue);
    expect(after.encounter!.bonusActionUsed, isFalse);
    expect(after.hero.spentSpellSlots, {'1': 1});
    expect(after.revision, before.revision + 1);
    expect(update.events.single.type, 'spell.magicMissile');
    expect(update.events.single.payload['missileRolls'], hasLength(3));
    expect(update.events.single.payload['damageType'], 'force');
    expect(Campaign.fromJson(after.toJson()).toJson(), after.toJson());
  });

  test('Unzulässige Kampfzustände scheitern vor dem Würfelwurf', () {
    final random = _FixedRandom(false);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final initial = _campaign(engine);
    final invalid = [
      initial.copyWith(encounter: _fight.copyWith(actionUsed: true)),
      initial.copyWith(
        encounter: _fight.copyWith(spellSlotExpendedThisTurn: true),
      ),
      initial.copyWith(encounter: _fight.copyWith(activeParticipant: 'enemy')),
      initial.copyWith(
        encounter: _fight.copyWith(enemyCover: CoverLevel.total),
      ),
      initial.copyWith(
        pendingRoll: const PendingRoll(
          id: 'roll',
          type: 'attack',
          modifier: 0,
          difficulty: 10,
        ),
      ),
    ];
    for (final game in invalid) {
      expect(() => _engineCast(engine, game), throwsFormatException);
    }
    expect(
      () => _engineCast(engine, initial, safe: false),
      throwsFormatException,
    );
    expect(random.calls, 0);
  });

  test('Eine zweite Platzwirkung im selben Zug ist gesperrt', () {
    final random = _FixedRandom(false);
    final engine = GameEngine(dice: DiceEngine(random: random));
    final after = _engineCast(engine, _campaign(engine)).campaign;
    expect(() => _engineCast(engine, after), throwsFormatException);
    expect(random.calls, 3);
    expect(after.hero.spentSpellSlots, {'1': 1});
  });

  test('Bei tödlichem Treffer greift vorhandener Abschluss der Begegnung', () {
    final engine = GameEngine(dice: DiceEngine(random: _FixedRandom(true)));
    final current = _campaign(
      engine,
    ).copyWith(encounter: _fight.copyWith(enemyHitPoints: 3));
    final update = _engineCast(engine, current);
    expect(update.events.single.payload['enemyHitPoints'], 0);
    expect(update.campaign.encounter?.isFinished ?? true, isTrue);
    expect(update.campaign.hero.spentSpellSlots, {'1': 1});
  });
}
