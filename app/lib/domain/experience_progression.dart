import 'character_creation_progression.dart';
import 'models.dart';

/// General SRD experience progression independent of a particular campaign.
///
/// Level-up remains an explicit character action; awarding XP never grants
/// class features, hit points or subclass choices automatically.
class ExperienceProgression {
  const ExperienceProgression._();

  static const thresholds = CharacterCreationProgression.experienceThresholds;

  static int levelForXp(int xp) {
    if (xp < 0) {
      throw const FormatException('XP dürfen nicht negativ sein.');
    }
    for (var i = thresholds.length - 1; i >= 0; i--) {
      if (xp >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  static int? nextThreshold(int level) {
    if (level < 1 || level > 20) {
      throw RangeError.range(level, 1, 20, 'level');
    }
    return level == 20 ? null : thresholds[level];
  }

  static int proficiencyBonus(int level) =>
      CharacterCreationProgression.proficiencyBonus(level);

  /// Grants an identified reward at most once, preserving unconfirmed XP.
  ///
  /// This generic reward API is distinct from the story-locked Rabenwacht
  /// rewards in CampaignExperience. Both require confirmed prior XP.
  static Campaign grant(
    Campaign campaign, {
    required String rewardId,
    required int amount,
  }) {
    if (rewardId.trim().isEmpty ||
        rewardId.length > 100 ||
        amount < 0 ||
        amount > 100000) {
      throw const FormatException('Ungültige XP-Vergabe.');
    }
    final key = 'xp.reward.$rewardId';
    if (campaign.facts.containsKey(key)) return campaign;

    final oldXp = campaign.hero.experience;
    if (oldXp == null) {
      throw const FormatException(
        'Unbestätigte historische XP dürfen nicht ersetzt werden.',
      );
    }
    if (oldXp > 1000000 - amount) {
      throw const FormatException('XP-Grenze überschritten.');
    }
    final xp = oldXp + amount;
    return campaign.copyWith(
      hero: campaign.hero.copyWith(experience: xp),
      facts: {
        ...campaign.facts,
        key: '$amount',
        if (levelForXp(xp) > campaign.hero.level) 'xp.levelUpAvailable': 'true',
      },
    );
  }

  static int pendingLevels(HeroCharacter hero) {
    final xp = hero.experience;
    if (xp == null) return 0;
    final target = levelForXp(xp);
    return target > hero.level ? target - hero.level : 0;
  }
}
