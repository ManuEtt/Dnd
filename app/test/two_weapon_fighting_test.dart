import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
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
      hasLength(1),
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

  test('Light extra attack works without style and omits positive damage', () {
    final engine = gm();
    final before = battle(engine, fighter(style: false));
    final after = missPrimary(engine, before);
    expect(after.encounter!.round, before.encounter!.round);
    expect(TwoWeaponFightingRules.canPrepare(after), isTrue);
    final requested = engine.act(after, 'Nebenhandangriff mit Dolch').campaign;
    final resolved = engine.resolveRoll(requested, natural: 15).campaign;
    expect(resolved.events.last.payload['damage'], 1);
  });

  test('Carrying a shield prevents the extra offhand attack', () {
    final engine = gm();
    final before = battle(engine, fighter(shield: true));
    final after = missPrimary(engine, before);
    expect(after.encounter!.round, before.encounter!.round + 1);
    expect(TwoWeaponFightingRules.canPrepare(after), isFalse);
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

  test(
    'Light helper: every class can use a confirmed pair of Light weapons',
    () {
      final rogue = fighter(style: false).copyWith(className: 'Schurke');
      expect(TwoWeaponFightingRules.offhandChoices(rogue), hasLength(1));
      final dagger = SrdEquipmentCatalog.byId('weapon-dagger')!;
      expect(
        TwoWeaponFightingRules.attackBonus(
          rogue,
          dagger,
          attackAbility: 'dexterity',
          proficient: true,
        ),
        5,
      );
      expect(
        TwoWeaponFightingRules.attackBonus(
          rogue,
          dagger,
          attackAbility: 'dexterity',
          proficient: false,
        ),
        3,
      );
      expect(
        () => TwoWeaponFightingRules.attackBonus(rogue, dagger),
        throwsFormatException,
      );
      // A fake style label on a class without the implemented style feature
      // does not grant a damage modifier.
      expect(
        TwoWeaponFightingRules.damage(
          rogue.copyWith(features: const ['Kampfstil: Kampf mit zwei Waffen']),
          dagger,
          2,
        ),
        2,
      );
    },
  );

  test(
    'Light helper: damage omits positive modifiers and keeps negative ones',
    () {
      final dagger = SrdEquipmentCatalog.byId('weapon-dagger')!;
      expect(
        TwoWeaponFightingRules.damage(fighter(style: false), dagger, 4),
        4,
      );
      expect(TwoWeaponFightingRules.damage(fighter(), dagger, 4), 7);
      final weak = fighter(
        style: false,
      ).copyWith(abilities: const {'strength': 8, 'dexterity': 6});
      expect(TwoWeaponFightingRules.damage(weak, dagger, 4), 2);
      expect(TwoWeaponFightingRules.damage(weak, dagger, 1), 0);
      expect(
        TwoWeaponFightingRules.damage(
          weak.copyWith(features: const ['Kampfstil: Kampf mit zwei Waffen']),
          dagger,
          4,
        ),
        2,
      );
    },
  );

  test(
    'Light helper: actual Finesse weapon permits an independent ability',
    () {
      final dagger = SrdEquipmentCatalog.byId('weapon-dagger')!;
      final handaxe = SrdEquipmentCatalog.byId('weapon-handaxe')!;
      final hero = fighter(style: false).copyWith(weaponAbility: 'strength');
      expect(
        TwoWeaponFightingRules.attackBonus(
          hero,
          dagger,
          attackAbility: 'dexterity',
        ),
        5,
      );
      expect(
        TwoWeaponFightingRules.attackBonus(
          hero,
          dagger,
          attackAbility: 'strength',
        ),
        3,
      );
      for (final invalid in ['dexterity', 'intelligence', '']) {
        expect(
          () => TwoWeaponFightingRules.ability(
            hero,
            handaxe,
            attackAbility: invalid,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => TwoWeaponFightingRules.ability(
          hero.copyWith(abilities: const {'strength': 12}),
          dagger,
          attackAbility: 'dexterity',
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'Light helper: preparation requires the remaining confirmed Bonus Action',
    () {
      final engine = gm();
      final after = missPrimary(engine, battle(engine, fighter(style: false)));
      expect(TwoWeaponFightingRules.canPrepare(after), isTrue);
      final fight = after.encounter!;
      for (final invalid in [
        after.copyWith(encounter: fight.copyWith(actionUsed: false)),
        after.copyWith(encounter: fight.copyWith(attacksRemaining: 1)),
        after.copyWith(encounter: fight.copyWith(bonusActionUsed: true)),
        after.copyWith(encounter: fight.copyWith(lightAttackAvailable: false)),
        after.copyWith(encounter: fight.copyWith(activeParticipant: 'enemy')),
        after.copyWith(encounter: fight.copyWith(surgeReserved: true)),
        after.copyWith(hero: after.hero.copyWith(hitPoints: 0)),
        after.copyWith(hero: fighter(shield: true)),
        after.copyWith(
          hero: after.hero.copyWith(conditions: const ['bewusstlos']),
        ),
        after.copyWith(
          pendingRoll: const PendingRoll(
            id: 'still-open',
            type: 'perception',
            modifier: 0,
            difficulty: 10,
          ),
        ),
      ]) {
        expect(TwoWeaponFightingRules.canPrepare(invalid), isFalse);
      }
    },
  );
}
