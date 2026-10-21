import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/ui/srd_fireball_grid_preview_dialog.dart';

Future<void> _open(WidgetTester tester, SrdSpellDefinition spell) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1100));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => SrdFireballGridPreviewDialog(fireball: spell),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final found = find.byKey(ValueKey(key));
  await tester.ensureVisible(found);
  await tester.tap(found);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  testWidgets('unconfirmed map cannot create a spell or preview', (
    tester,
  ) async {
    await _open(tester, catalog.find('Fireball')!);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsOneWidget,
    );

    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsOneWidget,
    );
    expect(find.textContaining('mögliche 2D-Bodenfelder'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsNothing,
    );

    await _tap(tester, 'fireball-preview-close');
    expect(find.text('Öffnen'), findsOneWidget);
    expect(find.text('Feuerball: Flächenvorschau'), findsNothing);
  });

  testWidgets('editing wall invalidates review and blocks origin ray', (
    tester,
  ) async {
    await _open(tester, catalog.find('Fireball')!);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsOneWidget,
    );

    await _tap(tester, 'fireball-tool-wall');
    await _tap(tester, 'fireball-cell-4-5');
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsNothing,
    );

    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsOneWidget,
    );
    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsNothing,
    );

    await _tap(tester, 'fireball-cell-4-5');
    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsOneWidget,
    );
  });

  testWidgets('reset clears walls, result and previous map confirmation', (
    tester,
  ) async {
    await _open(tester, catalog.find('Fireball')!);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _tap(tester, 'fireball-tool-wall');
    await _tap(tester, 'fireball-cell-4-5');
    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsOneWidget,
    );

    await _tap(tester, 'fireball-preview-reset');
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsNothing,
    );
    final confirmation = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('fireball-map-surveyed')),
    );
    expect(confirmation.value, isFalse);
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsOneWidget,
    );
    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsOneWidget,
    );
  });

  testWidgets('other spells cannot borrow Fireball dimensions', (tester) async {
    await _open(tester, catalog.find('Magic Missile')!);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _tap(tester, 'fireball-map-surveyed');
    await _tap(tester, 'fireball-preview-calculate');
    expect(
      find.byKey(const ValueKey('fireball-preview-error')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('fireball-preview-summary')),
      findsNothing,
    );
  });
}
