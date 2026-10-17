import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';

void main() {
  test('SRD 5.2.1 contains all 38 weapon and 13 armor table entries', () {
    final weapons = SrdEquipmentCatalog.all.where((e) => e.isWeapon);
    final armor = SrdEquipmentCatalog.all.where((e) => e.isArmor || e.isShield);
    expect(weapons, hasLength(38));
    expect(armor, hasLength(13));
    expect(SrdEquipmentCatalog.all.length, greaterThan(200));
    final ids = SrdEquipmentCatalog.all.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final entry in SrdEquipmentCatalog.all) {
      expect(entry.id, isNotEmpty);
      expect(entry.name, isNotEmpty);
      expect(entry.englishName, isNotEmpty);
      expect(entry.priceCp == null || entry.priceCp! >= 0, isTrue);
    }
  });

  test('Longsword stats, mastery and versatile damage are from SRD', () {
    final sword = SrdEquipmentCatalog.byId('weapon-longsword')!;
    expect(sword.name, 'Langschwert');
    expect(sword.damage, '1d8');
    expect(sword.twoHandDamage, '1d10');
    expect(sword.damageType, 'Hieb');
    expect(sword.mastery, 'sap');
    expect(sword.hasProperty('versatile'), isTrue);
    expect(sword.priceCp, 1500);
  });

  test('Finesse, thrown, ammunition, reach and mastery remain distinct', () {
    final dagger = SrdEquipmentCatalog.byId('weapon-dagger')!;
    expect(dagger.hasProperty('finesse'), isTrue);
    expect(dagger.hasProperty('thrown'), isTrue);
    expect(dagger.rangeNormal, 20);
    expect(dagger.rangeLong, 60);
    expect(dagger.mastery, 'nick');
    final bow = SrdEquipmentCatalog.byId('weapon-longbow')!;
    expect(bow.hasProperty('ammunition'), isTrue);
    expect(bow.hasProperty('heavy'), isTrue);
    expect(bow.rangeLong, 600);
    expect(bow.ammunitionType, 'arrows');
    expect(
      SrdEquipmentCatalog.byId('weapon-glaive')!.hasProperty('reach'),
      isTrue,
    );
  });

  test('Armor AC rules cap positive DEX, preserve negative DEX', () {
    expect(
      SrdEquipmentCatalog.byId('armor-leather-armor')!.armorClassWithDex(4),
      15,
    );
    expect(
      SrdEquipmentCatalog.byId('armor-leather-armor')!.armorClassWithDex(null),
      isNull,
    );
    expect(
      SrdEquipmentCatalog.byId('armor-scale-mail')!.armorClassWithDex(5),
      16,
    );
    expect(
      SrdEquipmentCatalog.byId('armor-scale-mail')!.armorClassWithDex(-1),
      13,
    );
    expect(
      SrdEquipmentCatalog.byId('armor-chain-mail')!.armorClassWithDex(null),
      16,
    );
    expect(SrdEquipmentCatalog.byId('armor-chain-mail')!.strengthMin, 13);
    expect(SrdEquipmentCatalog.byId('armor-shield')!.isShield, isTrue);
    expect(
      SrdEquipmentCatalog.byId('armor-shield')!.armorClassWithDex(4),
      isNull,
    ); // shield adds +2 only with training
  });

  test('German/English item search and category filters', () {
    expect(
      SrdEquipmentCatalog.search('Langschwert').single.id,
      'weapon-longsword',
    );
    expect(
      SrdEquipmentCatalog.search('Longsword').single.id,
      'weapon-longsword',
    );
    expect(
      SrdEquipmentCatalog.search('  LANGSCHWERT ').single.id,
      'weapon-longsword',
    );
    expect(
      SrdEquipmentCatalog.search(
        '',
        category: EquipmentCategory.shield,
      ).single.id,
      'armor-shield',
    );
    expect(
      SrdEquipmentCatalog.search('Longsword', category: EquipmentCategory.gear),
      isEmpty,
    );
    expect(SrdEquipmentCatalog.byId('missing'), isNull);
  });

  test('Magic catalog selection cannot invent automatic bonuses', () {
    final bag = SrdEquipmentCatalog.byId('magic-bag-of-holding')!;
    expect(bag.category, EquipmentCategory.magic);
    expect(bag.armorClassWithDex(3), isNull);
    expect(bag.damage, isNull);
    expect(bag.detail, contains('Keine automatische Regeländerung'));
  });

  test('Inventory catalog ID persists while legacy records are unmodified', () {
    final legacy = InventoryItem.fromJson({
      'id': 'old',
      'name': 'Magischer Schlüssel',
      'quantity': 2,
      'description': 'Historische Notiz',
    });
    expect(legacy.catalogId, '');
    expect(legacy.toJson().containsKey('catalogId'), isFalse);
    final selected = InventoryItem(
      id: 'new',
      name: 'Langschwert',
      description: SrdEquipmentCatalog.byId('weapon-longsword')!.detail,
      catalogId: 'weapon-longsword',
    );
    final restored = InventoryItem.fromJson(selected.toJson());
    expect(restored.catalogId, 'weapon-longsword');
    expect(restored.description, contains('1d8'));
    expect(restored.quantity, 1);
  });
}
