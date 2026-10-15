import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/equipment_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

InventoryItem owned(String id, String catalogId) => InventoryItem(
  id: id, name: catalogId, catalogId: catalogId);

HeroCharacter hero({int? strength = 16, int? dexterity = 14,
    List<InventoryItem>? inventory}) => HeroCharacter(
  id: 'hero', name: 'Elowen', className: 'Kämpfer', level: 5,
  armorClass: 13, weaponDamage: '1d4', weaponAbility: 'strength',
  abilities: {'strength': strength, 'dexterity': dexterity,
    'constitution': 14, 'intelligence': 10,
    'wisdom': 10, 'charisma': 10},
  inventory: inventory ?? [
    owned('leather', 'armor-leather-armor'),
    owned('scale', 'armor-scale-mail'),
    owned('plate', 'armor-plate-armor'),
    owned('shield', 'armor-shield'),
    owned('sword', 'weapon-longsword'),
    owned('dagger', 'weapon-dagger'),
    owned('bow', 'weapon-longbow'),
    owned('bag', 'magic-bag-of-holding'),
  ]);

void main() {
  group('SRD 5.2.1: Ausrüstungsvorschau und explizite Bestätigung', () {
    test('Leichte Rüstung mit voller GE und geübtem Schild', () {
      final h = hero(dexterity: 18);
      final choice = EquipmentSelection(armorId: 'leather', shieldId: 'shield',
        armorTrained: true, shieldTrained: true);
      final p = EquipmentRules.preview(h, choice);
      expect(p.armorClass, 17); // Leder 11 + GE 4 + Schild 2
      expect(p.armorUntrained, isFalse);
      expect(EquipmentRules.confirm(h, p).armorClass, 17);
      expect(h.armorClass, 13); // pure preview; no mutation
    });

    test('Mittelschwere Rüstung GE höchstens +2, Negativwert bleibt', () {
      expect(EquipmentRules.preview(hero(dexterity: 20),
        const EquipmentSelection(armorId: 'scale', armorTrained: true))
        .armorClass, 16);
      expect(EquipmentRules.preview(hero(dexterity: 8),
        const EquipmentSelection(armorId: 'scale', armorTrained: true))
        .armorClass, 13);
    });

    test('Schwere Rüstung ignoriert GE, ST-Grenze senkt Bewegung', () {
      final h = hero(strength: 10, dexterity: null);
      final p = EquipmentRules.preview(h,
        const EquipmentSelection(armorId: 'plate', armorTrained: true));
      expect(p.armorClass, 18);
      expect(p.speedPenaltyFeet, 10);
      expect(p.stealthDisadvantage, isTrue);
    });

    test('Ungeübter Schild bringt keinen RK-Bonus und Rüstungsnachteil', () {
      final p = EquipmentRules.preview(hero(),
        const EquipmentSelection(armorId: 'leather', shieldId: 'shield'));
      expect(p.armorClass, 13);
      expect(p.armorUntrained, isTrue);
      expect(p.warnings.join(' '), contains('keine Zauberwirkung'));
    });

    test('Waffenbonus und Waffenschaden rechnen Übung korrekt', () {
      final h = hero();
      final p = EquipmentRules.preview(h,
        const EquipmentSelection(weaponId: 'sword', weaponProficient: true,
          twoHands: true));
      expect(p.attackBonus, 6); // ST 3 + Übung 3
      expect(p.damageModifier, 3);
      expect(p.weaponDamage, '1d10');
      final applied = EquipmentRules.confirm(h, p);
      expect(applied.weaponDamage, '1d10');
      expect(applied.weaponAbility, 'strength');
      expect(applied.equippedWeaponId, 'sword');
      expect(applied.weaponProficient, isTrue);
    });

    test('Finesse und Wurfwaffen verwenden bestätigte GE', () {
      final p = EquipmentRules.preview(hero(strength: 10, dexterity: 18),
        const EquipmentSelection(weaponId: 'dagger',
          preferDexterity: true, thrown: true, weaponProficient: true));
      expect(p.weaponAbility, 'dexterity');
      expect(p.attackBonus, 7);
      expect(p.weaponDamage, '1d4');
      expect(p.rangeNormal, 20);
      expect(p.rangeLong, 60);
    });

    test('Schwere Fernkampfwaffe: GE unter 13 bringt Nachteil', () {
      final p = EquipmentRules.preview(hero(dexterity: 12),
        const EquipmentSelection(weaponId: 'bow'));
      expect(p.heavyAttackDisadvantage, isTrue);
      expect(p.needsAmmunition, isTrue);
      expect(p.weaponAbility, 'dexterity');
    });

    test('Keine Mehrfachbelegung, ungeeigneten Slot oder magische Effekte', () {
      final h = hero();
      expect(() => EquipmentRules.preview(h,
        const EquipmentSelection(armorId: 'sword')), throwsStateError);
      expect(() => EquipmentRules.preview(h,
        const EquipmentSelection(weaponId: 'bag')), throwsStateError);
      expect(() => EquipmentRules.preview(h,
        const EquipmentSelection(armorId: 'leather', weaponId: 'leather')),
        throwsStateError);
      expect(() => EquipmentRules.preview(h,
        const EquipmentSelection(shieldId: 'shield', weaponId: 'bow')),
        throwsStateError);
      expect(() => EquipmentRules.preview(h,
        const EquipmentSelection(shieldId: 'shield', weaponId: 'sword',
          twoHands: true)), throwsStateError);
    });

    test('Unbestätigte Werte und nicht besessene Items werden abgelehnt', () {
      expect(() => EquipmentRules.preview(hero(dexterity: null),
        const EquipmentSelection(armorId: 'leather')), throwsStateError);
      expect(() => EquipmentRules.preview(hero(),
        const EquipmentSelection(armorId: 'invented')), throwsStateError);
      expect(() => EquipmentRules.preview(hero(),
        const EquipmentSelection(weaponId: 'sword', preferDexterity: true)),
        throwsStateError);
    });

    test('Vorschau veraltet nach Attributsänderung', () {
      final h = hero();
      final p = EquipmentRules.preview(h,
        const EquipmentSelection(armorId: 'leather', weaponId: 'sword',
          weaponProficient: true));
      expect(() => EquipmentRules.confirm(h.copyWith(abilities: {
        ...h.abilities, 'strength': 18,
      }), p), throwsStateError);
    });

    test('Bestätigung lehnt anderen Helden und manuell geänderte RK ab', () {
      final h = hero();
      final p = EquipmentRules.preview(h,
        const EquipmentSelection(armorId: 'leather'));
      expect(() => EquipmentRules.confirm(h.copyWith(id: 'another'), p),
        throwsStateError);
      expect(() => EquipmentRules.confirm(h.copyWith(armorClass: 19), p),
        throwsStateError);
    });

    test('Schema-1-Altdaten erhalten, angelegte Referenzen werden geprüft', () {
      final original = hero();
      final legacy = HeroCharacter.fromJson(original.toJson());
      expect(legacy.equippedArmorId, isEmpty);
      expect(legacy.toJson().containsKey('equippedArmorId'), isFalse);
      final p = EquipmentRules.preview(legacy,
        const EquipmentSelection(armorId: 'scale', shieldId: 'shield',
          armorTrained: true, shieldTrained: true));
      final equipped = EquipmentRules.confirm(legacy, p);
      final parsed = HeroCharacter.fromJson(equipped.toJson());
      expect(parsed.equippedArmorId, 'scale');
      expect(parsed.equippedShieldId, 'shield');
      expect(parsed.equippedArmorTrained, isTrue);
      expect(parsed.armorClass, 18);
      final bad = equipped.toJson()..['equippedShieldId'] = 'ghost';
      expect(() => HeroCharacter.fromJson(bad), throwsFormatException);
    });
  });
}
