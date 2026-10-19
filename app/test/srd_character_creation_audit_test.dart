import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';

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
  skills: findSrdClass(name)!.skillChoices.take(
    findSrdClass(name)!.skillCount,
  ).toList(),
  savingThrowProficiencies: findSrdClass(name)!.savingThrows,
);

void main() {
  test('Kern-Checkliste für alle zwölf SRD-Klassen und offen gebliebene Merkmale', () {
    for (final klass in srdCharacterClasses) {
      final steps = SrdCharacterCreationAudit.inspect(hero(klass.name));
      expect(steps.length, 11);
      expect(
        steps.where((s) => s.status == CreationStepStatus.missing),
        isEmpty,
        reason: klass.name,
      );
      expect(
        steps.where((s) => s.status == CreationStepStatus.notAutomated)
            .map((s) => s.id),
        containsAll(['origin.feat', 'class.choices']),
        reason: klass.name,
      );
    }
  });

  test('Fehlende Attribute, Übungen, TP und Ausrüstung werden angezeigt', () {
    final missing = HeroCharacter(
      id: 'missing',
      name: 'Tira',
      className: 'Waldläufer',
      species: '',
      background: '',
      abilities: const {'dexterity': 14},
    );
    final incomplete = SrdCharacterCreationAudit.inspect(missing);
    expect(
      incomplete.where((s) => s.status == CreationStepStatus.missing)
          .map((s) => s.id),
      containsAll([
        'origin.species',
        'origin.background',
        'abilities.scores',
        'class.skills',
        'class.saving-throws',
        'class.hit-points',
        'combat.armor-speed',
        'class.equipment',
      ]),
    );
  });

  test('Unbekannte Hintergrundwerte werden nicht SRD-konform behauptet', () {
    final old = hero('Kämpfer').copyWith(background: 'Freie Hausregel');
    final audit = SrdCharacterCreationAudit.inspect(old);
    expect(
      audit.singleWhere((s) => s.id == 'origin.background').status,
      CreationStepStatus.notAutomated,
    );
  });
}
