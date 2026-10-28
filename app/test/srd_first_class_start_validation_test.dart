import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_first_class_start_validation.dart';

void main() {
  group('SRD 5.2.1: verpflichtende Startwerte für zwölf Klassen', () {
    for (final definition in srdCharacterClasses) {
      test('${definition.name}: requires confirmed equipment and KO', () {
        final skills = definition.skillChoices.take(definition.skillCount);
        final empty = SrdClassSelection(
          characterClass: definition,
          skills: skills,
        );
        expect(
          () => SrdFirstClassStartValidation.validate(
            selection: empty,
            isNewCharacter: true,
            characterLevel: 1,
            constitutionScore: 14,
            allowEquipment: true,
          ),
          throwsFormatException,
        );
        final selected = SrdClassSelection(
          characterClass: definition,
          skills: skills,
          kitIndex: definition.kits.length - 1,
        );
        final hp = SrdFirstClassStartValidation.validate(
          selection: selected,
          isNewCharacter: true,
          characterLevel: 1,
          constitutionScore: 14,
          allowEquipment: true,
        );
        expect(hp?.maximum, definition.hitDie + 2);
        expect(hp?.hitDie, definition.hitDie);
      });
    }

    test('invalid KO and level are rejected, not guessed', () {
      final selected = SrdClassSelection(
        characterClass: findSrdClass('Barde')!,
        skills: const ['Auftreten', 'Religion', 'Geschichte'],
        kitIndex: 1,
      );
      for (final score in <int?>[null, 0, 31]) {
        expect(
          () => SrdFirstClassStartValidation.validate(
            selection: selected,
            isNewCharacter: true,
            characterLevel: 1,
            constitutionScore: score,
            allowEquipment: true,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => SrdFirstClassStartValidation.validate(
          selection: selected,
          isNewCharacter: true,
          characterLevel: 2,
          constitutionScore: 14,
          allowEquipment: true,
        ),
        throwsFormatException,
      );
    });

    test('existing character edit does not replace historical hit points', () {
      final selected = SrdClassSelection(
        characterClass: findSrdClass('Kleriker')!,
        skills: const ['Religion', 'Heilkunde'],
      );
      expect(
        SrdFirstClassStartValidation.validate(
          selection: selected,
          isNewCharacter: false,
          characterLevel: 5,
          constitutionScore: null,
          allowEquipment: false,
        ),
        isNull,
      );
    });

    test('previously managed equipment cannot be granted again', () {
      final definition = findSrdClass('Magier')!;
      final skills = definition.skillChoices.take(definition.skillCount);
      final selected = SrdClassSelection(
        characterClass: definition,
        skills: skills,
        kitIndex: 1,
      );
      expect(
        () => SrdFirstClassStartValidation.validate(
          selection: selected,
          isNewCharacter: true,
          characterLevel: 1,
          constitutionScore: 10,
          allowEquipment: false,
        ),
        throwsFormatException,
      );
      expect(
        SrdFirstClassStartValidation.validate(
          selection: SrdClassSelection(
            characterClass: definition,
            skills: skills,
          ),
          isNewCharacter: true,
          characterLevel: 1,
          constitutionScore: 10,
          allowEquipment: false,
        )?.maximum,
        definition.hitDie,
      );
    });
  });
}
