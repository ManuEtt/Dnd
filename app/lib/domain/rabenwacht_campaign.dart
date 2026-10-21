import 'campaign_experience.dart';
import 'character_rule_engine.dart';
import 'models.dart';
import '../story/rabenwacht_campaign.dart';
import '../story/story_rule_port.dart';

export '../story/rabenwacht_campaign.dart' show RabenwachtTurn;

/// Backwards-compatible bridge. The full authored campaign now resides in
/// story/, which requests checks and rewards through a typed rule port.
/// Legacy callers keep their static API without owning campaign prose.
class RabenwachtCampaign {
  const RabenwachtCampaign._();

  static const title = RabenwachtStoryModule.title;
  static const mode = RabenwachtStoryModule.mode;

  static const _story = RabenwachtStoryModule(_RabenwachtRulesAdapter());

  static Campaign create({
    required HeroCharacter hero,
    required String campaignId,
    required String sessionId,
    required String messageId,
    required DateTime now,
  }) => _story.create(
    hero: hero,
    campaignId: campaignId,
    sessionId: sessionId,
    messageId: messageId,
    now: now,
  );

  static String discoveredClues(Campaign campaign) =>
      _story.discoveredClues(campaign);

  static RabenwachtTurn advance(
    Campaign campaign,
    String input, {
    required String rollId,
  }) => _story.advance(campaign, input, rollId: rollId);

  static RabenwachtTurn resolveCheck(
    Campaign campaign,
    PendingRoll pending,
    bool passed,
  ) => _story.resolveCheck(campaign, pending, passed);
}

/// The sole Rabenwacht-specific implementation of the story-rule contract.
/// This file contains no authored dialogue, branching or campaign prose.
class _RabenwachtRulesAdapter implements StoryRulePort {
  const _RabenwachtRulesAdapter();

  @override
  StoryAbilityCheck abilityCheck(
    HeroCharacter hero,
    String ability, {
    required String skill,
    required bool proficient,
    required bool stealth,
  }) {
    final result = CharacterRuleEngine.abilityCheck(
      hero,
      ability,
      skill: skill,
      proficient: proficient,
      stealth: stealth,
    );
    return StoryAbilityCheck(
      modifier: result.modifier,
      minimumNatural: result.minimumNatural,
      advantage: result.advantage,
      disadvantage: result.disadvantage,
    );
  }

  @override
  StoryMilestoneAward awardMilestone(Campaign campaign, String milestone) {
    final award = CampaignExperience.awardOnce(campaign, milestone);
    return StoryMilestoneAward(award.campaign, award.points, award.narration);
  }
}
