import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  test('Grafikpfade sind für alle Styles und Zustände eindeutig', () {
    final paths = <String>{};
    for (final style in FantasyButtonStyle.values) {
      for (final state in FantasyButtonState.values) {
        final path = FantasyButtonAssets.path(style, state);
        expect(path, startsWith('assets/fantasy/buttons/btn_'));
        expect(path, endsWith('_${state.name}.png'));
        expect(paths.add(path), isTrue);
      }
    }
    expect(paths.length, 30);
    expect(FantasyButtonAssets.wideCenterSlice.width, 144);
  });

  testWidgets('Beschrifteter Würfelbutton skaliert via 9-Slice', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 250,
              child: FantasyDiceButton(sides: 20, onPressed: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final surface = tester.widget<FantasyButtonSurface>(
      find.byType(FantasyButtonSurface),
    );
    expect(surface.style, FantasyButtonStyle.dice);
    expect(surface.square, isFalse);
    expect(find.text('W20 würfeln'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Primärbutton ruft Aktion und optionales Klicksignal auf', (
    tester,
  ) async {
    var actions = 0;
    var sounds = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: Center(
            child: FantasyButton(
              label: 'Abenteuer starten',
              icon: Icons.play_arrow,
              onPressed: () => actions++,
              onSound: () => sounds++,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abenteuer starten'));
    await tester.pumpAndSettle();
    expect(actions, 1);
    expect(sounds, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Deaktivierte Würfelaktion ist sichtbar, aber nicht auslösbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: const Scaffold(
          body: Center(child: FantasyDiceButton(sides: 20, onPressed: null)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('W20 würfeln'), findsOneWidget);
    await tester.tap(find.text('W20 würfeln'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hover, Auswahl und Disabled bestimmen die Grafikzustände', (
    tester,
  ) async {
    const style = FantasyButtonStyle.arcane;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: Column(
            children: [
              FantasyToggleButton(
                label: 'Magie',
                selected: true,
                onPressed: () {},
              ),
              const FantasyToggleButton(
                label: 'Gesperrt',
                selected: false,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final toggle = tester.widget<FantasyButton>(
      find.byWidgetPredicate(
        (widget) => widget is FantasyButton && widget.label == 'Magie',
      ),
    );
    expect(toggle.style, style);
    expect(toggle.selected, isTrue);
    expect(
      FantasyButtonAssets.path(style, FantasyButtonState.active),
      contains('_active.png'),
    );
    expect(
      FantasyButtonAssets.path(style, FantasyButtonState.disabled),
      contains('_disabled.png'),
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 920.0]) {
    testWidgets('Buttons sind bei $width dp ohne Überlauf bedienbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var count = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FantasyTextButton(
                    label: 'Neue Kampagne',
                    onPressed: () => count++,
                  ),
                  FantasyIconButton(
                    icon: Icons.settings,
                    tooltip: 'Optionen',
                    onPressed: () => count++,
                  ),
                  FantasyDiceButton(sides: 20, onPressed: () => count++),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Neue Kampagne'));
      await tester.tap(find.byTooltip('Optionen'));
      await tester.tap(find.text('W20 würfeln'));
      await tester.pumpAndSettle();
      expect(count, 3);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Normale Aktionen melden keinen Schalterzustand an TalkBack', (
    tester,
  ) async {
    var actions = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: FantasyButton(
            label: 'W20 würfeln',
            selected: true,
            onPressed: () => actions++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final semantic = tester.widget<Semantics>(
      find.descendant(
        of: find.byType(FantasyButton),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.button == true,
        ),
      ).first,
    );
    expect(semantic.properties.button, isTrue);
    expect(semantic.properties.toggled, isNull);
    await tester.tap(find.text('W20 würfeln'));
    expect(actions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nur Schalter melden ihren tatsächlichen Auswahlzustand', (
    tester,
  ) async {
    Future<void> showToggle({required bool selected, bool enabled = true}) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: FantasyToggleButton(
              label: 'Magie',
              selected: selected,
              onPressed: enabled ? () {} : null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Semantics toggleSemantics() => tester.widget<Semantics>(
      find.descendant(
        of: find.byType(FantasyButton),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.button == true,
        ),
      ).first,
    );

    await showToggle(selected: false);
    expect(toggleSemantics().properties.toggled, isFalse);
    expect(toggleSemantics().properties.enabled, isTrue);

    await showToggle(selected: true);
    expect(toggleSemantics().properties.toggled, isTrue);

    await showToggle(selected: false, enabled: false);
    expect(toggleSemantics().properties.toggled, isFalse);
    expect(toggleSemantics().properties.enabled, isFalse);
    expect(tester.takeException(), isNull);
  });
}
