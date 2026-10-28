import '../domain/models.dart';
import '../story/npc_story_selection.dart';
import 'player_action_outbox.dart';

/// An explicit, persisted NPC choice must never be inferred again from names.
enum PendingNpcActionState {
  plain,
  ready,
  alreadyConfirmed,
  stale,
  unavailable,
}

class PendingNpcActionResolution {
  const PendingNpcActionResolution(this.state, {this.choice});

  final PendingNpcActionState state;
  final NpcStorySelection? choice;
}

/// Pure recovery policy used by the UI after restart and before any retry.
///
/// There are deliberately no database writes or network calls here. Only the
/// exact durable receipt can acknowledge a lost reply. All stale alternatives
/// require the player to discard the old action and choose again.
PendingNpcActionResolution resolvePendingNpcAction(
  Campaign campaign,
  PendingPlayerAction action,
) {
  if (campaign.id != action.campaignId) {
    return const PendingNpcActionResolution(PendingNpcActionState.stale);
  }
  if (action.selectedNpcId == null) {
    return action.selectedNpcRevision == null
        ? const PendingNpcActionResolution(PendingNpcActionState.plain)
        : const PendingNpcActionResolution(PendingNpcActionState.stale);
  }
  if (campaign.revision != action.selectedNpcRevision) {
    final confirmed = campaign.events.any(
      (event) =>
          event.payload['actionRequestId'] == action.requestId &&
          event.payload['actionRequestText'] == action.text &&
          event.payload['actionSelectedNpcId'] == action.selectedNpcId,
    );
    return PendingNpcActionResolution(
      confirmed
          ? PendingNpcActionState.alreadyConfirmed
          : PendingNpcActionState.stale,
    );
  }
  try {
    return PendingNpcActionResolution(
      PendingNpcActionState.ready,
      choice: NpcStorySelection.choose(campaign, action.selectedNpcId!),
    );
  } on FormatException {
    return const PendingNpcActionResolution(PendingNpcActionState.unavailable);
  }
}
