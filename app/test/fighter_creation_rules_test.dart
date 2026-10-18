import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/character_creation_progression.dart';
import 'package:lebendiger_spielleiter/domain/fighter_creation_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  test('SRD 5.2.1 XP thresholds and proficiency bonus cover 1–20', () {
    const xp = <int>[
      0, 300, 900, 2700, 6500, 14000, 23000, 34000, 48000, 64000,
      85000, 100000, 120000, 140000, 165000, 195000, 225000,
      265000, 305000, 355000,
    ];
    for (var level = 1; level <= 20; level++) {
      expect(CharacterCreationProgression.startingExperience(level), xp[level - 1]);
      expect(CharacterCreationProgression.proficiencyBonus(level),
          2 + (level - 1) ~/ 4);
    }
    expect(() => CharacterCreationProgression.startingExperience(0), throwsRangeError);
    expect(() => CharacterCreationProgression.startingExperience(21), throwsRangeError);
  });

  test('new fighter records exactly one SRD style and three weapon kinds', () {
    expect(FighterCreationRules.hitDie, 10);
    expect(FighterCreationRules.secondWindUses, 2);
    expect(FighterCreationRules.fightingStyles, hasLength(4));
    final weapons = FighterCreationRules.masteryWeapons;
    expect(weapons.length, greaterThanOrEqualTo(3));
    final selected = FighterStartingChoices(
      styleId: 'defense',
      masteryWeaponIds: weapons.take(3).map((e) => e.id),
    );
    expect(selected.featureLabels, hasLength(5));
    expect(selected.featureLabels, contains('Kampfstil: Verteidigung'));
    expect(selected.featureLabels, contains('Zweite Luft (2 Anwendungen)'));
    final hero = HeroCharacter(
      id: 'test-fighter', name: 'Beispielkämpfer', className: 'Kämpfer',
      experience: CharacterCreationProgression.startingExperience(1),
      hitPoints: 12, maxHitPoints: 12,
      abilities: const {'constitution': 14},
      savingThrowProficiencies: const ['strength', 'constitution'],
      features: selected.featureLabels,
    );
    final restored = HeroCharacter.fromJson(hero.toJson());
    expect(restored.experience, 0);
    expect(restored.hitPoints, 12);
    expect(restored.features, selected.featureLabels);
    expect(restored.savingThrowProficiencies, ['strength', 'constitution']);
  });

  test('SRD fighting style and weapon choice validation rejects bad inputs', () {
    final three = FighterCreationRules.masteryWeapons.take(3).map((e) => e.id).toList();
    expect(() => FighterStartingChoices(styleId: 'dueling', masteryWeaponIds: three),
        throwsFormatException); // Not in freely licensed SRD 5.2.1.
    expect(() => FighterStartingChoices(styleId: 'archery',
        masteryWeaponIds: [three[0], three[0], three[1]]),
        throwsFormatException);
    expect(() => FighterStartingChoices(styleId: 'archery',
        masteryWeaponIds: ['not-in-srd', three[1], three[2]]),
        throwsFormatException);
    expect(() => FighterStartingChoices(styleId: 'archery',
        masteryWeaponIds: three.take(2)), throwsFormatException);
  });
}
