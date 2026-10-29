import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/fighter_creation_rules.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/domain/starting_class_choice.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';

StartingClassChoice choiceFor(SrdCharacterClass klass, {int? kitIndex}) {
  final kit = kitIndex == null ? null : klass.kits[kitIndex];
  return StartingClassChoice.confirmed(
    className: klass.name,
    skills: klass.skillChoices.take(klass.skillCount),
    kitIndex: kitIndex,
    equipmentChoices: {
      if (kit != null)
        for (final item in kit.items)
          if (StartingEquipmentImport.optionsFor(item).isNotEmpty)
            item.name: StartingEquipmentImport.optionsFor(item).last.id,
    },
    fighterChoices: klass.name == 'Kämpfer'
        ? FighterStartingChoices(
            styleId: 'defense',
            masteryWeaponIds: FighterCreationRules.masteryWeapons
                .take(3)
                .map((e) => e.id),
          )
        : null,
  );
}

HeroCharacter heroFor(StartingClassChoice choice) {
  final kit = choice.selection.startingKit;
  var id = 0;
  return HeroCharacter(
    id: 'proof',
    name: 'Testfigur',
    className: choice.className,
    startingClassChoice: choice,
    skills: choice.skills,
    savingThrowProficiencies: choice.selection.characterClass.savingThrows,
    gold: kit?.gold,
    inventory: [
      if (kit != null)
        for (final item in kit.items)
          StartingEquipmentImport.fromSelectedStartingItem(
            item,
            'item-${id++}',
            selectedCatalogId: choice.equipmentChoices[item.name],
          ),
    ],
  );
}

Map<String, CreationStepStatus> statuses(HeroCharacter hero) => {
  for (final step in SrdCharacterCreationAudit.inspect(hero))
    step.id: step.status,
};

void main() {
  for (final klass in srdCharacterClasses) {
    test('${klass.name}: ausdrückliche Quellenwahl, alle Pakete und JSON', () {
      final partial = choiceFor(klass);
      final hero = heroFor(partial);
      expect(statuses(hero)['class.selection'], CreationStepStatus.confirmed);
      expect(statuses(hero)['class.skills'], CreationStepStatus.confirmed);
      expect(
        statuses(hero)['class.saving-throws'],
        CreationStepStatus.confirmed,
      );
      expect(statuses(hero)['class.equipment'], CreationStepStatus.missing);
      expect(statuses(hero)['class.choices'], CreationStepStatus.notAutomated);
      expect(
        statuses(hero.copyWith(startingClassChoice: null))['class.selection'],
        CreationStepStatus.notAutomated,
      );
      for (var kit = 0; kit < klass.kits.length; kit++) {
        final initial = heroFor(choiceFor(klass, kitIndex: kit));
        final before = jsonEncode(initial.toJson());
        final restored = HeroCharacter.fromJson(
          jsonDecode(before) as Map<String, dynamic>,
        );
        expect(restored.toJson(), initial.toJson());
        expect(
          statuses(restored)['class.equipment'],
          (initial.inventory.any(
                    (i) => i.catalogId.isEmpty || i.stats == null,
                  ) ||
                  (klass.name == 'Mönch' &&
                      initial.startingClassChoice!.equipmentChoices.isNotEmpty))
              ? CreationStepStatus.notAutomated
              : CreationStepStatus.confirmed,
        );
        expect(jsonEncode(initial.toJson()), before);
        expect(
          statuses(restored)['origin.feat'],
          CreationStepStatus.notAutomated,
        );
        final later = restored.copyWith(level: 5, gold: 0, inventory: []);
        expect(
          later.startingClassChoice!.toJson(),
          initial.startingClassChoice!.toJson(),
        );
        expect(
          statuses(later)['class.equipment'],
          isNot(CreationStepStatus.confirmed),
        );
      }
    });
  }

  test('Nachweis ist unveränderlich und gewährt selbst keine Werte', () {
    final skills = ['Athletik', 'Wahrnehmung'];
    final choices = <String, String>{};
    final proof = StartingClassChoice.confirmed(
      className: 'Barbar',
      skills: skills,
      kitIndex: 1,
      equipmentChoices: choices,
    );
    skills.clear();
    choices['erfunden'] = 'falsch';
    expect(proof.skills, ['Athletik', 'Wahrnehmung']);
    expect(proof.equipmentChoices, isEmpty);
    expect(() => proof.skills.clear(), throwsUnsupportedError);
    expect(() => proof.equipmentChoices['x'] = 'y', throwsUnsupportedError);
    final existing = HeroCharacter(id: 'old', name: 'Altfigur', gold: 3);
    final attached = existing.copyWith(startingClassChoice: proof);
    expect(attached.gold, 3);
    expect(attached.inventory, isEmpty);
    expect(attached.skills, isEmpty);
    expect(
      attached.copyWith(startingClassChoice: null).toJson(),
      existing.toJson(),
    );
  });

  test('strenge Version, Klassenfertigkeiten und Kämpferentscheidungen', () {
    final valid = choiceFor(srdCharacterClasses.first).toJson();
    for (final patch in <Map<String, dynamic>>[
      {'version': 1.0},
      {'version': 3},
      {'className': 'fighter'},
      {'className': 'Erfundene Klasse'},
      {
        'skills': ['Athletik', 'Athletik'],
      },
      {
        'skills': ['Arkane Kunde', 'Religion'],
      },
      {'kitIndex': -1},
      {'kitIndex': 99},
      {'kitIndex': 1.0},
      {
        'equipmentChoices': {'erfunden': 'weapon-longsword'},
      },
      {'skills': null},
      {'equipmentChoices': null},
      {
        'fighterChoices': {'styleId': 'defense', 'masteryWeaponIds': []},
      },
    ]) {
      expect(
        () => StartingClassChoice.fromJson({...valid, ...patch}),
        throwsFormatException,
        reason: '$patch',
      );
    }
    final fighter = choiceFor(findSrdClass('Kämpfer')!).toJson();
    expect(
      () => StartingClassChoice.fromJson({...fighter, 'fighterChoices': null}),
      throwsFormatException,
    );
  });

  test('Instrumentwahl benötigt zulässigen konkreten Katalogeintrag', () {
    final bard = choiceFor(findSrdClass('Barde')!, kitIndex: 0);
    expect(bard.equipmentChoices, isNotEmpty);
    expect(
      () => StartingClassChoice.fromJson({
        ...bard.toJson(),
        'equipmentChoices': {},
      }),
      throwsFormatException,
    );
    expect(
      () => StartingClassChoice.fromJson({
        ...bard.toJson(),
        'equipmentChoices': {
          bard.equipmentChoices.keys.single: 'weapon-longsword',
        },
      }),
      throwsFormatException,
    );
  });

  test(
    'Mönch erhält nur Handwerkszeug oder Instrument, keine fremden Werkzeuge',
    () {
      final monk = choiceFor(findSrdClass('Mönch')!, kitIndex: 0);
      final label = monk.equipmentChoices.keys.single;
      for (final forbidden in [
        'item-thieves-tools',
        'item-herbalism-kit',
        'item-navigator-s-tools',
      ]) {
        expect(
          () => StartingClassChoice.fromJson({
            ...monk.toJson(),
            'equipmentChoices': {label: forbidden},
          }),
          throwsFormatException,
        );
      }
      final options = StartingEquipmentImport.optionsFor(
        SrdStartingItem(label),
      );
      expect(options.where((e) => e.category.name == 'tool'), hasLength(17));
      expect(options.any((e) => e.id == 'item-smith-s-tools'), isTrue);
      expect(options.any((e) => e.category.name == 'instrument'), isTrue);
    },
  );

  test(
    'Mönch-Paket verlangt noch den strukturierten Nachweis derselben Werkzeugübung',
    () {
      final hero = heroFor(choiceFor(findSrdClass('Mönch')!, kitIndex: 0));
      expect(
        hero.inventory.every((i) => i.catalogId.isNotEmpty && i.stats != null),
        isTrue,
      );
      expect(
        statuses(hero)['class.equipment'],
        CreationStepStatus.notAutomated,
      );
      expect(statuses(hero)['class.selection'], CreationStepStatus.confirmed);
      final report = SrdCharacterCreationAudit.inspect(
        hero,
      ).singleWhere((step) => step.id == 'class.equipment');
      expect(report.detail, contains('Werkzeugübung'));
    },
  );

  test(
    'Widersprüche werden geprüft, historische Ausrüstung nie neu vergeben',
    () {
      final hero = heroFor(choiceFor(findSrdClass('Barbar')!, kitIndex: 0));
      expect(
        statuses(hero.copyWith(className: 'Mönch'))['class.selection'],
        CreationStepStatus.invalid,
      );
      expect(
        statuses(hero.copyWith(skills: []))['class.skills'],
        CreationStepStatus.invalid,
      );
      expect(
        statuses(
          hero.copyWith(savingThrowProficiencies: []),
        )['class.saving-throws'],
        CreationStepStatus.missing,
      );
      expect(
        statuses(hero.copyWith(inventory: []))['class.equipment'],
        CreationStepStatus.notAutomated,
      );
      expect(
        statuses(hero.copyWith(gold: 0))['class.equipment'],
        CreationStepStatus.notAutomated,
      );
      final fakeItems = hero.inventory
          .map(
            (i) => InventoryItem(id: i.id, name: i.name, quantity: i.quantity),
          )
          .toList();
      expect(
        statuses(hero.copyWith(inventory: fakeItems))['class.equipment'],
        CreationStepStatus.notAutomated,
      );
      final overlaps = hero.copyWith(
        startingBackgroundPackage: SrdBackgroundPackageChoice(
          background: SrdBackground.soldier,
          takeGold: true,
          gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
        ),
      );
      expect(statuses(overlaps)['class.skills'], CreationStepStatus.invalid);
      expect(hero.inventory, isNotEmpty);
      expect(hero.gold, 15);
    },
  );
}
