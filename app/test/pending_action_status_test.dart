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
  double textScale = 1,
  VoidCallback? onRetry,
  VoidCallback? onDiscard,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
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
    expect(find.textContaining('noch nicht sicher bestätigt'), findsOneWidget);
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
    expect(
      find.byKey(const ValueKey('adventure-outbox-error')),
      findsOneWidget,
    );
    expect(
      find.textContaining('NPC-Auswahl ist nicht mehr aktuell'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('adventure-retry-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('adventure-discard-action')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('while a pending NPC action is sending controls are hidden', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(pending: _npcAction, submitting: true));
    expect(
      find.byKey(const ValueKey('adventure-action-submitting')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('adventure-retry-action')), findsNothing);
    expect(
      find.byKey(const ValueKey('adventure-discard-action')),
      findsNothing,
    );
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
    expect(
      find.byKey(const ValueKey('adventure-pending-npc-selection')),
      findsNothing,
    );
    await tester.pumpWidget(_screen());
    expect(find.byKey(const ValueKey('adventure-retry-action')), findsNothing);
    expect(find.byKey(const ValueKey('adventure-outbox-error')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('vollständige ausstehende Handlung anzeigen ohne Retry-Mutation', (
    tester,
  ) async {
    final longText = List<String>.filled(
      24,
      'Ich untersuche erst das linke Tor und spreche dann mit Mira.',
    ).join(' ');
    final action = PendingPlayerAction(
      campaignId: 'camp',
      requestId: 'request-long',
      text: longText,
      selectedNpcId: 'mira-two',
      selectedNpcRevision: 5,
    );
    final saved = Map<String, dynamic>.of(action.toJson());
    var retries = 0;
    var discards = 0;
    await tester.pumpWidget(
      _screen(
        pending: action,
        onRetry: () => retries++,
        onDiscard: () => discards++,
      ),
    );

    final intent = find.byKey(const ValueKey('adventure-pending-action-text'));
    expect(tester.widget<Text>(intent).maxLines, 2);
    expect(tester.widget<Text>(intent).overflow, TextOverflow.ellipsis);
    await tester.tap(
      find.byKey(const ValueKey('adventure-pending-action-toggle')),
    );
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(intent).data, longText);
    expect(tester.widget<Text>(intent).maxLines, isNull);
    expect(tester.widget<Text>(intent).overflow, TextOverflow.visible);
    expect(find.text('Weniger anzeigen'), findsOneWidget);
    final scrollArea = find.byKey(
      const ValueKey('adventure-pending-action-scroll'),
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scrollArea, matching: find.byType(Scrollable)),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
    expect(
      scrollable.position.pixels,
      scrollable.position.maxScrollExtent,
    );
    expect(action.toJson(), saved);
    expect(retries, 0);
    expect(discards, 0);

    await tester.ensureVisible(
      find.byKey(const ValueKey('adventure-retry-action')),
    );
    await tester.tap(find.byKey(const ValueKey('adventure-retry-action')));
    expect(retries, 1);
    expect(discards, 0);
    expect(action.toJson(), saved);
    await tester.ensureVisible(
      find.byKey(const ValueKey('adventure-pending-action-toggle')),
    );
    await tester.tap(
      find.byKey(const ValueKey('adventure-pending-action-toggle')),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(intent).maxLines, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wechselnder gespeicherter Auftrag setzt aufgeklappten Text zurück', (
    tester,
  ) async {
    await tester.pumpWidget(_screen(pending: _npcAction));
    await tester.tap(
      find.byKey(const ValueKey('adventure-pending-action-toggle')),
    );
    await tester.pump();
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('adventure-pending-action-text')),
          )
          .maxLines,
      isNull,
    );
    await tester.pumpWidget(_screen(pending: _plainAction));
    expect(find.text(_plainAction.text), findsOneWidget);
    expect(find.text('Ganzen Text anzeigen'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('adventure-pending-action-text')),
          )
          .maxLines,
      2,
    );
    await tester.pumpWidget(_screen());
    expect(
      find.byKey(const ValueKey('adventure-pending-action-toggle')),
      findsNothing,
    );
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('200 % Schrift bei $width dp: Auftrag trotz Sperre lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      var retries = 0;

      await tester.pumpWidget(
        _screen(
          pending: _npcAction,
          interactionBlocked: true,
          textScale: 2,
          onRetry: () => retries++,
        ),
      );
      await tester.pumpAndSettle();

      final toggle = find.byKey(
        const ValueKey('adventure-pending-action-toggle'),
      );
      expect(find.bySemanticsLabel('Ganzen Text anzeigen'), findsOneWidget);
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Weniger anzeigen'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('adventure-pending-action-text')),
            )
            .maxLines,
        isNull,
      );
      expect(find.text(_npcAction.text), findsOneWidget);
      final retry = tester.widget<FantasyTextButton>(
        find.byKey(const ValueKey('adventure-retry-action')),
      );
      expect(retry.onPressed, isNull);
      expect(retries, 0);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
