import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/domain/two_weapon_fighting_rules.dart';

class _MinimumRolls implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({
  String primary = 'Paladin',
  String secondary = '',
  int level = 2,
  int secondaryLevel = 0,
  int dexterity = 16,
  bool styleConfirmed = true,
}) => HeroCharacter(
  id: 'two-weapon-style-class',
  name: 'Flinke Klinge',
  className: primary,
  secondaryClassName: secondary,
  level: level,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 15,
  speed: 9,
  abilities: {
    'strength': 12,
    'dexterity': dexterity,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': 14,
  },
  weaponDamage: '1d6',
  weaponAbility: 'dexterity',
  weaponProficient: true,
  equippedWeaponId: 'main',
  features: styleConfirmed
      ? const ['Kampfstil: Kampf mit zwei Waffen']
      : const [],
  inventory: [
    InventoryItem(
      id: 'main',
      name: 'Kurzschwert',
      catalogId: 'weapon-shortsword',
      stats: InventoryItemStats.fromCatalog(
        SrdEquipmentCatalog.byId('weapon-shortsword')!,
      ),
    ),
    InventoryItem(
      id: 'offhand',
      name: 'Dolch',
      catalogId: 'weapon-dagger',
      stats: InventoryItemStats.fromCatalog(
        SrdEquipmentCatalog.byId('weapon-dagger')!,
      ),
    ),
  ],
);

void main() {
  final dagger = SrdEquipmentCatalog.byId('weapon-dagger')!;

  test(
    'Kämpfer 1, Paladin 2 und Waldläufer 2 erhalten gewählten Kampfstil',
    () {
      final eligible = <HeroCharacter>[
        _hero(primary: 'Kämpfer', level: 1),
        _hero(primary: 'Fighter', level: 1),
        _hero(primary: 'Paladin', level: 2),
        _hero(primary: 'Waldläufer', level: 2),
        _hero(primary: 'Ranger', level: 2),
        _hero(
          primary: 'Schurke',
          secondary: 'Paladin',
          level: 4,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Rogue',
          secondary: 'Ranger',
          level: 4,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Paladin',
          secondary: 'Wizard',
          level: 5,
          secondaryLevel: 3,
        ),
      ];
      for (final hero in eligible) {
        final snapshot = hero.toJson();
        expect(TwoWeaponFightingRules.getStyle(hero), isTrue);
        expect(
          TwoWeaponFightingRules.damage(
            hero,
            dagger,
            4,
            attackAbility: 'dexterity',
          ),
          7,
        );
        expect(hero.toJson(), snapshot);
      }
    },
  );

  test(
    'zu niedrige Stufe, fehlende Wahl und Fremdklasse geben keinen Bonus',
    () {
      final ineligible = <HeroCharacter>[
        _hero(primary: 'Paladin', level: 1),
        _hero(primary: 'Ranger', level: 1),
        _hero(primary: 'Rogue', level: 20),
        _hero(primary: 'Wizard', level: 20),
        _hero(primary: 'Paladin', level: 2, styleConfirmed: false),
        _hero(primary: 'Ranger', level: 2, styleConfirmed: false),
        _hero(
          primary: 'Rogue',
          secondary: 'Ranger',
          level: 3,
          secondaryLevel: 1,
        ),
        _hero(
          primary: 'Rogue',
          secondary: 'Paladin',
          level: 3,
          secondaryLevel: 1,
        ),
      ];
      for (final hero in ineligible) {
        expect(TwoWeaponFightingRules.getStyle(hero), isFalse);
        expect(
          TwoWeaponFightingRules.damage(
            hero,
            dagger,
            4,
            attackAbility: 'dexterity',
          ),
          4,
        );
      }
    },
  );

  test('ungültige Klassenprofile schalten den Stil nicht frei', () {
    final invalid = <HeroCharacter>[
      _hero(
        primary: 'Unbekannt',
        secondary: 'Ranger',
        level: 4,
        secondaryLevel: 2,
      ),
      _hero(
        primary: 'Paladin',
        secondary: 'Unbekannt',
        level: 4,
        secondaryLevel: 2,
      ),
      _hero(
        primary: 'Paladin',
        secondary: 'Paladin',
        level: 4,
        secondaryLevel: 2,
      ),
      _hero(
        primary: 'Ranger',
        secondary: 'Waldläufer',
        level: 4,
        secondaryLevel: 2,
      ),
      _hero(primary: 'Paladin', secondary: 'Rogue', level: 4),
      _hero(primary: 'Paladin', secondaryLevel: 1, level: 4),
      _hero(primary: 'Ranger', level: 0),
      _hero(primary: 'Paladin', level: 21),
      _hero(primary: 'Paladin', level: 3, secondaryLevel: -1),
      _hero(primary: 'Rogue', secondary: 'Ranger', level: 2, secondaryLevel: 2),
    ];
    for (final hero in invalid) {
      final snapshot = hero.toJson();
      expect(TwoWeaponFightingRules.getStyle(hero), isFalse);
      expect(TwoWeaponFightingRules.damage(hero, dagger, 1), 1);
      expect(hero.toJson(), snapshot);
    }
  });

  test('negativer Attributmodifikator bleibt auch ohne Stil bestehen', () {
    for (final styleConfirmed in [false, true]) {
      final hero = _hero(
        primary: 'Paladin',
        level: 2,
        dexterity: 8,
        styleConfirmed: styleConfirmed,
      );
      expect(TwoWeaponFightingRules.damage(hero, dagger, 4), 3);
      expect(TwoWeaponFightingRules.damage(hero, dagger, 1), 0);
    }
  });

  test(
    'Paladin und Waldläufer: bestätigter Nebenhandangriff verbucht Bonus',
    () {
      for (final hero in [
        _hero(primary: 'Paladin', level: 2),
        _hero(primary: 'Ranger', level: 2),
      ]) {
        final engine = GameEngine(
          dice: DiceEngine(random: _MinimumRolls()),
          clock: () => DateTime.utc(2026, 11, 6),
        );
        final before = engine
            .createDemo(hero: hero)
            .copyWith(
              encounter: const Encounter(
                id: 'fighting-style-target',
                enemyName: 'Trainingsgegner',
                enemyHitPoints: 100,
                enemyMaxHitPoints: 100,
                enemyArmorClass: 12,
                movementRemaining: 9,
              ),
            );
        final attack = engine.act(before, 'Ich greife an.').campaign;
        expect(attack.pendingRoll!.type, 'attack');
        final missed = engine.resolveRoll(attack, natural: 1).campaign;
        expect(TwoWeaponFightingRules.canPrepare(missed), isTrue);
        final prepared = engine
            .prepareOffhandAttack(
              missed,
              weaponId: 'offhand',
              attackAbility: 'dexterity',
              weaponProficient: true,
              weaponsHeldConfirmed: true,
              playerConfirmed: true,
            )
            .campaign;
        final result = engine.resolveRoll(prepared, natural: 15);
        expect(result.events.single.payload['damage'], 4);
        expect(result.campaign.encounter!.enemyHitPoints, 96);
        expect(result.campaign.hero.toJson(), hero.toJson());
        expect(TwoWeaponFightingRules.canPrepare(result.campaign), isFalse);
        expect(
          Campaign.fromJson(result.campaign.toJson()).toJson(),
          result.campaign.toJson(),
        );
      }
    },
  );
}
