import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/area_creature_registration_dialog.dart';

Finder _field(String name) => find.byKey(ValueKey('area-creature-$name'));

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required ValueChanged<TrackedAreaCreature?> onResult,
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
                await showDialog<TrackedAreaCreature>(
                  context: context,
                  builder: (_) => const AreaCreatureRegistrationDialog(),
                ),
              );
            },
            child: const Text('Kreatur öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Kreatur öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, String name, String value) async {
  final finder = _field(name);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> _fill(WidgetTester tester, {String hp = '7'}) async {
  await _enter(tester, 'id', 'goblin-2');
  await _enter(tester, 'name', 'Goblin');
  await _enter(tester, 'hp', hp);
  await _enter(tester, 'maxhp', '7');
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Kreaturen-Dialog $width dp/200 %/IME: Fehler und Abbruch', (
      tester,
    ) async {
      final results = <TrackedAreaCreature?>[];
      await _open(tester, width: width, onResult: results.add);

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      expect(
        find.ancestor(
          of: _field('maxhp'),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      expect(_field('confirmed'), findsOneWidget);
      await _tap(tester, _field('register'));
      expect(_field('error'), findsOneWidget);
      expect(find.textContaining('Bitte alle Werte'), findsOneWidget);
      expect(results, isEmpty);
      await _tap(tester, find.text('Abbrechen'));
      expect(results, [null]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: geprüfte Kreatur nur zurückgeben', (
    tester,
  ) async {
    final results = <TrackedAreaCreature?>[];
    await _open(tester, width: 320, onResult: results.add);
    await _fill(tester);
    expect(
      tester.widget<CheckboxListTile>(_field('confirmed')).value,
      isFalse,
    );
    await _tap(tester, _field('register'));
    expect(results, isEmpty);
    expect(find.textContaining('Bitte alle Werte'), findsOneWidget);
    await _tap(tester, _field('confirmed'));
    expect(
      tester.widget<CheckboxListTile>(_field('confirmed')).value,
      isTrue,
    );
    await _tap(tester, _field('register'));
    expect(results, hasLength(1));
    expect(results.single!.id, 'goblin-2');
    expect(results.single!.name, 'Goblin');
    expect(results.single!.hitPoints, 7);
    expect(results.single!.maxHitPoints, 7);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: null TP korrigieren vor Bestätigung', (
    tester,
  ) async {
    final results = <TrackedAreaCreature?>[];
    await _open(tester, width: 360, onResult: results.add);
    await _fill(tester, hp: '0');
    await _tap(tester, _field('confirmed'));
    await _tap(tester, _field('register'));
    expect(results, isEmpty);
    expect(find.textContaining('benötigt noch Trefferpunkte'), findsOneWidget);
    expect(_field('error'), findsOneWidget);
    expect(find.byType(AreaCreatureRegistrationDialog), findsOneWidget);
    await _enter(tester, 'hp', '4');
    await _tap(tester, _field('register'));
    expect(results.single!.hitPoints, 4);
    expect(results.single!.maxHitPoints, 7);
    expect(tester.takeException(), isNull);
  });
}
