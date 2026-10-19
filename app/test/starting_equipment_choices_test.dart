import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';

void main() {
  test('Bardeninstrument muss konkret gewählt werden und bleibt typisiert', () {
    final bard = findSrdClass('Barde')!;
    final kit = bard.kits.first;
    final item = kit.items.singleWhere(
      (item) => item.name == 'Musikinstrument (nach Wahl)',
    );
    final choices = StartingEquipmentImport.optionsFor(item);
    expect(choices.length, greaterThan(3));
    expect(
      choices.every((e) => e.category == EquipmentCategory.instrument),
      isTrue,
    );
    final lute = choices.singleWhere((e) => e.name == 'Laute');
    expect(
      () => StartingEquipmentImport.validateKitChoices(kit, {}),
      throwsFormatException,
    );
    StartingEquipmentImport.validateKitChoices(kit, {item.name: lute.id});
    final imported = StartingEquipmentImport.fromSelectedStartingItem(
      item,
      'bard-lute',
      selectedCatalogId: lute.id,
    );
    expect(imported.name, 'Laute');
    expect(imported.catalogId, lute.id);
    expect(imported.quantity, item.quantity);
    expect(imported.stats!.priceCp, lute.priceCp);
    expect(imported.stats!.weightLb, lute.weightLb);
    expect(imported.toJson()['catalogId'], lute.id);
  });

  test('Mönch darf nur echtes Werkzeug oder Instrument wählen', () {
    final monk = findSrdClass('Mönch')!;
    final kit = monk.kits.first;
    final item = kit.items.singleWhere(
      (item) => item.name == 'Handwerkszeug oder Musikinstrument (nach Wahl)',
    );
    final options = StartingEquipmentImport.optionsFor(item);
    expect(options.any((e) => e.category == EquipmentCategory.tool), isTrue);
    expect(
      options.any((e) => e.category == EquipmentCategory.instrument),
      isTrue,
    );
    final selected = options.firstWhere(
      (e) => e.category == EquipmentCategory.tool,
    );
    StartingEquipmentImport.validateKitChoices(kit, {item.name: selected.id});
    final result = StartingEquipmentImport.fromSelectedStartingItem(
      item,
      'monk-tool',
      selectedCatalogId: selected.id,
    );
    expect(result.name, selected.name);
    expect(result.catalogId, selected.id);
    expect(result.stats, isNotNull);
  });

  test(
    'Waffen, Rüstung und ungelöste heilige Symbole erhalten keine Scheinwahl',
    () {
      for (final name in ['Kettenpanzer', 'Heiliges Symbol', 'Langschwert']) {
        final item = SrdStartingItem(name);
        expect(StartingEquipmentImport.optionsFor(item), isEmpty);
        expect(
          () => StartingEquipmentImport.fromSelectedStartingItem(
            item,
            'invalid',
            selectedCatalogId: 'item-lute',
          ),
          throwsFormatException,
        );
        final normal = StartingEquipmentImport.fromSelectedStartingItem(
          item,
          'normal',
        );
        if (name == 'Heiliges Symbol') {
          expect(normal.catalogId, isEmpty);
          expect(normal.stats, isNull);
        } else {
          expect(normal.catalogId, isNotEmpty);
        }
      }
    },
  );

  test('Ungültige IDs und veraltete Klassenwahlen werden abgewiesen', () {
    final bard = findSrdClass('Barde')!.kits.first;
    const label = 'Musikinstrument (nach Wahl)';
    for (final choices in [
      <String, String>{label: 'weapon-longsword'},
      <String, String>{label: 'item-no-such-object'},
      <String, String>{label: 'item-lute', 'Unbekannte Wahl': 'item-flute'},
    ]) {
      expect(
        () => StartingEquipmentImport.validateKitChoices(bard, choices),
        throwsFormatException,
      );
    }
    expect(
      () => StartingEquipmentImport.fromSelectedStartingItem(
        const SrdStartingItem(label),
        'invalid',
        selectedCatalogId: 'weapon-longsword',
      ),
      throwsFormatException,
    );
  });

  test(
    'Alle zwölf Klassen: konkrete Auswahl nur in klassengebundenen Startpaketen',
    () {
      final withChoices = <String>[];
      for (final klass in srdCharacterClasses) {
        for (final kit in klass.kits) {
          final unresolved = [
            for (final item in kit.items)
              if (StartingEquipmentImport.optionsFor(item).isNotEmpty)
                item.name,
          ];
          if (unresolved.isEmpty) {
            StartingEquipmentImport.validateKitChoices(kit, {});
            continue;
          }
          withChoices.add(klass.name);
          expect(
            () => StartingEquipmentImport.validateKitChoices(kit, {}),
            throwsFormatException,
          );
          final selected = {
            for (final item in kit.items)
              if (StartingEquipmentImport.optionsFor(item).isNotEmpty)
                item.name: StartingEquipmentImport.optionsFor(item).first.id,
          };
          StartingEquipmentImport.validateKitChoices(kit, selected);
          for (final item in kit.items) {
            final result = StartingEquipmentImport.fromSelectedStartingItem(
              item,
              'test-${item.name}',
              selectedCatalogId: selected[item.name],
            );
            expect(result.quantity, greaterThan(0));
            if (selected.containsKey(item.name)) {
              expect(result.catalogId, selected[item.name]);
            }
          }
        }
      }
      expect(withChoices, containsAll(['Barde', 'Mönch']));
    },
  );
}
