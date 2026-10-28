import 'package:flutter/material.dart';

import '../services/player_action_outbox.dart';
import 'fantasy_buttons.dart';

/// The UI-only state of a durable player action.
///
/// There are no database reads, timers or narrator calls in this widget, so
/// retry/discard feedback can be tested without a FakeAsync/SQLite deadlock.
class PendingActionStatus extends StatelessWidget {
  const PendingActionStatus({
    super.key,
    required this.pending,
    required this.submitting,
    required this.interactionBlocked,
    required this.error,
    required this.onRetry,
    required this.onDiscard,
  });

  final PendingPlayerAction? pending;
  final bool submitting;
  final bool interactionBlocked;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (submitting)
          const SizedBox.shrink(key: ValueKey('adventure-action-submitting')),
        if (pending != null && !submitting) ...[
          const Text(
            'Ausstehende Handlung – noch nicht sicher bestätigt',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            pending!.text,
            key: const ValueKey('adventure-pending-action-text'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (pending!.selectedNpcId != null) ...[
            const SizedBox(height: 4),
            const Text(
              'Die ausgewählte Figur ist an diesen Auftrag gebunden. '
              'Bei Änderungen am Spielstand bitte verwerfen und neu auswählen.',
              key: ValueKey('adventure-pending-npc-selection'),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FantasyTextButton(
                key: const ValueKey('adventure-retry-action'),
                label: 'Erneut bestätigen',
                icon: Icons.refresh,
                style: FantasyButtonStyle.woodGold,
                onPressed: interactionBlocked || submitting ? null : onRetry,
              ),
              FantasyTextButton(
                key: const ValueKey('adventure-discard-action'),
                label: 'Verwerfen',
                icon: Icons.close,
                style: FantasyButtonStyle.iron,
                onPressed: interactionBlocked || submitting ? null : onDiscard,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (error != null)
          Text(
            error!,
            key: const ValueKey('adventure-outbox-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
