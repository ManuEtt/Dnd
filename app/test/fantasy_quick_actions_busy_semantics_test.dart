import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const _busyHint = 'Eine Handlung wird bereits verarbeitet.';

Finder _action(String name) => find.byKey(ValueKey('adventure-shortcut-$name'));

Semantics _semantics(WidgetTester tester, String action) {
  final button = find.descendant(
    of: _action(action),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.button == true,
    ),
  );
  expect(button, findsWidgets);
  return tester.widget<Semantics>(button.first);
}

Future<void> _mount(
  WidgetTester tester, {
  required double width,
  required bool busy,
  required bool listening,
  required bool attackEnabled,
  required List<String> calls,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 270);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await _pumpActions(
    tester,
    busy: busy,
    listening: listening,
    attackEnabled: attackEnabled,
    calls: calls,
  );
}

Future<void> _pumpActions(
  WidgetTester tester, {
  required bool busy,
  required bool listening,
  required bool attackEnabled,
  required List<String> calls,
}) async {
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
        body: const Center(child: Text('Abenteuer')),
        bottomNavigationBar: FantasyPinnedActionBar(
          busy: busy,
          listening: listening,
          attackEnabled: attackEnabled,
          attackUnavailableReason: 'Kein bestätigtes Ziel.',
          onSpeech: () => calls.add('speech'),
          onInspect: () => calls.add('inspect'),
          onAttack: () => calls.add('attack'),
          onRoll: () => calls.add('roll'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Schnellaktionen $width dp: Busy-Hinweis bei 2x Text und Android-IME',
      (tester) async {
        final calls = <String>[];
        await _mount(
          tester,
          width: width,
          busy: true,
          listening: false,
          attackEnabled: false,
          calls: calls,
        );

        for (final entry in <String, String>{
          'speech': 'Sprache',
          'inspect': 'Untersuchen',
          'attack': 'Angriff',
          'roll': 'W20',
        }.entries) {
          final tile = _action(entry.key);
          expect(tile.hitTestable(), findsOneWidget);
          final semantics = _semantics(tester, entry.key);
          expect(semantics.properties.label, entry.value);
          expect(semantics.properties.button, isTrue);
          expect(semantics.properties.enabled, isFalse);
          expect(semantics.properties.hint, _busyHint);
          await tester.tap(tile);
        }
        expect(calls, isEmpty);
        expect(find.text('Schnellaktionen'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Schnellaktionen $width dp: nur Angriff gesperrt, übrige aktiv',
      (tester) async {
        final calls = <String>[];
        await _mount(
          tester,
          width: width,
          busy: false,
          listening: true,
          attackEnabled: false,
          calls: calls,
        );

        for (final entry in <String, String>{
          'speech': 'Stopp',
          'inspect': 'Untersuchen',
          'roll': 'W20',
        }.entries) {
          final semantics = _semantics(tester, entry.key);
          expect(semantics.properties.label, entry.value);
          expect(semantics.properties.enabled, isTrue);
          expect(semantics.properties.hint, isNull);
          await tester.tap(_action(entry.key));
        }
        final attack = _semantics(tester, 'attack');
        expect(attack.properties.enabled, isFalse);
        expect(attack.properties.hint, 'Kein bestätigtes Ziel.');
        await tester.tap(_action('attack'));
        expect(calls, ['speech', 'inspect', 'roll']);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Busy-Ende entfernt alle Sperrhinweise ohne automatische Auslösung',
    (tester) async {
      final calls = <String>[];
      await _mount(
        tester,
        width: 320,
        busy: true,
        listening: false,
        attackEnabled: true,
        calls: calls,
      );

      for (final action in ['speech', 'inspect', 'attack', 'roll']) {
        expect(_semantics(tester, action).properties.hint, _busyHint);
      }

      await _pumpActions(
        tester,
        busy: false,
        listening: false,
        attackEnabled: true,
        calls: calls,
      );
      expect(calls, isEmpty);
      for (final action in ['speech', 'inspect', 'attack', 'roll']) {
        final semantics = _semantics(tester, action);
        expect(semantics.properties.enabled, isTrue);
        expect(semantics.properties.hint, isNull);
      }
      await tester.tap(_action('roll'));
      expect(calls, ['roll']);
      expect(tester.takeException(), isNull);
    },
  );
}
