import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/equipment_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/fighter_style_combat_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

HeroCharacter _fighter({
  String style = 'Bogenschießen',
  String className = 'Kämpfer',
  String equippedWeapon = 'bow',
}) => HeroCharacter(
  id: 'fighter-style-1',
  name: 'Elara',
  className: className,
  level: 1,
  armorClass: 15,
  weaponDamage: '1d8',
  weaponAbility: 'dexterity',
  weaponProficient: true,
  abilities: const {'strength': 12, 'dexterity': 16, 'constitution': 14},
  features: ['Kampfstil: $style'],
  inventory: const [
    InventoryItem(id: 'bow', name: 'Langbogen', catalogId: 'weapon-longbow'),
    InventoryItem(id: 'spear', name: 'Wurfspeer', catalogId: 'weapon-javelin'),
    InventoryItem(id: 'armor', name: 'Leder', catalogId: 'armor-leather-armor'),
    InventoryItem(id: 'shield', name: 'Schild', catalogId: 'armor-shield'),
  ],
  equippedWeaponId: equippedWeapon,
);

HeroCharacter _greatWeaponHero({
  String style = 'Kampf mit großen Waffen',
  String className = 'Kämpfer',
  String weaponId = 'greatsword',
  String damage = '2d6',
  String shieldId = '',
}) => HeroCharacter(
  id: 'great-fighter',
  name: 'Thora',
  className: className,
  weaponDamage: damage,
  weaponAbility: 'strength',
  abilities: const {'strength': 16},
  features: ['Kampfstil: $style'],
  inventory: const [
    InventoryItem(
      id: 'greatsword',
      name: 'Zweihandschwert',
      catalogId: 'weapon-greatsword',
    ),
    InventoryItem(
      id: 'longsword',
      name: 'Langschwert',
      catalogId: 'weapon-longsword',
    ),
    InventoryItem(id: 'spear', name: 'Speer', catalogId: 'weapon-spear'),
    InventoryItem(id: 'shield', name: 'Schild', catalogId: 'armor-shield'),
  ],
  equippedWeaponId: weaponId,
  equippedShieldId: shieldId,
);

DiceResult _damageDice(String expression, List<int> rolls) => DiceResult(
  expression: expression,
  rolls: rolls,
  modifier: 0,
  total: rolls.fold<int>(0, (sum, die) => sum + die),
);

void main() {
  group('SRD 5.2.1: ausführbare Kämpfer-Kampfstile', () {
    test('Bogenschießen +2 in echtem Angriffsbonus und Vorschau', () {
      final hero = _fighter();
      expect(RulesEngine.attackBonus(hero), 7);
      expect(CharacterRuleEngine.attack(hero).modifier, 7);
      final p = EquipmentRules.preview(
        hero,
        const EquipmentSelection(weaponId: 'bow', weaponProficient: true),
      );
      expect(p.attackBonus, 7);
      final equipped = EquipmentRules.confirm(hero, p);
      expect(RulesEngine.attackBonus(equipped), 7);
      expect(HeroCharacter.fromJson(equipped.toJson()).features, hero.features);
    });

    test('Wurfspeer als Nahkampfwaffe erhält keinen Fernkampfbonus', () {
      final hero = _fighter(equippedWeapon: 'spear');
      expect(RulesEngine.attackBonus(hero), 5);
      expect(
        EquipmentRules.preview(
          hero,
          const EquipmentSelection(
            weaponId: 'spear',
            thrown: true,
            weaponProficient: true,
          ),
        ).attackBonus,
        3,
      );
    });

    test('Ohne expliziten Stil, Klasse oder bestätigte Waffe kein Bonus', () {
      expect(RulesEngine.attackBonus(_fighter(style: 'Verteidigung')), 5);
      expect(RulesEngine.attackBonus(_fighter(className: 'Magier')), 5);
      expect(RulesEngine.attackBonus(_fighter(equippedWeapon: '')), 5);
      expect(
        FighterStyleCombatRules.equippedWeapon(
          _fighter(equippedWeapon: 'missing'),
        ),
        isNull,
      );
    });

    test('Verteidigung +1 nur mit tatsächlich angelegter Rüstung', () {
      final hero = _fighter(style: 'Verteidigung');
      final armor = EquipmentRules.preview(
        hero,
        const EquipmentSelection(armorId: 'armor', armorTrained: true),
      );
      expect(armor.armorClass, 15);
      expect(EquipmentRules.confirm(hero, armor).armorClass, 15);
      final shield = EquipmentRules.preview(
        hero,
        const EquipmentSelection(shieldId: 'shield', shieldTrained: true),
      );
      expect(shield.armorClass, 15);
      final noDefense = EquipmentRules.preview(
        _fighter(),
        const EquipmentSelection(armorId: 'armor', armorTrained: true),
      );
      expect(noDefense.armorClass, 14);
    });

    test('Historischer Charakter ohne gewählten Stil bleibt unverändert', () {
      final hero = HeroCharacter.fromJson(
        _fighter().copyWith(features: []).toJson(),
      );
      expect(RulesEngine.attackBonus(hero), 5);
    });
  });
  group('Kampf mit großen Waffen SRD 5.2.1', () {
    test('Schadenswürfel 1 und 2 gelten als 3; Attribut nur einmal', () {
      final hero = _greatWeaponHero();
      final damage = _damageDice('2d6', [1, 2]);
      expect(FighterStyleCombatRules.greatWeaponDamageBonus(hero, damage), 3);
      expect(RulesEngine.weaponDamage(hero, baseRoll: damage), 9);
    });

    test(
      'Kritischer Treffer korrigiert auch die zusätzlichen Waffenwürfel',
      () {
        final hero = _greatWeaponHero();
        final base = _damageDice('2d6', [1, 6]);
        final extra = _damageDice('2d6', [2, 1]);
        expect(
          RulesEngine.weaponDamage(hero, baseRoll: base, criticalExtra: extra),
          18,
        );
      },
    );

    test('Vielseitige Waffe erfordert gewählten Zweihandschaden', () {
      final bothHands = _greatWeaponHero(weaponId: 'longsword', damage: '1d10');
      final oneHand = _greatWeaponHero(weaponId: 'longsword', damage: '1d8');
      expect(
        RulesEngine.weaponDamage(bothHands, baseRoll: _damageDice('1d10', [1])),
        6,
      );
      expect(
        RulesEngine.weaponDamage(oneHand, baseRoll: _damageDice('1d8', [1])),
        4,
      );
    });

    test('Unbestätigte und inkompatible Ausrüstung aktiviert keinen Bonus', () {
      final base = _damageDice('2d6', [1, 2]);
      for (final hero in [
        _greatWeaponHero(style: 'Verteidigung'),
        _greatWeaponHero(className: 'Magier'),
        _greatWeaponHero(shieldId: 'shield'),
        _greatWeaponHero(weaponId: 'missing'),
        _greatWeaponHero(damage: '1d8'),
        _greatWeaponHero(weaponId: 'spear', damage: '1d8'),
      ]) {
        expect(FighterStyleCombatRules.greatWeaponDamageBonus(hero, base), 0);
      }
      expect(
        FighterStyleCombatRules.greatWeaponDamageBonus(
          _greatWeaponHero(),
          _damageDice('1d8', [1]),
        ),
        0,
      );
    });

    test(
      'JSON-Runde erhält bestätigten Stil; ältere Figuren bleiben gleich',
      () {
        final hero = HeroCharacter.fromJson(_greatWeaponHero().toJson());
        final base = _damageDice('2d6', [1, 2]);
        expect(RulesEngine.weaponDamage(hero, baseRoll: base), 9);
        final legacy = HeroCharacter.fromJson(
          hero.copyWith(features: []).toJson(),
        );
        expect(RulesEngine.weaponDamage(legacy, baseRoll: base), 6);
      },
    );
  });
}
