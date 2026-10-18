import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/equipment_rules.dart';
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
}
