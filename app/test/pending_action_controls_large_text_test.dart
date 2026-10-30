import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/pending_action_status.dart';

void main() {
  const pending = PendingPlayerAction(
    campaignId: 'camp',
    requestId: 'pending-accessible',
    text: 'Ich erkunde die Stadt.',
  );
  const longPending = PendingPlayerAction(
    campaignId: 'camp',
    requestId: 'pending-long-accessible',
    text:
        'Ich frage Mira nach dem Tor und untersuche die alte Karte. '
        'Danach spreche ich mit den Reisenden und suche die Spuren am Brunnen. '
        'Ich frage Mira nach dem Tor und untersuche die alte Karte. '
        'Danach spreche ich mit den Reisenden und suche die Spuren am Brunnen.',
    selectedNpcId: 'mira-two',
    selectedNpcRevision: 5,
  );

  Future<void> showStatus(
    WidgetTester tester, {
    required double width,
    required double scale,
    PendingPlayerAction? action = pending,
    bool blocked = false,
    bool submitting = false,
    bool keyboard = true,
    VoidCallback? retry,
    VoidCallback? discard,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    if (keyboard) {
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Column(
            children: [
              const TextField(key: ValueKey('pending-keyboard-field')),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: PendingActionStatus(
                      pending: action,
                      submitting: submitting,
                      interactionBlocked: blocked,
                      error: null,
                      onRetry: retry ?? () {},
                      onDiscard: discard ?? () {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool focusInside(WidgetTester tester, String key) {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return find
        .descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byElementPredicate(
            (element) => identical(element, context),
          ),
        )
        .evaluate()
        .isNotEmpty;
  }

  for (final width in [320.0, 360.0]) {
    testWidgets('Ausstehende Aktionen bei $width dp und 200 % erreichbar', (
      tester,
    ) async {
      var retries = 0;
      var discards = 0;
      final saved = pending.toJson();
      await showStatus(
        tester,
        width: width,
        scale: 2,
        retry: () => retries++,
        discard: () => discards++,
      );
      await tester.showKeyboard(
        find.byKey(const ValueKey('pending-keyboard-field')),
      );
      await tester.pumpAndSettle();

      final retry = find.byKey(const ValueKey('adventure-retry-action'));
      final discard = find.byKey(const ValueKey('adventure-discard-action'));
      expect(
        tester.getTopLeft(discard).dy,
        greaterThan(tester.getBottomLeft(retry).dy),
      );
      expect(
        tester.getSize(retry).width,
        closeTo(tester.getSize(discard).width, 1),
      );
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      expect(retry.hitTestable(), findsOneWidget);
      await tester.tap(retry);
      await tester.ensureVisible(discard);
      await tester.pumpAndSettle();
      expect(discard.hitTestable(), findsOneWidget);
      await tester.tap(discard);

      expect(retries, 1);
      expect(discards, 1);
      expect(pending.toJson(), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Tab und Enter erreichen beide ausstehenden Aktionen', (
    tester,
  ) async {
    final selected = <String>[];
    await showStatus(
      tester,
      width: 320,
      scale: 2,
      retry: () => selected.add('retry'),
      discard: () => selected.add('discard'),
    );
    await tester.showKeyboard(
      find.byKey(const ValueKey('pending-keyboard-field')),
    );
    await tester.pumpAndSettle();

    for (final key in ['adventure-retry-action', 'adventure-discard-action']) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      debugPrint(
        'Focus for $key: ${FocusManager.instance.primaryFocus?.debugLabel}',
      );
      expect(focusInside(tester, key), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }
    expect(selected, ['retry', 'discard']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gesperrte ausstehende Aktionen bleiben ohne Callback', (
    tester,
  ) async {
    var calls = 0;
    final saved = pending.toJson();
    await showStatus(
      tester,
      width: 320,
      scale: 2,
      blocked: true,
      retry: () => calls++,
      discard: () => calls++,
    );
    final retry = find.byKey(const ValueKey('adventure-retry-action'));
    final discard = find.byKey(const ValueKey('adventure-discard-action'));
    expect(tester.widget<FantasyTextButton>(retry).onPressed, isNull);
    expect(tester.widget<FantasyTextButton>(discard).onPressed, isNull);
    await tester.ensureVisible(retry);
    await tester.pumpAndSettle();
    await tester.tap(retry);
    await tester.ensureVisible(discard);
    await tester.pumpAndSettle();
    await tester.tap(discard);
    expect(calls, 0);
    expect(pending.toJson(), saved);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Langer NPC-Auftrag behält Volltextschalter und Daten', (
    tester,
  ) async {
    var retries = 0;
    final saved = longPending.toJson();
    await showStatus(
      tester,
      width: 320,
      scale: 2,
      action: longPending,
      retry: () => retries++,
    );
    final toggle = find.byKey(
      const ValueKey('adventure-pending-action-toggle'),
    );
    final retry = find.byKey(const ValueKey('adventure-retry-action'));
    final discard = find.byKey(const ValueKey('adventure-discard-action'));
    expect(toggle, findsOneWidget);
    expect(
      tester.getTopLeft(discard).dy,
      greaterThan(tester.getBottomLeft(retry).dy),
    );
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('Weniger anzeigen'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('adventure-pending-action-text')),
          )
          .maxLines,
      isNull,
    );
    expect(retries, 0);
    expect(longPending.toJson(), saved);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Beim Senden bleiben Wiederholen und Verwerfen unsichtbar', (
    tester,
  ) async {
    await showStatus(tester, width: 320, scale: 2, submitting: true);
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

  testWidgets('Bei normaler Schrift bleibt der kompakte Wrap', (tester) async {
    await showStatus(tester, width: 960, scale: 1, keyboard: false);
    final retry = find.byKey(const ValueKey('adventure-retry-action'));
    final discard = find.byKey(const ValueKey('adventure-discard-action'));
    expect(
      tester.getTopLeft(retry).dy,
      closeTo(tester.getTopLeft(discard).dy, 1),
    );
    expect(tester.takeException(), isNull);
  });
}
