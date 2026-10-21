import '../domain/models.dart';

/// Stable handshake: story authors request adjudication; only the rules
/// adapter may calculate modifiers, class features or XP.
class StoryAbilityCheck {
  const StoryAbilityCheck({
    required this.modifier,
    required this.minimumNatural,
    required this.advantage,
    required this.disadvantage,
  });

  final int modifier;
  final int? minimumNatural;
  final bool advantage, disadvantage;
}

class StoryMilestoneAward {
  const StoryMilestoneAward(this.campaign, this.amount, this.narration);

  final Campaign campaign;
  final int amount;
  final String narration;
}

/// Implemented by the rules layer, never by authored adventures.
/// Provider/AI text is never permitted to supply rule results directly.
abstract class StoryRulePort {
  StoryAbilityCheck abilityCheck(
    HeroCharacter hero,
    String ability, {
    required String skill,
    required bool proficient,
    required bool stealth,
  });

  StoryMilestoneAward awardMilestone(Campaign campaign, String milestone);
}
