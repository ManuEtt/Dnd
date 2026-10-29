import 'package:flutter/material.dart';

import '../services/player_action_outbox.dart';
import 'fantasy_buttons.dart';

/// The UI-only state of a durable player action.
///
/// There are no database reads, timers or narrator calls in this widget, so
/// retry/discard feedback can be tested without a FakeAsync/SQLite deadlock.
class PendingActionStatus extends StatefulWidget {
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
  State<PendingActionStatus> createState() => _PendingActionStatusState();
}

class _PendingActionStatusState extends State<PendingActionStatus> {
  bool _showFullText = false;
  final ScrollController _textScrollController = ScrollController(
    keepScrollOffset: false,
  );

  @override
  void dispose() {
    _textScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PendingActionStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.pending;
    final after = widget.pending;
    // An expanded, recovered intent must never carry over to another request.
    if (before?.campaignId != after?.campaignId ||
        before?.requestId != after?.requestId ||
        before?.text != after?.text ||
        before?.selectedNpcId != after?.selectedNpcId ||
        before?.selectedNpcRevision != after?.selectedNpcRevision) {
      _showFullText = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.pending;
    final submitting = widget.submitting;
    final interactionBlocked = widget.interactionBlocked;
    final error = widget.error;
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Compare with the actual available width rather than guessing
              // from string length or screen size. Short, complete previews
              // should not add a row to the fixed adventure composer.
              final preview = TextPainter(
                text: TextSpan(
                  text: pending.text,
                  style: DefaultTextStyle.of(context).style,
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 2,
              )..layout(maxWidth: constraints.maxWidth);
              final needsExpansion = preview.didExceedMaxLines;
              preview.dispose();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showFullText)
                    ConstrainedBox(
                      // The composer is fixed below the scene: long saved intents
                      // must scroll here rather than pushing the action bar away.
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: Scrollbar(
                        controller: _textScrollController,
                        child: SingleChildScrollView(
                          controller: _textScrollController,
                          primary: false,
                          key: const ValueKey('adventure-pending-action-scroll'),
                          child: Text(
                            pending.text,
                            key: const ValueKey('adventure-pending-action-text'),
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      pending.text,
                      key: const ValueKey('adventure-pending-action-text'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (pending.selectedNpcId != null) ...[
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
                      if (needsExpansion || _showFullText)
                        TextButton(
                          key: const ValueKey('adventure-pending-action-toggle'),
                          onPressed: () => setState(
                            () => _showFullText = !_showFullText,
                          ),
                          child: Text(
                            _showFullText
                                ? 'Weniger anzeigen'
                                : 'Ganzen Text anzeigen',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      FantasyTextButton(
                        key: const ValueKey('adventure-retry-action'),
                        label: 'Erneut bestätigen',
                        icon: Icons.refresh,
                        style: FantasyButtonStyle.woodGold,
                        onPressed: interactionBlocked || submitting
                            ? null
                            : widget.onRetry,
                      ),
                      FantasyTextButton(
                        key: const ValueKey('adventure-discard-action'),
                        label: 'Verwerfen',
                        icon: Icons.close,
                        style: FantasyButtonStyle.iron,
                        onPressed: interactionBlocked || submitting
                            ? null
                            : widget.onDiscard,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        if (error != null)
          Text(
            error,
            key: const ValueKey('adventure-outbox-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
