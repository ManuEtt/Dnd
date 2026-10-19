import 'character_creation_progression.dart';
import 'models.dart';

/// Spielleiter-Belohnungen für erreichte Szenenziele.
///
/// Die EP-Schwellen kommen aus dem SRD 5.2.1. Die Belohnungshöhen sind
/// ein bewusstes Abenteuerdesign, keine angeblichen offiziellen SRD-Werte.
/// Erfolgreiche Heimlichkeit und Kampf führen über dasselbe Etappenziel,
/// damit nicht nur das Töten von Gegnern belohnt wird.
class CampaignExperience {
  const CampaignExperience._();

  static const rewards = <String, int>{
    'well-discovery': 100,
    'reach-mill': 200,
    'reach-chapel': 220,
    'reach-archive': 260,
    'reach-graveyard': 240,
    'reach-ruins': 260,
    'reach-chamber': 340,
    'resolve-rabenwacht': 900,
  };

  static int? nextThreshold(HeroCharacter hero) =>
      hero.level >= 20
          ? null
          : CharacterCreationProgression.startingExperience(hero.level + 1);

  static int? pointsUntilLevel(HeroCharacter hero) {
    final next = nextThreshold(hero);
    final experience = hero.experience;
    if (next == null || experience == null) return null;
    return (next - experience).clamp(0, next);
  }

  static bool canLevelUp(HeroCharacter hero) {
    final next = nextThreshold(hero);
    return next != null && hero.experience != null && hero.experience! >= next;
  }

  static double? levelProgress(HeroCharacter hero) {
    final experience = hero.experience;
    if (experience == null) return null;
    final next = nextThreshold(hero);
    if (next == null) return 1;
    final base = CharacterCreationProgression.startingExperience(hero.level);
    return ((experience - base) / (next - base)).clamp(0.0, 1.0);
  }

  /// A single, validated story milestone is awarded at most once per
  /// campaign, with persistence through Campaign.facts. An unconfirmed
  /// historical experience value is never silently invented.
  static ExperienceAward awardOnce(Campaign campaign, String milestone) {
    final amount = rewards[milestone];
    if (amount == null) {
      throw const FormatException('Unbekannte EP-Belohnung.');
    }
    if (campaign.storyBible['mode'] != 'rabenwacht-v1') {
      throw const FormatException('Falsche Kampagne für diese EP-Belohnung.');
    }
    final marker = 'xpReward:$milestone';
    if (campaign.facts[marker] == 'true') {
      return ExperienceAward(campaign, 0, '');
    }
    final experience = campaign.hero.experience;
    if (experience == null) {
      return ExperienceAward(
        campaign,
        0,
        'Die Erfahrungspunkte deines Helden sind noch nicht bestätigt. '
        'Bitte trage den bisherigen EP-Stand im Charakterbogen ein.',
      );
    }
    if (experience > 1000000 - amount) {
      throw const FormatException('Der bestätigte EP-Stand ist zu hoch.');
    }
    final updated = campaign.copyWith(
      hero: campaign.hero.copyWith(experience: experience + amount),
      facts: {...campaign.facts, marker: 'true'},
    );
    final leveled = canLevelUp(updated.hero) && !canLevelUp(campaign.hero);
    return ExperienceAward(
      updated,
      amount,
      '+$amount EP für deinen Fortschritt. '
      'Du hast jetzt ${updated.hero.experience} EP.'
      '${leveled ? ' Eine neue Charakterstufe ist erreichbar! '
          'Öffne deinen Charakterbogen und nutze den Klassenaufstieg.' : ''}',
    );
  }
}

class ExperienceAward {
  const ExperienceAward(this.campaign, this.points, this.narration);
  final Campaign campaign;
  final int points;
  final String narration;
}
