import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';
import 'package:lebendiger_spielleiter/ui/pending_action_status.dart';

const _action = PendingPlayerAction(
  campaignId: 'outbox-accessibility',
  requestId: 'pending-error-live-region',
  text: 'Ich frage Mira nach dem Weg zum Brunnen.',
);

Widget _screen({
  required String? error,
  PendingPlayerAction? pending = _action,
  required VoidCallback onRetry,
  required VoidCallback onDiscard,
}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: const TextScaler.linear(2)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: PendingActionStatus(
        pending: pending,
        submitting: false,
        interactionBlocked: false,
        error: error,
        onRetry: onRetry,
        onDiscard: onDiscard,
      ),
    ),
  ),
);

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Outbox-Fehler bei $width dp/200 % wird angesagt und gelöscht', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      const firstError = 'Die Verbindung konnte nicht bestätigt werden.';
      const secondError = 'Der gespeicherte Auftrag ist nicht mehr aktuell.';
      final saved = _action.toJson();
      var retries = 0;
      var discards = 0;

      Widget view(String? message) => _screen(
        error: message,
        onRetry: () => retries++,
        onDiscard: () => discards++,
      );

      await tester.pumpWidget(view(firstError));
      await tester.pumpAndSettle();

      final errorText = find.byKey(const ValueKey('adventure-outbox-error'));
      final errorSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.liveRegion == true &&
            widget.properties.label ==
                'Fehler bei ausstehender Handlung: $firstError',
      );
      expect(find.text(firstError), findsOneWidget);
      expect(errorText, findsOneWidget);
      expect(errorSemantics, findsOneWidget);
      expect(
        find.bySemanticsLabel('Fehler bei ausstehender Handlung: $firstError'),
        findsOneWidget,
      );
      expect(retries, 0);
      expect(discards, 0);

      await tester.pumpWidget(view(secondError));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Fehler bei ausstehender Handlung: $firstError'),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel('Fehler bei ausstehender Handlung: $secondError'),
        findsOneWidget,
      );

      final retry = find.byKey(const ValueKey('adventure-retry-action'));
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      await tester.tap(retry);
      expect(retries, 1);
      expect(discards, 0);
      expect(_action.toJson(), saved);

      await tester.pumpWidget(view(null));
      await tester.pumpAndSettle();
      expect(errorText, findsNothing);
      expect(
        find.bySemanticsLabel(RegExp(r'^Fehler bei ausstehender Handlung:')),
        findsNothing,
      );
      expect(_action.toJson(), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Ohne Fehler gibt es keine künstliche Live-Warnung', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    var calls = 0;
    await tester.pumpWidget(
      _screen(
        error: null,
        pending: null,
        onRetry: () => calls++,
        onDiscard: () => calls++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('adventure-outbox-error')), findsNothing);
    expect(
      find.bySemanticsLabel(RegExp(r'^Fehler bei ausstehender Handlung:')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('adventure-retry-action')), findsNothing);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
}
