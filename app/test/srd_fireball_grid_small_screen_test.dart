import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/ui/srd_fireball_grid_preview_dialog.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required SrdSpellDefinition fireball,
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
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) =>
                    SrdFireballGridPreviewDialog(fireball: fireball),
              );
            },
            child: const Text('Flächenvorschau öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Flächenvorschau öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String name) async {
  final finder = _key(name);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('$width dp/200 %/IME: scrollable preview and touch cells', (
      tester,
    ) async {
      await _open(tester, width: width, fireball: catalog.find('Fireball')!);

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      expect(
        dialog.insetPadding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      );
      final cell = tester.getSize(_key('fireball-cell-0-0'));
      expect(cell.width, greaterThanOrEqualTo(48));
      expect(cell.height, greaterThanOrEqualTo(48));
      final mapScroll = tester.widget<SingleChildScrollView>(
        _key('fireball-map-horizontal'),
      );
      expect(mapScroll.scrollDirection, Axis.horizontal);

      await _tap(tester, 'fireball-preview-calculate');
      expect(_key('fireball-preview-summary'), findsNothing);
      expect(_key('fireball-preview-error'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && (widget.properties.liveRegion ?? false),
        ),
        findsWidgets,
      );
      await _tap(tester, 'fireball-preview-close');
      expect(find.byType(SrdFireballGridPreviewDialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: explicit review and map edit reset', (
    tester,
  ) async {
    await _open(tester, width: 320, fireball: catalog.find('Fireball')!);

    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(_key('fireball-preview-summary'), findsOneWidget);
    expect(_key('fireball-preview-error'), findsNothing);

    await _tap(tester, 'fireball-tool-wall');
    await _tap(tester, 'fireball-cell-0-0');
    expect(_key('fireball-preview-summary'), findsNothing);
    expect(
      tester
          .widget<CheckboxListTile>(_key('fireball-map-surveyed'))
          .value,
      isFalse,
    );
    await _tap(tester, 'fireball-preview-calculate');
    expect(_key('fireball-preview-error'), findsOneWidget);
    await _tap(tester, 'fireball-preview-reset');
    expect(_key('fireball-preview-error'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: large map reaches confirmation and reset', (
    tester,
  ) async {
    await _open(tester, width: 360, fireball: catalog.find('Fireball')!);

    await _tap(tester, 'fireball-map-size');
    final larger = find.text('32 × 32 Felder').last;
    await tester.ensureVisible(larger);
    await tester.pumpAndSettle();
    await tester.tap(larger);
    await tester.pumpAndSettle();

    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(_key('fireball-preview-summary'), findsOneWidget);
    await _tap(tester, 'fireball-preview-reset');
    expect(_key('fireball-preview-summary'), findsNothing);
    expect(
      tester
          .widget<CheckboxListTile>(_key('fireball-map-surveyed'))
          .value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
