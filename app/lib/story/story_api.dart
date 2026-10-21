/// Public story-only entrypoint. Worldbuilding implementations and AI
/// validations live behind CampaignStoryEngine, not inside the rule kernel.
///
/// Existing Rabenwacht files remain at their legacy path until the separate
/// narrative branch merges; campaign writers can use this stable facade.
export 'story_campaign_engine.dart';
export '../domain/ai_story.dart' show AiStoryPlan, AiStoryStep;
// RabenwachtCampaign remains at its legacy path until the campaign
// module is moved behind the validated story boundary.
