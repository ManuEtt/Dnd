import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_initiate_choice.dart';
import 'package:lebendiger_spielleiter/ui/srd_magic_initiate_dialog.dart';

Future<List<SrdMagicInitiateChoice?>> _open(
  WidgetTester tester, {
  required ValueNotifier<SrdBackground> source,
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(source.dispose);

  final results = <SrdMagicInitiateChoice?>[];
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
              results.add(
                await showDialog<SrdMagicInitiateChoice>(
                  context: context,
                  builder: (_) => ValueListenableBuilder<SrdBackground>(
                    valueListenable: source,
                    builder: (context, background, child) =>
                        SrdMagicInitiateDialog(background: background),
                  ),
                ),
              );
            },
            child: const Text('Zauberwahl öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Zauberwahl öffnen'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _choose(WidgetTester tester, String field, String value) async {
  final dropdown = find.byKey(ValueKey(field));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  if (find.text(value).evaluate().isEmpty) {
    await tester.dragUntilVisible(
      find.text(value),
      find.byType(Scrollable).last,
      const Offset(0, -160),
      maxIteration: 45,
    );
    await tester.pumpAndSettle();
  }
  final option = find.text(value).last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void _expectEmptyChoices(WidgetTester tester) {
  for (final field in [
    'magic-initiate-cantrip-one',
    'magic-initiate-cantrip-two',
    'magic-initiate-level-one',
    'magic-initiate-ability',
  ]) {
    final form = find.byKey(ValueKey(field));
    expect(tester.state<FormFieldState<String>>(form).value, isNull);
  }
  final confirm = find.byKey(const ValueKey('confirm-magic-initiate-choice'));
  expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
}

void main() {
  testWidgets('360 dp: Klerikerwahl wechselt sicher zur Magierliste', (
    tester,
  ) async {
    final source = ValueNotifier(SrdBackground.acolyte);
    final results = await _open(tester, source: source, width: 360);
    await _choose(tester, 'magic-initiate-cantrip-one', 'Guidance');
    await _choose(tester, 'magic-initiate-cantrip-two', 'Light');
    await _choose(tester, 'magic-initiate-level-one', 'Bless');
    await _choose(tester, 'magic-initiate-ability', 'wisdom');

    source.value = SrdBackground.sage;
    await tester.pumpAndSettle();
    expect(find.text('Magieinitiierter (Magier)'), findsOneWidget);
    _expectEmptyChoices(tester);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);

    await _choose(tester, 'magic-initiate-cantrip-one', 'Fire Bolt');
    await _choose(tester, 'magic-initiate-cantrip-two', 'Mage Hand');
    await _choose(tester, 'magic-initiate-level-one', 'Magic Missile');
    await _choose(tester, 'magic-initiate-ability', 'charisma');
    final confirm = find.byKey(const ValueKey('confirm-magic-initiate-choice'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect(results.single?.background, SrdBackground.sage);
    expect(results.single?.cantrips, ['Fire Bolt', 'Mage Hand']);
    expect(results.single?.levelOneSpell, 'Magic Missile');
    expect(results.single?.castingAbility, 'charisma');
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp: gemeinsame Zauber erfordern neue Bestätigung', (
    tester,
  ) async {
    final source = ValueNotifier(SrdBackground.sage);
    final results = await _open(tester, source: source, width: 320);
    await _choose(tester, 'magic-initiate-cantrip-one', 'Light');
    await _choose(tester, 'magic-initiate-cantrip-two', 'Mending');
    await _choose(tester, 'magic-initiate-level-one', 'Detect Magic');
    await _choose(tester, 'magic-initiate-ability', 'wisdom');
    final confirm = find.byKey(const ValueKey('confirm-magic-initiate-choice'));
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

    source.value = SrdBackground.acolyte;
    await tester.pumpAndSettle();
    expect(find.text('Magieinitiierter (Kleriker)'), findsOneWidget);
    _expectEmptyChoices(tester);
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });

  testWidgets('Nicht passender Hintergrund bleibt ohne Zauberfreigabe', (
    tester,
  ) async {
    final source = ValueNotifier(SrdBackground.sage);
    final results = await _open(tester, source: source, width: 320);
    source.value = SrdBackground.criminal;
    await tester.pumpAndSettle();
    expect(find.text('Magieinitiierter (nicht verfügbar)'), findsOneWidget);
    _expectEmptyChoices(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(results, [null]);
  });
}
