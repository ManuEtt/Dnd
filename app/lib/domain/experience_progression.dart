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
    if (campaign.facts.containsKey(key)) {
      // A repeated receipt is idempotent only if it agrees with the
      // confirmed amount. Mismatched/corrupt history must fail closed
      // rather than silently acknowledging a different reward.
      if (campaign.facts[key] != '$amount') {
        throw const FormatException(
          'Belohnungs-ID wurde mit anderer XP-Menge bereits bestätigt.',
        );
      }
      return campaign;
    }

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

  /// Required EP for the next single confirmed character level.
  /// Null means the historical EP value is unknown, not zero.
  static int? pointsUntilNextLevel(HeroCharacter hero) {
    final next = nextThreshold(hero.level);
    final xp = hero.experience;
    if (xp == null) return null;
    if (next == null) return 0;
    return (next - xp).clamp(0, next).toInt();
  }

  /// Progress within the *current* level, never across unconfirmed levels.
  /// A hero ready for multiple levels stays at 100% until each is confirmed.
  static double? progressToNextLevel(HeroCharacter hero) {
    final next = nextThreshold(hero.level);
    final xp = hero.experience;
    if (xp == null) return null;
    if (next == null) return 1.0;
    final start = CharacterCreationProgression.startingExperience(hero.level);
    return ((xp - start) / (next - start)).clamp(0.0, 1.0).toDouble();
  }

  /// XP can qualify for several levels, but does not apply any of them.
  /// The player must confirm every intermediate class advancement.
  static int reachableLevel(HeroCharacter hero) {
    if (hero.level < 1 || hero.level > 20) {
      throw RangeError.range(hero.level, 1, 20, 'level');
    }
    final xp = hero.experience;
    if (xp == null) return hero.level;
    final earned = levelForXp(xp);
    return earned > hero.level ? earned : hero.level;
  }

  static int pendingLevels(HeroCharacter hero) {
    return reachableLevel(hero) - hero.level;
  }
}
