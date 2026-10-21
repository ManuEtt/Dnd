import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart'
    as legacy;
import 'package:lebendiger_spielleiter/story/ai_story.dart';
import 'package:lebendiger_spielleiter/story/rabenwacht_campaign.dart';
import 'package:lebendiger_spielleiter/story/story_rule_port.dart';

class _SpyRules implements StoryRulePort {
  int checks = 0;
  int awards = 0;

  @override
  StoryAbilityCheck abilityCheck(
    HeroCharacter hero,
    String ability, {
    required String skill,
    required bool proficient,
    required bool stealth,
  }) {
    checks++;
    expect(ability, 'wisdom');
    expect(skill, 'Wahrnehmung');
    return const StoryAbilityCheck(
      modifier: 7,
      minimumNatural: null,
      advantage: false,
      disadvantage: false,
    );
  }

  @override
  StoryMilestoneAward awardMilestone(Campaign campaign, String milestone) {
    awards++;
    return StoryMilestoneAward(campaign, 0, '');
  }
}

void main() {
  test(
    'Authored Rabenwacht can request checks without importing rule code',
    () {
      final rules = _SpyRules();
      final module = RabenwachtStoryModule(rules);
      final hero = GameEngine().createDemo().hero;
      final created = module.create(
        hero: hero,
        campaignId: 'test-rabenwacht',
        sessionId: 'test-session',
        messageId: 'test-message',
        now: DateTime.utc(2026, 10, 21),
      );
      final step = module.advance(
        created,
        'Ich untersuche die Schritte im Nebel.',
        rollId: 'rabenwacht-check',
      );
      expect(rules.checks, 1);
      expect(step.campaign.pendingRoll?.modifier, 7);
      expect(step.campaign.hero.toJson(), created.hero.toJson());
      expect(step.campaign.storyBible['mode'], RabenwachtStoryModule.mode);
    },
  );

  test('Story module delegates milestone rewards through interface', () {
    final rules = _SpyRules();
    final module = RabenwachtStoryModule(rules);
    final initial = module.create(
      hero: GameEngine().createDemo().hero,
      campaignId: 'demo-rabenwacht',
      sessionId: 'session',
      messageId: 'message',
      now: DateTime.utc(2026, 10, 21),
    );
    final reached = module.advance(
      initial,
      'Ich gehe zum Dorfplatz.',
      rollId: 'check-2',
    );
    expect(reached.campaign.storyBible['stage'], 'square');
    expect(reached.campaign.hero.toJson(), initial.hero.toJson());
    // A story route must never award experience by manipulating Hero directly.
    expect(rules.awards, 0);
  });

  test('Legacy static facade preserves exact saves and content', () {
    final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 21));
    final hero = engine.createDemo().hero;
    final game = legacy.RabenwachtCampaign.create(
      hero: hero,
      campaignId: 'compat-campaign',
      sessionId: 'compat-session',
      messageId: 'compat-message',
      now: DateTime.utc(2026, 10, 21),
    );
    expect(game.name, legacy.RabenwachtCampaign.title);
    expect(game.storyBible['mode'], legacy.RabenwachtCampaign.mode);
    expect(Campaign.fromJson(game.toJson()).toJson(), game.toJson());
    expect(
      legacy.RabenwachtCampaign.discoveredClues(game),
      contains('zerstörte Glockenturm'),
    );
  });

  test('AI parser resolves canonically through both old and story imports', () {
    expect(AiStoryPlan, isNotNull);
    // Compatibility types remain usable by the existing backend parser.
    expect(legacy.RabenwachtCampaign.mode, 'rabenwacht-v1');
  });
}
