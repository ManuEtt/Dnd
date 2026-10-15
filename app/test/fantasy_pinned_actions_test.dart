import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets('Fixierte Schnellaktionen bei $width dp: sichtbar und bedienbar',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var speech = 0;
      var inspect = 0;
      var attack = 0;
      var dice = 0;
      await tester.pumpWidget(MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: Column(children: [
            Expanded(child: ListView(children: const [
              SizedBox(height: 1200, child: Text('Die Abenteuerszene')),
            ])),
            FantasyPinnedActionBar(
              busy: false, listening: false,
              onSpeech: () => speech++,
              onInspect: () => inspect++,
              onAttack: () => attack++,
              onRoll: () => dice++,
            ),
          ]),
          bottomNavigationBar: NavigationBar(destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Start'),
            NavigationDestination(icon: Icon(Icons.book), label: 'Abenteuer'),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      final bar = find.byKey(const ValueKey('adventure-fixed-shortcuts'));
      final firstPosition = tester.getTopLeft(bar);
      final navigationTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
      expect(tester.getBottomLeft(bar).dy, closeTo(navigationTop, 1));
      await tester.drag(find.byType(ListView), const Offset(0, -550));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(bar).dy, closeTo(firstPosition.dy, 1));
      expect(find.byKey(const ValueKey('adventure-shortcut-speech')), findsOneWidget);
      expect(find.byKey(const ValueKey('adventure-shortcut-inspect')), findsOneWidget);
      expect(find.byKey(const ValueKey('adventure-shortcut-attack')), findsOneWidget);
      expect(find.byKey(const ValueKey('adventure-shortcut-roll')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('adventure-shortcut-speech')));
      await tester.tap(find.byKey(const ValueKey('adventure-shortcut-inspect')));
      await tester.tap(find.byKey(const ValueKey('adventure-shortcut-attack')));
      await tester.tap(find.byKey(const ValueKey('adventure-shortcut-roll')));
      expect([speech, inspect, attack, dice], [1, 1, 1, 1]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Bei geöffneter Tastatur bleiben vier Schnellaktionen erreichbar',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(theme: buildFantasyTheme(), home:
      Scaffold(body: Column(children: [
        const Expanded(child: TextField()),
        FantasyPinnedActionBar(
          busy: false, listening: false,
          onSpeech: () {}, onInspect: () {},
          onAttack: () {}, onRoll: () {},
        ),
      ])),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Schnellaktionen'), findsNothing);
    // All four controls must actually receive taps while the IME is showing.
    for (final action in ['speech', 'inspect', 'attack', 'roll']) {
      expect(find.byKey(ValueKey('adventure-shortcut-$action')).hitTestable(),
          findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Schnellaktionen bleiben bei 320 dp und großer Schrift erreichbar',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var dice = 0;
    await tester.pumpWidget(MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(1.8)),
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
    ));
    await tester.pumpAndSettle();
    for (final action in ['speech', 'inspect', 'attack', 'roll']) {
      expect(find.byKey(ValueKey('adventure-shortcut-$action')).hitTestable(),
        findsOneWidget);
    }
    await tester.tap(find.byKey(const ValueKey('adventure-shortcut-roll')));
    expect(dice, 1);
    expect(tester.takeException(), isNull);
  });

}
