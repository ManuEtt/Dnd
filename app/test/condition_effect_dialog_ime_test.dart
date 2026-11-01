import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/condition_effect_dialog.dart';

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required HeroCharacter hero,
  required ValueChanged<ConditionEffectChoice?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await showDialog<ConditionEffectChoice>(
                  context: context,
                  builder: (_) => ConditionEffectDialog(
                    hero: hero,
                    encounter: null,
                  ),
                ),
              );
            },
            child: const Text('Quelle öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Quelle öffnen'));
  await tester.pumpAndSettle();
}

Finder _control(String name) => find.byKey(ValueKey('condition-effect-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Zustand $width dp/200 %/IME: Fehler und Abbruch', (
      tester,
    ) async {
      final hero = HeroCharacter(id: 'hero', name: 'Liora');
      final before = hero.toJson();
      final results = <ConditionEffectChoice?>[];
      await _open(tester, width: width, hero: hero, onResult: results.add);

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      expect(
        find.ancestor(
          of: _control('source'),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      await _tap(tester, _control('confirm'));
      expect(_control('error'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.liveRegion,
        ),
        findsWidgets,
      );
      expect(results, isEmpty);
      await _tap(tester, _control('cancel'));
      expect(results, [null]);
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: gültige Quelle wird nur zurückgegeben', (
    tester,
  ) async {
    final hero = HeroCharacter(id: 'hero', name: 'Liora');
    final before = hero.toJson();
    final results = <ConditionEffectChoice?>[];
    await _open(tester, width: 320, hero: hero, onResult: results.add);

    await tester.ensureVisible(_control('source'));
    await tester.pumpAndSettle();
    await tester.enterText(_control('source'), '  Giftfalle  ');
    await tester.pumpAndSettle();
    expect(_control('duration'), findsOneWidget);
    await _tap(tester, _control('confirm'));

    expect(results, hasLength(1));
    expect(results.single!.isRemoval, isFalse);
    expect(results.single!.condition, 'vergiftet');
    expect(results.single!.source, 'Giftfalle');
    expect(results.single!.duration, ConditionEffectDuration.untilRemoved);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: nur gewählte Quelle entfernen', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'hero',
      name: 'Liora',
      conditionEffects: [
        ConditionEffect(
          id: 'quelle-a',
          condition: 'vergiftet',
          source: 'Nebel',
        ),
        ConditionEffect(
          id: 'quelle-b',
          condition: 'vergiftet',
          source: 'Pfeil',
        ),
      ],
    );
    final before = hero.toJson();
    final results = <ConditionEffectChoice?>[];
    await _open(tester, width: 360, hero: hero, onResult: results.add);

    await _tap(tester, _control('remove-mode'));
    expect(_control('source'), findsNothing);
    expect(_control('existing-source'), findsOneWidget);
    await _tap(tester, _control('existing-source'));
    final second = find.text('vergiftet: Pfeil').last;
    await tester.ensureVisible(second);
    await tester.pumpAndSettle();
    await tester.tap(second);
    await tester.pumpAndSettle();
    await _tap(tester, _control('confirm'));

    expect(results, hasLength(1));
    expect(results.single!.isRemoval, isTrue);
    expect(results.single!.effectId, 'quelle-b');
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
