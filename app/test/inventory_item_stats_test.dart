import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';

void main() {
  test('Historische Items bleiben ohne erfundene Einzelwerte lesbar', () {
    final old = InventoryItem.fromJson({
      'id': 'old-key',
      'name': 'Alter Schlüssel',
      'quantity': 2,
      'description': 'Historische Beschreibung unverändert.',
    });
    expect(old.stats, isNull);
    expect(old.catalogId, isEmpty);
    expect(old.toJson().containsKey('stats'), isFalse);
    expect(old.description, 'Historische Beschreibung unverändert.');
  });

  test('Langschwertwerte kommen aus eigenen SRD-Datenfeldern', () {
    final entry = SrdEquipmentCatalog.byId('weapon-longsword')!;
    final item = InventoryItem(
      id: 'sword-1',
      name: entry.name,
      catalogId: entry.id,
      stats: InventoryItemStats.fromCatalog(entry),
    );
    final loaded = InventoryItem.fromJson(item.toJson());
    expect(loaded.stats!.kind, InventoryItemKind.weapon);
    expect(loaded.stats!.damage, '1d8');
    expect(loaded.stats!.versatileDamage, '1d10');
    expect(loaded.stats!.priceCp, 1500);
    expect(loaded.stats!.weaponProperties, contains('versatile'));
    expect(loaded.description, isEmpty);
    expect(loaded.catalogId, 'weapon-longsword');
  });

  test('Bearbeitete magische Items speichern Felder getrennt', () {
    final item = InventoryItem(
      id: 'staff',
      name: 'Stab',
      stats: InventoryItemStats.fromJson({
        'kind': 'magic',
        'rarity': 'selten',
        'requiresAttunement': true,
        'charges': 3,
        'maxCharges': 7,
        'priceCp': 250,
        'weightLb': 1.5,
        'effect': 'Wirkt nur nach manueller Bestätigung.',
      }),
    );
    final copy = InventoryItem.fromJson(item.toJson());
    expect(copy.stats!.requiresAttunement, true);
    expect(copy.stats!.charges, 3);
    expect(copy.stats!.maxCharges, 7);
    expect(copy.stats!.weightLb, 1.5);
    expect(copy.description, isEmpty);
    final stack = copy.copyWith(quantity: 2);
    expect(stack.stats!.rarity, 'selten');
    expect(stack.stats!.charges, 3);
  });

  test('Schilde speichern RK-Bonus und unbestätigte Flags nullable', () {
    final entry = SrdEquipmentCatalog.byId('armor-shield')!;
    final copy = InventoryItemStats.fromJson(
      InventoryItemStats.fromCatalog(entry).toJson(),
    );
    expect(copy.kind, InventoryItemKind.shield);
    expect(copy.armorBaseAc, 2);
    expect(copy.stealthDisadvantage, isNull);
  });

  test('Import lehnt ungültige Itemdaten ab, statt zu raten', () {
    final bad = <Map<String, dynamic>>[
      {'kind': 'magischesUnsinnswort'},
      {'kind': 'weapon', 'priceCp': -1},
      {'kind': 'weapon', 'weightLb': double.nan},
      {'kind': 'magic', 'requiresAttunement': 'yes'},
      {'kind': 'magic', 'charges': 10, 'maxCharges': 4},
      {'kind': 'weapon', 'rangeNormalFt': 90, 'rangeLongFt': 20},
      {
        'kind': 'weapon',
        'weaponProperties': [11],
      },
    ];
    for (final json in bad) {
      expect(
        () => InventoryItemStats.fromJson(json),
        throwsFormatException,
        reason: '$json',
      );
    }
  });
}
