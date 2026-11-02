import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/confirmed_spell_effects.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/confirmed_spell_effect_dialog.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'hero',
  name: 'Liora',
  spells: const ['Segen', 'Magische Rüstung'],
  concentratingOn: 'Segen',
  confirmedSpellEffects: [
    ConfirmedSpellEffect(
      id: 'source-one',
      spellName: 'Segen',
      source: 'Schriftrolle',
      concentrationBound: true,
    ),
    ConfirmedSpellEffect(
      id: 'source-two',
      spellName: 'Magische Rüstung',
      source: 'Artefakt',
      concentrationBound: false,
    ),
  ],
);

Finder _field(String name) => find.byKey(ValueKey('spell-effect-$name'));

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required HeroCharacter hero,
  required ValueChanged<ConfirmedSpellEffectChoice?> onResult,
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
                await showDialog<ConfirmedSpellEffectChoice>(
                  context: context,
                  builder: (_) =>
                      ConfirmedSpellEffectDialog(hero: hero, encounter: null),
                ),
              );
            },
            child: const Text('Zauber öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Zauber öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Zauberwirkung $width dp/200 %/IME: Fehler und Abbruch', (
      tester,
    ) async {
      final hero = _hero();
      final saved = hero.toJson();
      final results = <ConfirmedSpellEffectChoice?>[];
      await _open(tester, width: width, hero: hero, onResult: results.add);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      expect(
        find.ancestor(of: _field('source'), matching: find.byType(Scrollable)),
        findsOneWidget,
      );
      await _tap(tester, _field('confirm'));
      expect(_field('error'), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Semantics) return false;
          return widget.properties.liveRegion ?? false;
        }),
        findsWidgets,
      );
      expect(results, isEmpty);
      await _tap(tester, _field('cancel'));
      expect(results, [null]);
      expect(hero.toJson(), saved);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: bestätigte Quelle nur als Auswahl', (
    tester,
  ) async {
    final hero = _hero();
    final saved = hero.toJson();
    final results = <ConfirmedSpellEffectChoice?>[];
    await _open(tester, width: 320, hero: hero, onResult: results.add);
    await tester.ensureVisible(_field('source'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('source'), '  Geprüfter Beleg  ');
    await tester.pumpAndSettle();
    expect(_field('duration'), findsOneWidget);
    await _tap(tester, _field('confirm'));
    expect(results, hasLength(1));
    expect(results.single!.isRemoval, isFalse);
    expect(results.single!.spellName, 'Segen');
    expect(results.single!.source, 'Geprüfter Beleg');
    expect(results.single!.concentrationBound, isFalse);
    expect(results.single!.ownTurnEnds, isNull);
    expect(hero.toJson(), saved);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: nur ausgewählte Zauberquelle beenden', (
    tester,
  ) async {
    final hero = _hero();
    final saved = hero.toJson();
    final results = <ConfirmedSpellEffectChoice?>[];
    await _open(tester, width: 360, hero: hero, onResult: results.add);
    await _tap(tester, _field('remove-mode'));
    expect(_field('source'), findsNothing);
    await _tap(tester, _field('existing'));
    final option = find.text('Magische Rüstung · Artefakt').last;
    await tester.ensureVisible(option);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();
    await _tap(tester, _field('confirm'));
    expect(results, hasLength(1));
    expect(results.single!.isRemoval, isTrue);
    expect(results.single!.effectId, 'source-two');
    expect(hero.toJson(), saved);
    expect(tester.takeException(), isNull);
  });
}
