import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/two_weapon_fighting_rules.dart';

class LowRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

GameEngine gm() => GameEngine(
  dice: DiceEngine(random: LowRandom()),
  clock: () => DateTime.utc(2026, 10, 18),
);

HeroCharacter fighter({bool style = true, bool shield = false}) =>
    HeroCharacter(
      id: 'fighter-two-weapons',
      name: 'Elara',
      className: 'Kämpfer',
      level: 1,
      abilities: const {
        'strength': 12,
        'dexterity': 16,
        'constitution': 14,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
      },
      hitPoints: 12,
      maxHitPoints: 12,
      armorClass: 16,
      speed: 9,
      weaponDamage: '1d6',
      weaponAbility: 'dexterity',
      weaponProficient: true,
      equippedWeaponId: 'main',
      equippedShieldId: shield ? 'shield' : '',
      features: style ? const ['Kampfstil: Kampf mit zwei Waffen'] : const [],
      inventory: const [
        InventoryItem(
          id: 'main',
          name: 'Kurzschwert',
          catalogId: 'weapon-shortsword',
        ),
        InventoryItem(id: 'offhand', name: 'Dolch', catalogId: 'weapon-dagger'),
        InventoryItem(id: 'shield', name: 'Schild', catalogId: 'armor-shield'),
      ],
    );

Campaign battle(GameEngine engine, HeroCharacter hero) {
  final scene = engine.createDemo(hero: hero);
  return engine.act(scene, 'Ich gehe zum Waldschrein.').campaign;
}

Campaign missPrimary(GameEngine engine, Campaign game) {
  final requested = engine.act(game, 'Ich greife den Wächter an.').campaign;
  expect(requested.pendingRoll?.type, 'attack');
  return engine.resolveRoll(requested, natural: 1).campaign;
}

void main() {
  test('Two different confirmed Light weapons are required', () {
    expect(TwoWeaponFightingRules.offhandChoices(fighter()), hasLength(1));
    expect(
      TwoWeaponFightingRules.offhandChoices(fighter(style: false)),
      isEmpty,
    );
    expect(
      TwoWeaponFightingRules.offhandChoices(fighter(shield: true)),
      isEmpty,
    );
  });

  test('Miss opens extra Bonus Action; pending roll survives persistence', () {
    final engine = gm();
    final before = battle(engine, fighter());
    final after = missPrimary(engine, before);
    expect(after.encounter!.round, before.encounter!.round);
    expect(after.encounter!.lightAttackAvailable, isTrue);
    final requested = engine.act(after, 'Nebenhandangriff mit Dolch').campaign;
    expect(requested.pendingRoll!.type, 'offhandAttack');
    expect(requested.pendingRoll!.weaponId, 'offhand');
    expect(requested.pendingRoll!.modifier, 5);
    expect(requested.encounter!.bonusActionUsed, isTrue);
    final restored = Campaign.fromJson(requested.toJson());
    expect(restored.pendingRoll!.weaponId, 'offhand');
    final resolved = engine.resolveRoll(restored, natural: 1).campaign;
    expect(resolved.encounter!.round, before.encounter!.round + 1);
    expect(resolved.encounter!.bonusActionUsed, isFalse);
    expect(resolved.events.last.payload['offhandWeaponId'], 'offhand');
  });

  test('Critical doubles offhand weapon dice and adds ability once', () {
    final engine = gm();
    final before = battle(engine, fighter());
    final after = missPrimary(engine, before);
    final requested = engine.act(after, 'Nebenhandangriff: offhand').campaign;
    final resolved = engine.resolveRoll(requested, natural: 20).campaign;
    expect(resolved.events.last.payload['damage'], 5);
    expect(resolved.events.last.payload['criticalExtra'], isNotNull);
  });

  test('No chosen style or carrying shield gives no offhand attack', () {
    for (final hero in [fighter(style: false), fighter(shield: true)]) {
      final engine = gm();
      final before = battle(engine, hero);
      final after = missPrimary(engine, before);
      expect(after.encounter!.round, before.encounter!.round + 1);
    }
  });

  test('Player can end turn without making the optional offhand strike', () {
    final engine = gm();
    final before = battle(engine, fighter());
    final after = missPrimary(engine, before);
    final done = engine.act(after, 'Ich beende meinen Zug.').campaign;
    expect(done.encounter!.round, after.encounter!.round + 1);
    expect(done.encounter!.lightAttackAvailable, isFalse);
  });

  test(
    'Manipulated offhand attack modifiers and inventory references fail',
    () {
      final engine = gm();
      final before = battle(engine, fighter());
      final after = missPrimary(engine, before);
      final requested = engine
          .act(after, 'Nebenhandangriff mit Dolch')
          .campaign;
      final data = requested.toJson();
      final pending = Map<String, dynamic>.from(data['pendingRoll'] as Map);
      pending['modifier'] = 17;
      data['pendingRoll'] = pending;
      expect(() => Campaign.fromJson(data), throwsFormatException);
      pending['modifier'] = 5;
      pending['weaponId'] = 'shield';
      expect(() => Campaign.fromJson(data), throwsFormatException);
    },
  );
  test('Old encounters default to no optional light attack', () {
    final engine = gm();
    final original = battle(engine, fighter());
    final data = original.toJson();
    final fight = Map<String, dynamic>.from(data['encounter'] as Map);
    fight.remove('lightAttackAvailable');
    data['encounter'] = fight;
    final restored = Campaign.fromJson(data);
    expect(restored.encounter!.lightAttackAvailable, isFalse);
  });
}
