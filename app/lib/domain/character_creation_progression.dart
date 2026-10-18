/// D&D SRD 5.2.1: Character Advancement, total (not class) level.
/// Source: https://www.dndbeyond.com/srd
class CharacterCreationProgression {
  const CharacterCreationProgression._();

  static const experienceThresholds = <int>[
    0, 300, 900, 2700, 6500, 14000, 23000, 34000, 48000, 64000,
    85000, 100000, 120000, 140000, 165000, 195000, 225000, 265000,
    305000, 355000,
  ];

  static int startingExperience(int level) {
    if (level < 1 || level > 20) {
      throw RangeError.range(level, 1, 20, 'level');
    }
    return experienceThresholds[level - 1];
  }

  static int proficiencyBonus(int level) {
    startingExperience(level); // Validate total level.
    return 2 + (level - 1) ~/ 4;
  }
}
