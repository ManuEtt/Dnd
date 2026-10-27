import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/pending_action_status.dart';

const _npcAction = PendingPlayerAction(
  campaignId: 'camp',
  requestId: 'request-one',
  text: 'Ich frage die zweite Mira nach dem Tor.',
  selectedNpcId: 'mira-two',
  selectedNpcRevision: 5,
);
const _plainAction = PendingPlayerAction(
  campaignId: 'camp',
  requestId: 'request-two',
  text: 'Ich erkunde die Stadt.',
);

Widget _screen({
  PendingPlayerAction? pending,
  bool submitting = false,
  bool interactionBlocked = false,
  String? error,
  VoidCallback? onRetry,
  VoidCallback? onDiscard,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SingleChildScrollView(
        child: PendingActionStatus(
          pending: pending,
          submitting: submitting,
          interactionBlocked: interactionBlocked,
          error: error,
          onRetry: onRetry ?? () {},
          onDiscard: onDiscard ?? () {},
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('NPC pending action explains its binding and requires choice', (
    tester,
  ) async {
    var retries = 0;
    var discards = 0;
    await tester.pumpWidget(
      _screen(
        pending: _npcAction,
        onRetry: () => retries++,
        onDiscard: () => discards++,
      ),
    );
    expect(
      find.byKey(const ValueKey('adventure-pending-action-text')),
      findsOneWidget,
    );
    expect(find.text(_npcAction.text), findsOneWidget);
    expect(
      find.byKey(const ValueKey('adventure-pending-npc-selection')),
      findsOneWidget,
    );
    expect(
      find.textContaining('noch nicht sicher bestätigt'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('adventure-retry-action')));
    expect(retries, 1);
    expect(discards, 0);
    await tester.tap(find.byKey(const ValueKey('adventure-discard-action')));
    expect(discards, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a stale NPC selection shows the error and both safe choices', (
    tester,
  ) async {
    const message =
        'NPC-Auswahl ist nicht mehr aktuell. Bitte die ausstehende '
        'Handlung verwerfen und erneut auswählen.';
    await tester.pumpWidget(_screen(pending: _npcAction, error: message));
    expect(find.byKey(const ValueKey('adventure-outbox-error')), findsOneWidget);
    expect(find.textContaining('NPC-Auswahl ist nicht mehr aktuell'), findsOneWidget);
    expect(find.byKey(const ValueKey('adventure-retry-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('adventure-discard-action')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('while a pending NPC action is sending controls are hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(pending: _npcAction, submitting: true),
    );
    expect(find.byKey(const ValueKey('adventure-action-submitting')), findsOneWidget);
    expect(find.byKey(const ValueKey('adventure-retry-action')), findsNothing);
    expect(find.byKey(const ValueKey('adventure-discard-action')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rules block retry and discard without destroying intent', (
    tester,
  ) async {
    await tester.pumpWidget(
      _screen(pending: _npcAction, interactionBlocked: true),
    );
    final retry = tester.widget<FantasyTextButton>(
      find.byKey(const ValueKey('adventure-retry-action')),
    );
    final discard = tester.widget<FantasyTextButton>(
      find.byKey(const ValueKey('adventure-discard-action')),
    );
    expect(retry.onPressed, isNull);
    expect(discard.onPressed, isNull);
    expect(find.text(_npcAction.text), findsOneWidget);
  });

  testWidgets('ordinary pending action has no invented NPC association', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(pending: _plainAction));
    expect(find.text(_plainAction.text), findsOneWidget);
    expect(find.byKey(const ValueKey('adventure-pending-npc-selection')), findsNothing);
    await tester.pumpWidget(_screen());
    expect(find.byKey(const ValueKey('adventure-retry-action')), findsNothing);
    expect(find.byKey(const ValueKey('adventure-outbox-error')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
