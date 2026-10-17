import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/starting_hit_points.dart';

void main() {
  group('SRD 5.2.1 class starting options', () {
    test(
      'covers all twelve classes, saving throws, skill options and hit dice',
      () {
        expect(srdCharacterClasses, hasLength(12));
        const expected = <String, (int, int, List<String>)>{
          'Barbar': (12, 2, ['strength', 'constitution']),
          'Barde': (8, 3, ['dexterity', 'charisma']),
          'Kleriker': (8, 2, ['wisdom', 'charisma']),
          'Druide': (8, 2, ['intelligence', 'wisdom']),
          'Kämpfer': (10, 2, ['strength', 'constitution']),
          'Mönch': (8, 2, ['strength', 'dexterity']),
          'Paladin': (10, 2, ['wisdom', 'charisma']),
          'Waldläufer': (10, 3, ['strength', 'dexterity']),
          'Schurke': (8, 4, ['dexterity', 'intelligence']),
          'Zauberer': (6, 2, ['constitution', 'charisma']),
          'Hexenmeister': (8, 2, ['wisdom', 'charisma']),
          'Magier': (6, 2, ['intelligence', 'wisdom']),
        };
        for (final characterClass in srdCharacterClasses) {
          final traits = expected[characterClass.name];
          expect(traits, isNotNull);
          expect(characterClass.hitDie, traits!.$1);
          expect(
            StartingHitPoints.propose(
              className: characterClass.name,
              constitutionScore: 10,
              characterLevel: 1,
            ).hitDie,
            characterClass.hitDie,
          );
          expect(characterClass.skillCount, traits.$2);
          expect(characterClass.savingThrows, traits.$3);
          expect(
            characterClass.skillChoices.length,
            greaterThanOrEqualTo(characterClass.skillCount),
          );
          expect(
            characterClass.skillChoices.toSet(),
            hasLength(characterClass.skillChoices.length),
          );
          expect(characterClass.savingThrows.toSet(), hasLength(2));
          expect(
            characterClass.savingThrows.every(abilityNames.contains),
            isTrue,
          );
          for (final skill in characterClass.skillChoices) {
            expect(srdSkills, contains(skill));
          }
          characterClass.validateSkills(
            characterClass.skillChoices.take(characterClass.skillCount),
          );
          expect(characterClass.kits.length, greaterThanOrEqualTo(2));
          for (final kit in characterClass.kits) {
            expect(kit.gold, greaterThanOrEqualTo(0));
            expect(
              kit.items.every(
                (item) => item.quantity > 0 && item.name.isNotEmpty,
              ),
              isTrue,
            );
          }
        }
      },
    );

    test('bard can choose any three and rogue must choose four', () {
      final bard = findSrdClass('Barde')!;
      final rogue = findSrdClass('Schurke')!;
      expect(bard.skillChoices, srdSkills);
      expect(bard.skillCount, 3);
      expect(rogue.skillCount, 4);
      expect(
        () => SrdClassSelection(
          characterClass: bard,
          skills: const ['Auftreten', 'Religion'],
        ),
        throwsFormatException,
      );
      expect(
        () => SrdClassSelection(
          characterClass: rogue,
          skills: const ['Athletik', 'Athletik', 'Heimlichkeit', 'Wahrnehmung'],
        ),
        throwsFormatException,
      );
    });

    test('rejects off-list skills and invalid kit indexes', () {
      final fighter = findSrdClass('Kämpfer')!;
      expect(
        () => SrdClassSelection(
          characterClass: fighter,
          skills: const ['Arkane Kunde', 'Athletik'],
        ),
        throwsFormatException,
      );
      expect(
        () => SrdClassSelection(
          characterClass: fighter,
          skills: const ['Athletik', 'Wahrnehmung'],
          kitIndex: 3,
        ),
        throwsFormatException,
      );
      expect(
        () => SrdClassSelection(
          characterClass: fighter,
          skills: const ['Athletik', 'Wahrnehmung'],
          kitIndex: -1,
        ),
        throwsFormatException,
      );
      final chosen = SrdClassSelection(
        characterClass: fighter,
        skills: const ['Athletik', 'Wahrnehmung'],
        kitIndex: 2,
      );
      expect(chosen.startingKit?.gold, 155);
      expect(chosen.startingKit?.items, isEmpty);
    });

    test(
      'existing German and English class names resolve without rewriting them',
      () {
        const aliases = <String, String>{
          'BARBARIAN': 'Barbar',
          'bard': 'Barde',
          'cleric': 'Kleriker',
          'druid': 'Druide',
          'fighter': 'Kämpfer',
          '  KäMpFeRiN ': 'Kämpfer',
          'monk': 'Mönch',
          'paladin': 'Paladin',
          'ranger': 'Waldläufer',
          'rogue': 'Schurke',
          'sorcerer': 'Zauberer',
          'warlock': 'Hexenmeister',
          'wizard': 'Magier',
        };
        for (final item in aliases.entries) {
          expect(findSrdClass(item.key)?.name, item.value);
        }
        expect(findSrdClass('Mystische Eigenbauklasse'), isNull);
      },
    );

    test(
      'cancel is inert; proposal merges without deleting historical skills',
      () {
        final original = HeroCharacter(
          id: 'arescan',
          name: 'Arescan',
          className: 'Waldläufer',
          skills: const ['Geschichte'],
          savingThrowProficiencies: const ['wisdom'],
          unverifiedNotes: const ['Historischer Wert noch nicht bestätigt'],
          hitPoints: 7,
          maxHitPoints: 15,
        );
        final choice = SrdClassSelection(
          characterClass: findSrdClass('Kämpfer')!,
          skills: const ['Athletik', 'Wahrnehmung'],
        );
        expect(original.className, 'Waldläufer');
        final updated = choice.applyTo(original);
        expect(updated.className, 'Kämpfer');
        expect(updated.skills, ['Geschichte', 'Athletik', 'Wahrnehmung']);
        expect(updated.savingThrowProficiencies, [
          'wisdom',
          'strength',
          'constitution',
        ]);
        expect(updated.hitPoints, 7);
        expect(updated.maxHitPoints, 15);
        expect(updated.unverifiedNotes, original.unverifiedNotes);
        final replaced = choice.applyTo(original, replaceSkills: true);
        expect(replaced.skills, ['Athletik', 'Wahrnehmung']);
        expect(replaced.savingThrowProficiencies, ['strength', 'constitution']);
        expect(HeroCharacter.fromJson(updated.toJson()).skills, updated.skills);
      },
    );
  });
}
