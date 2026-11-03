import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/character_portrait_picker.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required double scale,
  required double keyboard,
  required ValueChanged<CharacterPortraitChoice?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
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
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await Navigator.of(context).push<CharacterPortraitChoice>(
                  MaterialPageRoute(
                    builder: (_) => const CharacterPortraitPicker(
                      initialPreset: 2,
                      initialPhotoBase64: '',
                    ),
                  ),
                ),
              );
            },
            child: const Text('Porträt wählen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Porträt wählen'));
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, int preset) async {
  final option = _key('portrait-option-$preset');
  await tester.scrollUntilVisible(
    option,
    180,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 30,
  );
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  expect(option.hitTestable(), findsOneWidget);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final width in [320.0, 360.0]) {
    testWidgets('$width dp / 200 % / IME: beide Aktionen bleiben erreichbar', (
      tester,
    ) async {
      final results = <CharacterPortraitChoice?>[];
      await _open(
        tester,
        width: width,
        scale: 2,
        keyboard: 220,
        onResult: results.add,
      );
      final cancel = _key('portrait-cancel');
      final apply = _key('portrait-apply');
      expect(cancel.hitTestable(), findsOneWidget);
      expect(apply.hitTestable(), findsOneWidget);
      expect(tester.getSize(cancel).width, greaterThan(250));
      expect(tester.getSize(apply).width, greaterThan(250));
      expect(
        (tester.getCenter(cancel).dx - tester.getCenter(apply).dx).abs(),
        lessThan(1),
      );
      expect(tester.getCenter(cancel).dy, lessThan(tester.getCenter(apply).dy));
      expect(tester.takeException(), isNull);

      await _select(tester, 7);
      final selected = tester.widget<Semantics>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label == 'Fantasy-Porträt 8',
        ),
      );
      expect(selected.properties.button, isTrue);
      expect(selected.properties.selected, isTrue);
      expect(cancel.hitTestable(), findsOneWidget);
      expect(apply.hitTestable(), findsOneWidget);
      expect(results, isEmpty);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp / 200 % / IME: Wahl erst durch Übernehmen zurückgeben', (
    tester,
  ) async {
    final results = <CharacterPortraitChoice?>[];
    await _open(
      tester,
      width: 320,
      scale: 2,
      keyboard: 220,
      onResult: results.add,
    );
    await _select(tester, 8);
    expect(results, isEmpty);
    await tester.tap(_key('portrait-apply'));
    await tester.pumpAndSettle();
    expect(results, hasLength(1));
    expect(results.single!.preset, 8);
    expect(results.single!.photoBase64, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '360 dp mit normaler Schrift behält zwei Aktionen nebeneinander',
    (tester) async {
      final results = <CharacterPortraitChoice?>[];
      await _open(
        tester,
        width: 360,
        scale: 1,
        keyboard: 0,
        onResult: results.add,
      );
      final cancel = _key('portrait-cancel');
      final apply = _key('portrait-apply');
      expect(cancel.hitTestable(), findsOneWidget);
      expect(apply.hitTestable(), findsOneWidget);
      expect(
        (tester.getCenter(cancel).dy - tester.getCenter(apply).dy).abs(),
        lessThan(1),
      );
      expect(tester.getCenter(cancel).dx, lessThan(tester.getCenter(apply).dx));
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(tester.takeException(), isNull);
    },
  );
}
