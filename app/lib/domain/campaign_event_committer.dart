import 'models.dart';

/// Shared append-only event boundary. Both the rules facade and the story
/// engine use the SAME revision, checkpoint and validation guarantees.
class CampaignEventCommitter {
  CampaignEventCommitter({
    required this.newId,
    required this.clock,
  });

  final String Function(String prefix) newId;
  final DateTime Function() clock;

  GameUpdate commit(
    Campaign before,
    Campaign next,
    String narration, {
    String type = 'narrative.turn',
    Map<String, dynamic> payload = const {},
  }) {
    final confirmed = next.copyWith(
      revision: before.revision + 1,
      messages: [
        ...next.messages,
        NarrativeMessage(
          id: newId('message'),
          role: 'gm',
          text: narration,
          timestamp: clock(),
        ),
      ],
    );
    final state = confirmed.copyWith(events: const []).toJson();
    final event = GameEvent(
      id: newId('event'),
      campaignId: before.id,
      sessionId: before.sessionId,
      timestamp: clock(),
      type: type,
      entities: [before.hero.id],
      payload: {
        ...payload,
        'revision': confirmed.revision,
        'stateAfter': state,
      },
    );
    final result = confirmed.copyWith(events: [...before.events, event]);
    Campaign.fromJson(result.toJson());
    return GameUpdate(campaign: result, events: [event]);
  }
}
