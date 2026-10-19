import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';

void main() {
  test('Alle 12 Klassen-Startsets behalten bekannte Waffen/Rüstungen vollständig', () {
    var imported = 0;
    for (final cls in srdCharacterClasses) {
      for (final kit in cls.kits) {
        for (final starting in kit.items) {
          final result = StartingEquipmentImport.fromStartingItem(
            starting,
            '${cls.name}-${kit.label}-${starting.name}',
          );
          expect(result.quantity, greaterThan(0), reason: starting.name);
          final entry = StartingEquipmentImport.catalogEntry(starting.name);
          if (entry == null) {
            expect(result.catalogId, isEmpty, reason: starting.name);
            expect(result.stats, isNull, reason: starting.name);
            continue;
          }
          imported++;
          expect(result.catalogId, entry.id, reason: starting.name);
          expect(result.stats!.kind, isNot(InventoryItemKind.other));
          expect(
            result.stats!.toJson(),
            InventoryItemStats.fromCatalog(entry).toJson(),
            reason: starting.name,
          );
          final restored = InventoryItem.fromJson(result.toJson());
          expect(restored.toJson(), result.toJson(), reason: starting.name);
        }
      }
    }
    expect(imported, greaterThan(40));
  });

  test('Langschwert: Schaden, Typ, vielseitig, Meisterschaft, Gewicht/Preis', () {
    const name = 'Langschwert';
    final result = StartingEquipmentImport.fromStartingItem(
      const SrdStartingItem(name),
      'sword',
    );
    final catalog = SrdEquipmentCatalog.byId('weapon-longsword')!;
    expect(result.catalogId, catalog.id);
    expect(result.stats!.damage, catalog.damage);
    expect(result.stats!.damageType, catalog.damageType);
    expect(result.stats!.versatileDamage, catalog.twoHandDamage);
    expect(result.stats!.mastery, catalog.mastery);
    expect(result.stats!.weaponProperties, catalog.properties);
    expect(result.stats!.weightLb, catalog.weightLb);
    expect(result.stats!.priceCp, catalog.priceCp);
  });

  test('Kettenpanzer, Schild und Lederrüstung speichern RK-Daten getrennt', () {
    for (final name in ['Kettenpanzer', 'Schild', 'Lederrüstung']) {
      final result = StartingEquipmentImport.fromStartingItem(
        SrdStartingItem(name),
        name,
      );
      final entry = SrdEquipmentCatalog.byId(result.catalogId)!;
      expect(result.stats!.armorBaseAc, entry.armorBaseAc);
      expect(result.stats!.strengthMin, entry.strengthMin);
      expect(result.stats!.dexCap, entry.dexCap);
      expect(
        result.stats!.stealthDisadvantage,
        entry.isArmor ? entry.stealthDisadvantage : null,
      );
    }
  });

  test('20 Pfeile werden genau ein SRD-Katalogpaket, niemals 400 Pfeile', () {
    final item = StartingEquipmentImport.fromStartingItem(
      const SrdStartingItem('Pfeil', 20),
      'arrows',
    );
    expect(item.catalogId, 'item-arrows-20');
    expect(item.quantity, 1);
    expect(item.name, 'Pfeile (20 Stück)');
    expect(item.stats, isNotNull);
    expect(
      () => StartingEquipmentImport.fromStartingItem(
        const SrdStartingItem('Pfeil', 7),
        'wrong',
      ),
      throwsFormatException,
    );
  });

  test('Unentschiedene Startausrüstung bekommt keine erfundene Katalog-ID', () {
    for (final name in [
      'Heiliges Symbol',
      'Musikinstrument (nach Wahl)',
      'Handwerkszeug oder Musikinstrument (nach Wahl)',
      'Druidischer Fokus (Mistelkraut)',
    ]) {
      final item = StartingEquipmentImport.fromStartingItem(
        SrdStartingItem(name),
        name,
      );
      expect(item.catalogId, isEmpty);
      expect(item.stats, isNull);
    }
  });

  test('Bestätigte Katalog-ID im Import ergänzt fehlende Attribute', () {
    final restored = InventoryItem.fromJson({
      'id': 'explicit',
      'name': 'Langschwert',
      'catalogId': 'weapon-longsword',
      'quantity': 1,
      'description': 'Erbstück',
    });
    expect(restored.stats!.damage, '1d8');
    expect(restored.description, 'Erbstück');
    expect(restored.toJson()['stats'], isA<Map<String, dynamic>>());

    final unknown = InventoryItem.fromJson({
      'id': 'unknown',
      'name': 'Unbekanntes Artefakt',
      'catalogId': 'unverified-custom',
    });
    expect(unknown.stats, isNull);
    expect(unknown.catalogId, 'unverified-custom');
  });

  test('Eigene Gegenstandswerte werden beim Import nicht überschrieben', () {
    final custom = InventoryItem.fromJson({
      'id': 'custom',
      'name': 'Langschwert',
      'catalogId': 'weapon-longsword',
      'stats': {
        'kind': 'weapon',
        'damage': '2d6',
        'damageType': 'Feuer',
      },
    });
    expect(custom.stats!.damage, '2d6');
    expect(custom.stats!.damageType, 'Feuer');
    expect(StartingEquipmentImport.enrichLegacyItem(custom).toJson(), custom.toJson());
  });

  test('Altstartsets werden erst nach ausdrücklicher Auswahl vervollständigt', () {
    const original = InventoryItem(
      id: 'historical',
      name: 'Kettenpanzer',
      quantity: 1,
      description: 'Früherer Held',
    );
    expect(original.stats, isNull);
    final enriched = StartingEquipmentImport.enrichLegacyItem(original);
    expect(original.stats, isNull);
    expect(enriched.id, original.id);
    expect(enriched.description, original.description);
    expect(enriched.catalogId, 'armor-chain-mail');
    expect(enriched.stats!.armorBaseAc, 16);
  });

  test('historischer Pfeilstapel bleibt zahlenmäßig exakt', () {
    const historical = InventoryItem(id: 'arrows', name: 'Pfeil', quantity: 20);
    final repaired = StartingEquipmentImport.enrichLegacyItem(historical);
    expect(repaired.quantity, 1);
    expect(repaired.catalogId, 'item-arrows-20');
    expect(
      StartingEquipmentImport.enrichLegacyItem(
        const InventoryItem(id: 'seven', name: 'Pfeil', quantity: 7),
      ).catalogId,
      isEmpty,
    );
  });

  test('Unverifizierte freie Namen werden nicht als SRD-Ausrüstung ausgegeben', () {
    final item = InventoryItem.fromJson({
      'id': 'legacy',
      'name': 'Langschwert',
      'description': 'Kampagne 2023',
    });
    expect(item.catalogId, isEmpty);
    expect(item.stats, isNull);
    expect(item.toJson().containsKey('stats'), isFalse);
  });
}
