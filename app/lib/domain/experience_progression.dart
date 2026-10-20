import 'models.dart';

/// Cumulative experience thresholds from the D&D 5e character advancement table.
/// Experience is never spent when gaining a level.
class ExperienceProgression {
  static const thresholds = <int>[
    0, 300, 900, 2700, 6500, 14000, 23000, 34000, 48000, 64000,
    85000, 100000, 120000, 140000, 165000, 195000, 225000,
    265000, 305000, 355000,
  ];

  static int levelForXp(int xp) {
    if (xp < 0) throw const FormatException('XP dürfen nicht negativ sein.');
    for (var i = thresholds.length - 1; i >= 0; i--) {
      if (xp >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  static int? nextThreshold(int level) =>
      level >= 20 ? null : thresholds[level];

  static int proficiencyBonus(int level) => 2 + (level - 1) ~/ 4;

  /// Adds XP once for a stable reward ID. Does not silently select a class,
  /// roll HP, or apply class features: those require a confirmed level-up.
  static Campaign grant(
    Campaign campaign, {
    required String rewardId,
    required int amount,
  }) {
    if (rewardId.isEmpty || rewardId.length > 100 || amount < 0 || amount > 100000) {
      throw const FormatException('Ungültige XP-Vergabe.');
    }
    final key = 'xp.reward.$rewardId';
    if (campaign.facts.containsKey(key)) return campaign;
    final oldXp = campaign.hero.experience ?? 0;
    final xp = oldXp + amount;
    if (xp > 100000000) {
      throw const FormatException('XP-Grenze überschritten.');
    }
    return campaign.copyWith(
      hero: campaign.hero.copyWith(experience: xp),
      facts: {
        ...campaign.facts,
        key: '$amount',
        if (levelForXp(xp) > campaign.hero.level)
          'xp.levelUpAvailable': 'true',
      },
    );
  }

  static int pendingLevels(HeroCharacter hero) {
    final xp = hero.experience ?? 0;
    final target = levelForXp(xp);
    return target > hero.level ? target - hero.level : 0;
  }
}
