import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';

HeroCharacter hero(String name) => HeroCharacter(
  id: 'new',
  name: 'Liora',
  species: 'Mensch',
  background: 'Soldat',
  className: name,
  abilities: const {
    'strength': 15,
    'dexterity': 14,
    'constitution': 13,
    'intelligence': 12,
    'wisdom': 10,
    'charisma': 8,
  },
  hitPoints: 10,
  maxHitPoints: 10,
  speed: 9,
  armorClass: 12,
  experience: 0,
  gold: 0,
  skills: findSrdClass(
    name,
  )!.skillChoices.take(findSrdClass(name)!.skillCount).toList(),
  savingThrowProficiencies: findSrdClass(name)!.savingThrows,
);
CreationStep step(HeroCharacter hero, String id) =>
    SrdCharacterCreationAudit.inspect(hero).singleWhere((s) => s.id == id);
StartingAbilityOrigin origin() => StartingAbilityOrigin.confirmed(
  method: 'standardArray',
  baseScores: const {
    'strength': 15,
    'dexterity': 14,
    'constitution': 13,
    'intelligence': 12,
    'wisdom': 10,
    'charisma': 8,
  },
  background: 'Soldat',
  increases: const {'strength': 2, 'constitution': 1},
);

void main() {
  test(
    'Zweitklassen und Stufenaufteilung werden nicht aus Namen bestätigt',
    () {
      final h = hero('Kämpfer').copyWith(level: 5);
      expect(
        step(
          h.copyWith(secondaryClassName: 'Zeitmagier', secondaryClassLevel: 1),
          'class.selection',
        ).status,
        CreationStepStatus.notInSrd,
      );
      expect(
        step(
          h.copyWith(secondaryClassName: 'Magier', secondaryClassLevel: 0),
          'class.selection',
        ).status,
        CreationStepStatus.invalid,
      );
      expect(
        step(
          h.copyWith(secondaryClassName: 'Magier', secondaryClassLevel: 5),
          'class.selection',
        ).status,
        CreationStepStatus.invalid,
      );
      expect(
        step(h.copyWith(secondaryClassLevel: 1), 'class.selection').status,
        CreationStepStatus.invalid,
      );
      expect(
        step(
          h.copyWith(secondaryClassName: 'Magier', secondaryClassLevel: 1),
          'class.selection',
        ).status,
        CreationStepStatus.notAutomated,
      );
    },
  );
  test('Amtlicher englischer Hintergrundname wird lesend zugeordnet', () {
    final o = origin();
    final h = hero('Kämpfer').copyWith(
      background: ' soldier ',
      abilities: o.startingScores,
      startingAbilityOrigin: o,
    );
    expect(step(h, 'abilities.scores').status, CreationStepStatus.confirmed);
    expect(
      step(h, 'origin.background').status,
      isNot(CreationStepStatus.notInSrd),
    );
    expect(h.background, ' soldier ');
  });

  test(
    'Ausgefüllte Felder sind für alle zwölf Klassen kein Erstellungsnachweis',
    () {
      for (final klass in srdCharacterClasses) {
        final h = hero(klass.name);
        final before = jsonEncode(h.toJson());
        final steps = SrdCharacterCreationAudit.inspect(h);
        expect(steps.length, 11);
        for (final id in [
          'origin.species',
          'abilities.scores',
          'class.skills',
          'class.saving-throws',
          'class.hit-points',
          'combat.armor-speed',
          'class.equipment',
        ]) {
          expect(
            step(h, id).status,
            isNot(CreationStepStatus.confirmed),
            reason: '${klass.name} $id',
          );
        }
        expect(
          step(h, 'class.selection').status,
          CreationStepStatus.notAutomated,
        );
        expect(jsonEncode(h.toJson()), before);
      }
    },
  );
  test('Frei erfundene Spezies, Klasse und Hintergründe sind kein SRD', () {
    final h = hero(
      'Kämpfer',
    ).copyWith(species: 'Vampir', className: 'Zeitmagier', background: 'König');
    for (final id in [
      'origin.species',
      'origin.background',
      'class.selection',
    ]) {
      expect(step(h, id).status, CreationStepStatus.notInSrd);
    }
  });
  test('Gold null oder null Gegenstände belegen keine Starterpaketwahl', () {
    final h = hero('Kämpfer');
    expect(
      step(h, 'class.equipment').status,
      isNot(CreationStepStatus.confirmed),
    );
    final item = InventoryItem(id: 'found', name: 'Gefundener Stein');
    expect(
      step(h.copyWith(gold: null, inventory: [item]), 'class.equipment').status,
      isNot(CreationStepStatus.confirmed),
    );
  });
  test(
    'Bestätigte Startattribute werden über den vorhandenen Nachweis geprüft',
    () {
      final o = origin();
      final h = hero(
        'Kämpfer',
      ).copyWith(abilities: o.startingScores, startingAbilityOrigin: o);
      expect(step(h, 'abilities.scores').status, CreationStepStatus.confirmed);
    },
  );
  test(
    'Abweichender Stufe-1-Entwurf wird nicht durch alten Nachweis legitimiert',
    () {
      final o = origin();
      final h = hero('Kämpfer').copyWith(
        abilities: {...o.startingScores, 'strength': 20},
        startingAbilityOrigin: o,
      );
      expect(step(h, 'abilities.scores').status, CreationStepStatus.invalid);
    },
  );
  test('Spätere Werte dürfen vom historischen Ursprung abweichen', () {
    final o = origin();
    final h = hero('Kämpfer').copyWith(
      level: 5,
      abilities: {...o.startingScores, 'strength': 20},
      startingAbilityOrigin: o,
    );
    expect(step(h, 'abilities.scores').status, CreationStepStatus.notAutomated);
    expect(
      step(h, 'origin.background').status,
      isNot(CreationStepStatus.invalid),
    );
  });
  test(
    'Fehlende Werte bleiben fehlend; freier Methodenname wird nicht geraten',
    () {
      final h = hero('Kämpfer').copyWith(
        abilities: const {'strength': 15},
        inventory: [],
        gold: null,
        hitPoints: null,
        maxHitPoints: null,
        speed: null,
        armorClass: null,
      );
      for (final id in [
        'abilities.scores',
        'class.hit-points',
        'combat.armor-speed',
        'class.equipment',
      ]) {
        expect(step(h, id).status, CreationStepStatus.missing, reason: id);
      }
    },
  );
  test('Doppelte Übungen einschließlich Medizin-Alias sind ungültig', () {
    final h = hero('Barde');
    expect(
      step(
        h.copyWith(skills: ['Heilkunde', 'Medizin', 'Geschichte']),
        'class.skills',
      ).status,
      CreationStepStatus.invalid,
    );
    expect(
      step(
        h.copyWith(
          savingThrowProficiencies: ['dexterity', 'dexterity', 'charisma'],
        ),
        'class.saving-throws',
      ).status,
      CreationStepStatus.invalid,
    );
  });
  test('Unbekannte Klasse blockiert davon abhängige Entscheidungen', () {
    final h = hero('Kämpfer').copyWith(className: '');
    expect(step(h, 'class.selection').status, CreationStepStatus.missing);
    expect(step(h, 'class.skills').status, CreationStepStatus.dependent);
    expect(step(h, 'class.hit-points').status, CreationStepStatus.dependent);
  });
  test(
    'Ungültige Zahlen und Zweitklasse auf Startstufe sind keine Bestätigung',
    () {
      final h = hero('Kämpfer');
      expect(
        step(
          h.copyWith(abilities: {...h.abilities, 'strength': 31}),
          'abilities.scores',
        ).status,
        CreationStepStatus.invalid,
      );
      expect(
        step(
          h.copyWith(hitPoints: 20, maxHitPoints: 10),
          'class.hit-points',
        ).status,
        CreationStepStatus.invalid,
      );
      expect(
        step(
          h.copyWith(secondaryClassName: 'Magier', secondaryClassLevel: 1),
          'class.selection',
        ).status,
        CreationStepStatus.invalid,
      );
    },
  );
}
