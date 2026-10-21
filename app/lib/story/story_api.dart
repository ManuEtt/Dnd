// Public story-only entrypoint for independently developed campaigns.
//
// Narrative state transitions are owned by StoryCampaignEngine; D&D rules
// are not exported. RabenwachtCampaign stays at its legacy domain path until
// the validated story boundary can fully absorb that implementation.
export 'story_campaign_engine.dart';
export '../domain/ai_story.dart' show AiStoryPlan, AiStoryStep;
