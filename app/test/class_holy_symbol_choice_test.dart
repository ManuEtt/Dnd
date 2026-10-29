import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/fighter_creation_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/domain/starting_class_choice.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';

const _symbolIds = [
  'item-holy-symbol-amulet',
  'item-holy-symbol-emblem',
  'item-holy-symbol-reliquary',
];

HeroCharacter _hero(StartingClassChoice proof) {
  var next = 0;
  return proof.selection
      .applyTo(HeroCharacter(id: 'symbol-hero', name: 'Liora'))
      .copyWith(
        startingClassChoice: proof,
        gold: proof.selection.startingKit!.gold,
        inventory: [
          for (final item in proof.selection.startingKit!.items)
            StartingEquipmentImport.fromSelectedStartingItem(
              item,
              'item-${next++}',
              selectedCatalogId: proof.equipmentChoices[item.name],
              choiceVersion: proof.version,
            ),
        ],
      );
}

CreationStep _equipment(HeroCharacter hero) =>
    SrdCharacterCreationAudit.inspect(
      hero,
    ).singleWhere((step) => step.id == 'class.equipment');

void main() {
  test(
    'Symbolwahl enthält nur drei amtliche Varianten, keine Fokus-Ersatzwahl',
    () {
      final options = StartingEquipmentImport.optionsFor(
        const SrdStartingItem('Heiliges Symbol'),
      );
      expect(options.map((entry) => entry.id), _symbolIds);
      expect(options.map((entry) => entry.priceCp), everyElement(500));
      expect(options.map((entry) => entry.weightLb), [1.0, null, 2.0]);
      expect(StartingEquipmentImport.catalogEntry('Heiliges Symbol'), isNull);
      expect(
        () => StartingEquipmentImport.fromSelectedStartingItem(
          const SrdStartingItem('Heiliges Symbol'),
          'missing',
        ),
        throwsFormatException,
      );
      expect(
        () => StartingEquipmentImport.validateKitChoices(
          findSrdClass('Kleriker')!.kits[1],
          {},
          choiceVersion: 999,
        ),
        throwsFormatException,
      );
    },
  );

  for (final className in ['Kleriker', 'Paladin']) {
    final klass = findSrdClass(className)!;
    final skills = klass.skillChoices.take(klass.skillCount).toList();
    for (final symbolId in _symbolIds) {
      test('$className: $symbolId mit typisiertem Inventar und Audit', () {
        final proof = StartingClassChoice.confirmed(
          className: className,
          skills: skills,
          kitIndex: 0,
          equipmentChoices: {'Heiliges Symbol': symbolId},
        );
        expect(proof.version, 2);
        final hero = _hero(proof);
        final symbol = hero.inventory.singleWhere(
          (item) => item.catalogId == symbolId,
        );
        final entry = SrdEquipmentCatalog.byId(symbolId)!;
        expect(symbol.quantity, 1);
        expect(symbol.name, entry.name);
        expect(
          symbol.stats!.toJson(),
          InventoryItemStats.fromCatalog(entry).toJson(),
        );
        expect(hero.gold, className == 'Kleriker' ? 7 : 9);
        expect(_equipment(hero).status, CreationStepStatus.confirmed);
        final before = jsonEncode(hero.toJson());
        expect(
          HeroCharacter.fromJson(jsonDecode(before)).toJson(),
          hero.toJson(),
        );
        expect(
          _equipment(hero.copyWith(inventory: [])).status,
          CreationStepStatus.notAutomated,
        );
        expect(
          _equipment(hero.copyWith(gold: 0)).status,
          CreationStepStatus.notAutomated,
        );
        expect(jsonEncode(hero.toJson()), before);
      });
    }
    test('$className: fehlende und fremde Symbolwahlen werden abgewiesen', () {
      for (final choices in <Map<String, String>>[
        {},
        {'Heiliges Symbol': 'item-arcane-focus-crystal'},
        {'Heiliges Symbol': 'item-lute'},
        {'Heiliges Symbol': 'item-holy-symbol-nonexistent'},
        {'Heiliges Symbol': _symbolIds.first, 'fremde Wahl': 'item-lute'},
      ]) {
        expect(
          () => StartingClassChoice.confirmed(
            className: className,
            skills: skills,
            kitIndex: 0,
            equipmentChoices: choices,
          ),
          throwsFormatException,
        );
      }
      final valid = StartingClassChoice.confirmed(
        className: className,
        skills: skills,
        kitIndex: 0,
        equipmentChoices: {'Heiliges Symbol': _symbolIds.first},
      ).toJson();
      expect(
        () => StartingClassChoice.fromJson({...valid, 'equipmentChoices': {}}),
        throwsFormatException,
      );
    });
    test('$className: Goldalternative vergibt kein Symbol', () {
      final proof = StartingClassChoice.confirmed(
        className: className,
        skills: skills,
        kitIndex: 1,
      );
      final hero = _hero(proof);
      expect(hero.gold, className == 'Kleriker' ? 110 : 150);
      expect(hero.inventory, isEmpty);
      expect(_equipment(hero).status, CreationStepStatus.confirmed);
      expect(
        () => StartingClassChoice.confirmed(
          className: className,
          skills: skills,
          kitIndex: 1,
          equipmentChoices: {'Heiliges Symbol': _symbolIds.first},
        ),
        throwsFormatException,
      );
    });
    test('$className: echte alte v1 bleibt ungelöst, wird nie aufgewertet', () {
      final raw = <String, dynamic>{
        'version': 1,
        'className': className,
        'skills': skills,
        'kitIndex': 0,
        'equipmentChoices': <String, String>{},
      };
      final before = jsonEncode(raw);
      final old = StartingClassChoice.fromJson(raw);
      expect(jsonEncode(old.toJson()), before);
      final hero = _hero(old);
      final unresolved = hero.inventory.singleWhere(
        (item) => item.name == 'Heiliges Symbol',
      );
      expect(unresolved.catalogId, isEmpty);
      expect(unresolved.stats, isNull);
      expect(_equipment(hero).status, CreationStepStatus.notAutomated);
      expect(HeroCharacter.fromJson(hero.toJson()).toJson(), hero.toJson());
      final updated = old.withUpdatedClassDecisions(
        StartingClassChoice.confirmed(
          className: className,
          skills: klass.skillChoices.toList().reversed.take(klass.skillCount),
        ),
      );
      expect(updated.version, 1);
      expect(updated.kitIndex, 0);
      expect(updated.equipmentChoices, isEmpty);
      expect(
        _equipment(_hero(updated)).status,
        CreationStepStatus.notAutomated,
      );
      expect(jsonEncode(old.toJson()), before);
      expect(
        () => StartingClassChoice.fromJson({
          ...raw,
          'equipmentChoices': {'Heiliges Symbol': _symbolIds.first},
        }),
        throwsFormatException,
      );
      expect(
        () => old.withUpdatedClassDecisions(
          StartingClassChoice.confirmed(
            className: 'Barbar',
            skills: const ['Athletik', 'Wahrnehmung'],
          ),
        ),
        throwsFormatException,
      );
    });
  }

  // Exercise every historical class and kit, not only the changed two.
  for (final klass in srdCharacterClasses) {
    test('${klass.name}: alle ursprünglichen v1-Kits bleiben lesbar', () {
      for (var kitIndex = 0; kitIndex < klass.kits.length; kitIndex++) {
        final kit = klass.kits[kitIndex];
        final raw = <String, dynamic>{
          'version': 1,
          'className': klass.name,
          'skills': klass.skillChoices.take(klass.skillCount).toList(),
          'kitIndex': kitIndex,
          'equipmentChoices': {
            for (final item in kit.items)
              if (StartingEquipmentImport.optionsFor(
                item,
                choiceVersion: 1,
              ).isNotEmpty)
                item.name: StartingEquipmentImport.optionsFor(
                  item,
                  choiceVersion: 1,
                ).first.id,
          },
          if (klass.name == 'Kämpfer')
            'fighterChoices': {
              'styleId': 'defense',
              'masteryWeaponIds': FighterCreationRules.masteryWeapons
                  .take(3)
                  .map((item) => item.id)
                  .toList(),
            },
        };
        final restored = StartingClassChoice.fromJson(raw);
        expect(restored.toJson(), raw);
        expect(
          () => SrdCharacterCreationAudit.inspect(_hero(restored)),
          returnsNormally,
        );
      }
    });
  }
}
