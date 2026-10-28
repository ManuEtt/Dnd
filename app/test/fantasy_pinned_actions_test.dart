import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets(
      'Fixierte Schnellaktionen bei $width dp: sichtbar und bedienbar',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var speech = 0;
        var inspect = 0;
        var attack = 0;
        var dice = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: buildFantasyTheme(),
            home: Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: const [
                        SizedBox(
                          height: 1200,
                          child: Text('Die Abenteuerszene'),
                        ),
                      ],
                    ),
                  ),
                  FantasyPinnedActionBar(
                    busy: false,
                    listening: false,
                    onSpeech: () => speech++,
                    onInspect: () => inspect++,
                    onAttack: () => attack++,
                    onRoll: () => dice++,
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'Start'),
                  NavigationDestination(
                    icon: Icon(Icons.book),
                    label: 'Abenteuer',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final bar = find.byKey(const ValueKey('adventure-fixed-shortcuts'));
        final firstPosition = tester.getTopLeft(bar);
        final navigationTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
        expect(tester.getBottomLeft(bar).dy, closeTo(navigationTop, 1));
        await tester.drag(find.byType(ListView), const Offset(0, -550));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(bar).dy, closeTo(firstPosition.dy, 1));
        expect(
          find.byKey(const ValueKey('adventure-shortcut-speech')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('adventure-shortcut-inspect')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('adventure-shortcut-attack')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('adventure-shortcut-roll')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('adventure-shortcut-speech')),
        );
        await tester.tap(
          find.byKey(const ValueKey('adventure-shortcut-inspect')),
        );
        await tester.tap(
          find.byKey(const ValueKey('adventure-shortcut-attack')),
        );
        await tester.tap(find.byKey(const ValueKey('adventure-shortcut-roll')));
        expect([speech, inspect, attack, dice], [1, 1, 1, 1]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Bei geöffneter Tastatur bleiben vier Schnellaktionen erreichbar',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: TextField()),
                FantasyPinnedActionBar(
                  busy: false,
                  listening: false,
                  onSpeech: () {},
                  onInspect: () {},
                  onAttack: () {},
                  onRoll: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Schnellaktionen'), findsNothing);
      // All four controls must actually receive taps while the IME is showing.
      for (final action in ['speech', 'inspect', 'attack', 'roll']) {
        expect(
          find.byKey(ValueKey('adventure-shortcut-$action')).hitTestable(),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Schnellaktionen bleiben bei 320 dp und großer Schrift erreichbar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var dice = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: const Center(child: Text('Abenteuerinhalt')),
            bottomNavigationBar: FantasyPinnedActionBar(
              busy: false,
              listening: false,
              onSpeech: () {},
              onInspect: () {},
              onAttack: () {},
              onRoll: () => dice++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final action in ['speech', 'inspect', 'attack', 'roll']) {
        expect(
          find.byKey(ValueKey('adventure-shortcut-$action')).hitTestable(),
          findsOneWidget,
        );
      }
      await tester.tap(find.byKey(const ValueKey('adventure-shortcut-roll')));
      expect(dice, 1);
      expect(tester.takeException(), isNull);
    },
  );

  // Regression: an open Android keyboard must not steal Tab/Enter actions.
  testWidgets(
    'Tastaturfokus aktiviert vier Schnellaktionen bei 320 dp, IME und 2x Text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      final invoked = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: TextField()),
                FantasyPinnedActionBar(
                  busy: false,
                  listening: false,
                  onSpeech: () => invoked.add('speech'),
                  onInspect: () => invoked.add('inspect'),
                  onAttack: () => invoked.add('attack'),
                  onRoll: () => invoked.add('roll'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(TextField));
      await tester.pump();

      bool focusedWithin(String name) {
        final focusContext = FocusManager.instance.primaryFocus?.context;
        if (focusContext == null) return false;
        return find
            .descendant(
              of: find.byKey(ValueKey('adventure-shortcut-$name')),
              matching: find.byElementPredicate(
                (element) => identical(element, focusContext),
              ),
            )
            .evaluate()
            .isNotEmpty;
      }

      for (final name in ['speech', 'inspect', 'attack', 'roll']) {
        final tile = find.byKey(ValueKey('adventure-shortcut-$name'));
        expect(tile.hitTestable(), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(focusedWithin(name), isTrue, reason: 'Fokus bei $name');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
      }
      expect(invoked, ['speech', 'inspect', 'attack', 'roll']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Deaktivierter Angriff wird im Tastaturfokus übersprungen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      final invoked = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Column(
              children: [
                const Expanded(child: TextField()),
                FantasyPinnedActionBar(
                  busy: false,
                  listening: false,
                  attackEnabled: false,
                  attackUnavailableReason: 'Kein bestätigtes Ziel.',
                  onSpeech: () => invoked.add('speech'),
                  onInspect: () => invoked.add('inspect'),
                  onAttack: () => invoked.add('attack'),
                  onRoll: () => invoked.add('roll'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(TextField));
      await tester.pump();

      final attack = find.byKey(const ValueKey('adventure-shortcut-attack'));
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: attack,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Semantics && widget.properties.button == true,
              ),
            )
            .first,
      );
      expect(semantics.properties.enabled, isFalse);
      expect(semantics.properties.label, 'Angriff');

      for (final name in ['speech', 'inspect', 'roll']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        final focusContext = FocusManager.instance.primaryFocus?.context;
        expect(
          find
              .descendant(
                of: find.byKey(ValueKey('adventure-shortcut-$name')),
                matching: find.byElementPredicate(
                  (element) => identical(element, focusContext),
                ),
              )
              .evaluate(),
          isNotEmpty,
          reason: 'Deaktivierter Angriff muss übersprungen werden: $name',
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
      }
      expect(invoked, ['speech', 'inspect', 'roll']);
      expect(tester.takeException(), isNull);
    },
  );
}
