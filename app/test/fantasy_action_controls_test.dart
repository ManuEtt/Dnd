import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  Future<void> mountActions(
    WidgetTester tester, {
    bool busy = false,
    bool listening = false,
    VoidCallback? speech,
    VoidCallback? inspect,
    VoidCallback? attack,
    VoidCallback? roll,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: Center(
            child: FantasyPinnedActionBar(
              busy: busy,
              listening: listening,
              onSpeech: speech ?? () {},
              onInspect: inspect ?? () {},
              onAttack: attack ?? () {},
              onRoll: roll ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FantasyButtonState stateOf(WidgetTester tester, String action) {
    final tile = find.byKey(ValueKey('adventure-shortcut-$action'));
    final artwork = find.descendant(
      of: tile,
      matching: find.byType(FantasyButtonSurface),
    );
    return tester.widget<FantasyButtonSurface>(artwork).state;
  }

  testWidgets('Kampf-Schnellaktionen zeigen definierte Material-Grafiken', (
    tester,
  ) async {
    await mountActions(tester);
    for (final entry in <String, FantasyButtonStyle>{
      'speech': FantasyButtonStyle.woodGold,
      'inspect': FantasyButtonStyle.arcane,
      'attack': FantasyButtonStyle.wax,
      'roll': FantasyButtonStyle.arcane,
    }.entries) {
      final tile = tester.widget<FantasyShortcutTile>(
        find.byKey(ValueKey('adventure-shortcut-${entry.key}')),
      );
      expect(tile.style, entry.value);
      expect(stateOf(tester, entry.key), FantasyButtonState.normal);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Aktives Mikrofon verwendet arkanes Aktivitätslicht', (
    tester,
  ) async {
    var count = 0;
    await mountActions(tester, listening: true, speech: () => count++);
    expect(find.text('Stopp'), findsOneWidget);
    expect(stateOf(tester, 'speech'), FantasyButtonState.active);
    await tester.tap(find.byKey(const ValueKey('adventure-shortcut-speech')));
    await tester.pumpAndSettle();
    expect(count, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Drücken wechselt in den Pressed-Zustand', (tester) async {
    var count = 0;
    await mountActions(tester, attack: () => count++);
    final tile = find.byKey(const ValueKey('adventure-shortcut-attack'));
    final gesture = await tester.startGesture(tester.getCenter(tile));
    await tester.pump();
    expect(stateOf(tester, 'attack'), FantasyButtonState.pressed);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(count, 1);
    expect(stateOf(tester, 'attack'), FantasyButtonState.normal);
  });

  testWidgets('Hover zeigt Magie-Glow, ohne die Aktion auszulösen', (
    tester,
  ) async {
    var count = 0;
    await mountActions(tester, inspect: () => count++);
    final tile = find.byKey(const ValueKey('adventure-shortcut-inspect'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(0, 0));
    await mouse.moveTo(tester.getCenter(tile));
    await tester.pumpAndSettle();
    expect(stateOf(tester, 'inspect'), FantasyButtonState.hover);
    expect(count, 0);
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(stateOf(tester, 'inspect'), FantasyButtonState.normal);
  });

  testWidgets('Während Busy sind alle vier Aktionen deaktiviert', (
    tester,
  ) async {
    var count = 0;
    void increment() => count++;
    await mountActions(
      tester,
      busy: true,
      speech: increment,
      inspect: increment,
      attack: increment,
      roll: increment,
    );
    for (final action in ['speech', 'inspect', 'attack', 'roll']) {
      expect(stateOf(tester, action), FantasyButtonState.disabled);
      await tester.tap(find.byKey(ValueKey('adventure-shortcut-$action')));
    }
    await tester.pumpAndSettle();
    expect(count, 0);
    expect(tester.takeException(), isNull);
  });
}
